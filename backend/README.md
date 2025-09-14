# FriendFund Backend API

## Architecture Overview

FriendFund uses a hybrid architecture that separates authentication from business logic:

- **Frontend ↔ Appwrite Direct**: Authentication (login, register, sessions) handled directly through Appwrite SDK
- **Frontend ↔ Backend Function**: All business logic (campaigns, contributions, OCR, etc.) handled through single unified backend function

This approach provides:

- ✅ Secure authentication with Appwrite's built-in security
- ✅ Simplified business logic in centralized backend function
- ✅ Better performance and scalability
- ✅ Easier maintenance and debugging

## Project Structure

```
backend/
├── index.js          # Main unified API function handler
├── package.json      # Dependencies and scripts
├── appwrite.json     # Function deployment configuration
└── README.md         # This documentation
```

## Authentication Flow

### Frontend Direct Appwrite Authentication

The Flutter frontend connects directly to Appwrite for all authentication operations:

```dart
// Frontend handles authentication directly
import 'package:appwrite/appwrite.dart';

final client = Client()
  .setEndpoint('https://cloud.appwrite.io/v1')
  .setProject('your-project-id');

final account = Account(client);

// Login
await account.createEmailSession(email, password);

// Register
await account.create(ID.unique(), email, password, name);

// Get current user
final user = await account.get();
```

### Backend API for Business Logic

All non-authentication operations go through the unified backend function:

```dart
// Frontend calls backend function for business operations
final response = await http.post(
  Uri.parse('https://cloud.appwrite.io/v1/functions/friendfund-main/executions'),
  headers: {
    'Content-Type': 'application/json',
    'X-Appwrite-Project': 'your-project-id',
    'X-Appwrite-User-ID': currentUser.$id, // From Appwrite auth
  },
  body: jsonEncode({
    'path': '/campaigns',
    'method': 'GET'
  })
);
```

## API Endpoints

The backend function handles all business logic through a single entry point with path-based routing:

### Campaign Management

- `GET /campaigns` - Get all active campaigns
- `GET /campaigns/{id}` - Get specific campaign with contributions
- `GET /campaigns/user` - Get current user's campaigns
- `POST /campaigns` - Create new campaign
- `PUT /campaigns/{id}` - Update campaign
- `DELETE /campaigns/{id}` - Delete campaign
- `POST /campaigns/link/{id}` - Generate campaign sharing link

### Contribution Management

- `GET /contributions/campaign/{id}` - Get campaign contributions
- `GET /contributions/user/{id}` - Get user contributions
- `POST /contributions` - Create new contribution
- `PATCH /contributions/repaid/{id}` - Mark loan as repaid

### Utility Services

- `POST /ocr/process` - Process payment screenshot OCR
- `GET /notifications/overdue` - Get overdue loans
- `POST /notifications/reminder` - Send loan reminder
- `GET /qr/{campaignId}` - Generate QR code for campaign
- `GET /health` - Health check endpoint

### Request Format

All requests to the backend function should include:

```javascript
{
  "path": "/campaigns",           // API endpoint path
  "method": "GET",               // HTTP method
  "headers": {
    "x-appwrite-user-id": "user123" // User ID from Appwrite auth
  },
  "bodyJson": {                  // Request payload (for POST/PUT)
    "title": "Help John",
    "targetAmount": 50000
  }
}
```

### Response Format

All responses follow a consistent structure:

```javascript
{
  "success": true,
  "message": "Operation completed successfully",
  "data": { /* response data */ },
  "timestamp": "2025-09-13T10:30:00.000Z"
}
```

## Frontend Integration

### Required Dependencies

Add these to your Flutter `pubspec.yaml`:

```yaml
dependencies:
  appwrite: ^12.0.0 # For direct Appwrite authentication
  http: ^1.2.0 # For backend function calls
```

### Authentication Setup

