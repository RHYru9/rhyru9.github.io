/* Dork Generator Manager - Fixed SES Exception */

class DorkManager {
    constructor() {
        this.dorkDatabase = {
            'Authentication & Access': {
                icon: '🔐',
                color: 'var(--orange)',
                dorks: {
                    'Login Pages': 'site:*.{domain} inurl:login | inurl:logon | inurl:sign-in | inurl:signin | inurl:wp-login | inurl:weblogin | inurl:loginpanel | inurl:quicklogin | inurl:memberlogin | inurl:forgotpassword | inurl:forgot-password | intitle:login | intitle:signin | intitle:sign-in | inurl:panel',
                    'Admin Login': 'site:*.{domain} inurl:admin | inurl:administrator | inurl:adm | inurl:wp-admin | inurl:adminlogin | inurl:admin-login',
                    'Register Pages': 'site:*.{domain} inurl:signup | inurl:register | inurl:create | inurl:join | inurl:account | inurl:subscription | inurl:apply | inurl:enroll | inurl:membership | inurl:sign-up | inurl:register-account',
                    'Dashboard Pages': 'site:*.{domain} intitle:dashboard | intitle:administrator | intitle:admin page | intitle:page admin | intitle:admin | intitle:portal admin',
                    'Logout Pages': 'site:*.{domain} inurl:"logout" | inurl:"auth?logout=" | inurl:"exit?" | inurl:"signout?" | inurl:"endSession" | inurl:"userSignOut" | inurl:"adminSignOut" | inurl:"logoutUser" | inurl:"?ReturnUrl=http" | inurl:"?back=http" | inurl:"=http" | inurl:"?relayState=http" -www',
                    'Contact Forms': 'site:*.{domain} inurl:feedback | inurl:contact | inurl:contact-us | inurl:contact-form | inurl:get-in-touch | inurl:reach-out'
                }
            },
            'Vulnerability Parameters': {
                icon: '🚨',
                color: '#f87171',
                dorks: {
                    'XSS Prone': 'inurl:lang=" | inurl:"name=" | inurl:"view=" | inurl:"callback=" | inurl:"id=" | inurl:"q=" | inurl:"s=" | inurl:"keyword=" | inurl:"search=" | inurl:"page=" | inurl:"query=" site:*.{domain}',
                    'Open Redirect': 'inurl:"page=" | inurl:"next=" | inurl:"host=" | inurl:"go=" | inurl:"goto=" | inurl:"file=" | inurl:"redirect_to=" | inurl:"url=" | inurl:"redirect" | inurl:src=http | inurl:r=http | inurl:return=" | inurl:"redir=" | inurl:"http" inurl:& site:*.{domain}',
                    'SQLi Prone': 'inurl:"id=" | inurl:"query=" | inurl:"q=" | inurl:"name=" | inurl:"from=" | inurl:"s=" | inurl:"search=" | inurl:"page=" | inurl:"filter=" | inurl:"action=" | inurl:"sort=" | inurl:"dir=" | inurl:"reg=" | inurl:"order=" | inurl:"update=" | inurl:"delete=" | inurl:"create=" inurl:& site:*.{domain}',
                    'SSRF Prone': 'inurl:"http=" | inurl:"load=" | inurl:"exec=" | inurl:"resource=" | inurl:"resources=" | inurl:"url=" | inurl:"path=" | inurl:"host=" | inurl:"proxy=" | inurl:"html=" | inurl:"data=" | inurl:"domain=" | inurl:"uri=" inurl:& site:*.{domain}',
                    'LFI Prone': 'inurl:"include=" | inurl:"page=" | inurl:"http=" | inurl:"path=" | inurl:"template=" | inurl:"show=" | inurl:"locate=" | inurl:"site=" | inurl:"dir=" | inurl:"detail=" | inurl:"file=" | inurl:"folder=" | inurl:"doc=" | inurl:"filename=" | inurl:"uri=http" inurl:& site:*.{domain}',
                    'SSTI Prone': 'inurl:"module=" | inurl:"template=" | inurl:"load=" | inurl:"run=" | inurl:"preview=" | inurl:"view=" | inurl:"content=" | inurl:"activity=" | inurl:"name=" inurl:& site:*.{domain}',
                    'RCE Prone': 'inurl:"cmd=" | inurl:"ip=" | inurl:"cli=" | inurl:"load=" | inurl:"module=" | inurl:"run=" | inurl:"print=" | inurl:"exec=" | inurl:"query=" | inurl:"code=" | inurl:"do=" | inurl:"read=" | inurl:"ping=" inurl:& site:*.{domain}',
                    'Sensitive Params': 'inurl:"email=" | inurl:"phone=" | inurl:"password=" | inurl:"secret=" | inurl:"token=" inurl:& site:*.{domain}'
                }
            },
            'Files & Extensions': {
                icon: '📄',
                color: '#fbbf24',
                dorks: {
                    'Backup Files': 'site:*.{domain} ext:bkf | ext:bkp | ext:bak | ext:old | ext:backup | ext:log | ext:sql',
                    'Config Files': 'site:*.{domain} ext:txt | ext:conf | ext:cnf | ext:ini | ext:env | ext:sh | ext:swp | ext:old | ext:~ | ext:htpasswd | ext:htaccess | ext:yaml | ext:yml | ext:cfg | ext:xml',
                    'Sensitive Files': 'site:*.{domain} ext:.git-credentials | ext:ppk | ext:pem | ext:json | ext:ps1 | ext:reg | ext:inf | ext:rdp | ext:ora | ext:dbf | ext:mdb',
                    'PHP Extensions': 'site:*.{domain} ext:php | ext:phtm | ext:phtml',
                    'Java Extensions': 'site:*.{domain} ext:jsp | ext:do | ext:action | ext:struts | ext:java | ext:class | ext:jar | ext:war | ext:ear',
                    'ASP.NET Extensions': 'site:*.{domain} ext:aspx | ext:asa | ext:asp | ext:asax',
                    'Script Extensions': 'site:*.{domain} ext:pl | ext:cfm | ext:py | ext:rb | ext:js',
                    'Document Files': 'site:*.{domain} ext:doc | ext:xlsx | ext:docx | ext:dotx | ext:xls | ext:xlsm | ext:odt | ext:pdf | ext:rtf | ext:sxw | ext:psw | ext:ppt | ext:pptx | ext:pps | ext:csv | ext:swf intext:password|pass|email|admin|user|offer|data|employee|order|internal|sensitive'
                }
            },
            'Web Applications': {
                icon: '🌐',
                color: '#4ade80',
                dorks: {
                    'API Docs': 'site:*.{domain} inurl:api | inurl:/rest | inurl:/v1 | inurl:/v2 | inurl:/v3 | inurl:swagger | inurl:graphql | inurl:graphiql',
                    'Server Errors': 'site:*.{domain} intext:"error" | intext:"exception" | intext:"failure" | intext:"server at" | intext:exception | intext:"database error" | intext:"SQL syntax"',
                    'File Upload': 'site:*.{domain} intext:"choose file" | intext:"file upload" | inurl:upload.php | inurl:upload.asp | inurl:upload.aspx | inurl:upload.jsp | inurl:upload.do | inurl:upload.action | intitle:"index of" "upload"',
                    'XSS Forms': 'site:*.{domain} intitle:"support" | inurl:support | inurl:"contact" | intitle:"survey" | inurl:"survey" | inurl:"feedback" | intitle:"feedback" | inurl:"submit" | intitle:"submit" -pdf -doc -docx -xls',
                    'App Frameworks': 'site:*.{domain} inurl:/content/usergenerated | inurl:/content/dam | inurl:/jcr:content | inurl:/libs/granite | inurl:/etc/clientlibs | inurl:/content/geometrixx | inurl:/bin/wcm | inurl:/crx/de | "Whoops! There was an error." | inurl:/frontend_dev.php/$ | inurl:/app/config/ | inurl:/settings.py intitle:"Index of" | "SF_ROOT_DIR"',
                    'Directory Listing': 'site:*.{domain} intitle:"index of /" | intitle:"index of /" admin|user|portal|data|config|backup|password|email|employee|upload|uploads|download | intitle:"Index of" .env | .git | wc.db | .svn | .hg | .ovpn | config.php | database.sql',
                    'Test Environment': 'site:*.{domain} inurl:test | inurl:env | inurl:dev | inurl:staging | inurl:sandbox | inurl:debug | inurl:temp | inurl:internal | inurl:demo',
                    'Error Messages': 'site:*.{domain} "unexpected error" | "Uncaught Exception" | "fatal error" | "Unknown column" | "exception occurred" | "undefined index" | "unhandled exception" | "stack trace" | "query failed"'
                }
            },
            'Cloud & Code Repositories': {
                icon: '☁️',
                color: '#60a5fa',
                dorks: {
                    'Cloud Storage': 'site:s3.amazonaws.com "*.{domain}" | site:blob.core.windows.net "*.{domain}" | site:googleapis.com "*.{domain}" | site:drive.google.com "*.{domain}" | site:dev.azure.com "*.{domain}" | site:onedrive.live.com "*.{domain}" | site:digitaloceanspaces.com "*.{domain}" | site:sharepoint.com "*.{domain}" | site:amazonaws.com "*.{domain}"',
                    'Dropbox & Box': 'inurl:www.dropbox.com/s/ "*.{domain}" | site:box.com/s "*.{domain}"',
                    'Google Docs': 'site:docs.google.com inurl:"/d/" "*.{domain}"',
                    'GitHub Leaks': 'site:github.com "*.{domain}" | site:gist.github.com "*.{domain}"',
                    'GitLab Leaks': 'site:gitlab.com "*.{domain}"',
                    'Pastebin': 'site:pastebin.com "*.{domain}"',
                    'Code Sharing': 'site:codebeautify.org "*.{domain}" | site:codepad.co "*.{domain}" | site:codepen.io "*.{domain}" | site:codeshare.io "*.{domain}"',
                    'Bitbucket': 'site:bitbucket.org "*.{domain}" | site:bitbucket.org inurl:*.{domain}',
                    'NPM & Libraries': 'site:jsfiddle.net "*.{domain}" | site:libraries.io "*.{domain}" | site:npm.runkit.com "*.{domain}" | site:npmjs.com "*.{domain}" | site:repl.it "*.{domain}"',
                    'Trello Boards': 'site:trello.com "*.{domain}"',
                    'Atlassian': 'site:atlassian.net "*.{domain}" | site:atlassian.net inurl:/servicedesk/customer/user/login "*.{domain}"',
                    'Firebase': 'site:firebaseio.com "*.{domain}"'
                }
            },
            'Advanced Search': {
                icon: '🔍',
                color: '#a78bfa',
                dorks: {
                    'Confidential Docs': 'site:*.{domain} ext:doc | ext:xlsx | ext:docx | ext:dotx | ext:xls | ext:xlsm | ext:odt | ext:pdf | ext:rtf | ext:sxw | ext:psw | ext:ppt | ext:pptx | ext:pps | ext:csv | ext:swf intext:password|pass|email|admin|user|offer|data|employee|order|internal|sensitive',
                    'Internal Only': 'site:*.{domain} intext:"confidential" | "Not for Public Release" | "internal use only" | "do not distribute"',
                    'Database Files': 'site:*.{domain} intitle:"Index of" ext:sql | ext:sql.gz | ext:sql.rar | ext:sql.zip | ext:bkp | ext:bkp.gz | ext:bkp.rar | ext:bkp.zip | ext:zip | ext:7z | ext:rar | ext:gz',
                    'WordPress Files': 'site:*.{domain} inurl:wp- | inurl:wp-content | inurl:plugins | inurl:uploads | inurl:themes | inurl:download | inurl:readme | inurl:license | inurl:install | inurl:setup | inurl:config',
                    'Shell Files': 'site:*.{domain} inurl:shell | inurl:backdoor | inurl:wso | inurl:cmd | shadow | passwd | boot.ini | inurl:backdoor',
                    'JDBC Connections': 'site:*.{domain} jdbc',
                    'Download Params': 'inurl:"download?path=" | inurl:"download?file=" | inurl:"download?location=" | inurl:"download?f=" | inurl:"download?view=" | inurl:"download?preview=" | inurl:"download?show=" | inurl:"download?folder" | inurl:"download?d=" | inurl:"download?index=" | inurl:"download?id=" inurl:& site:*.{domain}',
                    'Embed Params': 'inurl:"?url=http" | inurl:"?link=http" | inurl:"?redirect=http" | inurl:"?next=http" | inurl:"?path=http" | inurl:"?file=http" | inurl:"?external=http" | inurl:"?proxy=http" | inurl:"?view=http" | inurl:"?show=http" | inurl:"?site=http" | inurl:"?page=http" | inurl:"?goto=http" | inurl:"?include=http" | inurl:"?module=http" inurl:& site:*.{domain}',
                    'Error Pages': 'site:"*.{domain}" inurl:".php?error_message=" | inurl:".php?error_msg=" | inurl:".php?err_message=" | inurl:".php?msg=" | inurl:".php?message=" | inurl:".aspx?error_message=" | inurl:".aspx?error_msg=" | inurl:".aspx?err_message=" | inurl:".aspx?msg=" | inurl:".aspx?message=" | inurl:".asp?error_message=" | inurl:".asp?error_msg=" | inurl:".asp?err_message=" | inurl:".asp?msg=" | inurl:".asp?message=" | inurl:"error_message=" | inurl:"error_msg=" | inurl:"err_message=" | inurl:"msg=" | inurl:"message="'
                }
            },
            'International': {
                icon: '🌍',
                color: '#ec4899',
                dorks: {
                    'Confidential (Dutch)': 'site:*.{domain} (ext:doc OR ext:xlsx OR ext:docx OR ext:dotx OR ext:xls OR ext:xlsm OR ext:odt OR ext:pdf OR ext:rtf OR ext:sxw OR ext:psw OR ext:ppt OR ext:pptx OR ext:pps OR ext:csv OR ext:swf) (intext:"Vertrouwelijk" OR intext:"Niet delen" OR intext:"E-mail" OR intext:"Alleen voor privégebruik" OR intext:"Niet voor publieke verspreiding" OR intext:"Alleen voor intern gebruik" OR intext:"Niet verspreiden" OR intext:wachtwoord OR intext:gebruiker OR intext:admin OR intext:intern OR intext:gevoelig OR intext:aanbieding OR intext:medewerker OR intext:bestelling OR intext:data OR intext:informatie OR intext:persoonlijk)'
                }
            }
        };

        this.executedCount = 0;
        this.history = this.loadHistory();
    }

