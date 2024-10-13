const xssPayload = "<img src=x onerror=alert(1)>";
document.body.innerHTML = xssPayload;

