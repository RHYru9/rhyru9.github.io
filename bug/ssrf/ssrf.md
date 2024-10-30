### 1. **`fetch()`**
   - **Description**: Used to make network requests. Directly using user input can allow attackers to access internal services.
   ```javascript
   fetch(req.query.url); // Potential SSRF
   ```

### 2. **`axios.get()`**
   - **Description**: A method from the Axios library for making HTTP requests. If it uses unsanitized input, it can lead to SSRF.
   ```javascript
   axios.get(req.body.url); // Potential SSRF
   ```

### 3. **`http.get()`**
   - **Description**: Node.js method for making HTTP GET requests. User input can lead to SSRF if not validated.
   ```javascript
   http.get(req.query.url); // Potential SSRF
   ```

### 4. **`request()`**
   - **Description**: A commonly used HTTP client for Node.js. Directly passing user input can lead to SSRF.
   ```javascript
   request(req.body.url); // Potential SSRF
   ```

### 5. **`document.location`**
   - **Description**: Contains the URL of the current document. If read without validation, it can redirect to unsafe resources.
   ```javascript
   const redirectUrl = document.location; // Potentially unsafe
   ```

### 6. **`window.location`**
   - **Description**: Provides information about the current URL. Can be exploited for redirects.
   ```javascript
   const targetUrl = window.location.href; // Can be manipulated
   ```

### 7. **`XMLHttpRequest`**
   - **Description**: Allows sending HTTP requests. Unsanitized URLs can lead to SSRF.
   ```javascript
   const xhr = new XMLHttpRequest();
   xhr.open('GET', req.query.url); // Potential SSRF
   ```

### 8. **`WebSocket`**
   - **Description**: Establishes a WebSocket connection. If user input defines the URL, it can lead to SSRF.
   ```javascript
   const socket = new WebSocket(req.body.wsUrl); // Potential SSRF
   ```

### 9. **`eval()`**
   - **Description**: Executes JavaScript code represented as a string. If user input is evaluated, it can create unsafe requests.
   ```javascript
   eval(`fetch(${req.body.input})`); // Extremely risky
   ```

