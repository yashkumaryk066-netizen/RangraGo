import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class DriverRegistrationScreen extends StatefulWidget {
  final Map<String, dynamic> userData;
  final VoidCallback onComplete;

  const DriverRegistrationScreen({super.key, required this.userData, required this.onComplete});

  @override
  State<DriverRegistrationScreen> createState() => _DriverRegistrationScreenState();
}

class _DriverRegistrationScreenState extends State<DriverRegistrationScreen> {
  final AuthService _authService = AuthService();
  final TextEditingController _modelCtrl = TextEditingController();
  final TextEditingController _numberCtrl = TextEditingController();
  final TextEditingController _licenseCtrl = TextEditingController();
  final TextEditingController _aadhaarCtrl = TextEditingController();
  String _selectedType = "CAR";
  bool _isLoading = false;

  Future<void> _submit() async {
    if (_modelCtrl.text.isEmpty || _numberCtrl.text.isEmpty || _licenseCtrl.text.isEmpty || _aadhaarCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Sabhi details bharna zaroori hai!")));
      return;
    }

    setState(() => _isLoading = true);
    final updatedUser = await _authService.updateProfile({
      "vehicleInfo": {
        "model": _modelCtrl.text,
        "number": _numberCtrl.text,
        "type": _selectedType,
      },
      "licenseNumber": _licenseCtrl.text,
      "aadhaarNumber": _aadhaarCtrl.text,
      "isRegistered": true,
    });

    if (updatedUser != null) {
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
            const SizedBox(height: 60),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: const Color(0xFF7C3AED).withOpacity(0.1), shape: BoxShape.circle),
              child: const Icon(Icons.verified_user, size: 80, color: Color(0xFF06B6D4)),
            ),
            const SizedBox(height: 30),
            const Text("DRIVER ONBOARDING", style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: 2)),
            const Text("Enter your vehicle and license details", style: TextStyle(color: Colors.white38, fontSize: 12)),
            const SizedBox(height: 40),

            _buildInput("VEHICLE MODEL", "e.g. Maruti Suzuki Swift", _modelCtrl, Icons.directions_car),
            const SizedBox(height: 15),
            _buildInput("PLATE NUMBER", "e.g. BR 01 AB 1234", _numberCtrl, Icons.numbers),
            const SizedBox(height: 15),
            _buildInput("DRIVING LICENSE", "Enter DL Number", _licenseCtrl, Icons.badge),
            const SizedBox(height: 15),
            _buildInput("AADHAAR CARD", "Enter 12-digit Aadhaar", _aadhaarCtrl, Icons.fingerprint, keyboardType: TextInputType.number),
            const SizedBox(height: 25),

            const Align(
              alignment: Alignment.centerLeft,
              child: Text("VEHICLE TYPE", style: TextStyle(color: Color(0xFF06B6D4), fontSize: 10, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                _typeBtn("CAR"),
                const SizedBox(width: 10),
                _typeBtn("BIKE"),
                const SizedBox(width: 10),
                _typeBtn("AUTO"),
              ],
            ),

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
                : const Text("COMPLETE REGISTRATION", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _typeBtn(String type) {
    bool isSelected = _selectedType == type;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedType = type),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF06B6D4) : Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: isSelected ? Colors.transparent : Colors.white10),
          ),
          child: Center(
            child: Text(type, style: TextStyle(color: isSelected ? Colors.black : Colors.white70, fontWeight: FontWeight.bold, fontSize: 12)),
          ),
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
