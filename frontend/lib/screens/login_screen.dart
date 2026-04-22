import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  final Function(Map<String, dynamic>, bool) onLoginSuccess;
  const LoginScreen({super.key, required this.onLoginSuccess});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final AuthService _authService = AuthService();
  bool _isDriver = false;
  bool _isLoading = false;

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    clientId: "336631033589-nq28gonut9lsv33ocs68tq4h1dejbbb8.apps.googleusercontent.com",
    scopes: ["email", "profile"],
  );


  Future<void> _handleGoogleSignIn() async {
    setState(() => _isLoading = true);
    try {
      final account = await _googleSignIn.signIn();
      if (account != null) {
        final result = await _authService.loginOrRegister(
          email: account.email,
          name: account.displayName ?? "RangraUser",
          role: _isDriver ? "DRIVER" : "RIDER",
          googleId: account.id,
        );
        if (result != null && mounted) widget.onLoginSuccess(result, _isDriver);
      }
    } catch (e) {
      print("Google SignIn Error (Normal on Linux): $e");
      // MOCK LOGIN FOR LINUX TESTING
      final mockResult = await _authService.loginOrRegister(
        email: "mock_${_isDriver ? 'driver' : 'rider'}@rangra.go",
        name: "Test User",
        role: _isDriver ? "DRIVER" : "RIDER",
      );
      if (mockResult != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("RangraGo: Mock Login Activated for Linux")),
        );
        widget.onLoginSuccess(mockResult, _isDriver);
      }
    }
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF070712),
      body: Stack(
        children: [
          Positioned(top: -120, right: -120,
            child: Container(width: 400, height: 400,
              decoration: BoxDecoration(shape: BoxShape.circle,
                gradient: RadialGradient(colors: [const Color(0xFF7C3AED).withOpacity(0.25), Colors.transparent])))),
          Positioned(bottom: -80, left: -80,
            child: Container(width: 300, height: 300,
              decoration: BoxDecoration(shape: BoxShape.circle,
                gradient: RadialGradient(colors: [const Color(0xFF06B6D4).withOpacity(0.15), Colors.transparent])))),
          SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(flex: 2),
                Container(
                  width: 130, height: 130,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(32),
                    boxShadow: [
                      BoxShadow(color: const Color(0xFF7C3AED).withOpacity(0.5), blurRadius: 50, spreadRadius: 5),
                      BoxShadow(color: const Color(0xFF06B6D4).withOpacity(0.3), blurRadius: 30),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(32),
                    child: Image.asset('assets/logo.png', fit: BoxFit.cover),
                  ),
                ),
                const SizedBox(height: 28),
                ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                    colors: [Color(0xFF7C3AED), Color(0xFF06B6D4)],
                  ).createShader(bounds),
                  child: const Text("RangraGo",
                    style: TextStyle(fontSize: 44, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 1)),
                ),
                const SizedBox(height: 6),
                const Text("INDIA'S NEXT-GEN RIDE EXPERIENCE",
                  style: TextStyle(color: Color(0xFF06B6D4), fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 3)),
                const Spacer(flex: 2),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(50),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text("RIDER", style: TextStyle(color: !_isDriver ? Colors.white : Colors.white30, fontWeight: FontWeight.bold, fontSize: 13)),
                        Switch(
                          value: _isDriver,
                          onChanged: (v) => setState(() => _isDriver = v),
                          activeColor: const Color(0xFF06B6D4),
                          inactiveThumbColor: const Color(0xFF7C3AED),
                        ),
                        Text("DRIVER", style: TextStyle(color: _isDriver ? Colors.white : Colors.white30, fontWeight: FontWeight.bold, fontSize: 13)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Column(
                    children: [
                      _isLoading
                        ? const CircularProgressIndicator(color: Color(0xFF7C3AED))
                        : GestureDetector(
                            onTap: _handleGoogleSignIn,
                            child: Container(
                              height: 64, width: double.infinity,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(colors: [Color(0xFF7C3AED), Color(0xFF06B6D4)]),
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [BoxShadow(color: const Color(0xFF7C3AED).withOpacity(0.4), blurRadius: 24, offset: const Offset(0, 10))],
                              ),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.g_mobiledata, size: 36, color: Colors.white),
                                  SizedBox(width: 10),
                                  Text("Continue with Google", style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                          ),
                      const SizedBox(height: 15),
                      // MOCK LOGIN FOR MOBILE TESTING
                      GestureDetector(
                        onTap: () async {
                          setState(() => _isLoading = true);
                          final mockResult = await _authService.loginOrRegister(
                            email: "mock_${_isDriver ? 'driver' : 'rider'}@rangra.go",
                            name: "Test ${_isDriver ? 'Driver' : 'Rider'}",
                            role: _isDriver ? "DRIVER" : "RIDER",
                          );
                          if (mockResult != null && mounted) {
                            widget.onLoginSuccess(mockResult, _isDriver);
                          }
                          setState(() => _isLoading = false);
                        },
                        child: Container(
                          height: 50, width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(15),
                            border: Border.all(color: Colors.white10),
                          ),
                          child: const Center(
                            child: Text("PROCEED WITH MOCK LOGIN", style: TextStyle(color: Colors.white60, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      // Premium Download APK Button
                      OutlinedButton.icon(
                        onPressed: () {
                          html.window.open("https://github.com/yashkumaryk066-netizen/RangraGo/actions", "_blank");
                        },
                        icon: const Icon(Icons.android, color: Colors.greenAccent, size: 18),
                        label: const Text("DOWNLOAD ANDROID APP", style: TextStyle(color: Colors.white70, fontSize: 10, letterSpacing: 1.5)),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: Colors.greenAccent.withOpacity(0.3)),
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                const Text("RangraGo — Ride Smart, Ride Fast",
                  style: TextStyle(color: Colors.white24, fontSize: 10, letterSpacing: 1)),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

