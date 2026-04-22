import 'dart:convert';
import 'dart:html' as html; // Web persistence ke liye zaroori hai
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/driver_registration_screen.dart';
import 'screens/rider_registration_screen.dart';
import 'services/config.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const RangraGoApp());
}

class RangraGoApp extends StatefulWidget {
  const RangraGoApp({super.key});

  @override
  State<RangraGoApp> createState() => _RangraGoAppState();
}

class _RangraGoAppState extends State<RangraGoApp> {
  Future<Map<String, dynamic>?> _loadSession() async {
    try {
      final String? token = html.window.localStorage['token'];
      final String? userDataStr = html.window.localStorage['user_data'];
      final bool isDriver = html.window.localStorage['is_driver'] == 'true';

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

  void _updateSession(String token, Map<String, dynamic> user, bool isDriver) {
    html.window.localStorage['token'] = token;
    html.window.localStorage['user_data'] = jsonEncode(user);
    html.window.localStorage['is_driver'] = isDriver.toString();
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
      home: FutureBuilder<Map<String, dynamic>?>(
        future: _loadSession(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(body: Center(child: CircularProgressIndicator()));
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
                    onComplete: () {
                      user['isRegistered'] = true;
                      _updateSession(token, user, isDriver);
                    },
                  )
                : RiderRegistrationScreen(
                    userData: user,
                    onComplete: () {
                      user['isRegistered'] = true;
                      _updateSession(token, user, isDriver);
                    },
                  );
            }
          }

          return LoginScreen(
            onLoginSuccess: (data, isDriver) {
              _updateSession(data['token'], data['user'], isDriver);
            },
          );
        },
      ),
    );
  }
}
