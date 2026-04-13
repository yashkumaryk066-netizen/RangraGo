class AppConfig {
  static const String baseUrl = "http://localhost:5000/api"; // Use localhost for desktop, 10.0.2.2 for Android Emulator
  static const String socketUrl = "http://localhost:5000";
  static const String authUrl = "$baseUrl/auth";
  static const String rideUrl = "$baseUrl/rides";
  
  static String? userToken;
}
