document.addEventListener('DOMContentLoaded', () => {
  const encodedScript = getParameterByName('script');
  if (encodedScript) {
    const decodedScript = decodeURIComponent(encodedScript);
    const script = document.createElement('script');
    script.textContent = decodedScript;
    document.head.appendChild(script);
  }
});