### 10. **`fetch('file://...')`**
   - **Description**: Fetching local files using file URLs can lead to exposure of sensitive information.
   ```javascript
   fetch(`file://${req.query.path}`); // Potential SSRF
   ```

### 11. **`document.referrer`**
   - **Description**: Contains the URL of the document that linked to the current page. This could be manipulated to direct requests.
   ```javascript
   const referrer = document.referrer; // Can be unsafe if used
   ```

### 12. **`document.cookie`**
   - **Description**: Contains the cookies associated with the document. If exploited, attackers can read sensitive information.
   ```javascript
   const cookies = document.cookie; // Can leak information
   ```

### 13. **`localStorage`**
   - **Description**: Stores data in the user's browser. If user-controlled data is used for requests, it can lead to SSRF.
   ```javascript
   const storedUrl = localStorage.getItem('url'); // Potential SSRF
   ```

### 14. **`sessionStorage`**
   - **Description**: Similar to localStorage but limited to the session. User-controlled data can also lead to SSRF.
   ```javascript
   const sessionUrl = sessionStorage.getItem('url'); // Potential SSRF
   ```

### 15. **`history.pushState()`**
   - **Description**: Adds an entry to the browser's session history stack. If used with unsanitized input, it can redirect users to malicious sites.
   ```javascript
   history.pushState({}, '', req.body.newUrl); // Potentially unsafe
   ```

### 16. **`history.replaceState()`**
   - **Description**: Similar to `pushState`, but replaces the current history entry. User-controlled data can lead to malicious redirects.
   ```javascript
   history.replaceState({}, '', req.body.newUrl); // Potentially unsafe
   ```

### 17. **`document.baseURI`**
   - **Description**: Returns the base URI of the document. It can be manipulated to create unsafe requests.
   ```javascript
   const baseUri = document.baseURI; // Can lead to unsafe fetches
   ```

### 18. **`navigator` Object**
   - **Description**: Contains information about the browser. Manipulated properties can lead to SSRF if used in fetch requests.
   ```javascript
   const userAgent = navigator.userAgent; // Can be exploited in requests
   ```

### 19. **`setTimeout()`**
   - **Description**: Executes a function after a specified delay. If combined with user input, it could lead to delayed requests.
   ```javascript
   setTimeout(() => fetch(req.body.url), 1000); // Potential SSRF
   ```

### 20. **`setInterval()`**
   - **Description**: Repeatedly executes a function at specified intervals. Can lead to repeated unsafe requests.
   ```javascript
   setInterval(() => fetch(req.body.url), 5000); // Potential SSRF
   ```

### 21. **`document.createElement()`**
   - **Description**: Creates an HTML element. If user input is used in the `src` of a script or iframe, it can lead to SSRF.
   ```javascript
   const script = document.createElement('script');
   script.src = req.query.url; // Potential SSRF
   ```

### 22. **`iframe.src`**
   - **Description**: The URL of an iframe can be manipulated with user input, leading to potential SSRF.
   ```javascript
   const iframe = document.createElement('iframe');
   iframe.src = req.body.url; // Potential SSRF
   ```

### 23. **`fetch(new Request())`**
   - **Description**: Using the Request object can lead to SSRF if constructed with user input.
   ```javascript
   fetch(new Request(req.query.url)); // Potential SSRF
   ```

### 24. **`Response.redirect()`**
   - **Description**: Used to redirect a response to a different URL. If user-controlled data is used, it can lead to unsafe redirects.
   ```javascript
   response.redirect(req.body.url); // Potential SSRF
   ```

### 25. **`navigator.geolocation.getCurrentPosition()`**
   - **Description**: Accesses the user's geographical location. If used in combination with network requests, it can lead to SSRF.
   ```javascript
   navigator.geolocation.getCurrentPosition(pos => {
       fetch(`http://example.com/api?lat=${pos.coords.latitude}`);
   });
   ```

### 26. **`document.write()`**
   - **Description**: Writes HTML expressions or JavaScript code. If used with unsanitized URLs, it can lead to SSRF.
   ```javascript
   document.write(`<script src="${req.query.url}"></script>`); // Potential SSRF
   ```

### 27. **`console.log()`**
   - **Description**: While primarily for logging, if used to log and then fetch URLs, it can be abused.
   ```javascript
   console.log(req.query.url); // Logging can lead to unintentional exposure
   ```

### 28. **`fetch(new URL(req.body.url))`**
   - **Description**: Using the URL constructor with user input can lead to SSRF if not validated.
   ```javascript
   fetch(new URL(req.body.url)); // Potential SSRF
   ```

### 29. **`navigator.serviceWorker.register()`**
   - **Description**: Registers a service worker. If the URL is user-controlled, it can redirect requests.
   ```javascript
   navigator.serviceWorker.register(req.body.url); // Potential SSRF
   ```

### 30. **`location.replace()`**
   - **Description**: Replaces the current document with a new one. Unsanitized URLs can lead to redirection to malicious sites.
   ```javascript
   location.replace(req.body.url); // Potentially unsafe
   ```

### 31. **`location.assign()`**
   - **Description**: Similar to `replace()`, it loads a new document. Can be manipulated to redirect to unsafe URLs.
   ```javascript
   location.assign(req.body.url); // Potentially unsafe
   ```

### 32. **`URL.createObjectURL()`**
   - **Description**: Creates a temporary URL for a Blob or File. If user input is used, it can lead to SSRF.
   ```javascript
   const url = URL.createObjectURL(req.body.file); // Potential SSRF
   ```

### 33. **`navigator.mozApps.getSelf()`**
   - **Description**: Part of the Firefox OS APIs. If used improperly, it can lead to accessing internal resources.
   ```javascript
   navigator.mozApps.getSelf().then(app => fetch(app.origin)); // Potential SSRF
   ```

### 34. **`navigator.webkitGetUserMedia()`**
   - **Description**

: Allows access to media devices. If user input is not handled correctly, it can lead to data exposure.
   ```javascript
   navigator.webkitGetUserMedia({ video: true }, stream => fetch(stream), error => {}); // Potential SSRF
   ```

### 35. **`requestAnimationFrame()`**
   - **Description**: Used for smooth animations. If used with user-controlled URLs, it can lead to SSRF.
   ```javascript
   requestAnimationFrame(() => fetch(req.body.url)); // Potential SSRF
   ```

### 36. **`navigator.plugins`**
   - **Description**: Provides information about installed plugins. If misused, it can lead to SSRF through data exposure.
   ```javascript
   const plugins = navigator.plugins; // Can be exploited if used to make requests
   ```

### 37. **`document.getElementsByTagName('script')`**
   - **Description**: Accesses script elements in the document. Can be exploited by injecting malicious URLs.
   ```javascript
   const scripts = document.getElementsByTagName('script');
   const unsafeUrl = scripts[0].src; // Can lead to SSRF
   ```

### 38. **`document.getElementsByName()`**
   - **Description**: Returns a NodeList of elements with the specified name. If user input is used, it can lead to SSRF.
   ```javascript
   const elements = document.getElementsByName(req.body.name); // Potentially unsafe
   ```

### 39. **`window.open()`**
   - **Description**: Opens a new window. If unsanitized URLs are used, it can redirect users to malicious sites.
   ```javascript
   window.open(req.body.url); // Potentially unsafe
   ```

### 40. **`addEventListener()`**
   - **Description**: Attaches an event handler to an element. If used with user-controlled input, it can lead to SSRF through event-driven requests.
   ```javascript
   document.addEventListener('click', () => fetch(req.body.url)); // Potential SSRF
   ```
