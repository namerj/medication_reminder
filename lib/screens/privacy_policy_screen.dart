import 'package:flutter/material.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacy Policy'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: const SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Privacy Policy',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            Text(
              'Last updated: December 2024',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
            SizedBox(height: 24),
            
            Text(
              '1. Introduction',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'This Privacy Policy describes how the Medication Reminder app ("we", "our", or "the App") collects, uses, and protects your information when you use our mobile application. We are committed to protecting your privacy and ensuring the security of your personal health information.',
              style: TextStyle(fontSize: 14, height: 1.5),
            ),
            SizedBox(height: 16),
            
            Text(
              '2. Information We Collect',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Local Data Storage:\n\n• Medication names, dosages, and schedules\n• Medication intake history and records\n• Reminder preferences and settings\n• App usage preferences\n\nDevice Information:\n\n• Device model and operating system version (for compatibility)\n• App version and crash reports (for debugging)\n\nWe do NOT collect:\n\n• Personal identifying information (name, email, phone number)\n• Location data\n• Contacts or other personal data\n• Any data that could identify you personally',
              style: TextStyle(fontSize: 14, height: 1.5),
            ),
            SizedBox(height: 16),
            
            Text(
              '3. How We Use Your Information',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Your medication data is used solely to:\n\n• Provide medication reminders and notifications\n• Track your medication intake history\n• Display your medication schedule\n• Backup and restore your data when you choose to export it\n\nAll data processing occurs locally on your device. We do not transmit your medication data to external servers or third parties.',
              style: TextStyle(fontSize: 14, height: 1.5),
            ),
            SizedBox(height: 16),
            
            Text(
              '4. Data Storage and Security',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Local Storage:\n\n• All your medication data is stored locally on your device\n• Data is encrypted using your device\'s built-in security features\n• No data is transmitted to external servers without your explicit action\n\nData Export:\n\n• You can export your data for backup purposes\n• Exported data is only shared when you explicitly choose to do so\n• You have full control over where and how your exported data is shared',
              style: TextStyle(fontSize: 14, height: 1.5),
            ),
            SizedBox(height: 16),
            
            Text(
              '5. Permissions',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'The App may request the following permissions:\n\n• Notifications: To send medication reminders\n• Storage: To save and backup your medication data locally\n• Alarm: To set precise medication reminder times\n\nWe only request permissions that are necessary for the App\'s core functionality.',
              style: TextStyle(fontSize: 14, height: 1.5),
            ),
            SizedBox(height: 16),
            
            Text(
              '6. Third-Party Services',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'The App operates independently and does not integrate with third-party analytics, advertising, or data collection services. Your medication data remains private and is not shared with any external parties.',
              style: TextStyle(fontSize: 14, height: 1.5),
            ),
            SizedBox(height: 16),
            
            Text(
              '7. Children\'s Privacy',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'The App is not intended for children under 13 years of age. We do not knowingly collect personal information from children under 13. If you are a parent or guardian and believe your child has provided us with personal information, please contact us.',
              style: TextStyle(fontSize: 14, height: 1.5),
            ),
            SizedBox(height: 16),
            
            Text(
              '8. Data Retention and Deletion',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Your data is retained locally on your device until you:\n\n• Delete the App from your device\n• Manually delete specific medication records\n• Reset the App data through device settings\n\nWhen you uninstall the App, all locally stored data is automatically removed from your device.',
              style: TextStyle(fontSize: 14, height: 1.5),
            ),
            SizedBox(height: 16),
            
            Text(
              '9. Your Rights',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'You have the right to:\n\n• Access all your medication data within the App\n• Modify or delete any medication records\n• Export your data for backup purposes\n• Delete all data by uninstalling the App\n• Use the App without providing any personal identifying information',
              style: TextStyle(fontSize: 14, height: 1.5),
            ),
            SizedBox(height: 16),
            
            Text(
              '10. Changes to This Privacy Policy',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'We may update this Privacy Policy from time to time. We will notify you of any changes by updating the "Last updated" date at the top of this Privacy Policy. You are advised to review this Privacy Policy periodically for any changes.',
              style: TextStyle(fontSize: 14, height: 1.5),
            ),
            SizedBox(height: 16),
            
            Text(
              '11. Contact Us',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'If you have any questions about this Privacy Policy or our privacy practices, please contact us through the app store or leave a review with your concerns.',
              style: TextStyle(fontSize: 14, height: 1.5),
            ),
            SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}