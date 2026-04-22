#!/bin/bash

# RangraGo Launch Automation Script
# Use this to build and prepare for production

echo "🚀 Starting RangraGo Production Build..."

# 1. Backend Setup
echo "📦 Setting up Backend..."
cd backend
npm install --production
echo "✅ Backend dependencies installed."
cd ..

# 2. Frontend Build
echo "📱 Building Frontend (Web/Mobile)..."
cd frontend
flutter pub get
# Building for web as a sample deployment
flutter build web --release --base-href "/"
echo "✅ Frontend Web build completed in /frontend/build/web"
cd ..

# 3. Environment Check
if [ ! -f backend/.env ]; then
    echo "⚠️  Warning: backend/.env missing! Creating a template..."
    echo "PORT=5000\nMONGO_URI=mongodb://localhost:27017/rangrago\nJWT_SECRET=production_secret_key\nAGORA_APP_ID=your_id" > backend/.env
fi

echo "✨ RangraGo is ready for launch!"
echo "To start the server: cd backend && npm start"
