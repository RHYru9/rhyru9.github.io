// ========== SIMPLE VERSION WITH CONFIGURABLE TLDs ==========
let o = []; // originalUrls
let c = []; // currentUrls
let customTLDs = new Set(); // User-defined multi-level TLDs

// Init
document.addEventListener('DOMContentLoaded', function() {
    document.getElementById('currentDate').textContent = new Date().toLocaleDateString('en-US', {
        year: 'numeric',
        month: 'long',
        day: 'numeric'
    });

    // Load saved TLD config
    loadTLDConfig();

    let t;
    document.getElementById('urls').addEventListener('input', function() {
        clearTimeout(t);
        t = setTimeout(() => {
            u();
            s();
        }, 400);
    });
});

// ========== TLD CONFIGURATION ==========
function loadTLDConfig() {
    const saved = localStorage.getItem('customTLDs');
    if (saved) {
        try {
            const arr = JSON.parse(saved);
            customTLDs = new Set(arr);
            updateTLDDisplay();
        } catch (e) {
            console.error('Failed to load TLD config:', e);
        }
    }
}

function saveTLDConfig() {
    localStorage.setItem('customTLDs', JSON.stringify([...customTLDs]));
}

function updateTLDDisplay() {
    const display = document.getElementById('tldList');
    if (!display) return;
    
    const sorted = [...customTLDs].sort();
    if (sorted.length === 0) {
        display.innerHTML = '<em style="color: #666;">No custom TLDs configured</em>';
    } else {
        display.innerHTML = sorted.map(tld => 
            `<span class="tld-tag">.${tld} <button onclick="removeTLD('${tld}')" title="Remove">×</button></span>`
        ).join(' ');
    }
}

function showTLDConfig() {
    const modal = document.getElementById('tldModal');
    if (modal) {
        modal.style.display = 'flex';
        document.getElementById('tldInput').focus();
    }
}

function hideTLDConfig() {
    const modal = document.getElementById('tldModal');
    if (modal) {
        modal.style.display = 'none';
    }
}

function addTLD() {
    const input = document.getElementById('tldInput');
    let tld = input.value.trim().toLowerCase();
    
    if (!tld) {
        m('Please enter a TLD');
        return;
    }
    
    // Remove leading dot if present
    tld = tld.replace(/^\.+/, '');
    
    // Validate TLD format
    if (!/^[a-z0-9.-]+$/.test(tld)) {
        m('Invalid TLD format. Use only letters, numbers, dots, and hyphens.');
        return;
    }
    
    if (customTLDs.has(tld)) {
        m('TLD already exists');
        return;
    }
    
    customTLDs.add(tld);
    saveTLDConfig();
    updateTLDDisplay();
    input.value = '';
    m(`Added .${tld}`);
}

function removeTLD(tld) {
    if (confirm(`Remove .${tld}?`)) {
        customTLDs.delete(tld);
        saveTLDConfig();
        updateTLDDisplay();
        m(`Removed .${tld}`);
    }
}

function clearAllTLDs() {
    if (confirm('Clear all custom TLDs?')) {
        customTLDs.clear();
        saveTLDConfig();
        updateTLDDisplay();
        m('All TLDs cleared');
    }
}

function addCommonIndonesianTLDs() {
    const common = ['co.id', 'ac.id', 'go.id', 'sch.id', 'net.id', 'or.id', 'web.id', 'my.id', 'mil.id'];
    let added = 0;
    common.forEach(tld => {
        if (!customTLDs.has(tld)) {
            customTLDs.add(tld);
            added++;
        }
    });
    saveTLDConfig();
    updateTLDDisplay();
    m(`Added ${added} Indonesian TLDs`);
}

// ========== CORE FUNCTIONS ==========
function u() { // updateOriginalUrls
    const i = document.getElementById("urls").value.trim();
    o = i.split('\n')
        .map(url => x(url))
        .filter(url => url && url.length > 0);
    c = [...o];
}

function z(urls) { // updateCurrentUrls
    c = urls;
    document.getElementById("cleanedUrls").value = c.join('\n');
}

function x(url) { // sanitizeUrl
    if (!url || typeof url !== 'string') return '';
    return url.trim()
             .replace(/[\x00-\x1F\x7F]/g, '')
             .replace(/\s+/g, ' ');
}

