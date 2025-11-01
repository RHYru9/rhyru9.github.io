function extractDomain(url) {
  try {
    const trimmed = url.trim();
    if (!trimmed) return null;

    const u = new URL(trimmed);
    return u.hostname.toLowerCase();
  } catch (e) {
    return null;
  }
}

function extractPort(url) {
  try {
    const trimmed = url.trim();
    if (!trimmed) return null;

    const u = new URL(trimmed);
    return u.port || null;
  } catch (e) {
    return null;
  }
}

function filterUrls() {
  const urlInput = document.getElementById('urls').value;
  const domainInput = document.getElementById('domains').value;
  const portInput = document.getElementById('ports').value;
  const filterType = document.querySelector('input[name="filterType"]:checked').value;
  const portFilterType = document.querySelector('input[name="portFilterType"]:checked')?.value || 'none';

  const statusText = document.getElementById('statusText');
  const statusIndicator = document.getElementById('statusIndicator');
  const errorSection = document.getElementById('errorSection');
  const errorList = document.getElementById('errorList');
  const resultCount = document.getElementById('resultCount');
  const currentMode = document.getElementById('currentMode');

  // Update current mode display
  const domainMode = filterType === 'include' ? 'Include' : 'Exclude';
  let portMode = '';
  if (portFilterType === 'include') {
    portMode = ' | Port: Include';
  } else if (portFilterType === 'exclude') {
    portMode = ' | Port: Exclude';
  }
  currentMode.textContent = domainMode + portMode;

  // Validation
  if (!urlInput.trim()) {
    statusText.textContent = 'Error: Please enter at least one URL';
    statusIndicator.classList.add('error');
    showToast('Please enter URLs', 'error');
    return;
  }

  if (!domainInput.trim()) {
    statusText.textContent = 'Error: Please enter at least one domain';
    statusIndicator.classList.add('error');
    showToast('Please enter domains to filter', 'error');
    return;
  }

  // Validate port filter requirements
  if (portFilterType !== 'none' && !portInput.trim()) {
    statusText.textContent = 'Error: Please enter ports when using port filter';
    statusIndicator.classList.add('error');
    showToast('Please enter ports to filter', 'error');
    return;
  }

  statusIndicator.classList.remove('error');
  statusIndicator.classList.remove('warning');

  // Parse inputs
  const urls = urlInput.split('\n').map(s => s.trim()).filter(s => s);
  const domains = new Set(
    domainInput.split('\n').map(s => s.trim().toLowerCase()).filter(s => s)
  );
  
  // Parse ports (only if port filtering is enabled)
  const ports = portFilterType !== 'none' 
    ? new Set(portInput.split('\n').map(s => s.trim()).filter(s => s))
    : new Set();

  const filtered = [];
  const invalidUrls = [];

  // Process each URL
  for (const url of urls) {
    const domain = extractDomain(url);

    if (domain === null) {
      invalidUrls.push(url);
      continue;
    }

    const isDomainInList = domains.has(domain);

    // First check domain filter
    let passedDomainFilter = false;
    if (filterType === 'include' && isDomainInList) {
      passedDomainFilter = true;
    } else if (filterType === 'exclude' && !isDomainInList) {
      passedDomainFilter = true;
    }

    // If domain filter passed, check port filter (if enabled)
    if (passedDomainFilter) {
      if (portFilterType === 'none') {
        // No port filtering, add URL
        filtered.push(url);
      } else {
        const port = extractPort(url);
        
        // Key logic: Only check port filter if URL has explicit port
        if (port === null || port === '') {
          // URL has NO explicit port (e.g., http://example.com)
          // Always include it regardless of port filter
          filtered.push(url);
        } else {
          // URL has explicit port (e.g., http://example.com:8080)
          // Apply port filter
          const isPortInList = ports.has(port);

          if (portFilterType === 'include' && isPortInList) {
            filtered.push(url);
          } else if (portFilterType === 'exclude' && !isPortInList) {
            filtered.push(url);
          }
        }
      }
    }
  }

  // Display results
  const resultDiv = document.getElementById('result');
  if (filtered.length > 0) {
    resultDiv.textContent = filtered.join('\n');
    resultDiv.classList.remove('empty');
    resultCount.textContent = `${filtered.length} results`;
  } else {
    resultDiv.textContent = 'No matching URLs found';
    resultDiv.classList.add('empty');
    resultCount.textContent = '0 results';
  }

  // Handle invalid URLs
  if (invalidUrls.length > 0) {
    errorSection.style.display = 'flex';
    errorList.textContent = invalidUrls.join('\n');
    statusText.textContent = `Filtered ${urls.length} URLs: ${filtered.length} matches, ${invalidUrls.length} invalid`;
    statusIndicator.classList.add('warning');
    showToast(`Found ${invalidUrls.length} invalid URLs`, 'warning');
  } else {
    errorSection.style.display = 'none';
    statusText.textContent = `Filtered ${urls.length} URLs, found ${filtered.length} matches`;
    statusIndicator.classList.remove('warning');
    showToast(`Found ${filtered.length} matching URLs`, 'success');
  }
}

