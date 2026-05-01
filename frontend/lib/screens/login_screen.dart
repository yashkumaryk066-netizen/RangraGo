import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:ui';
import '../services/config.dart';
import '../services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  final Function(Map<String, dynamic>, bool) onLoginSuccess;
  const LoginScreen({super.key, required this.onLoginSuccess});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with TickerProviderStateMixin {
  final AuthService _authService = AuthService();
  bool _isDriver = false;
  bool _isLoading = false;
  late AnimationController _bgController;

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    // clientId is optional on Android if google-services.json is present, but mandatory for Web
    clientId: kIsWeb ? AppConfig.googleWebClientId : null,
    // Using the verified Web Client ID from google-services.json for Android serverClientId
    serverClientId: kIsWeb ? AppConfig.googleWebClientId : AppConfig.googleAndroidClientId,
    scopes: ["email", "profile"],
  );

  @override
  void initState() {
    super.initState();
    _bgController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();

    _googleSignIn.onCurrentUserChanged.listen((GoogleSignInAccount? account) {
      if (account != null) {
        _processLogin(account);
      }
    });

    if (kIsWeb) {
      // Modern GIS initialization: try silent sign-in first
      _googleSignIn.signInSilently();
    }
  }

  @override
  void dispose() {
    _bgController.dispose();
    super.dispose();
  }

  Future<void> _processLogin(GoogleSignInAccount account) async {
    setState(() => _isLoading = true);
    try {
      final result = await _authService.loginOrRegister(
        email: account.email,
        name: account.displayName ?? "RangraUser",
        role: _isDriver ? "DRIVER" : "RIDER",
        googleId: account.id,
      );
      if (result != null && mounted) {
        widget.onLoginSuccess(result, _isDriver);
      } else if (mounted) {
        _showError("Backend synchronization failed. Please try again.");
      }
    } catch (e) {
      print("Login Processing Error: $e");
      _showError("An unexpected error occurred during login.");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() => _isLoading = true);
    try {
      final account = await _googleSignIn.signIn();
      if (account != null) await _processLogin(account);
    } catch (e) {
      print("Google SignIn Error: $e");
      _showError("Google Sign-In failed: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF030308),
      body: Stack(
        children: [
          // Dynamic Background Glows
          _buildAnimatedBackground(),
          
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  const SizedBox(height: 60),
                  _buildHeader(),
                  const SizedBox(height: 60),
                  _buildRoleSelector(),
                  const SizedBox(height: 40),
                  _buildLoginSection(),
                  if (kIsWeb) ...[
                    const SizedBox(height: 30),
                    _buildDownloadSection(),
                  ],
                  const SizedBox(height: 40),
                  _buildFooter(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedBackground() {
    return AnimatedBuilder(
      animation: _bgController,
      builder: (context, child) {
        return Stack(
          children: [
            Positioned(
              top: -100 + (20 * _bgController.value),
              right: -100,
              child: _buildGlow(400, const Color(0xFF7C3AED).withOpacity(0.3)),
            ),
            Positioned(
              bottom: -50 - (30 * _bgController.value),
              left: -50,
              child: _buildGlow(350, const Color(0xFF06B6D4).withOpacity(0.2)),
            ),
            Positioned(
              top: 300 * _bgController.value,
              left: 200,
              child: _buildGlow(200, const Color(0xFFEC4899).withOpacity(0.1)),
            ),
          ],
        );
      },
    );
  }

  Widget _buildGlow(double size, Color color) {
    return Container(
      width: size, height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(colors: [color, Colors.transparent]),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          width: 120, height: 120,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(color: const Color(0xFF7C3AED).withOpacity(0.4), blurRadius: 40, spreadRadius: 2),
              BoxShadow(color: const Color(0xFF06B6D4).withOpacity(0.2), blurRadius: 20),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(30),
            child: Image.asset('assets/logo.png', fit: BoxFit.cover),
          ),
        ),
        const SizedBox(height: 32),
        ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [Color(0xFFA855F7), Color(0xFF06B6D4)],
          ).createShader(bounds),
          child: const Text("RangraGo",
            style: TextStyle(fontSize: 48, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: -1)),
        ),
        const SizedBox(height: 8),
        Text("INDIA'S NEXT-GEN RIDE EXPERIENCE",
          style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 4)),
      ],
    );
  }

  Widget _buildRoleSelector() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: Row(
            children: [
              _buildRoleTab("RIDER", !_isDriver, const Color(0xFF7C3AED)),
              _buildRoleTab("DRIVER", _isDriver, const Color(0xFF06B6D4)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRoleTab(String label, bool isSelected, Color activeColor) {
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _isDriver = (label == "DRIVER")),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: isSelected ? activeColor : Colors.transparent,
            borderRadius: BorderRadius.circular(18),
            boxShadow: isSelected ? [BoxShadow(color: activeColor.withOpacity(0.3), blurRadius: 15)] : [],
          ),
          child: Center(
            child: Text(label,
              style: TextStyle(color: isSelected ? Colors.white : Colors.white30, fontWeight: FontWeight.w800, fontSize: 14)),
          ),
        ),
      ),
    );
  }

  Widget _buildLoginSection() {
    return Column(
      children: [
        if (_isLoading)
          const Padding(
            padding: EdgeInsets.all(20),
            child: CircularProgressIndicator(color: Color(0xFFA855F7)),
          )
        else
          _buildCustomGoogleButton(),
        
        const SizedBox(height: 16),
        Text("By continuing, you agree to our Terms of Service",
          style: TextStyle(color: Colors.white.withOpacity(0.2), fontSize: 10)),
      ],
    );
  }

  Widget _buildCustomGoogleButton() {
    return GestureDetector(
      onTap: _handleGoogleSignIn,
      child: Container(
        height: 55,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Positioned(
              left: 20,
              child: Image.network(
                'https://img.icons8.com/color/48/000000/google-logo.png',
                height: 24,
              ),
            ),
            const Text(
              "SIGN IN WITH GOOGLE",
              style: TextStyle(
                color: Color(0xFF1F1F1F),
                fontWeight: FontWeight.bold,
                fontSize: 14,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDownloadSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [const Color(0xFF064E3B), const Color(0xFF065F46).withOpacity(0.5)]),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.greenAccent.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), shape: BoxShape.circle),
            child: const Icon(Icons.android_rounded, color: Colors.greenAccent, size: 32),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("GET THE APP",
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 1)),
                Text("Experience RangraGo at full power",
                  style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 12)),
              ],
            ),
          ),
          IconButton(
            onPressed: () => launchUrl(Uri.parse("https://github.com/yashkumaryk066-netizen/RangraGo/releases/latest/download/RangraGo.apk")),
            icon: const Icon(Icons.download_for_offline_rounded, color: Colors.white, size: 40),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Column(
      children: [
        const Text("RangraGo — Ride Smart, Ride Fast",
          style: TextStyle(color: Colors.white10, fontSize: 11, letterSpacing: 1)),
        const SizedBox(height: 20),
      ],
    );
  }
}