    init() {
        this.renderCategories();
        this.updateStats();
        this.renderHistory();
        this.setupEventListeners();
        console.log('✅ DorkManager initialized');
    }

    setupEventListeners() {
        const targetInput = document.getElementById('targetDomain');
        if (targetInput) {
            targetInput.addEventListener('input', () => {
                this.updateCurrentTarget();
            });
        }
    }

    updateCurrentTarget() {
        const targetInput = document.getElementById('targetDomain');
        const targetDisplay = document.getElementById('currentTarget');
        
        if (targetInput && targetDisplay) {
            const target = targetInput.value.trim();
            targetDisplay.textContent = target || 'Not Set';
        }
    }

    renderCategories() {
        const container = document.getElementById('dorkCategories');
        if (!container) return;

        let html = '';
        
        for (const [category, data] of Object.entries(this.dorkDatabase)) {
            html += `
                <div class="base-card mb-4">
                    <div class="collapsible">
                        <div class="collapsible-header">
                            <span style="font-weight: 600; font-size: 1.1rem;">
                                ${data.icon} ${category}
                            </span>
                            <span class="badge badge-info" style="background: rgba(254, 127, 45, 0.2); color: ${data.color};">
                                ${Object.keys(data.dorks).length} dorks
                            </span>
                        </div>
                        <div class="collapsible-content">
                            <div style="display: grid; grid-template-columns: repeat(auto-fit, minmax(200px, 1fr)); gap: 1rem; margin-top: 1rem;">
                                ${this.renderDorkButtons(category, data.dorks)}
                            </div>
                        </div>
                    </div>
                </div>
            `;
        }

        container.innerHTML = html;
    }

