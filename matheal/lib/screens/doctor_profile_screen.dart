// lib/screens/doctor/doctor_profile_screen.dart
import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../../utils/theme.dart';

class DoctorProfileScreen extends StatelessWidget {
  final UserModel doctor;

  const DoctorProfileScreen({Key? key, required this.doctor}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final profile = doctor.doctorProfile;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text(
          "My Profile",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Avatar + name
            CircleAvatar(
              radius: 50,
              backgroundColor: AppColors.primary.withOpacity(0.2),
              child: const Icon(Icons.person, size: 60, color: AppColors.primary),
            ),
            const SizedBox(height: 16),
            Text(
              "Dr. ${doctor.name}",
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              doctor.email,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),

            const SizedBox(height: 24),

            // Info cards
            _buildInfoCard(
              title: "Specialization",
              value: profile?.specialization ?? "Not set",
              icon: Icons.star_outline,
            ),
            _buildInfoCard(
              title: "Hospital",
              value: profile?.hospitalName ?? "Not set",
              icon: Icons.local_hospital_outlined,
            ),
            _buildInfoCard(
              title: "Joined",
              value:
                  "${doctor.createdAt.day}/${doctor.createdAt.month}/${doctor.createdAt.year}",
              icon: Icons.calendar_today,
            ),
            _buildInfoCard(
              title: "Role",
              value: doctor.role,
              icon: Icons.verified_user,
            ),

            const SizedBox(height: 24),

            // Edit profile button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.edit),
                label: const Text("Edit Profile"),
                onPressed: () {
                  // 👉 Navigate to edit profile screen (to be created)
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Edit profile coming soon")),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard({
    required String title,
    required String value,
    required IconData icon,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.only(bottom: 16),
      child: ListTile(
        leading: Icon(icon, color: AppColors.primary),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        subtitle: Text(
          value,
          style: const TextStyle(color: AppColors.textSecondary),
        ),
      ),
    );
  }
}
