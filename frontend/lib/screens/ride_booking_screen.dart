import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../models/ride_model.dart';
import '../services/geocoding_service.dart';

class RideBookingScreen extends StatefulWidget {
  final Function(String, String, LatLng, LatLng, String, double) onBook; 
  const RideBookingScreen({super.key, required this.onBook});

  @override
  State<RideBookingScreen> createState() => _RideBookingScreenState();
}

class _RideBookingScreenState extends State<RideBookingScreen> {
  final TextEditingController _pickupController = TextEditingController();
  final TextEditingController _dropController = TextEditingController();
  final MapController _mapController = MapController();

  LatLng _pickupPos = const LatLng(28.6139, 77.2090); // Default: New Delhi
  LatLng? _dropPos;
  String? _activeField;
  bool _isSearching = false;

  List<Map<String, dynamic>> _suggestions = [];
  Timer? _debounce;
  String selectedVehicle = "CAR";

  void _onQueryChanged(String query, String field) {
    setState(() => _activeField = field);

    if (_debounce?.isActive ?? false) _debounce!.cancel();
    if (query.trim().length < 2) {
      setState(() => _suggestions = []);
      return;
    }

    setState(() => _isSearching = true);
    _debounce = Timer(const Duration(milliseconds: 600), () async {
      final results = await GeocodingService.searchPlaces(query);
      if (mounted) {
        setState(() {
          _suggestions = results;
          _isSearching = false;
        });
      }
    });
  }

  void _selectSuggestion(Map<String, dynamic> place) {
    final pos = LatLng(place['lat'], place['lng']);
    final name = place['short'] ?? place['name'];

    setState(() {
      if (_activeField == 'pickup') {
        _pickupController.text = name;
        _pickupPos = pos;
      } else {
        _dropController.text = name;
        _dropPos = pos;
      }
      _suggestions = [];
      _activeField = null;
    });
    _mapController.move(pos, 14.0);
  }

  List<LatLng> get _routePoints {
    if (_dropPos == null) return [];
    return [_pickupPos, _dropPos!];
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _pickupController.dispose();
    _dropController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 260,
          child: Stack(
            children: [
              FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: _pickupPos,
                  initialZoom: 13.0,
                  onTap: (tapPos, latLng) async {
                    if (_activeField != null) {
                      final name = await GeocodingService.reverseGeocode(latLng);
                      if (name != null && mounted) {
                        setState(() {
                          if (_activeField == 'pickup') {
                            _pickupController.text = name;
                            _pickupPos = latLng;
                          } else {
                            _dropController.text = name;
                            _dropPos = latLng;
                          }
                          _suggestions = [];
                          _activeField = null;
                        });
                      }
                    }
                  },
                ),
                children: [
                  // GOOGLE MAPS TILES (No API Key Required)
                  TileLayer(
                    urlTemplate: "https://mt0.google.com/vt/lyrs=m&hl=en&x={x}&y={y}&z={z}",
                    userAgentPackageName: "com.rangra.go",
                  ),
                  if (_dropPos != null)
                    PolylineLayer(polylines: [
                      Polyline(
                        points: [_pickupPos, _dropPos!],
                        strokeWidth: 4.0,
                        color: Colors.blueAccent,
                      ),
                    ]),
                  MarkerLayer(markers: [
                    Marker(
                      point: _pickupPos,
                      width: 44,
                      height: 44,
                      child: const Icon(Icons.location_on, color: Colors.green, size: 40),
                    ),
                    if (_dropPos != null)
                      Marker(
                        point: _dropPos!,
                        width: 44,
                        height: 44,
                        child: const Icon(Icons.flag, color: Colors.red, size: 40),
                      ),
                  ]),
                ],
              ),
              Positioned(
                top: 10,
                right: 10,
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                      decoration: BoxDecoration(color: Colors.black87, borderRadius: BorderRadius.circular(20)),
                      child: const Row(
                        children: [
                          Icon(Icons.touch_app, color: Colors.white54, size: 12),
                          SizedBox(width: 4),
                          Text("Tap map to set", style: TextStyle(color: Colors.white54, fontSize: 8)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    GestureDetector(
                      onTap: () async {
                        setState(() => _isSearching = true);
                        try {
                          final pos = await GeocodingService.getCurrentLocation();
                          if (pos != null) {
                            final name = await GeocodingService.reverseGeocode(pos);
                            if (name != null && mounted) {
                                setState(() {
                                  _pickupController.text = name;
                                  _pickupPos = pos;
                                  _activeField = null;
                                });
                                _mapController.move(pos, 15.0);
                            }
                          }
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Could not get location. Ensure GPS is ON.")));
                        } finally {
                          setState(() => _isSearching = false);
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: const BoxDecoration(color: Color(0xFF7C3AED), shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black45, blurRadius: 10)]),
                        child: const Icon(Icons.my_location, color: Colors.white, size: 20),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
            child: Column(
              children: [
                _buildLocationField(
                  controller: _pickupController,
                  label: "PICKUP — Anywhere in India",
                  icon: Icons.my_location,
                  iconColor: Colors.greenAccent,
                  fieldKey: 'pickup',
                ),
                if (_activeField == 'pickup') _buildSuggestionsList(),
                const SizedBox(height: 12),
                _buildLocationField(
                  controller: _dropController,
                  label: "DROP — Destination",
                  icon: Icons.location_on,
                  iconColor: Colors.redAccent,
                  fieldKey: 'drop',
                ),
                if (_activeField == 'drop') _buildSuggestionsList(),
                
                const SizedBox(height: 24),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text("SELECT YOUR RIDE & PRICE", style: TextStyle(color: Colors.white24, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                ),
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _vehicleCard("BIKE", Icons.pedal_bike, _estimatePrice(5, 20)),
                      _vehicleCard("AUTO", Icons.electric_rickshaw, _estimatePrice(10, 30)),
                      _vehicleCard("CAR", Icons.directions_car, _estimatePrice(15, 50)),
                      _vehicleCard("PRIME", Icons.stars, _estimatePrice(25, 80)),
                    ],
                  ),
                ),
                
                const SizedBox(height: 24),
                GestureDetector(
                  onTap: () {
                    if (_pickupController.text.isNotEmpty && _dropController.text.isNotEmpty && _dropPos != null) {
                      const Distance distance = Distance();
                      double dist = distance.as(LengthUnit.Meter, _pickupPos, _dropPos!) / 1000.0;
                      widget.onBook(_pickupController.text, _dropController.text, _pickupPos, _dropPos!, selectedVehicle, dist);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Pickup aur Drop dono fill karo")));
                    }
                  },
                  child: Container(
                    width: double.infinity,
                    height: 56,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [Color(0xFF7C3AED), Color(0xFF06B6D4)]),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [BoxShadow(color: const Color(0xFF7C3AED).withOpacity(0.5), blurRadius: 20, offset: const Offset(0, 8))],
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.bolt, color: Colors.white),
                        SizedBox(width: 8),
                        Text("REQUEST RANGRAGO", style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold, letterSpacing: 2)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLocationField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required Color iconColor,
    required String fieldKey,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white10,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _activeField == fieldKey ? const Color(0xFF7C3AED) : Colors.white12),
      ),
      child: TextField(
        controller: controller,
        style: const TextStyle(color: Colors.white),
        onChanged: (v) => _onQueryChanged(v, fieldKey),
        onTap: () => setState(() => _activeField = fieldKey),
        decoration: InputDecoration(
          hintText: label,
          hintStyle: const TextStyle(color: Colors.white24, fontSize: 11),
          prefixIcon: Icon(icon, color: iconColor, size: 20),
          suffixIcon: _isSearching && _activeField == fieldKey
              ? const Padding(padding: EdgeInsets.all(14), child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white30)))
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
        ),
      ),
    );
  }