    renderDorkButtons(category, dorks) {
        let html = '';
        
        for (const [name, query] of Object.entries(dorks)) {
            // Encode category and name to handle special characters
            const encodedCategory = this.safeEncode(category);
            const encodedName = this.safeEncode(name);
            
            html += `
                <button 
                    class="btn btn-primary dork-btn" 
                    data-category="${encodedCategory}"
                    data-name="${encodedName}"
                    style="width: 100%; justify-content: center; font-size: 0.85rem; padding: 0.7rem 1rem;">
                    ${this.escapeHtml(name)}
                </button>
            `;
        }
        
        return html;
    }

    // Safe encoding for data attributes
    safeEncode(str) {
        return btoa(unescape(encodeURIComponent(str)));
    }

    // Safe decoding for data attributes
    safeDecode(str) {
        try {
            return decodeURIComponent(escape(atob(str)));
        } catch (e) {
            console.error('Decode error:', e);
            return str;
        }
    }

    // Escape HTML to prevent XSS
    escapeHtml(text) {
        const div = document.createElement('div');
        div.textContent = text;
        return div.innerHTML;
    }

    executeDork(category, dorkName) {
        const target = document.getElementById('targetDomain').value.trim();
        
        if (!target) {
            if (window.BugHunterToolkit) {
                window.BugHunterToolkit.showNotification('Please enter a target domain first!', 'warning');
            } else {
                alert('Please enter a target domain first!');
            }
            return;
        }

        const cleanDomain = this.cleanDomain(target);
        const dorkQuery = this.dorkDatabase[category].dorks[dorkName];
        
        if (!dorkQuery) {
            console.error('Dork not found:', category, dorkName);
            return;
        }
        
        const finalQuery = dorkQuery.replace(/{domain}/g, cleanDomain);
        
        this.openGoogleSearch(finalQuery);
        this.addToHistory(category, dorkName, cleanDomain);
        this.executedCount++;
        this.updateStats();
        this.updateLastExecuted();

        if (window.BugHunterToolkit) {
            window.BugHunterToolkit.showNotification(`Executing: ${dorkName}`, 'success');
        }
    }

