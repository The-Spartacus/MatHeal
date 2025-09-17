// lib/screens/features/user_appointments_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../services/firestore_service.dart';
import '../../models/appointment_model.dart';
import '../../models/user_model.dart';
import '../../utils/theme.dart';

class UserAppointmentsScreen extends StatelessWidget {
  const UserAppointmentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      appBar: AppBar(title: const Text("My Appointments")),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection("appointments")
            .where("userId", isEqualTo: userId)
            .orderBy("dateTime")
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No appointments booked yet."));
          }

          final appointments = snapshot.data!.docs
              .map((doc) => Appointment.fromFirestore(
                  doc.data() as Map<String, dynamic>, doc.id))
              .toList();

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: appointments.length,
            itemBuilder: (context, index) {
              final appointment = appointments[index];

              return FutureBuilder<UserModel?>(
                future: FirestoreService().getDoctorById(appointment.doctorId),
                builder: (context, docSnap) {
                  if (!docSnap.hasData) {
                    // Show a placeholder while loading doctor info
                    return const Card(
                      margin: EdgeInsets.symmetric(vertical: 8),
                      child: SizedBox(height: 120, child: Center(child: CircularProgressIndicator())),
                    );
                  }
                  
                  final doctor = docSnap.data!;
                  return _buildAppointmentCard(context, appointment, doctor);
                },
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildAppointmentCard(BuildContext context, Appointment appointment, UserModel doctor) {
    return Container(
      height: 120,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Stack(
        children: [
          // Background Card with Gradient
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            clipBehavior: Clip.antiAlias,
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF2C3E50), Color(0xFF1B2631)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
          ),
          // Doctor's Image
          Positioned(
            right: 0,
            bottom: 0,
            top: 0,
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                topRight: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
              child: doctor.avatarUrl != null
                  ? Image.network(
                      doctor.avatarUrl!,
                      width: 110,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Icon(Icons.person, size: 80, color: Colors.white54),
                    )
                  : const SizedBox(
                      width: 110,
                      child: Icon(Icons.person, size: 80, color: Colors.white54),
                    ),
            ),
          ),
          // Text Details
          Positioned.fill(
            right: 110, // Avoid overlap with image
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Date and Time
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
                  // Doctor Name
                  Text(
                    "Dr. ${doctor.name}",
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Specialization
                  Text(
                    doctor.specialization ?? "Specialist",
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