```dart
// lib/services/appwrite_service.dart
import 'package:appwrite/appwrite.dart';

class AppwriteService {
  static final Client _client = Client()
    .setEndpoint('https://cloud.appwrite.io/v1')
    .setProject('your-project-id');

  static final Account account = Account(_client);
  static final Databases databases = Databases(_client);

  // Direct authentication methods
  static Future<Session> login(String email, String password) async {
    return await account.createEmailSession(email, password);
  }

  static Future<User> register(String email, String password, String name) async {
    return await account.create(ID.unique(), email, password, name);
  }

  static Future<User> getCurrentUser() async {
    return await account.get();
  }

  static Future<void> logout() async {
    await account.deleteSession('current');
  }
}
```

### Backend API Service

```dart
// lib/services/api_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String functionUrl = 'https://cloud.appwrite.io/v1/functions/friendfund-main/executions';
  static const String projectId = 'your-project-id';

  static Future<Map<String, dynamic>> request({
    required String path,
    required String method,
    String? userId,
    Map<String, dynamic>? body,
  }) async {
    final response = await http.post(
      Uri.parse(functionUrl),
      headers: {
        'Content-Type': 'application/json',
        'X-Appwrite-Project': projectId,
        if (userId != null) 'X-Appwrite-User-ID': userId,
      },
      body: jsonEncode({
        'path': path,
        'method': method,
        if (body != null) 'bodyJson': body,
      }),
    );

    return jsonDecode(response.body);
  }

  // Campaign methods
  static Future<List<Campaign>> getCampaigns() async {
    final result = await request(path: '/campaigns', method: 'GET');
    return (result['data'] as List).map((json) => Campaign.fromJson(json)).toList();
  }

  static Future<Campaign> createCampaign(Map<String, dynamic> campaignData, String userId) async {
    final result = await request(
      path: '/campaigns',
      method: 'POST',
      userId: userId,
      body: campaignData,
    );
    return Campaign.fromJson(result['data']);
  }
}
```

## Appwrite Setup

### 1. Create Collections

Create the following collections in your Appwrite database:

#### Users Collection

**Note**: This collection stores additional user profile data. Authentication is handled directly by Appwrite Auth.

```json
{
  "collectionId": "users",
  "name": "Users",
  "permissions": ["read(\"any\")", "write(\"users\")"],
  "attributes": [
    {
      "key": "name",
      "type": "string",
      "required": true,
      "size": 100
    },
    {
      "key": "phoneNumber",
      "type": "string",
      "required": true,
      "size": 15
    },
    {
      "key": "email",
      "type": "string",
      "required": true,
      "size": 100
    },
    {
      "key": "upiId",
      "type": "string",
      "required": false,
      "size": 100
    },
    {
      "key": "profileImage",
      "type": "string",
      "required": false,
      "size": 500
    },
    {
      "key": "joinedAt",
      "type": "datetime",
      "required": true
    }
  ],
  "indexes": [
    {
      "key": "email_unique",
      "type": "unique",
      "attributes": ["email"]
    },
    {
      "key": "phoneNumber_unique",
      "type": "unique",
      "attributes": ["phoneNumber"]
    }
  ]
}
```

    {
      "key": "upiId",
      "type": "string",
      "required": false,
      "size": 100
    },
    {
      "key": "createdAt",
      "type": "datetime",
      "required": true
    }

],
"indexes": [
{
"key": "mobileNumber_unique",
"type": "unique",
"attributes": ["mobileNumber"]
}
]
}

````

#### Campaigns Collection

