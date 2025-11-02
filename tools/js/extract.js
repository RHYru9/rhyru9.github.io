/**
 * PathExtractor - Universal Pattern-Based Bug Bounty Wordlist Generator
 * 
 * WORKFLOW:
 * 1. Collect URLs from wayback machine, katana, waymore → tests.txt
 * 2. Process with Path Extractor → Extract clean segments
 * 3. Copy results → Paste to seclist.txt
 * 4. Use seclist.txt as wordlist for fuzzing (ffuf, dirsearch, etc)
 * 
 * PHILOSOPHY:
 * - NO hardcoded path names (gdl, library, etc)
 * - Filter based on UNIVERSAL PATTERNS (IDs, hashes, long titles)
 * - Let clean segments pass through (regardless of name)
 * - Smart document operation detection (/read/123, /view/456)
 */

class PathExtractor {
    constructor(options = {}) {
        this.options = {
            mode: options.mode || 'segments', // 'segments', 'fullpaths', 'domains'
            excludeQuery: options.excludeQuery !== false,
            excludeExtensions: options.excludeExtensions !== false,
            excludeDocumentContent: options.excludeDocumentContent !== false,
            minSegmentLength: options.minSegmentLength || 2,
            maxSegmentLength: options.maxSegmentLength || 40,
            blacklistFiles: options.blacklistFiles || [
                'blacklists/humannames.txt',
                'blacklists/keywords.txt'
            ]
        };

        // Technical words whitelist - always keep these
        this.technicalWords = new Set([
            'admin', 'api', 'auth', 'oauth', 'oauth2', 'login', 'logout', 'signin', 'signout',
            'register', 'signup', 'dashboard', 'panel', 'console', 'control', 'management',
            'settings', 'config', 'configuration', 'profile', 'account', 'user', 'users',
            'search', 'upload', 'download', 'export', 'import', 'backup', 'restore',
            'debug', 'test', 'dev', 'development', 'staging', 'production', 'beta',
            'checkout', 'cart', 'payment', 'order', 'orders', 'product', 'products',
            'category', 'categories', 'blog', 'post', 'posts', 'page', 'pages',
            'article', 'articles', 'news', 'media', 'gallery', 'images', 'photos',
            'contact', 'about', 'service', 'services', 'pricing', 'features', 'plans',
            'documentation', 'docs', 'help', 'support', 'faq', 'terms', 'privacy', 'policy',
            'webhook', 'callback', 'notify', 'notification', 'notifications', 'subscribe',
            'unsubscribe', 'report', 'reports', 'analytics', 'statistics', 'stats',
            'monitor', 'health', 'status', 'version', 'endpoint', 'endpoints',
            'route', 'routes', 'handler', 'handlers', 'middleware', 'controller',
            'model', 'view', 'template', 'assets', 'static', 'public', 'resources',
            'files', 'uploads', 'download', 'library', 'repo', 'repository',
            'archive', 'archives', 'data', 'database', 'storage', 'cache'
        ]);

        // Document operation keywords
        this.documentOperations = new Set([
            'read', 'view', 'show', 'display', 'preview', 'download', 'get', 'fetch',
            'detail', 'details', 'info', 'information', 'browse', 'explore', 'list',
            'view_data', 'read_data', 'show_data', 'get_data', 'fetch_data'
        ]);

        // Blacklists - will be loaded from files
        this.humanNames = new Set();
        this.spamKeywords = new Set();
        this.blacklistsLoaded = false;

        // Statistics
        this.stats = {
            total: 0,
            filtered: {
                spam: 0,
                humanName: 0,
                extension: 0,
                documentId: 0,
                longTitle: 0,
                hash: 0,
                base64: 0,
                uuid: 0,
                date: 0,
                numeric: 0,
                mixed: 0,
                technical: 0,
                length: 0
            }
        };
    }

