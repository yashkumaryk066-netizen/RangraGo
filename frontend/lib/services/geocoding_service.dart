import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';

class GeocodingService {
  // Photon API - Advanced A to Z Location Search (Key-less)
  
  static Future<List<Map<String, dynamic>>> searchPlaces(String query) async {
    if (query.trim().isEmpty) return [];

    try {
      final currentPos = await getCurrentLocation();
      String bias = "location_bias=78,20"; 
      if (currentPos != null) {
        bias = "lat=${currentPos.latitude}&lon=${currentPos.longitude}";
      }

      final uri = Uri.parse(
        "https://photon.komoot.io/api/?q=${Uri.encodeComponent(query)}&limit=15&$bias", 
      );

      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List features = data["features"];
        
        return features.map<Map<String, dynamic>>((f) {
          final p = f["properties"];
          final coords = f["geometry"]["coordinates"];
          
          String name = p["name"] ?? "";
          String house = p["housenumber"] ?? "";
          String street = p["street"] ?? "";
          String suburb = p["suburb"] ?? p["district"] ?? "";
          String city = p["city"] ?? p["state"] ?? "";
          
          String fullName = [
            if (name.isNotEmpty) name,
            if (house.isNotEmpty) house,
            if (street.isNotEmpty) street,
            if (suburb.isNotEmpty) suburb,
            if (city.isNotEmpty) city,
          ].join(", ");

          return {
            "name": fullName,
            "short": name.isNotEmpty ? name : (street.isNotEmpty ? "$house $street" : city),
            "lat": coords[1],
            "lng": coords[0],
          };
        }).toList();
      }
    } catch (e) {
      print("Search error: $e");
    }
    return [];
  }

  static Future<String?> reverseGeocode(LatLng pos) async {
    try {
      final uri = Uri.parse(
        "https://photon.komoot.io/reverse?lat=${pos.latitude}&lon=${pos.longitude}",
      );
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List features = data["features"];
        if (features.isNotEmpty) {
          final p = features[0]["properties"];
          String name = p["name"] ?? "";
          String street = p["street"] ?? "";
          String city = p["city"] ?? p["state"] ?? "";
          return "${name.isNotEmpty ? "$name, " : ""}${street.isNotEmpty ? "$street, " : ""}$city";
        }
      }
    } catch (e) {
      print("Reverse geocode error: $e");
    }
    return null;
  }

  static Future<LatLng?> getCurrentLocation() async {
    try {
      bool serviceEnabled;
      LocationPermission permission;

      serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return null;

      permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return null;
      }

      if (permission == LocationPermission.deniedForever) return null;

      final pos = await Geolocator.getCurrentPosition();
      return LatLng(pos.latitude, pos.longitude);
    } catch (e) {
      print("GPS blocked or non-secure origin: $e");
      return null;
    }
  }
}
