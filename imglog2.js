document.addEventListener('DOMContentLoaded', () => {
  const img = getParameterByName('img');
  if (img) {
    const script = document.createElement('script');
    script.textContent = `
      console.log('affected');
    `;
    document.head.appendChild(script);
  }
});