    /**
     * Load blacklist files (human names + spam keywords)
     */
    async loadBlacklists() {
        if (this.blacklistsLoaded) return;

        const results = {
            humanNames: 0,
            keywords: 0,
            errors: []
        };

        for (const filepath of this.options.blacklistFiles) {
            try {
                const response = await fetch(filepath);
                if (!response.ok) {
                    throw new Error(`HTTP ${response.status}`);
                }

                const text = await response.text();
                const entries = text
                    .split('\n')
                    .map(line => line.trim().toLowerCase())
                    .filter(line => line && !line.startsWith('#'));

                // Determine target set based on filename
                if (filepath.includes('humannames') || filepath.includes('human')) {
                    entries.forEach(name => this.humanNames.add(name));
                    results.humanNames += entries.length;
                    console.log(`✅ Loaded ${entries.length} human names from ${filepath}`);
                } else if (filepath.includes('keywords') || filepath.includes('spam')) {
                    entries.forEach(keyword => this.spamKeywords.add(keyword));
                    results.keywords += entries.length;
                    console.log(`✅ Loaded ${entries.length} spam keywords from ${filepath}`);
                } else {
                    // Default to spam keywords
                    entries.forEach(keyword => this.spamKeywords.add(keyword));
                    results.keywords += entries.length;
                    console.log(`✅ Loaded ${entries.length} entries from ${filepath}`);
                }
            } catch (error) {
                const errorMsg = `⚠️ Could not load ${filepath}: ${error.message}`;
                console.warn(errorMsg);
                results.errors.push(errorMsg);
            }
        }

        // If no blacklists loaded, use defaults
        if (this.humanNames.size === 0 && this.spamKeywords.size === 0) {
            console.warn('⚠️ No blacklists loaded, using defaults');
            this.useDefaultBlacklists();
        }

        this.blacklistsLoaded = true;
        console.log(`📊 Total loaded: ${results.humanNames} human names, ${results.keywords} spam keywords`);
        
        return results;
    }

    /**
     * Fallback default blacklists
     */
    useDefaultBlacklists() {
        // Default human names (common Indonesian names)
        const defaultNames = [
            'aan', 'abdul', 'abdullah', 'adam', 'ade', 'adi', 'aditya',
            'adrian', 'agung', 'agus', 'ahmad', 'akbar', 'alex', 'ali',
            'amelia', 'andi', 'andika', 'andre', 'andreas', 'andri',
            'angga', 'anna', 'anton', 'arif', 'aris', 'asep', 'budi',
            'bambang', 'deni', 'dian', 'dina', 'dwi', 'eka', 'endang',
            'fahmi', 'fajar', 'fauzi', 'fikri', 'hadi', 'handoko',
            'hendra', 'heri', 'herman', 'ida', 'imam', 'indah', 'irfan',
            'irwan', 'joko', 'kartika', 'lestari', 'made', 'maya',
            'muhammad', 'nia', 'nur', 'nurul', 'putra', 'putri', 'rani',
            'ratna', 'reza', 'rian', 'ridwan', 'rini', 'sari', 'siti',
            'sri', 'surya', 'taufik', 'tedi', 'tri', 'umar', 'wati',
            'widya', 'wulan', 'yanti', 'yudi', 'yusuf'
        ];
        defaultNames.forEach(name => this.humanNames.add(name));

        // Default spam keywords
        const defaultKeywords = [
            // Gambling & Adult
            'casino', 'poker', 'slot', 'slots', 'betting', 'bet', 'gamble',
            'viagra', 'cialis', 'pharmacy', 'adult', 'porn', 'xxx',
            
            // Indonesian gambling
            'togel', 'judi', 'maxwin', 'gacor', 'akun-pro', 'demo-',
            'bandar', 'agen-', 'depo', 'bonus', 'win-com', 'bola-',
            'prize', 'pools', 'toto', 'gaming', 'olympus', 'gates',
            'zeus', 'pragmatic', 'habanero', 'mahjong', 'jackpot',
            'rtp', 'login-com', 'situs', 'daftar', 'link', 'resmi-com',
            
            // Common spam
            'game', 'recipe', 'humidifier', 'discount', 'promo', 'sale',
            'cheap', 'free-', 'win-', 'earn-', 'money-'
        ];
        defaultKeywords.forEach(kw => this.spamKeywords.add(kw));

        console.log(`ℹ️ Using defaults: ${this.humanNames.size} names, ${this.spamKeywords.size} keywords`);
    }

