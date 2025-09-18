import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/appointment_model.dart';
import '../../models/user_model.dart';
import '../../services/firestore_service.dart';
import '../../services/appointment_service.dart';
import '../../widgets/appointment_card.dart'; // ✅ IMPORT THE NEW WIDGET

class DoctorAppointmentsScreen extends StatefulWidget {
  const DoctorAppointmentsScreen({super.key});

  @override
  State<DoctorAppointmentsScreen> createState() => _DoctorAppointmentsScreenState();
}

class _DoctorAppointmentsScreenState extends State<DoctorAppointmentsScreen> with SingleTickerProviderStateMixin {
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

  @override
  Widget build(BuildContext context) {
    final doctorId = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text("My Patients"),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [Tab(text: "Requests"), Tab(text: "Upcoming"), Tab(text: "History")],
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _appointmentService.getAppointmentsStreamForDoctor(doctorId),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final now = DateTime.now();
          final allAppointments = snapshot.data!.docs.map((d) => Appointment.fromFirestore(d.data() as Map<String, dynamic>, d.id)).toList();

          final requests = allAppointments.where((a) => a.dateTime.isAfter(now) && a.status == 'pending').toList();
          final upcoming = allAppointments.where((a) => a.dateTime.isAfter(now) && a.status == 'confirmed').toList();
          final history = allAppointments.where((a) => a.dateTime.isBefore(now)).toList();

          return TabBarView(
            controller: _tabController,
            children: [
              _buildAppointmentList(requests, "No new appointment requests."),
              _buildAppointmentList(upcoming, "No upcoming appointments."),
              _buildAppointmentList(history, "No appointment history."),
            ],
          );
        },
      ),
    );
  }

  Widget _buildAppointmentList(List<Appointment> appointments, String emptyMessage) {
    if (appointments.isEmpty) return Center(child: Text(emptyMessage));
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: appointments.length,
      itemBuilder: (context, index) {
        final appointment = appointments[index];
        return FutureBuilder<UserModel?>(
          future: FirestoreService().getUser(appointment.userId),
          builder: (context, userSnap) {
            if (!userSnap.hasData) return const SizedBox(height: 120, child: Center(child: CircularProgressIndicator()));
            // ✅ USE THE NEW APPOINTMENT CARD WIDGET
            return AppointmentCard(
              appointment: appointment,
              participant: userSnap.data!,
              isDoctorView: true,
              onConfirm: () => _appointmentService.updateAppointmentStatus(appointment.id, 'confirmed'),
              onCancel: () => _appointmentService.updateAppointmentStatus(appointment.id, 'cancelled'),
            );
          },
        );
      },
    );
  }
}