// Copy results to clipboard
function copyResults() {
  const resultText = document.getElementById('result').textContent;
  const statusText = document.getElementById('statusText');

  if (!resultText || resultText === 'No results yet. Click "Filter URLs" to start.' || resultText === 'No matching URLs found') {
    statusText.textContent = 'No results to copy';
    showToast('No results to copy', 'error');
    return;
  }

  navigator.clipboard.writeText(resultText)
    .then(() => {
      statusText.textContent = 'Results copied to clipboard!';
      showToast('Copied to clipboard!', 'success');
    })
    .catch(err => {
      statusText.textContent = 'Failed to copy results';
      showToast('Failed to copy', 'error');
      console.error('Failed to copy: ', err);
    });
}

// Clear all inputs and results
function clearAll() {
  document.getElementById('urls').value = '';
  document.getElementById('domains').value = '';
  document.getElementById('ports').value = '';
  document.getElementById('result').textContent = 'No results yet. Click "Filter URLs" to start.';
  document.getElementById('result').classList.add('empty');
  document.getElementById('errorSection').style.display = 'none';
  document.getElementById('statusText').textContent = 'All fields cleared';
  document.getElementById('statusIndicator').classList.remove('error');
  document.getElementById('statusIndicator').classList.remove('warning');
  document.getElementById('resultCount').textContent = '0 results';
  showToast('All fields cleared', 'success');
}

// Add quick domain patterns
function addQuickDomains(tld) {
  const domainsTextarea = document.getElementById('domains');
  const currentDomains = domainsTextarea.value.trim();
  const newDomain = `*.${tld}`;

  if (currentDomains) {
    domainsTextarea.value = currentDomains + '\n' + newDomain;
  } else {
    domainsTextarea.value = newDomain;
  }

  showToast(`Added ${newDomain} to filter`, 'success');
}

// Add quick ports
function addQuickPorts(portList) {
  const portsTextarea = document.getElementById('ports');
  const currentPorts = portsTextarea.value.trim();
  
  if (currentPorts) {
    portsTextarea.value = currentPorts + '\n' + portList;
  } else {
    portsTextarea.value = portList;
  }

  showToast(`Added ports to filter`, 'success');
}

// Toggle port filter section
function togglePortFilter() {
  const portSection = document.getElementById('portFilterSection');
  const portFilterType = document.querySelector('input[name="portFilterType"]:checked').value;
  
  if (portFilterType === 'none') {
    portSection.style.display = 'none';
  } else {
    portSection.style.display = 'block';
  }
  
  updateModeDisplay();
}

// Update mode display
function updateModeDisplay() {
  const filterType = document.querySelector('input[name="filterType"]:checked').value;
  const portFilterType = document.querySelector('input[name="portFilterType"]:checked')?.value || 'none';
  
  const domainMode = filterType === 'include' ? 'Include' : 'Exclude';
  let portMode = '';
  if (portFilterType === 'include') {
    portMode = ' | Port: Include';
  } else if (portFilterType === 'exclude') {
    portMode = ' | Port: Exclude';
  }
  
  document.getElementById('currentMode').textContent = domainMode + portMode;
}

// Show toast notification
function showToast(message, type = 'success') {
  const toast = document.createElement('div');
  toast.style.cssText = `
    position: fixed;
    bottom: 100px;
    right: 20px;
    background: ${type === 'error' ? '#f87171' : type === 'warning' ? '#fbbf24' : 'var(--orange)'};
    color: ${type === 'warning' ? '#1a1a1a' : 'var(--dark-blue)'};
    padding: 1rem 1.5rem;
    border-radius: 8px;
    font-weight: 600;
    z-index: 9999;
    box-shadow: 0 4px 12px rgba(0,0,0,0.3);
    font-family: var(--font-main);
    animation: slideIn 0.3s ease;
  `;
  toast.textContent = message;
  document.body.appendChild(toast);

  setTimeout(() => {
    toast.style.animation = 'slideOut 0.3s ease';
    setTimeout(() => toast.remove(), 300);
  }, 3000);
}

