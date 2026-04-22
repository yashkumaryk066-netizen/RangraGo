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
  bool isEditing = false;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.userData['name']);
    _phoneController = TextEditingController(text: widget.userData['phone'] ?? "");
  }

  Future<void> _handleUpdate() async {
    setState(() => isLoading = true);
    final updatedUser = await _authService.updateProfile({
      "name": _nameController.text,
      "phone": _phoneController.text,
    });
    
    if (updatedUser != null) {
      // Save to SharedPreferences
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_data', jsonEncode(updatedUser));
      
      // Update UI
      widget.onUpdate(updatedUser);
      
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Profile Updated Successfully")));
      setState(() => isEditing = false);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Update Failed")));
    }
    setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF070712),
      appBar: AppBar(
        backgroundColor: const Color(0xFF070712),
        elevation: 0,
        title: const Text("RangraGo Profile", style: TextStyle(fontWeight: FontWeight.w900, color: Colors.white)),
        actions: [
          IconButton(
            icon: Icon(isEditing ? Icons.close : Icons.edit, color: const Color(0xFF06B6D4)),
            onPressed: () => setState(() => isEditing = !isEditing),
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(25),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF7C3AED), width: 2),
              ),
              child: const CircleAvatar(
                radius: 56,
                backgroundColor: Colors.white10,
                child: Icon(Icons.person, size: 60, color: Color(0xFF06B6D4)),
              ),
            ),
            const SizedBox(height: 30),
            _buildInfoCard("NAME", _nameController, isEditing),
            const SizedBox(height: 15),
            _buildInfoCard("PHONE", _phoneController, isEditing, keyboardType: TextInputType.phone),
            const SizedBox(height: 20),
            ListTile(
              tileColor: Colors.white10,
              title: const Text("ROLE", style: TextStyle(color: Colors.white54, fontSize: 10)),
              subtitle: Text(widget.userData['role'], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            const SizedBox(height: 40),
            if (isEditing)
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF7C3AED),
                  minimumSize: const Size(double.infinity, 55),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                ),
                onPressed: isLoading ? null : _handleUpdate,
                child: isLoading 
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text("SAVE CHANGES", style: TextStyle(fontWeight: FontWeight.bold)),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(String label, TextEditingController controller, bool enabled, {TextInputType? keyboardType}) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(15)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Color(0xFF06B6D4), fontSize: 10, fontWeight: FontWeight.bold)),
          TextField(
            controller: controller,
            enabled: enabled,
            keyboardType: keyboardType,
            style: const TextStyle(color: Colors.white, fontSize: 16),
            decoration: const InputDecoration(border: InputBorder.none, isDense: true),
          ),
        ],
      ),
    );
  }
}
