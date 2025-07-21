import 'package:flutter/material.dart';
import 'main.dart'; // Import the ValueNotifier for dark mode
import 'app_colors.dart'; // Import color utilities

class AppPreferencesScreen extends StatefulWidget {
  const AppPreferencesScreen({super.key});

  @override
  _AppPreferencesScreenState createState() => _AppPreferencesScreenState();
}

class _AppPreferencesScreenState extends State<AppPreferencesScreen> {
  bool isDarkModeEnabled = isDarkMode.value;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'App Preferences',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
        ),
        centerTitle: true,
        elevation: 4,
        backgroundColor: AppColors.appBarBackgroundColor,
        iconTheme: IconThemeData(color: Theme.of(context).iconTheme.color),
      ),
      body: Container(
        color: AppColors.getBackgroundColor(context),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Customize your app preferences:',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 20),
              SwitchListTile(
                title: const Text(
                  'Dark Mode',
                  style: TextStyle(fontSize: 16),
                ),
                value: isDarkModeEnabled,
                activeColor: Colors.blueAccent,
                inactiveTrackColor: Colors.grey,
                onChanged: (bool value) {
                  setState(() {
                    isDarkModeEnabled = value;
                    isDarkMode.value = value; // Notify the app to switch themes
                  });
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
