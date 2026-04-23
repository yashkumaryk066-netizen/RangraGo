import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/foundation.dart';
import 'screens/login_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/home_screen.dart';
import 'screens/driver_registration_screen.dart';
import 'screens/rider_registration_screen.dart';
import 'services/config.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const RangraGoApp());
}

class UpdateChecker {
  static const int currentBuild = 3;

  static Future<void> check(BuildContext context) async {
    if (kIsWeb) return;
    try {
      final response = await http.get(Uri.parse('https://raw.githubusercontent.com/yashkumaryk066-netizen/RangraGo/master/version.json'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['build'] > currentBuild) {
          if (context.mounted) {
            _showUpdateDialog(context, data['message'], data['url']);
          }
        }
      }
    } catch (e) {
      debugPrint("Update check failed: $e");
    }
  }

  static void _showUpdateDialog(BuildContext context, String message, String url) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.system_update, color: Color(0xFF7C3AED)),
            SizedBox(width: 10),
            Text("Update Available", style: TextStyle(color: Colors.white)),
          ],
        ),
        content: Text(message, style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("LATER", style: TextStyle(color: Colors.white30)),
          ),
          ElevatedButton(
            onPressed: () => launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF7C3AED)),
            child: const Text("UPDATE NOW", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

class RangraGoApp extends StatefulWidget {
  const RangraGoApp({super.key});

  @override
  State<RangraGoApp> createState() => _RangraGoAppState();
}

class _RangraGoAppState extends State<RangraGoApp> {
  bool _isSplashFinished = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => UpdateChecker.check(context));
  }

  Future<Map<String, dynamic>?> _loadSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? token = prefs.getString('token');
      final String? userDataStr = prefs.getString('user_data');
      final bool isDriver = prefs.getBool('is_driver') ?? false;

      if (token != null && userDataStr != null && token.isNotEmpty) {
        final userData = jsonDecode(userDataStr);
        AppConfig.userToken = token;
        return {
          "token": token,
          "user": userData,
          "isDriver": isDriver,
        };
      }
    } catch (e) {
      print("Session Load Error: $e");
    }
    return null;
  }

  Future<void> _updateSession(String token, Map<String, dynamic> user, bool isDriver) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', token);
    await prefs.setString('user_data', jsonEncode(user));
    await prefs.setBool('is_driver', isDriver);
    AppConfig.userToken = token;
    setState(() {}); // Re-trigger FutureBuilder
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RangraGo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF7C3AED),
          brightness: Brightness.dark,
        ),
      ),
      home: !_isSplashFinished 
        ? SplashScreen(onFinish: () => setState(() => _isSplashFinished = true))
        : FutureBuilder<Map<String, dynamic>?>(
        future: _loadSession(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              backgroundColor: Color(0xFF070712),
              body: Center(child: CircularProgressIndicator(color: Color(0xFF7C3AED))),
            );
          }

          final session = snapshot.data;
          if (session != null) {
            final user = session['user'];
            final isDriver = session['isDriver'];
            final token = session['token'];

            if (user['isRegistered'] == true) {
              return HomeScreen(
                userId: user['_id'],
                isDriver: isDriver,
                userData: user,
              );
            } else {
              return isDriver 
                ? DriverRegistrationScreen(
                    userData: user,
                    onComplete: () async {
                      user['isRegistered'] = true;
                      await _updateSession(token, user, isDriver);
                    },
                  )
                : RiderRegistrationScreen(
                    userData: user,
                    onComplete: () async {
                      user['isRegistered'] = true;
                      await _updateSession(token, user, isDriver);
                    },
                  );
            }
          }

          return LoginScreen(
            onLoginSuccess: (data, isDriver) async {
              await _updateSession(data['token'], data['user'], isDriver);
            },
          );
        },
      ),
    );
  }
}
