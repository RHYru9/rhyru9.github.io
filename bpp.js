document.addEventListener('DOMContentLoaded', () => {
  const encodedScript = decodeURIComponent(getParameterByName('script'));
  if (encodedScript) {
    eval(encodedScript); 
  }
});