function v(domain, opt = {}) { // isValidDomain
    const { ip = true, local = true, strict = false } = opt;
    
    if (!domain) return false;

    // IP check
    if (/^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}$/.test(domain)) {
        if (!ip) return false;
        return p(domain);
    }

    // Local domains
    if (domain === 'localhost' || domain.endsWith('.local') || domain.endsWith('.test')) {
        return local;
    }

    // New TLDs
    if (domain.endsWith('.dev') || domain.endsWith('.local') || domain.endsWith('.internal')) {
        return !strict;
    }

    // IDN
    if (domain.startsWith('xn--')) {
        return !strict;
    }

    return strict ? vs(domain) : vl(domain);
}

function vl(domain) { // isValidDomainLenient
    if (!domain || domain.length > 253) return false;
    
    const l = domain.split('.');
    if (l.length < 1) return false;
    
    for (let i = 0; i < l.length; i++) {
        const label = l[i];
        if (label.length === 0 || label.length > 63) return false;
        if (!/^[a-z0-9-]+$/.test(label)) return false;
        if (label.startsWith('-') || label.endsWith('-')) return false;
    }
    
    return true;
}

function vs(domain) { // isValidDomainStrict
    if (!vl(domain)) return false;
    
    const parts = domain.split('.');
    const t = parts[parts.length - 1];
    
    if (t.length < 2) return false;
    if (/^\d+$/.test(t)) return false;
    if (!/[a-z]/.test(t)) return false;
    
    return true;
}

function p(ip) { // validateIPAddress
    const parts = ip.split('.');
    if (parts.length !== 4) return false;
    
    return parts.every(part => {
        const num = parseInt(part, 10);
        return num >= 0 && num <= 255 && part === num.toString();
    });
}

