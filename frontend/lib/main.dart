import 'package:flutter/material.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/driver_registration_screen.dart';

void main() {
  runApp(const RangraGoApp());
}

class RangraGoApp extends StatelessWidget {
  const RangraGoApp({super.key});

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
      home: Builder(
        builder: (context) => LoginScreen(
          onLoginSuccess: (data, isDriver) {
            final user = data['user'];
            
            if (isDriver && (user['isRegistered'] == false || user['isRegistered'] == null)) {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (context) => DriverRegistrationScreen(
                    userData: user,
                    onComplete: () {
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(
                          builder: (context) => HomeScreen(
                            userId: user['_id'],
                            isDriver: isDriver,
                            userData: user,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              );
            } else {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (context) => HomeScreen(
                    userId: user['_id'],
                    isDriver: isDriver,
                    userData: user,
                  ),
                ),
              );
            }
          },
        ),
      ),
    );
  }
}
