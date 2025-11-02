/**
 * Path Extractor Logic - Bug Bounty Wordlist Mode
 * FIXED VERSION - All 6 bugs resolved
 * 
 * Changelog:
 * - Bug #1: Changed return null to return '' in removeFileExtension()
 * - Bug #2: Fixed base64 filter - added common words to regex
 * - Bug #3: Removed splitSegments option - segments mode always splits
 * - Bug #4: Added hash fragment (#) handling
 * - Bug #5: Changed dot filter to only filter file extensions at end
 * - Bug #6: Improved normalizePath clarity
 */

class PathExtractor {
    constructor(options = {}) {
        this.options = {
            mode: options.mode || 'segments', // 'segments', 'fullpaths', 'domains'
            excludeQuery: options.excludeQuery !== false,
            excludeExtensions: options.excludeExtensions !== false,
            excludeArticles: options.excludeArticles !== false
        };

        // Common words yang diizinkan meski panjang/mirip base64
        // FIX: Added authentication, authorization, session, etc
        this.commonWords = /admin|api|user|login|logout|search|download|upload|profile|settings|config|debug|test|dev|backup|dashboard|panel|account|register|forgot|reset|password|checkout|cart|payment|order|product|category|blog|post|page|contact|about|service|pricing|feature|documentation|docs|help|support|faq|terms|privacy|policy|v1|v2|v3|auth|oauth|token|refresh|verify|confirm|activate|webhook|callback|notify|subscribe|unsubscribe|export|import|report|analytics|stats|monitor|health|status|version|authentication|authorization|session|cookie|handler|controller|middleware|endpoint|route/i;

        // Spam keywords untuk artikel
        this.spamKeywords = ['game', 'linux', 'olivia', 'manning', 'humidifier', 'cmhwgu', 'recipe', 'casino', 'poker', 'slot', 'viagra'];

        // Technical noise patterns
        this.technicalNoise = ['Symbol.', 'Math.', 'modernizr.', 'prototype.', '__proto__'];
    }

    /**
     * Main extraction function
     * @param {string} input - Raw input (newline separated URLs/paths)
     * @returns {object} - { results: string[], stats: object }
     */
    extract(input) {
        const lines = input.split('\n').map(line => line.trim()).filter(line => line);
        const allPaths = new Set();
        let totalProcessed = 0;
        let filtered = 0;

        for (const line of lines) {
            totalProcessed++;
            const parsed = this.parseLine(line);
            
            if (!parsed) {
                filtered++;
                continue;
            }

            const paths = this.processPath(parsed);
            
            if (paths.length === 0) {
                filtered++;
            }
            
            paths.forEach(p => allPaths.add(p));
        }

        const results = Array.from(allPaths).sort();

        return {
            results,
            stats: {
                total: totalProcessed,
                filtered: totalProcessed - results.length,
                unique: results.length
            }
        };
    }

    /**
     * Parse single line - URL or path
     * @param {string} line
     * @returns {object|null} - { pathname, query, hostname }
     */
    parseLine(line) {
        if (!line) return null;

        try {
            // Try parse as full URL
            if (line.startsWith('http://') || line.startsWith('https://')) {
                const url = new URL(line);
                return {
                    pathname: url.pathname,
                    query: url.search,
                    hostname: url.hostname
                };
            }

            // Treat as relative path
            return {
                pathname: line.startsWith('/') ? line : '/' + line,
                query: '',
                hostname: null
            };
        } catch (e) {
            // Invalid URL, treat as path
            return {
                pathname: line.startsWith('/') ? line : '/' + line,
                query: '',
                hostname: null
            };
        }
    }

    /**
     * Process parsed path based on mode
     * @param {object} parsed
     * @returns {string[]}
     */
    processPath(parsed) {
        // Domain mode - return hostname only
        if (this.options.mode === 'domains') {
            return parsed.hostname ? [parsed.hostname] : [];
        }

        let pathname = parsed.pathname;

        // FIX Bug #4: Handle both ? and # fragments
        if (this.options.excludeQuery) {
            pathname = pathname.split('?')[0].split('#')[0];
        }

        // Normalize: remove multiple slashes
        pathname = this.normalizePath(pathname);

        // Remove file extensions if option enabled
        if (this.options.excludeExtensions) {
            pathname = this.removeFileExtension(pathname);
            if (!pathname) return []; // Empty string check
        }

        // Full path mode
        if (this.options.mode === 'fullpaths') {
            if (this.shouldRemovePath(pathname)) return [];
            return [pathname];
        }

        // FIX Bug #3: Segments mode always splits (no splitSegments option)
        if (this.options.mode === 'segments') {
            return this.extractSegments(pathname);
        }

        return [];
    }