    /**
     * MAIN EXTRACTION FUNCTION
     * Input: tests.txt content (URLs from wayback/katana/waymore)
     * Output: seclist.txt content (clean wordlist for fuzzing)
     */
    async extract(input) {
        // Load blacklists first
        await this.loadBlacklists();

        const lines = input.split('\n').map(line => line.trim()).filter(line => line);
        const allPaths = new Set();
        
        // Reset stats
        this.stats.total = lines.length;
        Object.keys(this.stats.filtered).forEach(key => this.stats.filtered[key] = 0);

        for (const line of lines) {
            const parsed = this.parseLine(line);
            if (!parsed) continue;

            const paths = this.processPath(parsed);
            paths.forEach(p => allPaths.add(p));
        }

        const results = Array.from(allPaths).sort();

        return {
            results,
            stats: {
                total: this.stats.total,
                unique: results.length,
                filtered: this.stats.filtered,
                filteredTotal: Object.values(this.stats.filtered).reduce((a, b) => a + b, 0),
                keepRate: ((results.length / this.stats.total) * 100).toFixed(2) + '%'
            }
        };
    }

    /**
     * Parse URL or path into components
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
                    hash: url.hash,
                    hostname: url.hostname
                };
            }

            // Treat as relative path
            return {
                pathname: line.startsWith('/') ? line : '/' + line,
                query: '',
                hash: '',
                hostname: null
            };
        } catch (e) {
            // Invalid URL, treat as path
            return {
                pathname: line.startsWith('/') ? line : '/' + line,
                query: '',
                hash: '',
                hostname: null
            };
        }
    }

    /**
     * Process path based on mode
     */
    processPath(parsed) {
        // Domain mode - extract hostnames only
        if (this.options.mode === 'domains') {
            return parsed.hostname ? [parsed.hostname] : [];
        }

        let pathname = parsed.pathname;

        // Remove query string and hash fragment
        if (this.options.excludeQuery) {
            pathname = pathname.split('?')[0].split('#')[0];
        }

        // Normalize path (remove duplicate slashes)
        pathname = this.normalizePath(pathname);

        // Check and remove file extensions
        if (this.options.excludeExtensions) {
            pathname = this.removeFileExtension(pathname);
            if (!pathname) return []; // Was a file, filtered out
        }

        // Full path mode - return complete paths
        if (this.options.mode === 'fullpaths') {
            if (this.shouldRemovePath(pathname)) return [];
            return [pathname];
        }

        // Segments mode - split into individual segments
        if (this.options.mode === 'segments') {
            return this.extractSegments(pathname);
        }

        return [];
    }

    /**
     * Normalize path: /a//b -> /a/b
     */
    normalizePath(path) {
        const normalized = path.replace(/\/+/g, '/').replace(/\/$/, '');
        return normalized || '/';
    }

