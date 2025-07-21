import 'package:flutter/material.dart';
import 'app_colors.dart';

class AboutUsScreen extends StatelessWidget {
  const AboutUsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'About Us',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.appBarBackgroundColor,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'About Our App',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.getAccentColor(context),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Our app leverages advanced IoT and machine learning technologies to ensure the safety and quality of water for diverse applications.',
              style: TextStyle(fontSize: 16, color: AppColors.getSubtitleTextColor(context)),
            ),
            const SizedBox(height: 30),
            Text(
              'Key Features:',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.getAccentColor(context),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              '- Real-time water quality monitoring.\n'
              '- Advanced analytics for contamination detection.\n'
              '- Actionable insights for maintaining water standards.',
              style: TextStyle(fontSize: 16, color: AppColors.getSubtitleTextColor(context)),
            ),
            const SizedBox(height: 30),
            Text(
              'Our Mission:',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.getAccentColor(context),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'To empower communities and industries with cutting-edge tools to ensure access to clean and safe water.',
              style: TextStyle(fontSize: 16, color: AppColors.getSubtitleTextColor(context)),
            ),
            const Spacer(),
            Center(
              child: Text(
                'Version 1.0.0',
                style: TextStyle(fontSize: 14, color: AppColors.getSubtitleTextColor(context)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
