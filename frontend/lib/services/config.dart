class AppConfig {
  // 1. DEVELOPMENT (Jab laptop par test karein)
  // static const String serverIp = "192.168.2.124"; 
  
  // 2. PRODUCTION (Jab Render/Netlify par deploy karein)
  // APNA RENDER URL YAHAN DALEIN (e.g. https://rangrago-backend.onrender.com)
  static const String liveUrl = "https://rangrago-backend.onrender.com"; 
  
  static const String baseUrl = "$liveUrl/api";
  static const String socketUrl = liveUrl;
  static const String authUrl = "$baseUrl/auth";
  static const String rideUrl = "$baseUrl/rides";
  
  // PASTE YOUR GOOGLE MAPS API KEY HERE for A to Z Locations
  static const String googleMapsKey = "YOUR_GOOGLE_MAPS_API_KEY_HERE";

  // GOOGLE CLIENT ID (for Google Sign In)
  static const String googleClientId = "336631033589-nq28gonut9lsv33ocs68tq4h1dejbbb8.apps.googleusercontent.com";

  // AGORA APP ID (for Voice Calling)
  static const String agoraAppId = "4c3f88bf7f8c40de879736f0fc8807e4";
  
  static String? userToken;
}
