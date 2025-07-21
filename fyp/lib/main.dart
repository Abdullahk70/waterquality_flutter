import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'welcome_screen.dart';
import 'water_quality_monitor_screen.dart';
import 'notificationHelper.dart';

final ValueNotifier<bool> isDarkMode = ValueNotifier(false); 

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await NotificationHelper.initializeNotifications();
  runApp(const WaterQualityApp());
}

class WaterQualityApp extends StatelessWidget {
  const WaterQualityApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: isDarkMode,
      builder: (context, darkModeEnabled, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          home: FirebaseAuth.instance.currentUser != null
              ? const WaterQualityMonitorScreen()
              : const WelcomeScreen(),
          theme: ThemeData(
            brightness: darkModeEnabled ? Brightness.dark : Brightness.light,
            primarySwatch: Colors.blue,
          ),
        );
      },
    );
  }
}
