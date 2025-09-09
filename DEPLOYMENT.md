# Deployment Guide for FriendFund API

## Prerequisites

1. **Appwrite Account**: Create an account at [Appwrite Cloud](https://cloud.appwrite.io/)
2. **Appwrite CLI**: Install the Appwrite CLI tool
3. **Node.js**: Ensure Node.js 18+ is installed

## Setup Steps

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
appwrite init project
```

### 4. Create Database and Collections

1. Go to your Appwrite console
2. Create a new database named `friend-fund-db`
3. Create the following collections with attributes as specified in `database-schema.md`:
   - `users`
   - `campaigns`
   - `contributions`

### 5. Configure Environment Variables

1. Copy `.env.example` to `.env`
2. Update the values with your Appwrite project details:
   - `APPWRITE_FUNCTION_PROJECT_ID`: Your project ID from Appwrite console
   - `APPWRITE_FUNCTION_API_KEY`: Create an API key in Appwrite console with appropriate permissions

### 6. Deploy Function

```bash
appwrite functions deploy friend-fund-api
```

### 7. Set Function Variables

In the Appwrite console, go to Functions > friend-fund-api > Settings > Variables and add:

- `APPWRITE_FUNCTION_ENDPOINT`
- `APPWRITE_FUNCTION_PROJECT_ID`
- `APPWRITE_FUNCTION_API_KEY`

### 8. Test the Deployment

1. Get the function URL from the Appwrite console
2. Update the `baseUrl` in your Postman collection
3. Run the Postman tests to verify all endpoints are working

## Function URL

After deployment, your function will be available at:

```
https://[your-project-id].appwrite.global/functions/friend-fund-api/executions
```

## Testing

1. Import the Postman collection: `FriendFund-API.postman_collection.json`
2. Import the environment: `FriendFund-Development.postman_environment.json`
3. Update the `baseUrl` variable with your function URL
4. Run the collection to test all endpoints

## Monitoring

- Check function logs in the Appwrite console
- Monitor function execution metrics
- Set up alerts for errors or performance issues

## Troubleshooting

### Common Issues

1. **Function timeout**: Increase timeout in `appwrite.json`
2. **Permission errors**: Check API key permissions
3. **Database errors**: Verify collection names and attributes
4. **CORS errors**: Ensure proper headers are set in responses

### Logs

Check function logs in the Appwrite console under Functions > friend-fund-api > Executions.
