# RangraGo 🚀
### India's Next-Gen Ride Experience

RangraGo is a premium, cost-optimized ride-hailing application designed for full reliability and scale. Built with a Cyber-Dark aesthetic, it offers a seamless experience for both Riders and Drivers.

## ✨ Key Features
- **Premium Branding**: Custom unified identity with high-end dark theme.
- **Cost Optimized**: Fully integrated with **OpenStreetMap** (Free) for mapping and navigation across India.
- **Strict OTP Verification**: Secure ride starts via server-validated OTP.
- **Dynamic Pricing**: Real-time fare estimation based on vehicle type (Bike, Auto, Car, Prime).
- **In-App Communication**: Agora-powered voice calling between rider and driver.
- **Professional Driver Onboarding**: Complete vehicle registration and license verification flow.
- **Real-time Sync**: Socket.io integration for instant ride updates and driver availability.

## 🛠️ Technology Stack
- **Frontend**: Flutter (Android/iOS/Web/Desktop)
- **Backend**: Node.js & Express
- **Database**: MongoDB
- **Real-time**: Socket.io
- **Voice/Communication**: Agora RTC
- **Maps**: OpenStreetMap (Nominatim Geocoding)

## 🚀 Getting Started
1. **Full Deployment**: Run `./deploy.sh` to install dependencies and build the web version.
2. **Local APK Build (Experimental)**: 
   - If tools (Java/Android SDK) are missing, run: `chmod +x setup_env.sh && ./setup_env.sh`
   - To build the APK, run: `chmod +x build_apk_locally.sh && ./build_apk_locally.sh`
   - The APK will be available in the root as `RangraGo_Local.apk`.

3. **Backend**: 
   - `cd backend`
   - `npm install`
   - Configure `.env` with your Mongo URI and Agora credentials.
   - `npm start`

4. **Frontend**:
   - `cd frontend`
   - `flutter pub get`
   - `flutter run`

## 📊 Business Logic (Pricing)
- **Bike**: ₹5/km + ₹20 base
- **Auto**: ₹10/km + ₹30 base
- **Car**: ₹15/km + ₹50 base
- **Prime**: ₹25/km + ₹80 base

---
Developed with ❤️ for the RangraGo Community.
