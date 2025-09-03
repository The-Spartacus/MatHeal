import 'package:flutter/material.dart';
import '../services/notification_service.dart';

class NotificationDebuggerScreen extends StatelessWidget {
  const NotificationDebuggerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notification Debugger'),
        backgroundColor: Colors.redAccent,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'This screen tests the most basic notification functionality.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                ),
                onPressed: () async {
                  print('--- IMMEDIATE NOTIFICATION TEST ---');
                  try {
                    await NotificationService.showNotification(
                      id: 1, // Simple ID for this test
                      title: 'Immediate Test',
                      body: 'If you see this, basic notifications work.',
                    );
                    print('Notification request sent successfully.');
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Immediate notification request sent!'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  } catch (e) {
                    print('Error sending notification: $e');
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
                child: const Text(
                  'Show Immediate Notification',
                  style: TextStyle(fontSize: 16),
                ),
              ),
              const SizedBox(height: 40),
              const Divider(),
              const SizedBox(height: 20),
              const Text(
                'If the notification does not appear, please check:\n\n'
                '1. You have UNINSTALLED and reinstalled the app.\n\n'
                '2. App Permissions: "Notifications" are ALLOWED in your phone settings.\n\n'
                '3. Battery Saver: Your app is set to "Unrestricted".\n\n'
                '4. "Do Not Disturb" mode is OFF.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
