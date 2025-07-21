import 'package:flutter/material.dart';
import 'package:fyp/app_colors.dart';
import 'NotificationManager.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  @override
  void initState() {
    super.initState();
    NotificationManager().addListener(_updateNotifications);
  }

  @override
  void dispose() {
    NotificationManager().removeListener(_updateNotifications);
    super.dispose();
  }

  void _updateNotifications() {
    setState(() {}); // Refresh the UI when notifications update
  }

  void _clearNotifications() {
    NotificationManager().clearNotifications();
    setState(() {}); // Refresh UI after clearing notifications
  }

  Widget _buildNotificationCard(Map<String, dynamic> notification) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: const Icon(Icons.notifications, color: Colors.blue),
        title: Text(
          notification['title'] ?? '',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(notification['body'] ?? ''),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final notifications = NotificationManager().notifications;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        centerTitle: true,
        backgroundColor: AppColors.appBarBackgroundColor,
        iconTheme: IconThemeData(color: Theme.of(context).iconTheme.color),
        leading: null,
        actions: [
          if (notifications.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: _clearNotifications,
              tooltip: 'Clear All Notifications',
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: notifications.isNotEmpty
            ? ListView.builder(
                itemCount: notifications.length,
                itemBuilder: (context, index) {
                  return _buildNotificationCard(notifications[index]);
                },
              )
            : const Center(
                child: Text(
                  "No notifications available.",
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
              ),
      ),
    );
  }
}