function d(url) { // extractDomain
    if (!url) return null;
    
    try {
        url = x(url);
        const u = new URL(url.startsWith('http') ? url : 'http://' + url);
        return u.hostname;
    } catch {
        return url.replace(/^https?:\/\//, '')
                 .replace(/^www\./, '')
                 .split('/')[0]
                 .split('?')[0]
                 .split('#')[0]
                 .split(':')[0];
    }
}

function r(url) { // extractRootDomain
    if (!url) return '';
    
    try {
        const domain = d(url);
        if (!domain) return '';
        return rd(domain);
    } catch {
        return '';
    }
}

function rd(hostname) { // extractRootDomainFromHostname - WITH CUSTOM TLD SUPPORT
    if (!hostname || typeof hostname !== 'string') return '';
    
    const parts = hostname.split('.').filter(p => p);
    if (parts.length <= 2) return hostname;

    // Check custom TLDs first (exact match)
    for (let i = 1; i < parts.length; i++) {
        const suffix = parts.slice(-i).join('.');
        if (customTLDs.has(suffix)) {
            // Return domain + custom TLD
            if (parts.length > i) {
                return parts.slice(-(i + 1)).join('.');
            }
            return hostname;
        }
    }

    const tld = parts[parts.length - 1];
    const sld = parts[parts.length - 2];

    // Country TLDs
    const countryTLDs = new Set([
        'id', 'uk', 'au', 'jp', 'in', 'br', 'cn', 'fr', 'de', 'it', 'es', 'nl', 'ru',
        'kr', 'sg', 'hk', 'tw', 'th', 'vn', 'my', 'ph', 'tr', 'pl', 'se', 'no', 'dk',
        'fi', 'cz', 'hu', 'ro', 'gr', 'pt', 'il', 'sa', 'ae', 'eg', 'za', 'ng', 'ke',
        'mx', 'ar', 'cl', 'co', 'pe', 've', 'ec', 'uy', 'py', 'bo', 'cr', 'do', 'gt',
        'hn', 'ni', 'pa', 'sv'
    ]);

    // Common SLDs
    const commonSLDs = new Set([
        'ac', 'co', 'go', 'sch', 'mil', 'net', 'or', 'web', 'my',
        'com', 'org', 'edu', 'gov', 'ltd', 'plc', 'inc', 'pub', 'mod'
    ]);

    // Heuristic for country TLDs with short SLDs
    if (countryTLDs.has(tld) && sld.length <= 3) {
        return parts.slice(-3).join('.');
    }

    // Heuristic for common SLDs
    if (countryTLDs.has(tld) && commonSLDs.has(sld)) {
        return parts.slice(-3).join('.');
    }

    // Fallback: 2-level domain
    return parts.slice(-2).join('.');
}

function n(url) { // normalizeUrl
    if (!url) return '';
    
    try {
        url = x(url);
        const u = new URL(url.startsWith('http') ? url : 'http://' + url);
        
        let domain = u.hostname.toLowerCase().replace(/^www\./, '');
        let path = u.pathname;
        let np = npath(path);
        let nq = nquery(u.searchParams);
        
        return domain + np + nq;
    } catch {
        return url;
    }
}

function npath(path) { // normalizePath
    if (!path || path === '/') return '';
    
    const seg = path.split('/').filter(s => s !== '');
    
    const ns = seg.map(s => {
        if (/^\d+$/.test(s)) return '{id}';
        if (/^[a-f0-9]{8,}$/i.test(s)) return '{hash}';
        if (/^(id|user_id|item_id|product_id)[=_]\d+$/i.test(s)) {
            return s.replace(/\d+$/, '{id}');
        }
        return s;
    });
    
    return '/' + ns.join('/');
}

function nquery(sp) { // normalizeQueryParams
    if (!sp || sp.toString() === '') return '';
    
    const params = [];
    const names = [];
    
    sp.forEach((v, k) => names.push(k));
    names.sort();
    
    names.forEach(k => {
        const val = sp.get(k);
        let nv;
        
        if (/^\d+$/.test(val)) nv = '{num}';
        else if (/^[a-f0-9]{8,}$/i.test(val)) nv = '{hash}';
        else nv = '{val}';
        
        params.push(`${k}=${nv}`);
    });
    
    return params.length > 0 ? '?' + params.join('&') : '';
}

function e(url) { // extractBaseEndpoint
    if (!url) return '';
    
    try {
        url = x(url);
        const u = new URL(url.startsWith('http') ? url : 'http://' + url);
        
        const domain = u.hostname.toLowerCase().replace(/^www\./, '');
        let path = u.pathname;
        
        let cp = path.split('/')
            .map(s => /^\d+$/.test(s) ? '' : s)
            .filter(s => s !== '')
            .join('/');
        
        return domain + (cp ? '/' + cp : '');
    } catch {
        return url;
    }
}

// ========== MAIN OPERATIONS ==========
function a() { // removePathCaseDuplicates
    l(true);
    
    setTimeout(() => {
        try {
            const urls = c;
            const map = new Map();
            
            urls.forEach(url => {
                try {
                    const u = new URL(url.startsWith('http') ? url : 'http://' + url);
                    const domain = u.hostname.toLowerCase();
                    const path = u.pathname.toLowerCase();
                    
                    const key = domain + path;
                    
                    if (!map.has(key)) {
                        map.set(key, url);
                    }
                } catch (err) {
                    const norm = url.toLowerCase();
                    if (!map.has(norm)) {
                        map.set(norm, url);
                    }
                }
            });
            
            const unique = Array.from(map.values());
            z(unique);
            m(`Removed ${urls.length - unique.length} case duplicates`);
        } catch (err) {
            m('Error: ' + err.message);
        } finally {
            l(false);
        }
    }, 100);
}

function b() { // cleanUrls
    const urls = c;
    let cleaned = [...new Set(urls.map(url => d(url)).filter(Boolean))];
    z(cleaned);
    m(`Cleaned ${cleaned.length} domains from ${urls.length} URLs`);
}

function c1() { // cleanUrlsWithPaths
    l(true);
    
    setTimeout(() => {
        const urls = c;
        const map = new Map();
        
        urls.forEach(url => {
            const norm = n(url);
            if (!map.has(norm)) {
                map.set(norm, url);
            }
        });
        
        const unique = Array.from(map.values());
        z(unique);
        m(`Normalized ${urls.length} URLs, found ${unique.length} unique`);
        l(false);
    }, 100);
}

function d1() { // removeEndpointDuplicates
    const urls = c;
    const map = new Map();
    
    urls.forEach(url => {
        const endpoint = e(url);
        if (endpoint && !map.has(endpoint)) {
            map.set(endpoint, url);
        }
    });
    
    const unique = Array.from(map.values());
    z(unique);
    m(`Removed ${urls.length - unique.length} endpoint duplicates`);
}

function e1() { // addHttps
    const urls = c;
    let cleaned = urls.map(url => {
        url = x(url);
        if (url.startsWith('http://')) {
            return url.replace('http://', 'https://');
        } else if (!url.startsWith('https://') && !url.startsWith('http://')) {
            return "https://" + url;
        }
        return url;
    });
    z(cleaned);
    m('Added HTTPS to all URLs');
}

function f() { // addHttp
    const urls = c;
    let cleaned = urls.map(url => {
        url = x(url);
        if (url.startsWith('https://')) {
            return url.replace('https://', 'http://');
        } else if (!url.startsWith('http://') && !url.startsWith('https://')) {
            return "http://" + url;
        }
        return url;
    });
    z(cleaned);
    m('Added HTTP to all URLs');
}

function g() { // removeProtocols
    const urls = c;
    let cleaned = urls.map(url => url.replace(/^https?:\/\//, ''));
    z(cleaned);
    m('Removed all protocols');
}

function h() { // removeWww
    const urls = c;
    let cleaned = urls.map(url => url.replace(/^(https?:\/\/)?www\./i, '$1'));
    z(cleaned);
    m('Removed WWW from all URLs');
}

function i() { // addWww
    const urls = c;
    let cleaned = urls.map(url => {
        if (url.match(/^https?:\/\//i)) {
            return url.replace(/^(https?:\/\/)((?!www\.))/i, '$1www.');
        } else {
            return url.startsWith('www.') ? url : 'www.' + url;
        }
    });
    z(cleaned);
    m('Added WWW to all URLs');
}

function j() { // removeDuplicates
    const urls = c;
    let cleaned = [...new Set(urls)];
    z(cleaned);
    m(`Removed ${urls.length - cleaned.length} duplicates`);
}

function k() { // extractDomains
    const urls = c;
    let cleaned = [...new Set(urls.map(url => r(url)).filter(Boolean))];
    z(cleaned);
    m(`Extracted ${cleaned.length} root domains`);
}

function l1() { // sortUrls
    const urls = c;
    let cleaned = urls.sort((a, b) => a.toLowerCase().localeCompare(b.toLowerCase()));
    z(cleaned);
    m('URLs sorted');
}

function m1() { // validateUrls
    const urls = c;
    let valid = urls.filter(url => vu(url));
    let invalid = urls.length - valid.length;
    z(valid);
    m(`Found ${valid.length} valid, removed ${invalid} invalid`);
}

function n1() { // applyIncludeFilter
    const inc = gt('includeDomains');
    if (inc.length === 0) {
        m('Enter domains to include');
        return;
    }
    
    const urls = o;
    const filtered = urls.filter(url => {
        const domain = d(url);
        return domain && inc.some(incl => 
            domain === incl || domain.endsWith('.' + incl)
        );
    });
    
    z(filtered);
    m(`Filtered to ${filtered.length} URLs`);
}

function o1() { // applyExcludeFilter
    const exc = gt('excludeDomains');
    if (exc.length === 0) {
        m('Enter domains to exclude');
        return;
    }
    
    const urls = o;
    const filtered = urls.filter(url => {
        const domain = d(url);
        return !domain || !exc.some(excl => 
            domain === excl || domain.endsWith('.' + excl)
        );
    });
    
    z(filtered);
    m(`Filtered to ${filtered.length} URLs`);
}

// ========== HELPER FUNCTIONS ==========
function vu(url) { // isValidUrl
    if (!url) return false;
    
    url = x(url);
    
    const domainPat = /^(?:https?:\/\/)?(?:[a-zA-Z0-9-]+\.)+[a-zA-Z]{2,}(?:\/[^\s]*)?$/i;
    const ipPat = /^(?:https?:\/\/)?(?:\d{1,3}\.){3}\d{1,3}(?::\d+)?(?:\/[^\s]*)?$/;
    const localPat = /^(?:https?:\/\/)?localhost(?::\d+)?(?:\/[^\s]*)?$/i;
    
    return domainPat.test(url) || ipPat.test(url) || localPat.test(url);
}

function tld(domain) { // extractTLD
    if (!domain) return '';
    
    domain = x(domain);
    const root = r(domain);
    if (!root) return '';
    
    const parts = root.split('.');
    return parts[parts.length - 1];
}

function m(msg) { // showToast
    const toast = document.getElementById('toast');
    toast.textContent = msg;
    toast.classList.add('show');
    setTimeout(() => {
        toast.classList.remove('show');
    }, 3000);
}

function tc() { // toggleFilterControls
    const fc = document.getElementById('filterControls');
    if (fc.style.display === 'none') {
        fc.style.display = 'block';
    } else {
        fc.style.display = 'none';
    }
}

function gt(id) { // getDomainListFromTextarea
    const input = document.getElementById(id).value.trim();
    return input.split('\n')
        .map(line => x(line.trim()))
        .filter(line => line.length > 0)
        .map(domain => {
            return domain.replace(/^https?:\/\//, '').replace(/^www\./, '').split('/')[0];
        });
}

function s() { // updateStats
    const urls = o;
    const valid = urls.filter(line => vu(line));
    const domains = [...new Set(urls.map(line => r(line)).filter(Boolean))];
    
    document.getElementById('totalLines').textContent = urls.length;
    document.getElementById('validUrls').textContent = valid.length;
    document.getElementById('uniqueDomains').textContent = domains.length;
}

function p1() { // addSlash
    const urls = c;
    let cleaned = urls.map(url => {
        if (url.includes('?') || url.includes('#')) {
            return url;
        }
        return url.endsWith('/') ? url : url + '/';
    });
    z(cleaned);
    m('Added trailing slash');
}

function q() { // clearAll
    if (confirm('Clear all?')) {
        document.getElementById("urls").value = '';
        document.getElementById("cleanedUrls").value = '';
        document.getElementById("includeDomains").value = '';
        document.getElementById("excludeDomains").value = '';
        o = [];
        c = [];
        s();
        m('All cleared');
    }
}

function cr() { // copyResults
    const res = document.getElementById("cleanedUrls");
    res.select();
    res.setSelectionRange(0, 99999);
    navigator.clipboard.writeText(res.value).then(() => {
        m('Copied!');
    }).catch(() => {
        document.execCommand('copy');
        m('Copied!');
    });
}

function dr() { // downloadResults
    const res = document.getElementById("cleanedUrls").value;
    if (!res.trim()) {
        m('No results');
        return;
    }
    const blob = new Blob([res], { type: 'text/plain' });
    const url = window.URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = `urls-${new Date().toISOString().split('T')[0]}.txt`;
    document.body.appendChild(a);
    a.click();
    document.body.removeChild(a);
    window.URL.revokeObjectURL(url);
    m('Downloaded!');
}

function et() { // extractTLDs
    const urls = c;
    let tlds = [...new Set(urls.map(url => {
        const domain = d(url);
        return domain ? tld(domain) : null;
    }).filter(Boolean))];
    z(tlds);
    m(`Extracted ${tlds.length} TLDs`);
}

function gtld() { // groupByTLD
    l(true);
    
    setTimeout(() => {
        const urls = c;
        const grouped = {};
        urls.forEach(url => {
            const domain = d(url);
            if (domain) {
                const t = tld(domain);
                if (!grouped[t]) {
                    grouped[t] = [];
                }
                grouped[t].push(domain);
            }
        });
        let result = [];
        Object.keys(grouped).sort().forEach(t => {
            result.push(`=== .${t} ===`);
            result.push(...[...new Set(grouped[t])].sort());
            result.push('');
        });
        z(result);
        m(`Grouped by ${Object.keys(grouped).length} TLDs`);
        l(false);
    }, 100);
}

function count() { // countResults
    const res = document.getElementById("cleanedUrls").value.trim();
    const cnt = res ? res.split('\n').filter(line => line.trim()).length : 0;
    m(`Results: ${cnt} lines`);
}

function ci() { // clearIncludeFilter
    document.getElementById('includeDomains').value = '';
}

function ce() { // clearExcludeFilter
    document.getElementById('excludeDomains').value = '';
}

function l(show) { // showLoading
    const loading = document.getElementById('loading');
    const btns = document.querySelectorAll('button');
    
    if (show) {
        loading.style.display = 'block';
        btns.forEach(btn => btn.disabled = true);
    } else {
        loading.style.display = 'none';
        btns.forEach(btn => btn.disabled = false);
    }
}

// ========== TEST FUNCTION ==========
function test() {
    const testCases = [
        'ugm.ac.id',
        'kemendagri.go.id', 
        'smkn1.sch.id',
        'telkom.co.id',
        'bca.co.id',
        'desa.id',
        'google.com',
        'example.co.uk',
        'ox.ac.uk'
    ];
    
    console.log('🔍 TESTING ROOT DOMAIN EXTRACTION WITH CUSTOM TLDs:');
    console.log('='.repeat(50));
    console.log('Custom TLDs configured:', [...customTLDs]);
    console.log('');
    
    testCases.forEach(domain => {
        const result = r(domain);
        console.log(`📌 ${domain} → ${result}`);
    });
    
    const urlTests = [
        'https://ugm.ac.id/api/v1/users',
        'http://kemendagri.go.id/login',
        'www.xxx.sch.id:8080/path'
    ];
    
    console.log('\nTESTING WITH FULL URLs:');
    console.log('='.repeat(40));
    
    urlTests.forEach(url => {
        const root = r(url);
        console.log(`${url} → ${root}`);
    });
}

// Init
s();
test();
