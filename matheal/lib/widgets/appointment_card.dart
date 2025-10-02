import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/appointment_model.dart';
import '../models/user_model.dart';
import '../utils/theme.dart';

class AppointmentCard extends StatelessWidget {
  final Appointment appointment;
  final UserModel participant; // Can be a doctor or a patient
  final bool isDoctorView;
  final VoidCallback? onCancel;
  final VoidCallback? onConfirm;

  const AppointmentCard({
    super.key,
    required this.appointment,
    required this.participant,
    this.isDoctorView = false,
    this.onCancel,
    this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    final status = appointment.status;
    final statusColor = status == 'confirmed'
        ? AppColors.success
        : (status == 'cancelled' ? AppColors.error : Colors.orange);

    return Container(
      height: 140,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Stack(
        children: [
          // Background
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            clipBehavior: Clip.antiAlias,
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color.fromARGB(255, 84, 151, 218), Color.fromARGB(255, 45, 150, 255)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
          ),
          // Image
          Positioned(
            right: 0,
            bottom: 3,
            top: 4,
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                topRight: Radius.circular(20),
                bottomRight: Radius.circular(20),
                
              ),
              child: participant.avatarUrl != null
                  ? Image.network(
                      participant.avatarUrl!,
                      height: 80,
                      width: 110,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Icon(Icons.person, size: 60, color: Colors.white54),
                    )
                  : SizedBox(
                      width: 110,
                      height: 80,
                      child: Icon(isDoctorView ? Icons.person_outline : Icons.medical_services_outlined, size: 80, color: Colors.white54),
                    ),
            ),
          ),
          // Details
          Positioned.fill(
            right: 110,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                      const SizedBox(height: 22),


                  Row(
                    children: [
                      const Icon(Icons.calendar_today, color: Colors.white70, size: 14),
                      const SizedBox(width: 8),
                      Text(
                        DateFormat('MMMM d, hh:mm a').format(appointment.dateTime),
                        style: const TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Text(
                    isDoctorView ? participant.name : "Dr. ${participant.name}",
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isDoctorView ? "Patient" : (participant.specialization ?? "Specialist"),
                    style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 14),
                  ),
                ],
              ),
            ),
          ),
          // Status Chip
          Positioned(
            top: 12,
            left: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.8),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                status.toUpperCase(),
                style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          // Action Buttons for Doctor
          if (isDoctorView && status == 'pending')
          Positioned(
            bottom: 8,
            right: 120,
            child: Row(
              children: [
                IconButton(icon: const Icon(Icons.check_circle, color: AppColors.success), onPressed: onConfirm),
                IconButton(icon: const Icon(Icons.cancel, color: AppColors.error), onPressed: onCancel),
              ],
            )
          )
        ],
      ),
    );
  }
}
