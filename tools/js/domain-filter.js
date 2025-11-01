// Extract domain from URL
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

// Filter URLs based on domains
function filterUrls() {
  const urlInput = document.getElementById('urls').value;
  const domainInput = document.getElementById('domains').value;
  const filterType = document.querySelector('input[name="filterType"]:checked').value;

  const statusText = document.getElementById('statusText');
  const statusIndicator = document.getElementById('statusIndicator');
  const errorSection = document.getElementById('errorSection');
  const errorList = document.getElementById('errorList');
  const resultCount = document.getElementById('resultCount');
  const currentMode = document.getElementById('currentMode');

  // Update current mode display
  currentMode.textContent = filterType === 'include' ? 'Include' : 'Exclude';

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

  statusIndicator.classList.remove('error');
  statusIndicator.classList.remove('warning');

  // Parse inputs
  const urls = urlInput.split('\n').map(s => s.trim()).filter(s => s);
  const domains = new Set(
    domainInput.split('\n').map(s => s.trim().toLowerCase()).filter(s => s)
  );

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

    if (filterType === 'include' && isDomainInList) {
      filtered.push(url);
    } else if (filterType === 'exclude' && !isDomainInList) {
      filtered.push(url);
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

// Collapsible functionality
document.querySelectorAll('.collapsible-header').forEach(header => {
  header.addEventListener('click', function() {
    const collapsible = this.parentElement;
    collapsible.classList.toggle('active');
  });
});

// Update filter mode display on change
document.querySelectorAll('input[name="filterType"]').forEach(radio => {
  radio.addEventListener('change', function() {
    document.getElementById('currentMode').textContent = this.value === 'include' ? 'Include' : 'Exclude';
  });
});

// Add CSS animation
const style = document.createElement('style');
style.textContent = `
            @keyframes slideIn {
                from { transform: translateX(400px); opacity: 0; }
                to { transform: translateX(0); opacity: 1; }
            }
            @keyframes slideOut {
                from { transform: translateX(0); opacity: 1; }
                to { transform: translateX(400px); opacity: 0; }
            }
        `;
document.head.appendChild(style);