```json
{
  "collectionId": "campaigns",
  "name": "Campaigns",
  "permissions": ["read(\"any\")", "write(\"users\")"],
  "attributes": [
    {
      "key": "hostId",
      "type": "string",
      "required": true,
      "size": 36
    },
    {
      "key": "title",
      "type": "string",
      "required": true,
      "size": 100
    },
    {
      "key": "description",
      "type": "string",
      "required": true,
      "size": 1000
    },
    {
      "key": "purpose",
      "type": "string",
      "required": true,
      "size": 200
    },
    {
      "key": "targetAmount",
      "type": "double",
      "required": true
    },
    {
      "key": "collectedAmount",
      "type": "double",
      "required": true,
      "default": 0
    },
    {
      "key": "repaymentDueDate",
      "type": "datetime",
      "required": false
    },
    {
      "key": "status",
      "type": "string",
      "required": true,
      "size": 20,
      "default": "active"
    },
    {
      "key": "campaignLink",
      "type": "string",
      "required": false,
      "size": 500
    },
    {
      "key": "qrCodeUrl",
      "type": "string",
      "required": false,
      "size": 500
    },
    {
      "key": "createdAt",
      "type": "datetime",
      "required": true
    },
    {
      "key": "updatedAt",
      "type": "datetime",
      "required": true
    }
  ],
  "indexes": [
    {
      "key": "hostId_index",
      "type": "key",
      "attributes": ["hostId"]
    },
    {
      "key": "status_index",
      "type": "key",
      "attributes": ["status"]
    },
    {
      "key": "createdAt_index",
      "type": "key",
      "attributes": ["createdAt"]
    }
  ]
}
````

#### Contributions Collection

```json
{
  "collectionId": "contributions",
  "name": "Contributions",
  "permissions": ["read(\"any\")", "write(\"users\")"],
  "attributes": [
    {
      "key": "campaignId",
      "type": "string",
      "required": true,
      "size": 36
    },
    {
      "key": "contributorId",
      "type": "string",
      "required": false,
      "size": 36
    },
    {
      "key": "contributorName",
      "type": "string",
      "required": true,
      "size": 100
    },
    {
      "key": "contributorName",
      "type": "string",
      "required": true,
      "size": 100
    },
    {
      "key": "amount",
      "type": "double",
      "required": true
    },
    {
      "key": "utr",
      "type": "string",
      "required": true,
      "size": 12
    },
    {
      "key": "type",
      "type": "string",
      "required": true,
      "size": 10
    },
    {
      "key": "repaymentStatus",
      "type": "string",
      "required": false,
      "size": 20,
      "default": "na"
    },
    {
      "key": "repaymentDueDate",
      "type": "datetime",
      "required": false
    },
    {
      "key": "isAnonymous",
      "type": "boolean",
      "required": true,
      "default": false
    },
    {
      "key": "paymentScreenshotUrl",
      "type": "string",
      "required": false,
      "size": 500
    },
    {
      "key": "createdAt",
      "type": "datetime",
      "required": true
    },
    {
      "key": "repaidAt",
      "type": "datetime",
      "required": false
    }
  ],
  "indexes": [
    {
      "key": "campaignId_index",
      "type": "key",
      "attributes": ["campaignId"]
    },
    {
      "key": "contributorId_index",
      "type": "key",
      "attributes": ["contributorId"]
    },
    {
      "key": "utr_campaign_unique",
      "type": "unique",
      "attributes": ["utr", "campaignId"]
    },
    {
      "key": "type_index",
      "type": "key",
      "attributes": ["type"]
    },
    {
      "key": "createdAt_index",
      "type": "key",
      "attributes": ["createdAt"]
    }
  ]
}
```

#### Notifications Collection

```json
{
  "collectionId": "notifications",
  "name": "Notifications",
  "permissions": ["read(\"users\")", "write(\"users\")"],
  "attributes": [
    {
      "key": "contributionId",
      "type": "string",
      "required": true,
      "size": 36
    },
    {
      "key": "type",
      "type": "string",
      "required": true,
      "size": 50
    },
    {
      "key": "message",
      "type": "string",
      "required": true,
      "size": 500
    },
    {
      "key": "sentAt",
      "type": "datetime",
      "required": true
    },
    {
      "key": "sentBy",
      "type": "string",
      "required": true,
      "size": 36
    }
  ],
  "indexes": [
    {
      "key": "contributionId_index",
      "type": "key",
      "attributes": ["contributionId"]
    },
    {
      "key": "type_index",
      "type": "key",
      "attributes": ["type"]
    },
    {
      "key": "sentAt_index",
      "type": "key",
      "attributes": ["sentAt"]
    }
  ]
}
```

### 2. Create Storage Bucket

Create a storage bucket for payment screenshots:

```json
{
  "bucketId": "screenshots",
  "name": "Payment Screenshots",
  "permissions": ["read(\"any\")", "write(\"users\")"],
  "fileSecurity": true,
  "enabled": true,
  "maximumFileSize": 10485760,
  "allowedFileExtensions": ["jpg", "jpeg", "png", "webp"],
  "compression": "gzip",
  "encryption": true,
  "antivirus": true
}
```

    {
      "key": "utr",
      "type": "string",
      "required": true,
      "size": 12
    },
    {
      "key": "type",
      "type": "string",
      "required": true,
      "size": 10
    },
    {
      "key": "repaymentStatus",
      "type": "string",
      "required": true,
      "size": 20,
      "default": "pending"
    },
    {
      "key": "paymentScreenshotUrl",
      "type": "string",
      "required": false,
      "size": 500
    },
    {
      "key": "isAnonymous",
      "type": "boolean",
      "required": true,
      "default": false
    },
    {
      "key": "createdAt",
      "type": "datetime",
      "required": true
    },
    {
      "key": "repaidAt",
      "type": "datetime",
      "required": false
    }

],
"indexes": [
{
"key": "campaignId_index",
"type": "key",
"attributes": ["campaignId"]
},
{
"key": "contributorId_index",
"type": "key",
"attributes": ["contributorId"]
},
{
"key": "utr_campaign_unique",
"type": "unique",
"attributes": ["campaignId", "utr"]
}
]
}

````

#### Notifications Collection

```json
{
  "collectionId": "notifications",
  "name": "Notifications",
  "permissions": ["read(\"users\")", "write(\"users\")"],
  "attributes": [
    {
      "key": "contributionId",
      "type": "string",
      "required": false,
      "size": 36
    },
    {
      "key": "type",
      "type": "string",
      "required": true,
      "size": 50
    },
    {
      "key": "message",
      "type": "string",
      "required": true,
      "size": 500
    },
    {
      "key": "sentAt",
      "type": "datetime",
      "required": true
    },
    {
      "key": "sentBy",
      "type": "string",
      "required": true,
      "size": 36
    }
  ]
}
````

