import 'package:flutter/material.dart';

class ContactUsScreen extends StatelessWidget {
  const ContactUsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Contact Us',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: Colors.blue.shade600,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Text(
              'We’d love to hear from you!',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.blue.shade700,
              ),
            ),
            SizedBox(height: 10),
            Text(
              'Feel free to reach out to us via the following methods:',
              style: TextStyle(fontSize: 16, color: Colors.grey.shade700),
            ),
            SizedBox(height: 30),
            // Contact Methods
            ListTile(
              leading: Icon(Icons.email, color: Colors.blue),
              title: Text('Email: support@example.com'),
            ),
            Divider(),
            ListTile(
              leading: Icon(Icons.phone, color: Colors.blue),
              title: Text('Phone: +1 (234) 567-890'),
            ),
            Divider(),
            ListTile(
              leading: Icon(Icons.location_on, color: Colors.blue),
              title: Text('Address: 123 Main Street, City, Country'),
            ),
            Spacer(),
            // Footer
            Center(
              child: Text(
                'We’ll get back to you as soon as possible!',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
