import 'package:flutter/material.dart';
import 'app_drawer.dart';
import 'sensorSettingScreen.dart';
import 'appPreferencesScreen.dart';
import 'NotifSettingScreen.dart';
import 'app_colors.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Settings',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
        ),
        centerTitle: true,
        elevation: 4,
        backgroundColor: AppColors.appBarBackgroundColor,
        iconTheme: const IconThemeData(color: Colors.black),
        leading: null,
      ),
      drawer: AppDrawer(),
      body: Container(
        decoration: BoxDecoration(
          gradient: AppColors.getBackgroundGradient(context),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Manage your app settings:',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: AppColors.getSubtitleTextColor(context),
                ),
              ),
              const SizedBox(height: 20),
              _buildSettingsTile(
                context,
                icon: Icons.settings,
                title: 'Sensor Settings',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => SensorSettingsScreen()),
                ),
              ),
              const SizedBox(height: 10),
              _buildSettingsTile(
                context,
                icon: Icons.palette,
                title: 'App Preferences',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => AppPreferencesScreen()),
                ),
              ),
              const SizedBox(height: 10),
              _buildSettingsTile(
                context,
                icon: Icons.notifications,
                title: 'Notifications',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => NotificationScreen(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: ListTile(
        leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: AppColors.getTextColor(context),
          ),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, color: Colors.grey),
        onTap: onTap,
        tileColor: Theme.of(context).cardColor,
      ),
    );
  }
}
