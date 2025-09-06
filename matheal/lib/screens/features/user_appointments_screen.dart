// lib/screens/features/user_appointments_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/doctor_service.dart';
import '../../models/appointment_model.dart';
import '../../models/doctor_model.dart';

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
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final appointments = snapshot.data!.docs
              .map((doc) => Appointment.fromFirestore(doc.data() as Map<String, dynamic>, doc.id))
              .toList();

          if (appointments.isEmpty) {
            return const Center(child: Text("No appointments booked yet."));
          }

          return ListView.builder(
            itemCount: appointments.length,
            itemBuilder: (context, index) {
              final a = appointments[index];

              return FutureBuilder<Doctor?>(
                future: DoctorService().getDoctorById(a.doctorId),
                builder: (context, docSnap) {
                  final doctor = docSnap.data;

                  return Card(
                    margin: const EdgeInsets.all(10),
                    child: ListTile(
                      leading: const Icon(Icons.local_hospital, color: Colors.blue),
                      title: Text(doctor?.name ?? "Doctor"),
                      subtitle: Text(
                        doctor != null
                            ? "${doctor.specialization} at ${doctor.hospitalName}\n${a.dateTime}"
                            : a.dateTime.toString(),
                      ),
                      trailing: Text(
                        a.status,
                        style: TextStyle(
                          color: a.status == "confirmed"
                              ? Colors.green
                              : (a.status == "cancelled" ? Colors.red : Colors.orange),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