### 2. Create Storage Bucket

Create a storage bucket for payment screenshots:

```json
{
  "bucketId": "screenshots",
  "name": "Payment Screenshots",
  "permissions": [
    "read(\"any\")",
    "create(\"users\")",
    "update(\"users\")",
    "delete(\"users\")"
  ],
  "fileSecurity": true,
  "enabled": true,
  "maximumFileSize": 10485760,
  "allowedFileExtensions": ["jpg", "jpeg", "png", "webp"],
  "compression": "gzip",
  "encryption": true,
  "antivirus": true
}
```

## Deployment Steps

### 1. Install Appwrite CLI

```bash
npm install -g appwrite-cli
```

### 2. Login to Appwrite

```bash
appwrite login
```

### 3. Initialize Project

```bash
cd backend
appwrite init project
```

### 4. Deploy Function

```bash
appwrite deploy function
```

Or manually:

```bash
appwrite functions create \
  --functionId friendfund-main \
  --name "FriendFund Main API" \
  --runtime node-18.0 \
  --execute any \
  --timeout 30
```

### 5. Set Environment Variables

```bash
appwrite functions updateVariables \
  --functionId friendfund-main \
  --variables '{
    "APPWRITE_DATABASE_ID": "your-database-id",
    "USERS_COLLECTION_ID": "users",
    "CAMPAIGNS_COLLECTION_ID": "campaigns",
    "CONTRIBUTIONS_COLLECTION_ID": "contributions",
    "NOTIFICATIONS_COLLECTION_ID": "notifications",
    "SCREENSHOTS_BUCKET_ID": "screenshots",
    "FRONTEND_BASE_URL": "https://your-domain.com"
  }'
```

