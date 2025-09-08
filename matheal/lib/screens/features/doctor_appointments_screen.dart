// lib/screens/features/doctor_appointments_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../models/appointment_model.dart';
import '../../models/user_model.dart';
import '../../services/firestore_service.dart';

class DoctorAppointmentsScreen extends StatefulWidget {
  const DoctorAppointmentsScreen({super.key});

  @override
  State<DoctorAppointmentsScreen> createState() =>
      _DoctorAppointmentsScreenState();
}

class _DoctorAppointmentsScreenState extends State<DoctorAppointmentsScreen> {
  bool showHistory = false; // toggle for history view

  @override
  Widget build(BuildContext context) {
    final doctorId = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text("My Patients"),
        actions: [
          IconButton(
            icon: Icon(showHistory ? Icons.list_alt : Icons.history),
            tooltip: showHistory ? "Show Upcoming" : "Show History",
            onPressed: () {
              setState(() {
                showHistory = !showHistory;
              });
            },
          ),
        ],
      ),
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

          final now = DateTime.now();

          final appointments = snapshot.data!.docs
              .map((doc) => Appointment.fromFirestore(
                  doc.data() as Map<String, dynamic>, doc.id))
              .toList();

          // Upcoming: not cancelled and in the future
          final upcoming = appointments
              .where((a) => a.status != "cancelled" && a.dateTime.isAfter(now))
              .toList();

          // History: cancelled OR confirmed in the past
          final history = appointments
              .where((a) =>
                  a.status == "cancelled" ||
                  (a.status == "confirmed" && a.dateTime.isBefore(now)))
              .toList();

          final listToShow = showHistory ? history : upcoming;

          if (listToShow.isEmpty) {
            return Center(
                child: Text(showHistory
                    ? "No history available."
                    : "No upcoming appointments."));
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: listToShow.length,
            itemBuilder: (context, index) {
              final appointment = listToShow[index];
              return _buildAppointmentCard(appointment, showHistory);
            },
          );
        },
      ),
    );
  }

  Widget _buildAppointmentCard(Appointment a, bool isHistory) {
    return FutureBuilder<UserModel?>(
      future: FirestoreService().getUser(a.userId),
      builder: (context, userSnap) {
        final patientName = userSnap.data?.name ?? "Patient";
        final formattedDate =
            DateFormat('dd MMM yyyy, hh:mm a').format(a.dateTime.toLocal());

        // subtle grey background for cancelled appointments
        final bool isCancelled = a.status == 'cancelled';
        final cardColor = isCancelled ? Colors.grey[100] : null;

        return Card(
          color: cardColor,
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left: expanded details (prevents cut off)
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        patientName,
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        "Date: $formattedDate",
                        style:
                            const TextStyle(fontSize: 14, color: Colors.black87),
                      ),
                      const SizedBox(height: 6),
                      if (a.notes.isNotEmpty)
                        Text(
                          "Notes: ${a.notes}",
                          style:
                              const TextStyle(fontSize: 14, color: Colors.black87),
                          softWrap: true,
                        ),
                      const SizedBox(height: 6),
                      Text(
                        "Status: ${a.status}",
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: a.status == 'confirmed'
                              ? Colors.green
                              : (a.status == 'cancelled' ? Colors.red : Colors.orange),
                        ),
                      ),
                    ],
                  ),
                ),

                // Right: action buttons (fixed width so left can use remaining space)
                const SizedBox(width: 12),
                SizedBox(
                  width: 120,
                  child: isHistory
                      ? Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.history, color: Colors.grey),
                            const SizedBox(height: 6),
                            Text(
                              isCancelled ? "Cancelled" : "Past",
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: Colors.grey),
                            ),
                          ],
                        )
                      : Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // If pending -> show Confirm + Cancel
                            if (a.status == "pending") ...[
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: () {
                                    FirebaseFirestore.instance
                                        .collection("appointments")
                                        .doc(a.id)
                                        .update({"status": "confirmed"});
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green,
                                    minimumSize: const Size.fromHeight(40),
                                  ),
                                  child: const Text("Confirm"),
                                ),
                              ),
                              const SizedBox(height: 8),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: () {
                                    FirebaseFirestore.instance
                                        .collection("appointments")
                                        .doc(a.id)
                                        .update({"status": "cancelled"});
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red,
                                    minimumSize: const Size.fromHeight(40),
                                  ),
                                  child: const Text("Cancel"),
                                ),
                              ),
                            ] else if (a.status == "confirmed" &&
                                a.dateTime.isAfter(DateTime.now())) ...[
                              // confirmed but still upcoming -> only Cancel
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: () {
                                    FirebaseFirestore.instance
                                        .collection("appointments")
                                        .doc(a.id)
                                        .update({"status": "cancelled"});
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red,
                                    minimumSize: const Size.fromHeight(40),
                                  ),
                                  child: const Text("Cancel"),
                                ),
                              ),
                            ] else ...[
                              // fallback (shouldn't normally hit)
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: null,
                                  style: ElevatedButton.styleFrom(
                                    minimumSize: const Size.fromHeight(40),
                                  ),
                                  child: const Text("N/A"),
                                ),
                              ),
                            ],
                          ],
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
