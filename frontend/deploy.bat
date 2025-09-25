@echo off
echo Starting deployment build for Friend Fund...

REM Clean previous builds
flutter clean

REM Get dependencies 
flutter pub get

REM Build for web production
flutter build web --release --web-renderer html --base-href="/"

echo Build completed! 
echo Upload the contents of build/web/ to your Netlify deployment
echo or commit and push to trigger auto-deployment.

pause