// Update filter mode display on change
document.addEventListener('DOMContentLoaded', function() {
  document.querySelectorAll('input[name="filterType"]').forEach(radio => {
    radio.addEventListener('change', updateModeDisplay);
  });

  document.querySelectorAll('input[name="portFilterType"]').forEach(radio => {
    radio.addEventListener('change', function() {
      togglePortFilter();
    });
  });
});


// ========================================
// HTML CODE
// ========================================

<!DOCTYPE html>
<html lang="en">

<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Domain Filter - Bug Bounty Toolkit</title>
  <link rel="stylesheet" href="css/style.css">
</head>

<body>
  <!-- Navigation -->
  <nav>
    <div class="logo">🐛 BugHunter Toolkit</div>
    <ul class="nav-links">
      <li><a href="index.html">Home</a></li>
      <li><a href="uri-manager.html">URI Manager</a></li>
      <li><a href="path-extractor.html">Path Extractor</a></li>
      <li><a href="dork-generator.html">Dork Generator</a></li>
      <li><a href="domain-filter.html">Domain Filters</a></li>
    </ul>
    <div class="nav-actions">
      <button id="themeToggle" class="btn btn-secondary" title="Toggle Dark/Light Mode">
        <span id="themeIcon">🌙</span>
      </button>
    </div>
  </nav>

  <!-- Header -->
  <header>
    <div class="container">
      <h1 style="font-size: 2.5rem; margin-bottom: 1rem; color: var(--yellow); text-align: center;">
        🔍 Filter URL by Active Domains
      </h1>
      <p style="text-align: center; font-size: 1.1rem; color: var(--text-secondary); max-width: 800px; margin: 0 auto;">
        Filter your URLs based on active domains with exclude/include options and port filtering
      </p>
    </div>
  </header>

  <!-- Main Content -->
  <div class="container" style="padding-bottom: 100px;">
    <!-- Main Tool Container -->
    <section class="base-card">
      <h2 class="text-secondary mb-3" style="font-size: 1.3rem;">🛠️ URL Filter Tool</h2>

      <!-- URLs Input -->
      <div class="input-group">
        <label for="urls">Paste URLs (one per line):</label>
        <textarea id="urls" placeholder="http://example.com/path
https://sub.example.com:8080/api
https://target.gov.id:443/admin
https://api.example.co.id:3000/data"></textarea>
      </div>

      <!-- Domains Input -->
      <div class="input-group">
        <label for="domains">Paste domains to filter (one per line):</label>
        <textarea id="domains" placeholder="example.com
sub.example.com
target.gov.id"></textarea>
      </div>

      <!-- Filter Mode -->
      <div class="input-group">
        <label>Domain Filter Mode:</label>
        <div class="radio-group">
          <div class="radio-item">
            <input type="radio" id="includeMode" name="filterType" value="include" checked>
            <label for="includeMode">Include only these domains</label>
          </div>
          <div class="radio-item">
            <input type="radio" id="excludeMode" name="filterType" value="exclude">
            <label for="excludeMode">Exclude these domains</label>
          </div>
        </div>
      </div>

      <!-- Port Filter Mode -->
      <div class="input-group">
        <label>Port Filter Mode:</label>
        <div class="radio-group">
          <div class="radio-item">
            <input type="radio" id="portNone" name="portFilterType" value="none" checked>
            <label for="portNone">No port filtering</label>
          </div>
          <div class="radio-item">
            <input type="radio" id="portInclude" name="portFilterType" value="include">
            <label for="portInclude">Include only these ports</label>
          </div>
          <div class="radio-item">
            <input type="radio" id="portExclude" name="portFilterType" value="exclude">
            <label for="portExclude">Exclude these ports</label>
          </div>
        </div>
      </div>

      <!-- Ports Input (Hidden by default) -->
      <div id="portFilterSection" class="input-group" style="display: none;">
        <label for="ports">Paste ports to filter (one per line):</label>
        <textarea id="ports" placeholder="8080
