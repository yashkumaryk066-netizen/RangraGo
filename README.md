# RangraGo - Ride + Call MVP

This project is a working MVP (Minimum Viable Product) for a ride-sharing application with integrated in-app calling via Agora. 

## 🚀 Getting Started

### 1. Backend Setup (Node.js)
1. Navigate to the `backend` directory:
   ```bash
   cd backend
   ```
2. Install dependencies:
   ```bash
   npm install
   ```
3. Configure your environment variables in `.env`:
   - `MONGO_URI`: Your MongoDB connection string.
   - `AGORA_APP_ID`: Your Agora project ID.
   - `AGORA_APP_CERTIFICATE`: Your Agora project certificate.
4. Start the server:
   ```bash
   npm start
   ```

### 2. Frontend Setup (Flutter)
1. Navigate to the `frontend` directory:
   ```bash
   cd frontend
   ```
2. Fetch dependencies:
   ```bash
   flutter pub get
   ```
3. (Important) Update the `serverUrl` in `lib/services/socket_service.dart` with your machine's IP address if running on a physical device.
4. Run the app:
   ```bash
   flutter run
   ```

## 🏗️ System Architecture
- **Backend**: Express.js, Socket.io, MongoDB.
- **Frontend**: Flutter, `socket_io_client`, `agora_rtc_engine`.
- **Calling**: Signaling via Sockets -> Audio via Agora (using `ride_$rideId` as channel).

## 🔒 Security Rules
- Only riders/drivers with an `ACCEPTED` ride can initiate a call signaling request.
- Phone numbers are never exchanged between users.
