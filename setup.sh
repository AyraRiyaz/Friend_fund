#!/bin/bash

# FriendFund Setup Script

echo "🚀 Setting up FriendFund Backend..."

# Check if Node.js is installed
if ! command -v node &> /dev/null; then
    echo "❌ Node.js is not installed. Please install Node.js 18+ first."
    exit 1
fi

# Check if npm is installed
if ! command -v npm &> /dev/null; then
    echo "❌ npm is not installed. Please install npm first."
    exit 1
fi

# Install dependencies
echo "📦 Installing dependencies..."
npm install

# Check if Appwrite CLI is installed
if ! command -v appwrite &> /dev/null; then
    echo "📥 Installing Appwrite CLI..."
    npm install -g appwrite-cli
fi

# Create .env file if it doesn't exist
if [ ! -f .env ]; then
    echo "📝 Creating .env file from template..."
    cp .env.example .env
    echo "⚠️  Please update the .env file with your Appwrite credentials before deploying."
fi

echo "✅ Setup complete!"
echo ""
echo "Next steps:"
echo "1. Update .env file with your Appwrite project details"
echo "2. Create database and collections in Appwrite console (see database-schema.md)"
echo "3. Run 'appwrite functions deploy friend-fund-api' to deploy"
echo "4. Import Postman collection to test the API"
echo ""
echo "📚 See DEPLOYMENT.md for detailed deployment instructions."