    executeCustomDork() {
        const target = document.getElementById('targetDomain').value.trim();
        const customDork = document.getElementById('customDork').value.trim();

        if (!target) {
            if (window.BugHunterToolkit) {
                window.BugHunterToolkit.showNotification('Please enter a target domain first!', 'warning');
            } else {
                alert('Please enter a target domain first!');
            }
            return;
        }

        if (!customDork) {
            if (window.BugHunterToolkit) {
                window.BugHunterToolkit.showNotification('Please enter a custom dork query!', 'warning');
            } else {
                alert('Please enter a custom dork query!');
            }
            return;
        }

        const cleanDomain = this.cleanDomain(target);
        const finalQuery = customDork.replace(/{domain}/g, cleanDomain);
        
        this.openGoogleSearch(finalQuery);
        this.addToHistory('Custom', 'Custom Dork', cleanDomain, customDork);
        this.executedCount++;
        this.updateStats();
        this.updateLastExecuted();

        if (window.BugHunterToolkit) {
            window.BugHunterToolkit.showNotification('Executing custom dork...', 'success');
        }
    }

    clearCustomDork() {
        const customDorkInput = document.getElementById('customDork');
        if (customDorkInput) {
            customDorkInput.value = '';
        }
    }

    cleanDomain(domain) {
        return domain
            .replace(/^https?:\/\//, '')
            .replace(/^www\./, '')
            .replace(/\/$/, '');
    }

    openGoogleSearch(query) {
        const url = `https://www.google.com/search?q=${encodeURIComponent(query)}`;
        window.open(url, '_blank');
    }

    addToHistory(category, dorkName, domain, customQuery = null) {
        const entry = {
            category: category,
            name: dorkName,
            domain: domain,
            timestamp: new Date().toISOString(),
            customQuery: customQuery
        };

        this.history.unshift(entry);
        
        // Keep only last 50 entries
        if (this.history.length > 50) {
            this.history = this.history.slice(0, 50);
        }

        this.saveHistory();
        this.renderHistory();
    }

    renderHistory() {
        const container = document.getElementById('dorkHistory');
        if (!container) return;

        if (this.history.length === 0) {
            container.innerHTML = '<div class="output-content empty">No dorks executed yet</div>';
            return;
        }

        let html = '<div class="output-content" style="padding: 0;">';
        html += '<ul class="list-output" style="margin: 0;">';
        
        this.history.slice(0, 10).forEach((entry, index) => {
            const date = new Date(entry.timestamp);
            const timeStr = date.toLocaleTimeString('en-US', { 
                hour: '2-digit', 
                minute: '2-digit' 
            });
            
            const encodedIndex = this.safeEncode(String(index));
            
            html += `
                <li style="display: flex; justify-content: space-between; align-items: center; gap: 1rem;">
                    <div style="flex: 1;">
                        <strong style="color: var(--yellow);">${this.escapeHtml(entry.name)}</strong>
                        <br>
                        <span style="color: var(--text-muted); font-size: 0.85rem;">
                            ${this.escapeHtml(entry.category)} • ${this.escapeHtml(entry.domain)} • ${timeStr}
                        </span>
                    </div>
                    <button 
                        class="btn btn-secondary history-btn" 
                        data-index="${encodedIndex}"
                        style="padding: 0.4rem 0.8rem; font-size: 0.75rem; white-space: nowrap;">
                        Re-execute
                    </button>
                </li>
            `;
        });
        
        html += '</ul></div>';
        container.innerHTML = html;
    }

    reexecuteFromHistory(index) {
        const entry = this.history[index];
        if (!entry) return;

        const targetInput = document.getElementById('targetDomain');
        if (targetInput) {
            targetInput.value = entry.domain;
            this.updateCurrentTarget();
        }

        if (entry.customQuery) {
            const customDorkInput = document.getElementById('customDork');
            if (customDorkInput) {
                customDorkInput.value = entry.customQuery;
            }
            this.executeCustomDork();
        } else {
            this.executeDork(entry.category, entry.name);
        }
    }

    clearHistory() {
        if (confirm('Are you sure you want to clear all dork history?')) {
            this.history = [];
            this.saveHistory();
            this.renderHistory();
            
            if (window.BugHunterToolkit) {
                window.BugHunterToolkit.showNotification('History cleared!', 'success');
            }
        }
    }

    updateStats() {
        const totalDorks = Object.values(this.dorkDatabase).reduce((sum, cat) => {
            return sum + Object.keys(cat.dorks).length;
        }, 0);

        const totalDorksEl = document.getElementById('totalDorks');
        const executedDorksEl = document.getElementById('executedDorks');
        
        if (totalDorksEl) totalDorksEl.textContent = totalDorks;
        if (executedDorksEl) executedDorksEl.textContent = this.executedCount;
    }

    updateLastExecuted() {
        const now = new Date();
        const timeStr = now.toLocaleTimeString('en-US', {
            hour: '2-digit',
            minute: '2-digit',
            second: '2-digit'
        });
        
        const lastExecutedEl = document.getElementById('lastExecutedTime');
        if (lastExecutedEl) {
            lastExecutedEl.textContent = timeStr;
        }
    }

    loadHistory() {
        try {
            const saved = localStorage.getItem('dork_history');
            return saved ? JSON.parse(saved) : [];
        } catch (e) {
            console.error('Error loading dork history:', e);
            return [];
        }
    }

    saveHistory() {
        try {
            // Sanitize history before saving
            const sanitizedHistory = this.history.map(entry => ({
                category: String(entry.category || ''),
                name: String(entry.name || ''),
                domain: String(entry.domain || ''),
                timestamp: entry.timestamp,
                customQuery: entry.customQuery ? String(entry.customQuery) : null
            }));
            
            localStorage.setItem('dork_history', JSON.stringify(sanitizedHistory));
        } catch (e) {
            console.error('Error saving dork history:', e);
        }
    }
}

// Initialize when DOM is ready
if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', initDorkManager);
} else {
    initDorkManager();
}

function initDorkManager() {
    // Initialize DorkManager
    window.dorkManager = new DorkManager();
    window.dorkManager.init();
    
    // Setup event delegation for dork buttons
    document.addEventListener('click', function(e) {
        // Handle dork button clicks
        if (e.target.classList.contains('dork-btn')) {
            const encodedCategory = e.target.getAttribute('data-category');
            const encodedName = e.target.getAttribute('data-name');
            
            if (encodedCategory && encodedName) {
                const category = window.dorkManager.safeDecode(encodedCategory);
                const name = window.dorkManager.safeDecode(encodedName);
                window.dorkManager.executeDork(category, name);
            }
        }
        
        // Handle history button clicks
        if (e.target.classList.contains('history-btn')) {
            const encodedIndex = e.target.getAttribute('data-index');
            if (encodedIndex) {
                const index = parseInt(window.dorkManager.safeDecode(encodedIndex));
                if (!isNaN(index)) {
                    window.dorkManager.reexecuteFromHistory(index);
                }
            }
        }
    });
    
    console.log('🔍 Dork Manager initialized with event delegation');
}
