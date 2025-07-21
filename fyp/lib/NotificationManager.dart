import 'package:flutter/material.dart';

class NotificationManager extends ChangeNotifier {
  static final NotificationManager _instance = NotificationManager._internal();

  factory NotificationManager() {
    return _instance;
  }

  NotificationManager._internal();

  final List<Map<String, String>> _notifications = [];

  List<Map<String, String>> get notifications => List.unmodifiable(_notifications);

  void addNotification(String title, String body) {
    _notifications.add({'title': title, 'body': body});
    notifyListeners(); // Notify listeners when a new notification is added
  }

  void clearNotifications() {
    _notifications.clear();
    notifyListeners(); // Notify listeners after clearing notifications
  }
}
