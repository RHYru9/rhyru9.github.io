## Regex oth
---
### crisp chat
**Identifier**
```regex
[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}
```
**Key**
```regex
\b[a-f0-9]{32,64}\b
```

**Requests**
```
GET /v1/website/{website_id}/people/profiles/{id} HTTP/2
Host: api.crisp.chat
Authorization: Basic BASE64(identifier:key)
User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/138.0.0.0 Safari/537.36
X-Crisp-Tier: plugin
```
---
