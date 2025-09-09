# FriendFund Setup Script for Windows

Write-Host "🚀 Setting up FriendFund Backend..." -ForegroundColor Green

# Check if Node.js is installed
try {
    $nodeVersion = node --version
    Write-Host "✅ Node.js found: $nodeVersion" -ForegroundColor Green
} catch {
    Write-Host "❌ Node.js is not installed. Please install Node.js 18+ first." -ForegroundColor Red
    exit 1
}

# Check if npm is installed
try {
    $npmVersion = npm --version
    Write-Host "✅ npm found: $npmVersion" -ForegroundColor Green
} catch {
    Write-Host "❌ npm is not installed. Please install npm first." -ForegroundColor Red
    exit 1
}

# Install dependencies
Write-Host "📦 Installing dependencies..." -ForegroundColor Yellow
npm install

# Check if Appwrite CLI is installed
try {
    $appwriteVersion = appwrite --version
    Write-Host "✅ Appwrite CLI found: $appwriteVersion" -ForegroundColor Green
} catch {
    Write-Host "📥 Installing Appwrite CLI..." -ForegroundColor Yellow
    npm install -g appwrite-cli
}

# Create .env file if it doesn't exist
if (-not (Test-Path ".env")) {
    Write-Host "📝 Creating .env file from template..." -ForegroundColor Yellow
    Copy-Item ".env.example" ".env"
    Write-Host "⚠️  Please update the .env file with your Appwrite credentials before deploying." -ForegroundColor Yellow
}

Write-Host "✅ Setup complete!" -ForegroundColor Green
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Cyan
Write-Host "1. Update .env file with your Appwrite project details"
Write-Host "2. Create database and collections in Appwrite console (see database-schema.md)"
Write-Host "3. Run 'appwrite functions deploy friend-fund-api' to deploy"
Write-Host "4. Import Postman collection to test the API"
Write-Host ""
Write-Host "📚 See DEPLOYMENT.md for detailed deployment instructions." -ForegroundColor Cyan
