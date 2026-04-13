import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../services/config.dart';

class RideHistoryScreen extends StatefulWidget {
  final String userId;
  final bool isDriver;
  const RideHistoryScreen({super.key, required this.userId, required this.isDriver});

  @override
  State<RideHistoryScreen> createState() => _RideHistoryScreenState();
}

class _RideHistoryScreenState extends State<RideHistoryScreen> {
  List rides = [];
  Map<String, dynamic>? stats;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchAll();
  }

  Future<void> _fetchAll() async {
    await Future.wait([_fetchHistory(), _fetchStats()]);
    if (mounted) setState(() => isLoading = false);
  }

  Future<void> _fetchHistory() async {
    try {
      final response = await http.get(
        Uri.parse("${AppConfig.rideUrl}/history"),
        headers: {"Authorization": "Bearer ${AppConfig.userToken}"},
      );
      if (mounted && response.statusCode == 200) {
        setState(() => rides = jsonDecode(response.body));
      }
    } catch (e) {
      print("History fetch error: $e");
    }
  }

  Future<void> _fetchStats() async {
    try {
      final response = await http.get(
        Uri.parse("${AppConfig.baseUrl}/stats/stats"),
        headers: {"Authorization": "Bearer ${AppConfig.userToken}"},
      );
      if (mounted && response.statusCode == 200) {
        setState(() => stats = jsonDecode(response.body));
      }
    } catch (e) {
      print("Stats fetch error: $e");
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case "COMPLETED": return Colors.greenAccent;
      case "CANCELLED": return Colors.redAccent;
      case "STARTED":   return Colors.blueAccent;
      default:          return Colors.orangeAccent;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF070712),
      appBar: AppBar(
        backgroundColor: const Color(0xFF070712),
        elevation: 0,
        title: const Text("RangraGo History", style: TextStyle(fontWeight: FontWeight.w900, color: Colors.white)),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.deepPurpleAccent))
          : Column(
              children: [
                // Stats Cards
                if (stats != null)
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        _statCard("TOTAL", "${stats!['total']}", Colors.white24),
                        const SizedBox(width: 10),
                        _statCard("DONE", "${stats!['completed']}", Colors.greenAccent.withOpacity(0.3)),
                        const SizedBox(width: 10),
                        _statCard("EARNINGS", "₹${stats!['totalEarnings']}", Colors.amber.withOpacity(0.3)),
                      ],
                    ),
                  ),
                // Rides List
                Expanded(
                  child: rides.isEmpty
                      ? const Center(
                          child: Text("No rides yet", style: TextStyle(color: Colors.white38)),
                        )
                      : ListView.builder(
                          itemCount: rides.length,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemBuilder: (context, index) {
                            final ride = rides[index];
                            final status = ride['status'] ?? 'UNKNOWN';
                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white10,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: Colors.white12),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          "${ride['pickup']} → ${ride['drop']}",
                                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: _statusColor(status).withOpacity(0.15),
                                          borderRadius: BorderRadius.circular(20),
                                        ),
                                        child: Text(status, style: TextStyle(color: _statusColor(status), fontSize: 10, fontWeight: FontWeight.bold)),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Icon(Icons.currency_rupee, size: 14, color: Colors.white54),
                                      Text("${ride['fare'] ?? 0}", style: const TextStyle(color: Colors.white54, fontSize: 13)),
                                      const SizedBox(width: 16),
                                      Icon(Icons.access_time, size: 14, color: Colors.white38),
                                      const SizedBox(width: 3),
                                      Text(
                                        ride['createdAt']?.toString().substring(0, 10) ?? '',
                                        style: const TextStyle(color: Colors.white38, fontSize: 11),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }

  Widget _statCard(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white10),
        ),
        child: Column(
          children: [
            Text(value, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(color: Colors.white54, fontSize: 9, letterSpacing: 1)),
          ],
        ),
      ),
    );
  }
}