    /**
     * FIX Bug #6: Improved clarity
     * Normalize path: /a//b -> /a/b
     */
    normalizePath(path) {
        const normalized = path.replace(/\/+/g, '/').replace(/\/$/, '');
        return normalized || '/';
    }

    /**
     * FIX Bug #1: Return empty string instead of null
     * Remove file extension from path
     * Returns empty string if path ends with excluded extension
     */
    removeFileExtension(path) {
        const excludedExts = [
            '.js', '.jsx', '.ts', '.tsx',
            '.css', '.scss', '.sass', '.less',
            '.png', '.jpg', '.jpeg', '.gif', '.svg', '.ico', '.webp',
            '.woff', '.woff2', '.ttf', '.eot', '.otf',
            '.mp4', '.mp3', '.avi', '.mov', '.webm',
            '.pdf', '.doc', '.docx', '.xls', '.xlsx',
            '.zip', '.rar', '.tar', '.gz',
            '.json', '.xml', '.txt', '.md'
        ];
        
        const lowerPath = path.toLowerCase();
        for (const ext of excludedExts) {
            if (lowerPath.endsWith(ext)) {
                return ''; // Return empty string, not null
            }
        }

        return path;
    }

    /**
     * Extract segments from path
     * /api/v1/users -> ['/api', '/v1', '/users']
     */
    extractSegments(path) {
        const segments = path.split('/').filter(s => s);
        const results = [];

        for (const segment of segments) {
            if (!this.shouldRemoveSegment(segment)) {
                results.push('/' + segment);
            }
        }

        return results;
    }

    /**
     * Check if entire path should be removed
     */
    shouldRemovePath(path) {
        const segments = path.split('/').filter(s => s);
        
        // If all segments are bad, remove path
        const validSegments = segments.filter(s => !this.shouldRemoveSegment(s));
        return validSegments.length === 0;
    }

    /**
     * Core filtering logic for segments
     */
    shouldRemoveSegment(segment) {
        if (!segment) return true;

        // FIX Bug #5: Only filter if looks like file extension at end
        // Changed from segment.includes('.') to more specific pattern
        if (/\.[a-z]{2,4}$/i.test(segment)) {
            return true;
        }

        // 2. Base64 standard pattern (long alphanumeric with +/=)
        if (/^[A-Za-z0-9+\/=]{20,}$/.test(segment)) {
            return true;
        }

        // FIX Bug #2: Base64 URL-safe pattern with better common words check
        if (/^[A-Za-z0-9_-]{20,}$/.test(segment)) {
            // Exception: if contains common words, keep it
            // Now checks if segment CONTAINS any common word (not exact match)
            if (!this.commonWords.test(segment)) {
                return true;
            }
        }

        // 4. UUID patterns
        if (/^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(segment)) {
            return true;
        }

        // 5. Long hexadecimal (MD5, SHA, etc - 32+ chars)
        if (/^[0-9a-f]{32,}$/i.test(segment)) {
            return true;
        }

        // 6. Pure numeric ID
        if (/^\d+$/.test(segment)) {
            return true;
        }

        // 7. Technical noise patterns
        for (const noise of this.technicalNoise) {
            if (segment.includes(noise)) {
                return true;
            }
        }

        // 8. SEO spam / article paths (if option enabled)
        if (this.options.excludeArticles && this.isSpammyArticle(segment)) {
            return true;
        }

        return false;
    }

    /**
     * Detect spammy article paths
     * Example: olivia-manning-cmhwgu
     */
    isSpammyArticle(segment) {
        const clean = segment.toLowerCase();
        
        // Count hyphens
        const hyphenCount = (clean.match(/-/g) || []).length;
        
        // Must have at least 2 hyphens
        if (hyphenCount < 2) return false;

        // Check for spam keywords
        const hasSpam = this.spamKeywords.some(keyword => clean.includes(keyword));
        
        return hasSpam;
    }

    /**
     * Format output as string
     */
    formatOutput(results) {
        return results.join('\n');
    }
}

// Export for CommonJS (optional, safe in browser)
if (typeof module !== 'undefined' && module.exports) {
    module.exports = PathExtractor;
}
