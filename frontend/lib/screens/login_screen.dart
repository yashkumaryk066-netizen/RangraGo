import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/config.dart';
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
    clientId: kIsWeb ? AppConfig.googleClientId : null,
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
        if (result != null && mounted) {
          widget.onLoginSuccess(result, _isDriver);
        } else if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Backend Connection Error. Check your internet.")),
          );
        }
      }
    } catch (e) {
      print("Google SignIn Error: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Google Sign-In failed: $e")),
        );
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
                    ],
                  ),
                ),
                // ─── PREMIUM DOWNLOAD SECTION (WEB ONLY) ───
                if (kIsWeb) ...[
                  const SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: GestureDetector(
                      onTap: () {
                        // Always fetch fresh from GitHub latest release
                        final url = "https://github.com/yashkumaryk066-netizen/RangraGo/releases/latest/download/RangraGo.apk";
                        launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
                      },
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.green.shade800, Colors.green.shade600],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.greenAccent.withOpacity(0.25),
                              blurRadius: 20,
                              offset: const Offset(0, 6),
                            )
                          ],
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.android, color: Colors.white, size: 28),
                            SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "DOWNLOAD RANGRAGO",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 14,
                                    letterSpacing: 1.5,
                                  ),
                                ),
                                Text(
                                  "Latest Version • Android APK",
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                            Spacer(),
                            Icon(Icons.download_rounded, color: Colors.white, size: 24),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
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