  String _estimatePrice(double ratePerKm, double baseFare) {
    if (_dropPos == null) return "Select drop";
    const Distance distance = Distance();
    final double res = distance.as(LengthUnit.Meter, _pickupPos, _dropPos!) / 1000.0; // Distance in KM
    final double total = baseFare + (res * ratePerKm);
    return "₹${total.toStringAsFixed(0)}";
  }

  Widget _buildSuggestionsList() {
    if (_suggestions.isEmpty && !_isSearching) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.only(top: 4),
      decoration: BoxDecoration(color: const Color(0xFF14142A), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white12)),
      child: _suggestions.isEmpty
          ? const Padding(padding: EdgeInsets.all(16), child: Text("Typing...", style: TextStyle(color: Colors.white38, fontSize: 12)))
          : Column(
              children: _suggestions.map((s) => ListTile(
                dense: true,
                leading: const Icon(Icons.place, color: Color(0xFF7C3AED), size: 18),
                title: Text(s['short'] ?? s['name'], style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                subtitle: Text(s['name'], maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white38, fontSize: 10)),
                onTap: () => _selectSuggestion(s),
              )).toList(),
            ),
    );
  }

  Widget _vehicleCard(String type, IconData icon, String price) {
    bool isSelected = selectedVehicle == type;
    return GestureDetector(
      onTap: () => setState(() => selectedVehicle = type),
      child: Container(
        width: 100,
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF06B6D4) : Colors.white10,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isSelected ? Colors.transparent : Colors.white12),
        ),
        child: Column(
          children: [
            Icon(icon, color: isSelected ? Colors.black : Colors.white70, size: 24),
            const SizedBox(height: 8),
            Text(type, style: TextStyle(color: isSelected ? Colors.black : Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
            Text(price, style: TextStyle(color: isSelected ? Colors.black54 : Colors.white24, fontSize: 9)),
          ],
        ),
      ),
    );
  }
}

class _PulseMarker extends StatelessWidget {
  final Color color;
  const _PulseMarker({required this.color});
  @override
  Widget build(BuildContext context) {
    return Stack(alignment: Alignment.center, children: [
      Container(width: 36, height: 36, decoration: BoxDecoration(shape: BoxShape.circle, color: color.withOpacity(0.2), border: Border.all(color: color.withOpacity(0.4), width: 1))),
      Icon(Icons.circle, color: color, size: 14),
    ]);
  }
}
