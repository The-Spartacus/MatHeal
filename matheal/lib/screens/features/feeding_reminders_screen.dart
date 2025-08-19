// lib/screens/features/feeding_reminders_screen.dart
import 'package:flutter/material.dart';
import '../../utils/theme.dart';

class FeedingRemindersScreen extends StatelessWidget {
  const FeedingRemindersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Feeding Reminders'),
        backgroundColor: AppColors.background,
      ),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.restaurant,
                size: 100,
                color: AppColors.accent,
              ),
              SizedBox(height: 24),
              Text(
                'Feeding Reminders',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 16),
              Text(
                'Track your nutrition and set meal reminders. This feature is under development.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}