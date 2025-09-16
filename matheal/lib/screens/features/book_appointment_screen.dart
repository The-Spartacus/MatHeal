// lib/screens/features/book_appointment_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../../models/user_model.dart';
import '../../models/appointment_model.dart';
import '../../services/firestore_service.dart';
import '../../services/notification_service.dart';

class BookAppointmentScreen extends StatefulWidget {
  const BookAppointmentScreen({super.key});

  @override
  State<BookAppointmentScreen> createState() => _BookAppointmentScreenState();
}

class _BookAppointmentScreenState extends State<BookAppointmentScreen> {
  DateTime? _selectedDateTime;
  final _notesController = TextEditingController();
  final _searchController = TextEditingController();

  String? _filterSpecialization;
  String? _filterHospital;
  String _searchQuery = "";

  Future<void> _pickDateTimeAndBook(UserModel doctor) async {
    final now = DateTime.now();

    final date = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );
    if (date == null) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (time == null) return;

    setState(() {
      _selectedDateTime = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "Confirm Appointment",
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            Text(
              "Doctor: Dr. ${doctor.name}\n"
              "Specialization: ${doctor.specialization ?? 'N/A'}\n"
              "Hospital: ${doctor.hospitalName ?? 'N/A'}\n"
              "Date & Time: ${DateFormat('dd MMM yyyy, hh:mm a').format(_selectedDateTime!)}",
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: "Notes (optional)",
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text("Cancel"),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      Navigator.pop(ctx);
                      await _bookAppointment(doctor);
                    },
                    child: const Text("Confirm"),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  Future<void> _bookAppointment(UserModel doctor) async {
      if (_selectedDateTime == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Please select date and time")),
    );
    return;
  }
    final userId = FirebaseAuth.instance.currentUser!.uid;

    final appointment = Appointment(
      id: "",
      userId: userId,
      doctorId: doctor.uid,
      dateTime: _selectedDateTime!,
      status: "pending",
      notes: _notesController.text,
    );

    final docRef = FirebaseFirestore.instance.collection("appointments").doc();
    await docRef.set(appointment.toFirestore());

    await NotificationService.scheduleAppointment(
      id: docRef.id.hashCode,
      title: "Doctor Appointment",
      body:
          "You have an appointment with Dr. ${doctor.name} at ${DateFormat('hh:mm a, dd MMM').format(_selectedDateTime!)}",
      scheduledDate: _selectedDateTime!.subtract(const Duration(minutes: 30)),
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Appointment booked successfully!")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Book Appointment"),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list),
            onSelected: (value) {
              setState(() {
                if (value.startsWith("Spec:")) {
                  _filterSpecialization = value.substring(5);
                  _filterHospital = null;
                } else if (value.startsWith("Hosp:")) {
                  _filterHospital = value.substring(5);
                  _filterSpecialization = null;
                } else {
                  _filterSpecialization = null;
                  _filterHospital = null;
                }
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: "All", child: Text("All Doctors")),
              const PopupMenuItem(value: "Spec:Cardiology", child: Text("Cardiology")),
              const PopupMenuItem(value: "Spec:Dermatology", child: Text("Dermatology")),
              const PopupMenuItem(value: "Hosp:City Hospital", child: Text("City Hospital")),
              const PopupMenuItem(value: "Hosp:General Clinic", child: Text("General Clinic")),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // 🔍 Search bar
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: "Search doctors, specialization, hospital...",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (val) {
                setState(() {
                  _searchQuery = val.toLowerCase();
                });
              },
            ),
          ),
          Expanded(
            child: FutureBuilder<List<UserModel>>(
              future: FirestoreService().getAllDoctors(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                var doctors = snapshot.data!;

                // Apply filter
                if (_filterSpecialization != null) {
                  doctors = doctors
                      .where((d) => d.specialization == _filterSpecialization)
                      .toList();
                }
                if (_filterHospital != null) {
                  doctors = doctors
                      .where((d) => d.hospitalName == _filterHospital)
                      .toList();
                }

                // Apply search
                if (_searchQuery.isNotEmpty) {
                  doctors = doctors.where((d) {
                    final name = d.name.toLowerCase();
                    final spec = (d.specialization ?? "").toLowerCase();
                    final hosp = (d.hospitalName ?? "").toLowerCase();
                    return name.contains(_searchQuery) ||
                        spec.contains(_searchQuery) ||
                        hosp.contains(_searchQuery);
                  }).toList();
                }

                if (doctors.isEmpty) {
                  return const Center(child: Text("No doctors found."));
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: doctors.length,
                  itemBuilder: (context, index) {
                    final doc = doctors[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(16),
                        title: Text(
                          "Dr. ${doc.name}",
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Text(
                          "${doc.specialization ?? "Specialization not set"}\n"
                          "${doc.hospitalName ?? "Hospital not set"}",
                          style: const TextStyle(fontSize: 14, color: Colors.grey),
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.add_circle,
                              color: Colors.blue, size: 32),
                          onPressed: () => _pickDateTimeAndBook(doc),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
