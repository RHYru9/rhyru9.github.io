document.addEventListener('DOMContentLoaded', () => {
  const img = getParameterByName('img');
  if (img) {
    const script = document.createElement('script');
    script.textContent = `console.log('1');`;
    document.head.appendChild(script);
  }
});
