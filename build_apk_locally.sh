#!/bin/bash

# RangraGo Local Build Script
# This script builds the Flutter APK locally.

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${BLUE}🚀 Starting RangraGo Local Build...${NC}"

# 1. Navigate to frontend
echo -e "${BLUE}📁 Navigating to frontend directory...${NC}"
cd frontend || { echo -e "${RED}❌ Frontend directory not found!${NC}"; exit 1; }

# 2. Get dependencies
echo -e "${BLUE}📦 Getting Flutter dependencies...${NC}"
flutter pub get || { echo -e "${RED}❌ Failed to get dependencies!${NC}"; exit 1; }

# 3. Build APK
echo -e "${BLUE}🏗️ Building Release APK...${NC}"
flutter build apk --release || { echo -e "${RED}❌ Build failed!${NC}"; exit 1; }

# 4. Move APK to root
echo -e "${BLUE}🚚 Moving APK to root directory...${NC}"
cp build/app/outputs/flutter-apk/app-release.apk ../RangraGo_Local.apk

echo -e "${GREEN}✅ BUILD SUCCESSFUL!${NC}"
echo -e "${GREEN}📍 APK Location: $(pwd)/../RangraGo_Local.apk${NC}"
echo ""
echo -e "${BLUE}You can now transfer 'RangraGo_Local.apk' to your phone.${NC}"
