// lib/screens/features/doctor_appointments_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/appointment_model.dart';

class DoctorAppointmentsScreen extends StatelessWidget {
  const DoctorAppointmentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final doctorId = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      appBar: AppBar(title: const Text("My Patients")),
    body: StreamBuilder<QuerySnapshot>(
  stream: FirebaseFirestore.instance
      .collection("appointments")
      .where("doctorId", isEqualTo: doctorId)
      .orderBy("dateTime")
      .snapshots(),
  builder: (context, snapshot) {
    if (snapshot.hasError) {
      return Center(child: Text("Error: ${snapshot.error}"));
    }
    if (snapshot.connectionState == ConnectionState.waiting) {
      return const Center(child: CircularProgressIndicator());
    }

    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
      return const Center(child: Text("No appointments yet."));
    }

    final appointments = snapshot.data!.docs
        .map((doc) => Appointment.fromFirestore(doc.data() as Map<String, dynamic>, doc.id))
        .toList();

    return ListView.builder(
      itemCount: appointments.length,
      itemBuilder: (context, index) {
        final a = appointments[index];
        return Card(
          margin: const EdgeInsets.all(10),
          child: ListTile(
            leading: const Icon(Icons.person, color: Colors.teal),
            title: Text("Patient ID: ${a.userId}"),
            subtitle: Text("Date: ${a.dateTime}\nNotes: ${a.notes}"),
            trailing: DropdownButton<String>(
              value: a.status,
              items: const [
                DropdownMenuItem(value: "pending", child: Text("Pending")),
                DropdownMenuItem(value: "confirmed", child: Text("Confirmed")),
                DropdownMenuItem(value: "cancelled", child: Text("Cancelled")),
              ],
              onChanged: (newStatus) {
                if (newStatus != null) {
                  FirebaseFirestore.instance
                      .collection("appointments")
                      .doc(a.id)
                      .update({"status": newStatus});
                }
              },
            ),
          ),
        );
      },
    );
  },
),

    );
  }
}