3000
8443
9000"></textarea>
        <p class="text-muted" style="font-size: 0.85rem; margin-top: 0.5rem;">
          💡 <strong>Important:</strong> Port filter only applies to URLs with <strong>explicit ports</strong>. URLs without explicit ports (e.g., http://example.com) will always pass through port filter.
        </p>
      </div>

      <!-- Action Buttons -->
      <div class="button-group mt-2">
        <button class="btn btn-primary" onclick="filterUrls()">🔍 Filter URLs</button>
        <button class="btn btn-primary" onclick="copyResults()">📋 Copy Results</button>
        <button class="btn btn-secondary" onclick="clearAll()">🗑️ Clear All</button>
      </div>

      <!-- Results Section -->
      <div class="output-section">
        <div class="output-header">
          <span class="output-label">Filtered Results</span>
          <span class="badge badge-success" id="resultCount">0 results</span>
        </div>
        <div id="result" class="output-content empty">No results yet. Click "Filter URLs" to start.</div>
      </div>

      <!-- Error Section -->
      <div id="errorSection" class="alert alert-error mt-2" style="display: none;">
        <span style="font-size: 1rem;">⚠️</span>
        <div style="flex: 1;">
          <strong>Invalid URLs Found:</strong>
          <div id="errorList" style="margin-top: 0.5rem; font-size: 0.85rem; font-family: 'Courier New', monospace;">
          </div>
        </div>
      </div>
    </section>

    <!-- Quick Actions -->
    <section class="base-card">
      <h2 class="text-secondary mb-3" style="font-size: 1.3rem;">⚡ Quick Actions</h2>

      <div class="collapsible active">
        <div class="collapsible-header">
          <span style="font-weight: 600;">🇮🇩 Indonesian Domains</span>
        </div>
        <div class="collapsible-content">
          <p class="text-muted mb-2" style="font-size: 0.85rem;">Click to add common Indonesian TLDs to domain filter
          </p>
          <div class="button-group">
            <button class="btn btn-secondary" onclick="addQuickDomains('co.id')">Add *.co.id</button>
            <button class="btn btn-secondary" onclick="addQuickDomains('ac.id')">Add *.ac.id</button>
            <button class="btn btn-secondary" onclick="addQuickDomains('go.id')">Add *.go.id</button>
            <button class="btn btn-secondary" onclick="addQuickDomains('gov.id')">Add *.gov.id</button>
          </div>
        </div>
      </div>

      <div class="collapsible">
        <div class="collapsible-header">
          <span style="font-weight: 600;">🌍 International Domains</span>
        </div>
        <div class="collapsible-content">
          <p class="text-muted mb-2" style="font-size: 0.85rem;">Click to add common international TLDs to domain filter
          </p>
          <div class="button-group">
            <button class="btn btn-secondary" onclick="addQuickDomains('gov.uk')">Add *.gov.uk</button>
            <button class="btn btn-secondary" onclick="addQuickDomains('gov.au')">Add *.gov.au</button>
            <button class="btn btn-secondary" onclick="addQuickDomains('gov')">Add *.gov</button>
            <button class="btn btn-secondary" onclick="addQuickDomains('edu')">Add *.edu</button>
          </div>
        </div>
      </div>

      <div class="collapsible">
        <div class="collapsible-header">
          <span style="font-weight: 600;">🔌 Common Ports</span>
        </div>
        <div class="collapsible-content">
          <p class="text-muted mb-2" style="font-size: 0.85rem;">Click to add common port numbers to port filter
          </p>
          <div class="button-group">
            <button class="btn btn-secondary" onclick="addQuickPorts('80\n443')">Add HTTP/HTTPS (80, 443)</button>
            <button class="btn btn-secondary" onclick="addQuickPorts('8080\n8443')">Add Alt HTTP (8080, 8443)</button>
            <button class="btn btn-secondary" onclick="addQuickPorts('3000\n5000\n8000')">Add Dev Ports</button>
            <button class="btn btn-secondary" onclick="addQuickPorts('21\n22\n23\n25')">Add Service Ports</button>
          </div>
        </div>
      </div>
    </section>
  </div>

  <!-- Status Bar -->
  <div class="status-bar">
    <div class="status-item">
      <div class="status-indicator" id="statusIndicator"></div>
      <span id="statusText">Ready to filter URLs</span>
    </div>
    <div class="status-item">
      <span>Mode: <span id="currentMode">Include</span></span>
    </div>
    <div class="status-item">
      <span>Version: 1.1.0</span>
    </div>
  </div>

  <!-- Scripts -->
  <script src="js/settings.js"></script>
  <script src="js/domain-filter.js"></script>
</body>

</html>
