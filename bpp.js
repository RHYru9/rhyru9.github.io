document.addEventListener('DOMContentLoaded', () => {
  const encodedScript = decodeURIComponent(getParameterByName('script'));
  if (encodedScript) {
    eval(encodedScript); // Berhati-hatilah dengan penggunaan eval; ini hanya untuk contoh.
  }
});
