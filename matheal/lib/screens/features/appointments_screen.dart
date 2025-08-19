// lib/screens/features/appointments_screen.dart
import 'package:flutter/material.dart';
import '../../utils/theme.dart';

class AppointmentsScreen extends StatelessWidget {
  const AppointmentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Doctor Appointments'),
        backgroundColor: AppColors.background,
      ),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.local_hospital,
                size: 100,
                color: AppColors.primary,
              ),
              SizedBox(height: 24),
              Text(
                'Appointments Feature',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 16),
              Text(
                'This feature is coming soon! You\'ll be able to schedule and track your doctor appointments.',
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