# FriendFund Backend Deployment

## Quick Setup Commands

```bash
# Install dependencies
npm install

# Deploy to Appwrite
appwrite functions deploy

# Check deployment status
appwrite functions list

# View function logs
appwrite functions logs --functionId friendfund-main

# Test the function
appwrite functions createExecution --functionId friendfund-main --async false --data '{"path":"/health","method":"GET"}'
```

## Environment Variables Required

Make sure these are set in your Appwrite function configuration:

- `APPWRITE_DATABASE_ID`: Your database ID (default: friendfund-db)
- `USERS_COLLECTION_ID`: Users collection ID (default: users)
- `CAMPAIGNS_COLLECTION_ID`: Campaigns collection ID (default: campaigns)
- `CONTRIBUTIONS_COLLECTION_ID`: Contributions collection ID (default: contributions)
- `NOTIFICATIONS_COLLECTION_ID`: Notifications collection ID (default: notifications)
- `SCREENSHOTS_BUCKET_ID`: Screenshots bucket ID (default: screenshots)
- `FRONTEND_BASE_URL`: Your frontend URL (default: https://friendfund.pro26.in)

## Test Endpoints

After deployment, test with:

```bash
# Health check
curl -X POST https://cloud.appwrite.io/v1/functions/friendfund-main/executions \
  -H "Content-Type: application/json" \
  -H "X-Appwrite-Project: YOUR_PROJECT_ID" \
  -d '{"path":"/health","method":"GET"}'

# Get campaigns
curl -X POST https://cloud.appwrite.io/v1/functions/friendfund-main/executions \
  -H "Content-Type: application/json" \
  -H "X-Appwrite-Project: YOUR_PROJECT_ID" \
  -d '{"path":"/campaigns","method":"GET"}'
```
