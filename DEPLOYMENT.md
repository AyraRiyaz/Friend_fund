# FriendFund Appwrite Function Deployment Guide

## Quick Deployment Steps

### 1. Push to GitHub

```bash
git init
git add .
git commit -m "Initial commit: FriendFund backend"
git branch -M main
git remote add origin <your-github-repo-url>
git push -u origin main
```

### 2. Deploy via Appwrite Dashboard

#### Method A: GitHub Integration (Recommended)

1. Go to Appwrite Dashboard → Functions
2. Click "Create Function"
3. Choose "Git Integration"
4. Connect your GitHub repository
5. Set:
   - **Runtime**: Node.js 18
   - **Entry Point**: `main.js`
   - **Branch**: `main`
   - **Root Directory**: `/` (or your function folder)

#### Method B: Manual Upload

1. Zip your project files (excluding node_modules)
2. Go to Appwrite Dashboard → Functions
3. Click "Create Function"
4. Choose "Manual Upload"
5. Upload your zip file
6. Set **Runtime**: Node.js 18

### 3. Configure Environment Variables

In your Appwrite Function settings, add:

```
APPWRITE_ENDPOINT=https://cloud.appwrite.io/v1
APPWRITE_PROJECT=your-actual-project-id
APPWRITE_API_KEY=your-server-api-key
DATABASE_ID=friendfundDB
COLLECTION_USERS=users
COLLECTION_CAMPAIGNS=campaigns
COLLECTION_CONTRIBUTIONS=contributions

# Optional for SMS:
TWILIO_SID=your-twilio-sid
TWILIO_AUTH=your-twilio-auth-token
TWILIO_PHONE=your-twilio-phone
```

### 4. Set Function Permissions

- **Execute**: Any (for public endpoints)
- **Events**: None (HTTP-triggered only)
- **Timeout**: 30 seconds
- **Memory**: 512 MB

### 5. Test Your Function

Your function will be available at:

```
https://cloud.appwrite.io/v1/functions/{function-id}/executions
```

## Database Setup Checklist

### Create Collections in Appwrite Console:

#### 1. Users Collection

- ID: `users`
- Permissions: Users can read/write their own documents

#### 2. Campaigns Collection

- ID: `campaigns`
- Permissions:
  - Read: Any
  - Write: Users (authenticated)

**Attributes:**

- `title` (string, required)
- `description` (string, required)
- `purpose` (string, required)
- `targetAmount` (double, required)
- `collectedAmount` (double, default: 0)
- `repaymentDueDate` (string, required)
- `upiId` (string, required)
- `hostId` (string, required)
- `hostName` (string, required)
- `status` (string, required, default: "active")
- `createdAt` (string, required)
- `updatedAt` (string, required)

#### 3. Contributions Collection

- ID: `contributions`
- Permissions:
  - Read: Users (authenticated)
  - Write: Users (authenticated)

**Attributes:**

- `campaignId` (string, required)
- `contributorId` (string)
- `contributorName` (string, required)
- `amount` (double, required)
- `utr` (string, required)
- `type` (string, required) // "donation" or "loan"
- `isAnonymous` (boolean, default: false)
- `isRepaid` (boolean, default: false)
- `repaymentDueDate` (string)
- `repaidAt` (string)
- `lastReminderSent` (string)
- `createdAt` (string, required)

### Create Indexes (Optional but Recommended)

- `campaigns`: Index on `status` and `hostId`
- `contributions`: Index on `campaignId` and `type`

## Testing Your Deployment

### 1. Test via Appwrite Console

1. Go to Functions → Your Function → Execute
2. Test with sample requests

### 2. Test via Postman/cURL

```bash
# Test campaign creation
curl -X POST "https://cloud.appwrite.io/v1/functions/{function-id}/executions" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer {jwt-token}" \
  -d '{
    "path": "/campaigns",
    "method": "POST",
    "body": {
      "title": "Test Campaign",
      "description": "Testing the API",
      "purpose": "Test",
      "targetAmount": 1000,
      "repaymentDueDate": "2025-12-31",
      "upiId": "test@paytm"
    }
  }'
```

## Troubleshooting

### Common Issues:

1. **"Function not found"**

   - Check function ID in URL
   - Ensure function is deployed and active

2. **"Authentication required"**

   - Add JWT token to Authorization header
   - Ensure user is authenticated via Appwrite Auth

3. **"Database not found"**

   - Verify DATABASE_ID environment variable
   - Check if database exists in Appwrite Console

4. **"Collection not found"**

   - Verify collection IDs in environment variables
   - Check if collections exist with correct names

5. **SMS not working**
   - Verify Twilio credentials
   - Check Twilio phone number format (+country code)

### Debugging:

- Check function logs in Appwrite Console
- Use `log()` statements for debugging
- Test individual endpoints one by one

## Security Checklist

- ✅ Environment variables set securely
- ✅ JWT authentication implemented
- ✅ User authorization checks in place
- ✅ Input validation for all endpoints
- ✅ No sensitive data in error messages
- ✅ CORS headers configured for Flutter
- ✅ API key has appropriate permissions only

Your FriendFund backend is now ready for production! 🚀
