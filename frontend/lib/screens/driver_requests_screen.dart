import 'package:flutter/material.dart';
import '../models/ride_model.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../services/config.dart';

class DriverRequestsScreen extends StatefulWidget {
  final List<RideRequest> requests;
  final Function(RideRequest, double?) onAccept;

  const DriverRequestsScreen({super.key, required this.requests, required this.onAccept});

  @override
  State<DriverRequestsScreen> createState() => _DriverRequestsScreenState();
}

class _DriverRequestsScreenState extends State<DriverRequestsScreen> {
  final Map<String, TextEditingController> _fareControllers = {};

  @override
  void dispose() {
    _fareControllers.values.forEach((c) => c.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.requests.isEmpty
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
        : ListView.builder(
            itemCount: widget.requests.length,
            padding: const EdgeInsets.symmetric(vertical: 10),
            itemBuilder: (context, index) {
              final ride = widget.requests[index];
              if (!_fareControllers.containsKey(ride.id)) {
                _fareControllers[ride.id] = TextEditingController(text: ride.fare.toString());
              }

              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(color: const Color(0xFF7C3AED).withOpacity(0.2), shape: BoxShape.circle),
                            child: const Icon(Icons.bolt, color: Color(0xFF06B6D4)),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("${ride.pickup} → ${ride.drop}", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                                const Text("SYSTEM ANALYZING ROUTE...", style: TextStyle(color: Colors.white24, fontSize: 9)),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white10)),
                              child: TextField(
                                controller: _fareControllers[ride.id],
                                keyboardType: TextInputType.number,
                                style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold),
                                decoration: const InputDecoration(
                                  prefixIcon: Icon(Icons.currency_rupee, size: 16, color: Colors.greenAccent),
                                  labelText: "YOUR FARE",
                                  labelStyle: TextStyle(color: Colors.white38, fontSize: 10),
                                  border: InputBorder.none,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          GestureDetector(
                            onTap: () {
                              final double? customFare = double.tryParse(_fareControllers[ride.id]!.text);
                              widget.onAccept(ride, customFare);
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 15),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(colors: [Color(0xFF7C3AED), Color(0xFF06B6D4)]),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text("ACCEPT", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
  }
}
