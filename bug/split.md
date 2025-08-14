# Split.io

## 🔑 Authentication

All Split.io SDK endpoints require proper authentication using API keys. There are different types:

- **Server-side SDK Key**: For server applications (starts with `sdk-`)
- **Client-side SDK Key**: For browser/mobile apps (starts with `client-`)
- **Admin API Key**: For management operations

```
Authorization: Bearer YOUR_SDK_KEY
```

## 🎯 Core SDK Endpoints (Production Ready)

### 1. Get Split Changes (Feature Flag Definitions)

**Endpoint**: `GET https://sdk.split.io/api/splitChanges`

```http
GET /api/splitChanges?since=-1 HTTP/1.1
Host: sdk.split.io
Authorization: Bearer YOUR_SDK_KEY
Accept: application/json
Cache-Control: no-cache
SplitSDKVersion: js-10.25.2
SplitSDKMachineIP: 127.0.0.1
SplitSDKMachineName: localhost
```

**Parameters**:
- `since`: Change number for incremental updates (-1 for all)
- `sets`: Optional filter by feature flag sets

**Response Structure**:
```json
{
  "splits": [
    {
      "name": "feature_name",
      "status": "ACTIVE",
      "trafficAllocation": 100,
      "defaultTreatment": "off",
      "conditions": [...],
      "configurations": {...}
    }
  ],
  "since": -1,
  "till": 1752018203936
}
```

### 2. Get My Segments (User Segmentation)

**Endpoint**: `GET https://sdk.split.io/api/mySegments/{userKey}`

```http
GET /api/mySegments/user123 HTTP/1.1
Host: sdk.split.io
Authorization: Bearer YOUR_SDK_KEY
Accept: application/json
SplitSDKVersion: js-10.25.2
```

**Response**:
```json
{
  "mySegments": [
    {
      "name": "beta_users"
    },
    {
      "name": "premium_customers"
    }
  ]
}
```

---
