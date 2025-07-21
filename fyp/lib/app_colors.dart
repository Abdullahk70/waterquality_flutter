import 'package:flutter/material.dart';

class AppColors {
  static Color getBackgroundColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? Colors.grey.shade900
        : Colors.white;
  }

  static LinearGradient getBackgroundGradient(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? LinearGradient(
            colors: [Colors.grey.shade800, Colors.grey.shade700],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          )
        : LinearGradient(
            colors: [Colors.blue.shade50, Colors.blue.shade100],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          );
  }

  static const Color appBarBackgroundColor = Color.fromARGB(255, 66, 137, 218);

  static Color getTextColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? Colors.white
        : Colors.black87;
  }

  static Color getSubtitleTextColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? Colors.white60
        : Colors.grey.shade700;
  }

  static Color getAccentColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? Colors.blueAccent.shade200
        : Colors.blue.shade600;
  }
}
