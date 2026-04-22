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
  
  static String? userToken;
}
