# FriendFund Backend

A complete Appwrite Function for the FriendFund application - a fundraising platform supporting both donations and loans with UPI payment integration.

## 🚀 Features

- **Campaign Management**: Create and manage fundraising campaigns
- **Contribution Tracking**: Log donations and loans with UPI integration
- **Authentication**: JWT-based authentication using Appwrite
- **SMS Reminders**: Twilio integration for loan payment reminders
- **Anonymous Contributions**: Support for anonymous donations
- **Loan Repayment Tracking**: Mark loans as repaid with due date management

## 📁 Project Structure

```
friendfund-backend/
├── main.js                 # Main Appwrite function
├── package.json           # Node.js dependencies
├── README.md             # Project documentation
├── .env.example          # Environment variables template
└── appwrite.json         # Appwrite function configuration
```

## 🛠 Setup Instructions

### 1. Clone and Install Dependencies

```bash
git clone <your-repo-url>
cd friendfund-backend
npm install
```

### 2. Environment Variables

Create environment variables in your Appwrite Function settings:

```env
APPWRITE_ENDPOINT=https://cloud.appwrite.io/v1
APPWRITE_PROJECT=your-project-id
APPWRITE_API_KEY=your-api-key
DATABASE_ID=friendfundDB
COLLECTION_USERS=users
COLLECTION_CAMPAIGNS=campaigns
COLLECTION_CONTRIBUTIONS=contributions

# Optional: SMS Reminders (Twilio)
TWILIO_SID=your-twilio-sid
TWILIO_AUTH=your-twilio-auth-token
TWILIO_PHONE=your-twilio-phone-number
```

### 3. Database Setup

Create these collections in your Appwrite database (`friendfundDB`):

#### Users Collection (`users`)

- Collection ID: `users`
- Permissions: Read/Write for authenticated users

#### Campaigns Collection (`campaigns`)

```json
{
  "title": "string",
  "description": "string",
  "purpose": "string",
  "targetAmount": "number",
  "collectedAmount": "number",
  "repaymentDueDate": "string",
  "upiId": "string",
  "hostId": "string",
  "hostName": "string",
  "status": "string",
  "createdAt": "string",
  "updatedAt": "string"
}
```

#### Contributions Collection (`contributions`)

```json
{
  "campaignId": "string",
  "contributorId": "string",
  "contributorName": "string",
  "amount": "number",
  "utr": "string",
  "type": "string",
  "isAnonymous": "boolean",
  "isRepaid": "boolean",
  "repaymentDueDate": "string",
  "repaidAt": "string",
  "lastReminderSent": "string",
  "createdAt": "string"
}
```

### 4. Deploy to Appwrite

1. Create a new Function in Appwrite Dashboard
2. Set Runtime: **Node.js 18**
3. Set Trigger: **HTTP**
4. Upload your code or connect via Git
5. Set environment variables
6. Deploy!

## 📡 API Endpoints

### Authentication

All protected endpoints require JWT token in Authorization header:

```
Authorization: Bearer <jwt-token>
```

### 1. Create Campaign

```http
POST /campaigns
Content-Type: application/json

{
  "title": "Help John's Medical Treatment",
  "description": "John needs urgent medical treatment...",
  "purpose": "Medical Emergency",
  "targetAmount": 50000,
  "repaymentDueDate": "2025-12-31",
  "upiId": "john@paytm"
}
```

### 2. Get Campaigns

```http
# Get all active campaigns
GET /campaigns

# Get only user's campaigns
GET /campaigns?hostOnly=true
```

### 3. Create Contribution

```http
POST /contributions
Content-Type: application/json

{
  "campaignId": "campaign-id-here",
  "contributorName": "Jane Doe",
  "amount": 1000,
  "utr": "UTR123456789",
  "type": "donation",
  "isAnonymous": false
}
```

### 4. Mark Loan as Repaid

```http
PATCH /contributions/:contributionId/repaid
```

### 5. Send Reminder

```http
POST /remind
Content-Type: application/json

{
  "contributionId": "contribution-id-here"
}
```

## 🔧 Response Format

### Success Response

```json
{
  "success": true,
  "data": {
    // Response data here
  },
  "error": null
}
```

### Error Response

```json
{
  "success": false,
  "data": null,
  "error": "Error message here"
}
```

## 🔐 Security Features

- JWT token validation for protected routes
- User authorization checks for campaign ownership
- Input validation and sanitization
- Secure error messages (no sensitive data exposure)
- CORS headers for Flutter frontend integration

## 💳 Payment Integration

- UPI deep link support
- Manual payment confirmation via UTR tracking
- Automatic campaign amount updates
- Support for both donations and loans

## 📱 Flutter Integration

This backend is designed to work seamlessly with Flutter frontend:

1. Use Appwrite Flutter SDK for authentication
2. Send JWT tokens with API requests
3. Handle UPI payments via Flutter UPI plugins
4. Call these APIs after successful payments

## 🛠 Development

### Local Testing

```bash
# Install dependencies
npm install

# The function runs in Appwrite environment
# Test via Appwrite Dashboard or deploy to staging
```

### Environment Setup

Copy `.env.example` to set up your environment variables for local development reference.

## 📝 License

This project is licensed under the MIT License.

## 🤝 Contributing

1. Fork the repository
2. Create your feature branch
3. Commit your changes
4. Push to the branch
5. Open a Pull Request

## 🆘 Support

For issues and questions:

1. Check the Appwrite documentation
2. Review the API responses for error messages
3. Check the function logs in Appwrite Dashboard

---

**Happy Fundraising! 🎉**
