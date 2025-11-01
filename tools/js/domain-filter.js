// Ekstrak hostname dan port EKSPLISIT dari URL string asli
function extractDomainAndPort(url) {
  try {
    const trimmed = url.trim();
    if (!trimmed) return null;

    let normalizedUrl = trimmed;
    if (!normalizedUrl.startsWith('http://') && !normalizedUrl.startsWith('https://')) {
      normalizedUrl = 'http://' + normalizedUrl;
    }

    // Ekstrak port eksplisit dari string asli
    const portMatch = trimmed.match(/:(\d{1,5})/);
    const explicitPort = portMatch ? parseInt(portMatch[1], 10) : null;

    const u = new URL(normalizedUrl);
    const hostname = u.hostname.toLowerCase();

    return { hostname, port: explicitPort };
  } catch (e) {
    return null;
  }
}

function filterUrls() {
  const urlInput = document.getElementById('urls').value;
  const domainInput = document.getElementById('domains').value;
  const portInput = document.getElementById('ports').value;
  const filterType = document.querySelector('input[name="filterType"]:checked').value;
  const portFilterType = document.querySelector('input[name="portFilterType"]:checked').value;

  const statusText = document.getElementById('statusText');
  const statusIndicator = document.getElementById('statusIndicator');
  const errorSection = document.getElementById('errorSection');
  const errorList = document.getElementById('errorList');
  const resultCount = document.getElementById('resultCount');
  const currentMode = document.getElementById('currentMode');

  currentMode.textContent = filterType === 'include' ? 'Include' : 'Exclude';

  if (!urlInput.trim()) {
    statusText.textContent = 'Error: Please enter at least one URL';
    statusIndicator.classList.add('error');
    showToast('Please enter URLs', 'error');
    return;
  }

  // Parse domains → EXACT MATCH ONLY (no wildcard)
  const domains = domainInput.trim()
    ? new Set(domainInput.split('\n').map(s => s.trim().toLowerCase()).filter(s => s))
    : null;

  // Parse ports
  let ports = null;
  if (portInput.trim()) {
    const portStrings = portInput.split(',').map(s => s.trim()).filter(s => s);
    ports = new Set(
      portStrings
        .map(p => {
          const n = parseInt(p, 10);
          return isNaN(n) || n < 1 || n > 65535 ? null : n;
        })
        .filter(p => p !== null)
    );
  }

  statusIndicator.classList.remove('error', 'warning');

  const urls = urlInput.split('\n').map(s => s.trim()).filter(s => s);
  const filtered = [];
  const invalidUrls = [];

  for (const url of urls) {
    const info = extractDomainAndPort(url);
    if (!info) {
      invalidUrls.push(url);
      continue;
    }

    const { hostname, port } = info;

    // === DOMAIN FILTERING: EXACT MATCH ONLY ===
    let domainPass = true;
    if (domains) {
      const isDomainInList = domains.has(hostname);
      domainPass = filterType === 'include' ? isDomainInList : !isDomainInList;
    }

    if (!domainPass) continue;

    // === PORT FILTERING ===
    let portPass = true;
    if (ports) {
      if (portFilterType === 'include') {
        // Hanya izinkan jika port eksplisit ADA dan SESUAI
        portPass = (port !== null) && ports.has(port);
      } else if (portFilterType === 'exclude') {
        // Izinkan semua kecuali port eksplisit yang di-block
        portPass = (port === null) || !ports.has(port);
      }
    }

    if (portPass) {
      filtered.push(url);
    }
  }

  // Tampilkan hasil
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

  // Tangani URL tidak valid
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

// === FUNGSI BANTUAN (copyResults, clearAll, dll) ===
function copyResults() {
  const resultText = document.getElementById('result').textContent;
  if (
    !resultText ||
    resultText === 'No results yet. Click "Filter URLs" to start.' ||
    resultText === 'No matching URLs found'
  ) {
    showToast('No results to copy', 'error');
    return;
  }

  navigator.clipboard
    .writeText(resultText)
    .then(() => showToast('Copied to clipboard!', 'success'))
    .catch(err => {
      console.error('Failed to copy: ', err);
      showToast('Failed to copy', 'error');
    });
}

function clearAll() {
  document.getElementById('urls').value = '';
  document.getElementById('domains').value = '';
  document.getElementById('ports').value = '';
  document.getElementById('result').textContent = 'No results yet. Click "Filter URLs" to start.';
  document.getElementById('result').classList.add('empty');
  document.getElementById('errorSection').style.display = 'none';
  document.getElementById('statusText').textContent = 'All fields cleared';
  document.getElementById('statusIndicator').className = 'status-indicator';
  document.getElementById('resultCount').textContent = '0 results';
  showToast('All fields cleared', 'success');
}

function addQuickDomains(tld) {
  const domainsTextarea = document.getElementById('domains');
  const currentDomains = domainsTextarea.value.trim();
  const newDomain = `*.${tld}`; // opsional: bisa dihapus jika tidak pakai wildcard

  if (currentDomains) {
    domainsTextarea.value = currentDomains + '\n' + newDomain;
  } else {
    domainsTextarea.value = newDomain;
  }

  showToast(`Added ${newDomain} to filter`, 'success');
}

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

// Collapsible & UI
document.querySelectorAll('.collapsible-header').forEach(header => {
  header.addEventListener('click', function () {
    const collapsible = this.parentElement;
    collapsible.classList.toggle('active');
  });
});

document.querySelectorAll('input[name="filterType"]').forEach(radio => {
  radio.addEventListener('change', function () {
    document.getElementById('currentMode').textContent = this.value === 'include' ? 'Include' : 'Exclude';
  });
});

const style = document.createElement('style');
style.textContent = `
  @keyframes slideIn { from { transform: translateX(400px); opacity: 0; } to { transform: translateX(0); opacity: 1; } }
  @keyframes slideOut { from { transform: translateX(0); opacity: 1; } to { transform: translateX(400px); opacity: 0; } }
`;
document.head.appendChild(style);
