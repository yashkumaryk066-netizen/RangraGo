import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth_service.dart';

class ProfileScreen extends StatefulWidget {
  final Map<String, dynamic> userData;
  final Function(Map<String, dynamic>) onUpdate;
  const ProfileScreen({super.key, required this.userData, required this.onUpdate});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final AuthService _authService = AuthService();
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _modelController;
  late TextEditingController _numberController;
  late TextEditingController _licenseController;
  late TextEditingController _aadhaarController;
  
  bool isEditing = false;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.userData['name']);
    _phoneController = TextEditingController(text: widget.userData['phone'] ?? "");
    
    final vehicle = widget.userData['vehicleInfo'] ?? {};
    _modelController = TextEditingController(text: vehicle['model'] ?? "");
    _numberController = TextEditingController(text: vehicle['number'] ?? "");
    _licenseController = TextEditingController(text: vehicle['license'] ?? "");
    _aadhaarController = TextEditingController(text: vehicle['aadhaar'] ?? "");
  }

  Future<void> _handleUpdate() async {
    setState(() => isLoading = true);
    final Map<String, dynamic> updates = {
      "name": _nameController.text,
      "phone": _phoneController.text,
    };

    if (widget.userData['role'] == "DRIVER") {
      updates["vehicleInfo"] = {
        "model": _modelController.text,
        "number": _numberController.text,
        "license": _licenseController.text,
        "aadhaar": _aadhaarController.text,
        "type": widget.userData['vehicleInfo']?['type'] ?? "BIKE",
      };
    }

    final updatedUser = await _authService.updateProfile(updates);
    
    if (updatedUser != null) {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_data', jsonEncode(updatedUser));
      widget.onUpdate(updatedUser);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("✅ Profile Updated Successfully")));
      setState(() => isEditing = false);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("❌ Update Failed")));
    }
    setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = const Color(0xFF06B6D4);
    final secondary = const Color(0xFF7C3AED);
    final isDriver = widget.userData['role'] == "DRIVER";

    return Scaffold(
      backgroundColor: const Color(0xFF070712),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            backgroundColor: const Color(0xFF070712),
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [secondary.withOpacity(0.5), const Color(0xFF070712)],
                      ),
                    ),
                  ),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 60),
                      Hero(
                        tag: 'profile_pic',
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: theme, width: 2)),
                          child: const CircleAvatar(
                            radius: 50,
                            backgroundColor: Colors.white10,
                            child: Icon(Icons.person, size: 50, color: Colors.white70),
                          ),
                        ),
                      ),
                      const SizedBox(height: 15),
                      Text(widget.userData['name'] ?? "User", style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                      Text(widget.userData['role'] ?? "", style: TextStyle(color: theme, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 2)),
                    ],
                  ),
                ],
              ),
            ),
            actions: [
              IconButton(
                icon: Icon(isEditing ? Icons.close : Icons.edit_note_rounded, color: Colors.white, size: 28),
                onPressed: () => setState(() => isEditing = !isEditing),
              ),
              const SizedBox(width: 10),
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (isDriver) ...[
                    _buildStatsGrid(),
                    const SizedBox(height: 30),
                  ],
                  _sectionHeader("PERSONAL INFORMATION"),
                  _buildInputField("Full Name", _nameController, Icons.person_outline, isEditing),
                  _buildInputField("Phone Number", _phoneController, Icons.phone_android_outlined, isEditing, keyboard: TextInputType.phone),
                  
                  if (isDriver) ...[
                    const SizedBox(height: 30),
                    _sectionHeader("VEHICLE DETAILS"),
                    _buildInputField("Vehicle Model", _modelController, Icons.directions_car_outlined, isEditing),
                    _buildInputField("Vehicle Number", _numberController, Icons.tag, isEditing),
                    const SizedBox(height: 30),
                    _sectionHeader("IDENTITY DOCUMENTS"),
                    _buildInputField("Driver License", _licenseController, Icons.badge_outlined, isEditing),
                    _buildInputField("Aadhaar Number", _aadhaarController, Icons.fingerprint, isEditing),
                    _buildVerificationStatus(),
                  ],

                  const SizedBox(height: 40),
                  if (isEditing)
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: secondary,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 60),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                        elevation: 8,
                        shadowColor: secondary.withOpacity(0.4),
                      ),
                      onPressed: isLoading ? null : _handleUpdate,
                      child: isLoading 
                        ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Text("SAVE PROFILE CHANGES", style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.2)),
                    ),
                  const SizedBox(height: 50),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid() {
    return Row(
      children: [
        Expanded(child: _statCard("TOTAL EARNED", "₹${widget.userData['totalEarnings'] ?? 0}", Icons.account_balance_wallet, Colors.amber)),
        const SizedBox(width: 15),
        Expanded(child: _statCard("COMPLETED", "${widget.userData['completedRides'] ?? 0}", Icons.verified, Colors.greenAccent)),
      ],
    );
  }

  Widget _statCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 12),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900)),
          Text(label, style: const TextStyle(color: Colors.white38, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 1)),
        ],
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15, left: 5),
      child: Text(title, style: const TextStyle(color: Colors.white24, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
    );
  }

  Widget _buildInputField(String label, TextEditingController ctrl, IconData icon, bool enabled, {TextInputType? keyboard}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: enabled ? Colors.white.withOpacity(0.07) : Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: enabled ? const Color(0xFF06B6D4).withOpacity(0.3) : Colors.white10),
      ),
      child: TextField(
        controller: ctrl,
        enabled: enabled,
        keyboardType: keyboard,
        style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.white38, fontSize: 12),
          prefixIcon: Icon(icon, color: const Color(0xFF06B6D4), size: 20),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        ),
      ),
    );
  }

  Widget _buildVerificationStatus() {
    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.greenAccent.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.greenAccent.withOpacity(0.2)),
      ),
      child: const Row(
        children: [
          Icon(Icons.verified_user, color: Colors.greenAccent, size: 20),
          const SizedBox(width: 12),
          Text("KYC DOCUMENTS VERIFIED", style: TextStyle(color: Colors.greenAccent, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1)),
        ],
      ),
    );
  }
}
