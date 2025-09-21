import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/firestore_service.dart';
import '../../services/appointment_service.dart';
import '../../models/appointment_model.dart';
import '../../models/user_model.dart';
import '../../utils/theme.dart';
import '../../widgets/appointment_card.dart'; // Using the reusable stylish card

class UserAppointmentsScreen extends StatefulWidget {
  const UserAppointmentsScreen({super.key});

  @override
  State<UserAppointmentsScreen> createState() => _UserAppointmentsScreenState();
}

class _UserAppointmentsScreenState extends State<UserAppointmentsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final AppointmentService _appointmentService = AppointmentService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  /// Handles the logic for cancelling an appointment.
  Future<void> _cancelAppointment(Appointment appointment) async {
    final bool didRequestCancel = await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Cancel Appointment'),
            content: const Text('Are you sure you want to cancel this appointment?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('No'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
                child: const Text('Yes, Cancel'),
              ),
            ],
          ),
        ) ??
        false;

    if (didRequestCancel && mounted) {
      try {
        // If the appointment was only pending, delete it so the doctor doesn't see it.
        // If it was confirmed, update the status to 'cancelled'.
        if (appointment.status == 'pending') {
          await _appointmentService.deleteAppointment(appointment.id);
        } else {
          await _appointmentService.updateAppointmentStatus(appointment.id, 'cancelled');
        }
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Appointment cancelled.'), backgroundColor: AppColors.success),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text("My Appointments"),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: "Upcoming"),
            Tab(text: "Pending"),
            Tab(text: "History"),
          ],
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _appointmentService.getAppointmentsStreamForUser(userId),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final now = DateTime.now();
          final allAppointments = snapshot.data!.docs
              .map((d) => Appointment.fromFirestore(d.data() as Map<String, dynamic>, d.id))
              .toList();

          // Filter appointments into the correct categories
          final upcoming = allAppointments
              .where((a) => a.dateTime.isAfter(now) && a.status == 'confirmed')
              .toList();
          final pending = allAppointments
              .where((a) => a.dateTime.isAfter(now) && a.status == 'pending')
              .toList();
          final history = allAppointments.where((a) => a.dateTime.isBefore(now)).toList();
          
          return TabBarView(
            controller: _tabController,
            children: [
              _buildAppointmentList(upcoming, "No upcoming appointments."),
              _buildAppointmentList(pending, "No pending appointment requests."),
              _buildAppointmentList(history, "No appointment history."),
            ],
          );
        },
      ),
    );
  }

  /// Builds a list of appointments for a specific tab.
  Widget _buildAppointmentList(List<Appointment> appointments, String emptyMessage) {
    if (appointments.isEmpty) {
      return Center(child: Text(emptyMessage, style: TextStyle(color: AppColors.textSecondary)));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: appointments.length,
      itemBuilder: (context, index) {
        final appointment = appointments[index];
        return FutureBuilder<UserModel?>(
          future: FirestoreService().getDoctorById(appointment.doctorId),
          builder: (context, docSnap) {
            if (!docSnap.hasData) {
              // Show a placeholder while the doctor's details are loading
              return const SizedBox(height: 120, child: Center(child: CircularProgressIndicator()));
            }
            final doctor = docSnap.data!;
            
            // Use the stylish reusable card
            return AppointmentCard(
              appointment: appointment,
              participant: doctor,
              onCancel: appointment.dateTime.isAfter(DateTime.now())
                  ? () => _cancelAppointment(appointment)
                  : null, // Only show cancel for future appointments
            );
          },
        );
      },
    );
  }
}