### 6. Deploy Code

```bash
appwrite functions createDeployment \
  --functionId friendfund-main \
  --entrypoint index.js \
  --commands "npm install"
```

## API Endpoints

Once deployed, your function will handle the following endpoints:

### Health Check

- `GET /health` - Check backend status

### Campaigns

- `GET /campaigns` - Get all active campaigns
- `GET /campaigns/{id}` - Get specific campaign
- `GET /campaigns/user/{userId}` - Get user's campaigns
- `POST /campaigns` - Create new campaign
- `PUT /campaigns/{id}` - Update campaign
- `POST /campaigns/{id}/link` - Generate campaign link

### Contributions

- `GET /contributions/campaign/{campaignId}` - Get campaign contributions
- `GET /contributions/user/{userId}` - Get user contributions
- `POST /contributions` - Create contribution
- `PATCH /contributions/{id}/repaid` - Mark loan as repaid

### OCR

- `POST /ocr/process` - Process payment screenshot

### Notifications

- `POST /notifications/reminder` - Send loan reminder
- `GET /notifications/overdue` - Get overdue loans

### QR Codes

- `GET /qr/{campaignId}` - Generate QR code

## Testing

Test your deployed function:

```bash
curl -X GET "https://[PROJECT-ID].appwrite.global/v1/functions/friendfund-main/executions" \
  -H "X-Appwrite-Project: [PROJECT-ID]" \
  -H "X-Appwrite-Key: [API-KEY]"
```

## Environment Variables

Required environment variables for the function:

| Variable                      | Description                 | Default                     |
| ----------------------------- | --------------------------- | --------------------------- |
| `APPWRITE_DATABASE_ID`        | Database ID                 | friendfund-db               |
| `USERS_COLLECTION_ID`         | Users collection ID         | users                       |
| `CAMPAIGNS_COLLECTION_ID`     | Campaigns collection ID     | campaigns                   |
| `CONTRIBUTIONS_COLLECTION_ID` | Contributions collection ID | contributions               |
| `NOTIFICATIONS_COLLECTION_ID` | Notifications collection ID | notifications               |
| `SCREENSHOTS_BUCKET_ID`       | Screenshots bucket ID       | screenshots                 |
| `FRONTEND_BASE_URL`           | Frontend URL                | https://friendfund.pro26.in |

## Monitoring

Monitor your function through:

1. **Appwrite Console**: View execution logs and metrics
2. **Function Logs**: Real-time logging for debugging
3. **Error Tracking**: Built-in error reporting
4. **Performance**: Execution time and memory usage

## Troubleshooting

### Common Issues

1. **Permission Denied**: Check collection permissions
2. **Missing Collections**: Ensure all collections are created
3. **Environment Variables**: Verify all required variables are set
4. **Function Timeout**: Increase timeout for heavy operations

### Debug Mode

Enable debug logging:

```javascript
const DEBUG = process.env.DEBUG === "true";

if (DEBUG) {
  log(`Debug: ${JSON.stringify(payload)}`);
}
```

## Security Considerations

1. **API Keys**: Never expose API keys in frontend
2. **User Authentication**: Validate user sessions
3. **Input Validation**: Sanitize all inputs
4. **Rate Limiting**: Implement request throttling
5. **CORS**: Configure appropriate CORS headers

## Support

For issues and questions:

- **GitHub Issues**: https://github.com/ayrariyaz/FriendFund/issues
- **Documentation**: Check `/docs` folder
- **Email**: ayra@pro26.in

---

**Built with ❤️ by Pro26**