    /**
     * Remove file extensions from paths
     * Returns empty string if extension should be filtered
     */
    removeFileExtension(path) {
        const excludedExts = [
            // Code
            '.js', '.jsx', '.ts', '.tsx', '.mjs', '.cjs', '.vue', '.py', '.rb', '.php',
            '.java', '.go', '.rs', '.c', '.cpp', '.h', '.hpp',
            
            // Styles
            '.css', '.scss', '.sass', '.less', '.styl',
            
            // Images
            '.png', '.jpg', '.jpeg', '.gif', '.svg', '.ico', '.webp', '.bmp', '.tiff',
            
            // Fonts
            '.woff', '.woff2', '.ttf', '.eot', '.otf',
            
            // Media
            '.mp4', '.mp3', '.avi', '.mov', '.webm', '.mkv', '.flv', '.wav', '.ogg',
            
            // Documents
            '.pdf', '.doc', '.docx', '.xls', '.xlsx', '.ppt', '.pptx', '.odt', '.ods',
            
            // Archives
            '.zip', '.rar', '.tar', '.gz', '.7z', '.bz2',
            
            // Data
            '.json', '.xml', '.yaml', '.yml', '.toml', '.ini', '.csv', '.log',
            '.txt', '.md', '.markdown'
        ];
        
        const lowerPath = path.toLowerCase();
        for (const ext of excludedExts) {
            if (lowerPath.endsWith(ext)) {
                this.stats.filtered.extension++;
                return '';
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

        // Detect if this is a document operation path
        const isDocPath = this.isDocumentOperationPath(segments);

        for (let i = 0; i < segments.length; i++) {
            const segment = segments[i];
            const nextSegment = segments[i + 1];
            
            // Special handling for document operations
            if (isDocPath && this.documentOperations.has(segment.toLowerCase())) {
                // Keep operation keyword (e.g., "read", "view")
                if (!this.shouldRemoveSegment(segment, false)) {
                    results.push('/' + segment);
                }
                
                // Skip next segment if it's numeric ID
                if (nextSegment && this.isNumericId(nextSegment)) {
                    this.stats.filtered.documentId++;
                    i++; // Skip next iteration
                    continue;
                }
            } else {
                // Normal segment processing
                if (!this.shouldRemoveSegment(segment, isDocPath)) {
                    results.push('/' + segment);
                }
            }
        }

        return results;
    }

    /**
     * Detect document operation path pattern
     * Examples: /gdl/read/123, /library/view/456, /repo/download/789
     */
    isDocumentOperationPath(segments) {
        if (!this.options.excludeDocumentContent) return false;
        
        for (let i = 0; i < segments.length - 1; i++) {
            const segment = segments[i].toLowerCase();
            const nextSegment = segments[i + 1];
            
            // Pattern: operation keyword + numeric ID
            if (this.documentOperations.has(segment) && this.isNumericId(nextSegment)) {
                return true;
            }
        }
        
        return false;
    }

    /**
     * Check if segment is pure numeric ID
     */
    isNumericId(segment) {
        return /^\d+$/.test(segment);
    }

    /**
     * Check if entire path should be removed
     */
    shouldRemovePath(path) {
        const segments = path.split('/').filter(s => s);
        
        // If all segments are filtered, remove entire path
        const validSegments = segments.filter(s => !this.shouldRemoveSegment(s, false));
        return validSegments.length === 0;
    }

    /**
     * CORE FILTERING LOGIC
     * Universal pattern-based filtering - NO hardcoded path names
     */
    shouldRemoveSegment(segment, isDocContext = false) {
        if (!segment) return true;

        const lower = segment.toLowerCase();
        const len = segment.length;

        // 0. LENGTH BOUNDARIES
        if (len < this.options.minSegmentLength) {
            this.stats.filtered.length++;
            return true;
        }
        
        if (len > this.options.maxSegmentLength) {
            this.stats.filtered.length++;
            return true;
        }

        // 1. TECHNICAL WORDS WHITELIST - Always keep
        if (this.technicalWords.has(lower)) {
            return false; // Explicitly keep
        }

        // 2. HUMAN NAMES - Filter out (only as whole tokens, not arbitrary substrings)
        for (const name of this.humanNames) {
            if (name.length < 2) continue; // avoid matching "a", "i", etc.

            // Escape special regex chars
            const escaped = name.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
            
            // Match only if name is surrounded by start/end, '-', '_', or digits
            const regex = new RegExp(`(^|[-_\\d])${escaped}([-_\\d]|$)`, 'i');
            
            if (regex.test(segment)) {
                this.stats.filtered.humanName++;
                return true;
            }
        }

        // 3. SPAM KEYWORDS - High priority filter
        for (const keyword of this.spamKeywords) {
            if (lower.includes(keyword)) {
                this.stats.filtered.spam++;
                return true;
            }
        }

        // 4. FILE EXTENSIONS at end (e.g., "segment.js")
        if (/\.[a-z]{2,4}$/i.test(segment)) {
            this.stats.filtered.extension++;
            return true;
        }

        // 5. PURE NUMERIC - Document IDs
        if (/^\d+$/.test(segment)) {
            this.stats.filtered.numeric++;
            return true;
        }

        // 6. DATE PATTERNS - YYYY-MM-DD, YYYY-MM, YYYY
        if (/^\d{4}(-\d{1,2}){0,2}$/.test(segment)) {
            this.stats.filtered.date++;
            return true;
        }

        // 7. UUID PATTERNS
        if (/^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(segment)) {
            this.stats.filtered.uuid++;
            return true;
        }

        // 8. HASH - Long hexadecimal (MD5=32, SHA256=64, etc)
        if (/^[0-9a-f]{32,}$/i.test(segment)) {
            this.stats.filtered.hash++;
            return true;
        }

        // 9. BASE64 STANDARD - Long alphanumeric with +/=
        if (/^[A-Za-z0-9+\/=]{20,}$/.test(segment)) {
            this.stats.filtered.base64++;
            return true;
        }

        // 10. BASE64 URL-SAFE - Long alphanumeric with _-
        if (/^[A-Za-z0-9_-]{20,}$/.test(segment)) {
            this.stats.filtered.base64++;
            return true;
        }

        // 11. MIXED ALPHANUMERIC SPAM
        if (len > 15) {
            const digitCount = (segment.match(/\d/g) || []).length;
            const upperCount = (segment.match(/[A-Z]/g) || []).length;
            if (digitCount > 3 && upperCount > 2) {
                this.stats.filtered.mixed++;
                return true;
            }
        }

        // 12. MOSTLY NUMBERS - 60%+ digits
        if (len > 10) {
            const digitCount = (segment.match(/\d/g) || []).length;
            const digitRatio = digitCount / len;
            if (digitRatio > 0.6) {
                this.stats.filtered.numeric++;
                return true;
            }
        }

        // 13. LONG ARTICLE TITLES - Multiple hyphens
        const hyphenCount = (segment.match(/-/g) || []).length;
        if (hyphenCount >= 5) {
            this.stats.filtered.longTitle++;
            return true;
        }
        if (len > 50 && hyphenCount >= 3) {
            this.stats.filtered.longTitle++;
            return true;
        }
        if (len > 30 && hyphenCount >= 4) {
            this.stats.filtered.longTitle++;
            return true;
        }

        // 14. TECHNICAL NOISE PATTERNS
        const technicalNoise = [
            'Symbol.', 'Math.', 'modernizr.', 'prototype.', '__proto__',
            'constructor', 'toString', 'valueOf', 'hasOwnProperty'
        ];
        for (const noise of technicalNoise) {
            if (segment.includes(noise)) {
                this.stats.filtered.technical++;
                return true;
            }
        }

        return false;
    }

    /**
     * Format results as string (ready for seclist.txt)
     */
    formatOutput(results) {
        return results.join('\n');
    }

    /**
     * Get detailed statistics report
     */
    getStatsReport() {
        const total = this.stats.total;
        const filteredTotal = Object.values(this.stats.filtered).reduce((a, b) => a + b, 0);
        
        return {
            summary: {
                total: total,
                filtered: filteredTotal,
                kept: total - filteredTotal,
                filterRate: ((filteredTotal / total) * 100).toFixed(2) + '%',
                keepRate: (((total - filteredTotal) / total) * 100).toFixed(2) + '%'
            },
            breakdown: this.stats.filtered
        };
    }
}

// Export for Node.js or browser
if (typeof module !== 'undefined' && module.exports) {
    module.exports = PathExtractor;
}
