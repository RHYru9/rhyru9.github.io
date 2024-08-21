document.addEventListener('DOMContentLoaded', () => {
  const img = getParameterByName('img');
  if (img) {
    const script = document.createElement('script');
    script.textContent = `
      console.log('Injected script executed');
      // Menambahkan payload lainnya jika perlu
    `;
    document.head.appendChild(script);
  }
});
