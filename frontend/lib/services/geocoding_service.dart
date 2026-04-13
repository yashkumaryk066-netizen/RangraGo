import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';

class GeocodingService {
  // Nominatim - OpenStreetMap ka free geocoding API
  // Covers entire India - every city, village, mohalla
  static const String _baseUrl = "https://nominatim.openstreetmap.org";

  static Future<List<Map<String, dynamic>>> searchPlaces(String query) async {
    if (query.trim().isEmpty) return [];

    try {
      final uri = Uri.parse(
        "$_baseUrl/search?q=${Uri.encodeComponent(query)}&countrycodes=in&format=json&limit=8&addressdetails=1",
      );

      final response = await http.get(uri, headers: {
        "Accept": "application/json",
        "User-Agent": "RangraGo/1.0 (rangra.go.app)",
      });

      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        return data.map<Map<String, dynamic>>((item) => {
          "name": item["display_name"],
          "short": _shortName(item),
          "lat": double.parse(item["lat"]),
          "lng": double.parse(item["lon"]),
        }).toList();
      }
    } catch (e) {
      print("Geocoding error: $e");
    }
    return [];
  }

  static Future<String?> reverseGeocode(LatLng pos) async {
    try {
      final uri = Uri.parse(
        "$_baseUrl/reverse?lat=${pos.latitude}&lon=${pos.longitude}&format=json",
      );
      final response = await http.get(uri, headers: {
        "User-Agent": "RangraGo/1.0",
      });
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data["display_name"];
      }
    } catch (e) {
      print("Reverse geocode error: $e");
    }
    return null;
  }

  static String _shortName(Map<String, dynamic> item) {
    final addr = item["address"] ?? {};
    final parts = <String>[];

    for (final key in ["road", "suburb", "city", "town", "village", "state_district", "state"]) {
      final val = addr[key];
      if (val != null && val.toString().isNotEmpty) {
        parts.add(val.toString());
        if (parts.length >= 3) break;
      }
    }

    return parts.isNotEmpty ? parts.join(", ") : item["display_name"];
  }

  static Future<LatLng?> getCurrentLocation() async {
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
  }
}
