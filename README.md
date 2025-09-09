# FriendFund Backend

A serverless backend for the FriendFund application built with Appwrite Functions and Node.js.

## Overview

FriendFund is a community-focused platform for individuals to request or send small amounts of money to friends and peers using direct UPI payment links.

## Features

- User authentication with mobile number verification
- Campaign creation and management
- Contribution tracking (Gifts and Loans)
- Public campaign viewing
- Loan repayment management

## API Endpoints

### Authentication

- `POST /auth/register` - Register a new user
- `POST /auth/login` - Login user
- `POST /auth/verify-otp` - Verify OTP
- `GET /auth/user` - Get current user profile

### Campaigns

- `POST /campaigns` - Create a new campaign
- `GET /campaigns/:id` - Get campaign details
- `GET /campaigns` - Get user's campaigns
- `PUT /campaigns/:id` - Update campaign
- `DELETE /campaigns/:id` - Close/delete campaign

### Contributions

- `POST /contributions` - Make a contribution
- `GET /campaigns/:id/contributions` - Get campaign contributions
- `PUT /contributions/:id/repay` - Mark loan as repaid

## Setup

1. Clone the repository
2. Install dependencies: `npm install`
3. Configure Appwrite credentials
4. Deploy to Appwrite Functions

## Environment Variables

- `APPWRITE_FUNCTION_ENDPOINT`
- `APPWRITE_FUNCTION_API_KEY`
- `APPWRITE_FUNCTION_PROJECT_ID`

## Deployment

This function is designed to be deployed as an Appwrite Function.
