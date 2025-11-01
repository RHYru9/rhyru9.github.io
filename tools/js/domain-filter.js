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
