import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_map/flutter_map.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';
import '../services/socket_service.dart';
import '../models/ride_model.dart';
import '../services/config.dart';
import 'profile_screen.dart';
import 'call_screen.dart';
import 'ride_booking_screen.dart';
import 'driver_requests_screen.dart';
import 'history_screen.dart';
import 'login_screen.dart';

class HomeScreen extends StatefulWidget {
  final String userId;
  final bool isDriver;
  final Map<String, dynamic> userData;

  const HomeScreen({
    super.key, 
    required this.userId, 
    required this.isDriver, 
    required this.userData
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final SocketService _socketService = SocketService();
  bool isLoading = false;
  bool isOnline = false;
  
  List<RideRequest> pendingRides = [];
  String? currentStatus; 
  String? activeRideId;
  String? remoteId;
  String? rideOtp;
  double? rideFare;
  LatLng? pickupLoc = const LatLng(28.6139, 77.2090); // Default: Delhi
  LatLng? dropLoc;
  LatLng? driverPos; // Live Driver Tracking
  String? driverDistance; // e.g. "1.5 km"
  List<LatLng> polylinePoints = [];
  Timer? _locationTimer;

  @override
  void initState() {
    super.initState();
    _setupSocket();
    if (widget.isDriver) {
      _startLocationUpdates();
    }
  }

  void _startLocationUpdates() {
    _locationTimer = Timer.periodic(const Duration(seconds: 30), (timer) async {
      if (isOnline) {
        void _updateLocation() async {
          final pos = await Geolocator.getCurrentPosition();
          if (pos != null) {
            // Local state update for distance checks
            setState(() => driverPos = LatLng(pos.latitude, pos.longitude));
            
            await http.put(
              Uri.parse("${AppConfig.authUrl}/location"),
              headers: {
                "Content-Type": "application/json",
                "Authorization": "Bearer ${AppConfig.userToken}"
              },
              body: jsonEncode({"lat": pos.latitude, "lng": pos.longitude}),
            );
          }
        }
        _updateLocation();
      }
    });
  }

  @override
  void dispose() {
    _locationTimer?.cancel();
    _socketService.disconnect();
    super.dispose();
  }

  void _setupSocket() {
    _socketService.connect(
      userId: widget.userId,
      onIncomingCall: (data) {
        _showIncomingCallDialog(data['from'], data['rideId']);
      },
      onRideAccepted: (data) {
        if (mounted) {
          setState(() {
            currentStatus = "ACCEPTED";
            remoteId = data['driverId'];
            activeRideId = data['rideId'];
            rideOtp = data['otp']?.toString();
            rideFare = data['fare']?.toDouble();
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("RangraGo: Driver linked! Share OTP to start."),
              backgroundColor: Color(0xFF06B6D4),
            ),
          );
        }
      },
      onRideStarted: (data) {
        if (mounted) setState(() => currentStatus = "STARTED");
      },
      onRideCompleted: (data) {
        if (mounted) {
          setState(() {
            currentStatus = "COMPLETED";
            rideFare = data['fare']?.toDouble();
          });
        }
      },
      onRideCancelled: (data) {
        if (mounted) {
          setState(() {
            currentStatus = null;
            activeRideId = null;
            remoteId = null;
          });
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Ride Cancelled by peer.")));
        }
      },
      onNewRide: widget.isDriver ? (data) {
        if (mounted && isOnline) {
          _fetchPendingRides();
        }
      } : null,
    );

    _socketService.socket!.on("driver-location-update", (data) {
      if (mounted && !widget.isDriver) {
        final lat = data['lat'] as double;
        final lng = data['lng'] as double;
        setState(() {
          driverPos = LatLng(lat, lng);
          if (pickupLoc != null) {
            final dist = const Distance().as(LengthUnit.Meter, driverPos!, pickupLoc!);
            driverDistance = (dist < 1000) ? "${dist}m" : "${(dist / 1000).toStringAsFixed(1)}km";
          }
        });
      }
    });

    if (widget.isDriver) {
      _socketService.socket.on('ride-taken', (data) {
        if (mounted) {
          setState(() {
            pendingRides.removeWhere((r) => r.id == data['rideId']);
          });
        }
      });
    }
  }

  void _toggleOnline(bool value) {
    setState(() => isOnline = value);
    _socketService.updateStatus(widget.userId, value);
    if (value) _fetchPendingRides();
  }

  Future<void> _fetchPendingRides() async {
    try {
      final response = await http.get(
        Uri.parse("${AppConfig.rideUrl}/active"),
        headers: {"Authorization": "Bearer ${AppConfig.userToken}"}
      );
      if (response.statusCode == 200 && mounted) {
        final List data = jsonDecode(response.body);
        setState(() {
          pendingRides = data.map((r) => RideRequest.fromJson(r)).toList();
        });
      }
    } catch (e) {
      print("Fetch error: $e");
    }
  }

  Future<void> _handleBookRide(
    String pickup, 
    String drop, 
    LatLng pickupPos, 
    LatLng dropPos, 
    String vehicleType, 
    double distanceKm
  ) async {
    setState(() => isLoading = true);
    try {
      final response = await http.post(
        Uri.parse(AppConfig.rideUrl),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer ${AppConfig.userToken}"
        },
        body: jsonEncode({
          "userId": widget.userId,
          "pickup": pickup,
          "pickupCoords": {"lat": pickupPos.latitude, "lng": pickupPos.longitude},
          "drop": drop,
          "dropCoords": {"lat": dropPos.latitude, "lng": dropPos.longitude},
          "vehicleType": vehicleType,
          "distanceKm": distanceKm,
        }),
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        setState(() {
          activeRideId = data['_id'];
          currentStatus = "REQUESTED";
          rideOtp = data['otp'].toString();
          rideFare = data['fare']?.toDouble();
          if (data['pickupCoords'] != null) {
            pickupLoc = LatLng(data['pickupCoords']['lat'], data['pickupCoords']['lng']);
          }
          if (data['dropCoords'] != null) {
            dropLoc = LatLng(data['dropCoords']['lat'], data['dropCoords']['lng']);
          }
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Booking failed: $e")));
    }
    setState(() => isLoading = false);
  }

  Future<void> _handleAcceptRide(RideRequest ride, double? customFare) async {
    try {
      final response = await http.post(
        Uri.parse("${AppConfig.rideUrl}/${ride.id}/accept"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer ${AppConfig.userToken}"
        },
        body: jsonEncode({"fare": customFare}),
      );
      if (response.statusCode == 200) {
        setState(() {
          activeRideId = ride.id;
          currentStatus = "ACCEPTED";
          remoteId = ride.userId;
          rideFare = customFare ?? ride.fare;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Failed to accept ride")));
    }
  }

  void _logout() async {
    _socketService.disconnect();
    // Clear both SharedPreferences and LocalStorage for maximum safety
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => LoginScreen(onLoginSuccess: (data, isDriver) {
          // Re-use logic or just reload app
        })),
        (route) => false,
      );
    }
  }

  void _showOtpDialog() {
    final TextEditingController otpCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF14142A),
        title: const Text("ENTER OTP FROM CUSTOMER", style: TextStyle(color: Colors.white, fontSize: 14)),
        content: TextField(
          controller: otpCtrl,
          keyboardType: TextInputType.number,
          style: const TextStyle(color: Colors.white, fontSize: 32, letterSpacing: 10),
          decoration: const InputDecoration(hintText: "0000", hintStyle: TextStyle(color: Colors.white10)),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("CANCEL")),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _handleStartRide(otpCtrl.text);
            }, 
            child: const Text("VERIFY & START")
          ),
        ],
      ),
    );
  }

  Future<void> _handleStartRide(String otp) async {
    try {
      final response = await http.post(
        Uri.parse("${AppConfig.rideUrl}/$activeRideId/start"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer ${AppConfig.userToken}"
        },
        body: jsonEncode({"otp": otp}),
      );
      if (response.statusCode == 200) {
        setState(() => currentStatus = "STARTED");
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("INVALID OTP"), backgroundColor: Colors.red));
      }
    } catch (e) {
      print("Start error: $e");
    }
  }

  Future<void> _handleCompleteRide() async {
    try {
      final response = await http.post(
        Uri.parse("${AppConfig.rideUrl}/$activeRideId/complete"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer ${AppConfig.userToken}"
        },
      );
      if (response.statusCode == 200) {
        setState(() => currentStatus = "COMPLETED");
      }
    } catch (e) {
      print("Complete error: $e");
    }
  }

  void _showIncomingCallDialog(String from, String rideId) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF070712),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("INCOMING CALL", style: TextStyle(color: Colors.greenAccent, letterSpacing: 2)),
        content: Text("Call from $from", style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () {
              _socketService.rejectCall(from);
              Navigator.pop(context);
            },
            child: const Text("REJECT", style: TextStyle(color: Colors.redAccent)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.greenAccent),
            onPressed: () {
              Navigator.pop(context);
              _socketService.socket!.emit("accept-call", {"to": from, "rideId": rideId});
              Navigator.push(context, MaterialPageRoute(builder: (context) => CallScreen(
                channelId: rideId,
                socketService: _socketService,
                remoteUserId: from,
              )));
            },
            child: const Text("ACCEPT", style: TextStyle(color: Colors.black)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF070712),
      appBar: AppBar(
        backgroundColor: const Color(0xFF070712),
        elevation: 0,
        title: Row(
          children: [
            Image.asset('assets/logo.png', height: 30, width: 30),
            const SizedBox(width: 10),
            const Text("RangraGo", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: Colors.white)),
            const SizedBox(width: 6),
            Text(
              widget.isDriver ? "· Driver" : "· Rider",
              style: const TextStyle(fontSize: 11, color: Color(0xFF06B6D4), fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          if (widget.isDriver && currentStatus == null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Switch(
                value: isOnline,
                onChanged: _toggleOnline,
                activeColor: const Color(0xFF06B6D4),
              ),
            ),
        ],
      ),
      drawer: Drawer(
        backgroundColor: const Color(0xFF070712),
        child: Column(
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(
                gradient: LinearGradient(colors: [Color(0xFF7C3AED), Color(0xFF070712)]),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.asset('assets/logo.png', height: 44, width: 44),
                      ),
                      const SizedBox(width: 12),
                      const Text("RangraGo", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 20)),
                    ],
                  ),
                  const Spacer(),
                  Text(widget.userData['name'] ?? "User", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                  Text(widget.userData['email'] ?? "", style: const TextStyle(color: Colors.white54, fontSize: 11)),
                ],
              ),
            ),
            _drawerTile(Icons.history, "RIDE HISTORY", () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (context) => RideHistoryScreen(userId: widget.userId, isDriver: widget.isDriver)));
            }),
            _drawerTile(Icons.person_outline, "PROFILE SETTINGS", () {
              Navigator.pop(context);
              Navigator.of(context).push(MaterialPageRoute(
                builder: (context) => ProfileScreen(
                  userData: widget.userData,
                  onUpdate: (newData) {
                    setState(() {
                      widget.userData.clear();
                      widget.userData.addAll(newData);
                    });
                  },
                ),
              ));
            }),
            _drawerTile(Icons.android, "DOWNLOAD ANDROID APP", () {
              launchUrl(Uri.parse("https://github.com/yashkumaryk066-netizen/RangraGo/releases/latest/download/RangraGo.apk"), mode: LaunchMode.externalApplication);
            }, color: Colors.greenAccent),
            const Spacer(),
            _drawerTile(Icons.logout, "EXIT SYSTEM", _logout, color: Colors.redAccent),
            const SizedBox(height: 20),
          ],
        ),
      ),
      body: currentStatus == null 
          ? (widget.isDriver ? _buildDriverDashboard() : _buildRiderDashboard())
          : _buildActiveRideUI(),
    );
  }

  Widget _drawerTile(IconData icon, String title, VoidCallback onTap, {Color color = Colors.white70}) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(title, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1)),
      onTap: onTap,
    );
  }

  Widget _buildRiderDashboard() {
    return Column(
      children: [
        Expanded(child: RideBookingScreen(onBook: _handleBookRide)),
      ],
    );
  }

  Widget _buildDriverDashboard() {
    if (!isOnline) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.radar, size: 80, color: Colors.white10),
            const SizedBox(height: 20),
            const Text("RADAR OFFLINE", style: TextStyle(fontSize: 18, color: Colors.white38, fontWeight: FontWeight.bold, letterSpacing: 4)),
            const SizedBox(height: 30),
            GestureDetector(
              onTap: () => _toggleOnline(true),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFF7C3AED), Color(0xFF06B6D4)]),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: const Text("GO ONLINE", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      );
    }
    return pendingRides.isEmpty 
        ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(width: 40, height: 40, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF06B6D4))),
                const SizedBox(height: 20),
                Text("SCANNING NEARBY...", style: TextStyle(color: const Color(0xFF06B6D4).withOpacity(0.5), fontSize: 10, letterSpacing: 2)),
              ],
            ),
          )
        : DriverRequestsScreen(requests: pendingRides, onAccept: _handleAcceptRide);
  }

  Widget _buildActiveRideUI() {
    String message = "Searching for driver...";
    Color theme = const Color(0xFF7C3AED);
    
    if (currentStatus == "ACCEPTED") {
      message = "Driver is on the way";
      theme = const Color(0xFF06B6D4);
    } else if (currentStatus == "STARTED") {
      message = "Ride in progress";
      theme = Colors.blueAccent;
    } else if (currentStatus == "COMPLETED") {
      message = "Arrived at destination";
      theme = Colors.greenAccent;
    }

    return Column(
      children: [
        // Map Section (60% of Screen)
        Expanded(
          flex: 6,
          child: Stack(
            children: [
              FlutterMap(
                options: MapOptions(
                  initialCenter: pickupLoc ?? const LatLng(20.5937, 78.9629),
                  initialZoom: 13.0,
                ),
                children: [
                  // GOOGLE MAPS TILES (No API Key Required)
                  TileLayer(
                    urlTemplate: "https://mt0.google.com/vt/lyrs=m&hl=en&x={x}&y={y}&z={z}",
                    userAgentPackageName: "com.rangra.go",
                  ),
                  if (pickupLoc != null && dropLoc != null)
                    PolylineLayer(
                      polylines: [
                        Polyline(
                          points: [pickupLoc!, dropLoc!],
                          color: theme,
                          strokeWidth: 4,
                        ),
                      ],
                    ),
                  MarkerLayer(
                    markers: [
                      if (pickupLoc != null)
                        Marker(
                          point: pickupLoc!,
                          width: 44,
                          height: 44,
                          child: const _PulseMarker(color: Colors.greenAccent),
                        ),
                      if (dropLoc != null)
                        Marker(
                          point: dropLoc!,
                          width: 44,
                          height: 44,
                          child: const _PulseMarker(color: Colors.redAccent),
                        ),
                      if (driverPos != null)
                        Marker(
                          point: driverPos!, 
                          width: 44,
                          height: 44,
                          child: const _PulseMarker(color: Color(0xFF06B6D4)),
                        ),
                    ],
                  ),
                ],
              ),
              // Status Overlay
              Positioned(
                top: 20,
                left: 20,
                right: 20,
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                      decoration: BoxDecoration(
                        color: const Color(0xFF070712).withOpacity(0.9),
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(color: theme.withOpacity(0.5)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.radar, color: theme, size: 16),
                          const SizedBox(width: 10),
                          Text(message.toUpperCase(), style: TextStyle(color: theme, fontWeight: FontWeight.bold, fontSize: 10, letterSpacing: 1.5)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    if (currentStatus == "ACCEPTED" && driverPos != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                        decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFF7C3AED).withOpacity(0.3))),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.directions_car, color: Color(0xFF06B6D4), size: 16),
                            const SizedBox(width: 8),
                            Text(
                              driverDistance != null ? "DRIVER IS $driverDistance AWAY" : "DRIVER IS ON THE WAY", 
                              style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Controls Section (40% of Screen)
        Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            color: Color(0xFF14142A),
            borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
            boxShadow: [BoxShadow(color: Colors.black54, blurRadius: 40, offset: Offset(0, -10))],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("CURRENT STATUS", style: TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.bold)),
                      Text(currentStatus ?? "", style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  if (rideFare != null)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text("FINAL FARE", style: TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.bold)),
                        Text("₹$rideFare", style: const TextStyle(color: Colors.greenAccent, fontSize: 24, fontWeight: FontWeight.bold)),
                      ],
                    ),
                ],
              ),
              
              const SizedBox(height: 25),

              if (rideOtp != null && currentStatus != "COMPLETED") ...[
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(15)),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("OTP: ", style: TextStyle(color: Colors.white38, fontSize: 18)),
                      Text(rideOtp!, style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900, letterSpacing: 8)),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],

              if (widget.isDriver && currentStatus == "ACCEPTED")
                _actionBtn("START RIDE (VERIFY OTP)", const Color(0xFF7C3AED), _showOtpDialog),
              
              if (widget.isDriver && currentStatus == "STARTED")
                _actionBtn("COMPLETE RIDE", Colors.greenAccent, _handleCompleteRide),

              if (currentStatus == "COMPLETED")
                _actionBtn("BACK TO DASHBOARD", Colors.white10, () {
                  setState(() {
                    currentStatus = null;
                    activeRideId = null;
                  });
                }),

              if (currentStatus != "COMPLETED" && currentStatus != "REQUESTED") ...[
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: () {
                    if (remoteId != null) {
                      _socketService.callUser(remoteId!, widget.userId, activeRideId!);
                      Navigator.push(context, MaterialPageRoute(builder: (context) => CallScreen(
                        channelId: activeRideId!,
                        socketService: _socketService,
                        remoteUserId: remoteId!,
                      )));
                    }
                  },
                  child: Container(
                    height: 50,
                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(12)),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.call, color: Colors.greenAccent, size: 18),
                        SizedBox(width: 10),
                        Text("VOICE CALL", style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 12)),
                      ],
                    ),
                  ),
                ),
              ],
              
              if (currentStatus != "COMPLETED") ...[
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: () async {
                    final confirm = await showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        backgroundColor: const Color(0xFF14142A),
                        title: const Text("CANCEL RIDE?", style: TextStyle(color: Colors.white)),
                        content: const Text("Are you sure you want to cancel this ride?", style: TextStyle(color: Colors.white70)),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("NO")),
                          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("YES, CANCEL", style: TextStyle(color: Colors.redAccent))),
                        ],
                      ),
                    );
                    if (confirm == true) {
                      await http.post(
                        Uri.parse("${AppConfig.rideUrl}/$activeRideId/cancel"),
                        headers: {"Authorization": "Bearer ${AppConfig.userToken}"},
                      );
                      setState(() {
                        currentStatus = null;
                        activeRideId = null;
                      });
                    }
                  },
                  child: Container(
                    height: 50,
                    decoration: BoxDecoration(color: Colors.redAccent.withOpacity(0.1), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.redAccent.withOpacity(0.3))),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.close, color: Colors.redAccent, size: 18),
                        SizedBox(width: 10),
                        Text("CANCEL RIDE", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 12)),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _actionBtn(String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 60,
        width: double.infinity,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: color.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 8))],
        ),
        alignment: Alignment.center,
        child: Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
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
