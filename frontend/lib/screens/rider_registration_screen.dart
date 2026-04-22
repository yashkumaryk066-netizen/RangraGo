import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class RiderRegistrationScreen extends StatefulWidget {
  final Map<String, dynamic> userData;
  final VoidCallback onComplete;

  const RiderRegistrationScreen({super.key, required this.userData, required this.onComplete});

  @override
  State<RiderRegistrationScreen> createState() => _RiderRegistrationScreenState();
}

class _RiderRegistrationScreenState extends State<RiderRegistrationScreen> {
  final AuthService _authService = AuthService();
  final TextEditingController _phoneCtrl = TextEditingController();
  final TextEditingController _nameCtrl = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl.text = widget.userData['name'] ?? "";
  }

  Future<void> _submit() async {
    if (_phoneCtrl.text.isEmpty || _nameCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Phone aur Name bharna zaroori hai!")));
      return;
    }

    setState(() => _isLoading = true);
    final success = await _authService.updateProfile({
      "name": _nameCtrl.text,
      "phone": _phoneCtrl.text,
      "isRegistered": true,
    });

    if (success != null) {
      widget.onComplete();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Registration failed. Try again.")));
    }
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF070712),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(30),
        child: Column(
          children: [
            const SizedBox(height: 100),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: const Color(0xFF7C3AED).withOpacity(0.1), shape: BoxShape.circle),
              child: const Icon(Icons.person_add, size: 80, color: Color(0xFF06B6D4)),
            ),
            const SizedBox(height: 30),
            const Text("WELCOME TO RANGRAGO", style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: 2)),
            const Text("Complete your profile to start riding", style: TextStyle(color: Colors.white38, fontSize: 12)),
            const SizedBox(height: 40),

            _buildInput("FULL NAME", "Enter your name", _nameCtrl, Icons.person),
            const SizedBox(height: 20),
            _buildInput("PHONE NUMBER", "Enter 10-digit number", _phoneCtrl, Icons.phone, keyboardType: TextInputType.phone),

            const SizedBox(height: 50),
            ElevatedButton(
              onPressed: _isLoading ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF7C3AED),
                minimumSize: const Size(double.infinity, 60),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              ),
              child: _isLoading 
                ? const CircularProgressIndicator(color: Colors.white)
                : const Text("START RIDING", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInput(String label, String hint, TextEditingController ctrl, IconData icon, {TextInputType? keyboardType}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Color(0xFF06B6D4), fontSize: 10, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 15),
          decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(15)),
          child: TextField(
            controller: ctrl,
            keyboardType: keyboardType,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              prefixIcon: Icon(icon, color: Colors.white24, size: 20),
              hintText: hint,
              hintStyle: const TextStyle(color: Colors.white10),
              border: InputBorder.none,
            ),
          ),
        ),
      ],
    );
  }
}
