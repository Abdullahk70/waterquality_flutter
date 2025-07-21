import 'package:flutter/material.dart';
import 'app_colors.dart';

class FAQsScreen extends StatelessWidget {
  final List<Map<String, String>> faqs = [
    {
      'question': 'Why is the water quality data inaccurate?',
      'answer': 'Check the calibration of your sensor and ensure proper installation.',
    },
    {
      'question': 'Why can’t I access my reports?',
      'answer': 'Ensure you have a stable internet connection and that your account is synced.',
    },
    {
      'question': 'How do I reset my sensor?',
      'answer': 'Go to Settings > Sensor Settings and follow the reset instructions.',
    },
  ];

  FAQsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'FAQs',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.getTextColor(context),
          ),
        ),
        backgroundColor: AppColors.appBarBackgroundColor,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: ListView.separated(
          itemCount: faqs.length,
          separatorBuilder: (context, index) => Divider(
            color: AppColors.getAccentColor(context).withOpacity(0.3),
            thickness: 1,
          ),
          itemBuilder: (context, index) {
            final faq = faqs[index];
            return ExpansionTile(
              leading: Icon(Icons.help_outline, color: AppColors.getAccentColor(context)),
              title: Text(
                faq['question']!,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: AppColors.getAccentColor(context),
                ),
              ),
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: Text(
                    faq['answer']!,
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.getSubtitleTextColor(context),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
