# Appwrite Database Schema Setup

This document describes the database collections needed for the FriendFund application.

## Collections

### 1. users

- **Collection ID**: `users`
- **Attributes**:
  - `userId` (string, required) - Primary key
  - `mobileNumber` (string, required) - User's mobile number
  - `upiId` (string, required) - User's UPI ID
  - `name` (string, required) - User's name
  - `createdAt` (datetime, required) - Account creation timestamp

### 2. campaigns

- **Collection ID**: `campaigns`
- **Attributes**:
  - `campaignId` (string, required) - Primary key
  - `hostId` (string, required) - Reference to users.userId
  - `title` (string, required) - Campaign title
  - `description` (string, required) - Campaign description
  - `purpose` (string, required) - Campaign purpose
  - `targetAmount` (float, required) - Target amount to raise
  - `collectedAmount` (float, required, default: 0) - Amount collected so far
  - `status` (string, required, default: "active") - Campaign status
  - `repaymentDueDate` (datetime, optional) - Due date for loan repayments
  - `createdAt` (datetime, required) - Campaign creation timestamp

### 3. contributions

- **Collection ID**: `contributions`
- **Attributes**:
  - `contributionId` (string, required) - Primary key
  - `campaignId` (string, required) - Reference to campaigns.campaignId
  - `contributorName` (string, required) - Contributor's name
  - `amount` (float, required) - Contribution amount
  - `utr` (string, required) - UPI transaction reference
  - `type` (string, required) - "gift" or "loan"
  - `repaymentStatus` (string, optional) - "pending" or "repaid" (for loans only)
  - `isAnonymous` (boolean, required, default: false) - Whether contribution is anonymous
  - `createdAt` (datetime, required) - Contribution timestamp

## Indexes

### campaigns collection

- Create index on `hostId` for faster user campaign queries
- Create index on `status` for filtering active campaigns

### contributions collection

- Create index on `campaignId` for faster campaign contribution queries
- Create index on `type` for filtering gifts/loans
- Create index on `repaymentStatus` for loan management

## Permissions

### users collection

- Read: User can read own document
- Write: User can update own document
- Create: Any authenticated user
- Delete: User can delete own document

### campaigns collection

- Read: Any user (for public campaign view)
- Write: Campaign host only
- Create: Any authenticated user
- Delete: Campaign host only

### contributions collection

- Read: Any user (for public contribution list)
- Write: Contribution creator and campaign host (for repayment status)
- Create: Any user
- Delete: None (contributions should not be deleted)

## Setup Commands

Use the Appwrite console or CLI to create these collections with the specified attributes and permissions.
