// lib/screens/features/doctor_home_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/doctor_model.dart';
import 'doctor_appointments_screen.dart';
import '../../utils/theme.dart';

class DoctorHomeScreen extends StatelessWidget {
  final Doctor doctor;
  const DoctorHomeScreen({super.key, required this.doctor});

  void _logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    Navigator.of(context).popUntil((route) => route.isFirst); // back to login
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text("Welcome Dr. ${doctor.name}"),
        backgroundColor: AppColors.primary,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _logout(context),
          )
        ],
      ),
      body: GridView.count(
        crossAxisCount: 2,
        padding: const EdgeInsets.all(16),
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        children: [
          _buildCard(
            context,
            icon: Icons.people,
            title: "Appointments",
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const DoctorAppointmentsScreen()),
            ),
          ),
          _buildCard(
            context,
            icon: Icons.medical_services_outlined,
            title: "Prescriptions",
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Prescriptions coming soon")),
              );
            },
          ),
          _buildCard(
            context,
            icon: Icons.chat_bubble_outline,
            title: "Messages",
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Chat feature coming soon")),
              );
            },
          ),
          _buildCard(
            context,
            icon: Icons.analytics_outlined,
            title: "Reports",
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Reports coming soon")),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCard(BuildContext context,
      {required IconData icon, required String title, required VoidCallback onTap}) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 50, color: AppColors.primary),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
