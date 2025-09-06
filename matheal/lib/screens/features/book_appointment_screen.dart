// lib/screens/features/book_appointment_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../../models/doctor_model.dart';
import '../../models/appointment_model.dart';
import '../../services/doctor_service.dart';
import '../../services/notification_service.dart';

class BookAppointmentScreen extends StatefulWidget {
  const BookAppointmentScreen({super.key});

  @override
  State<BookAppointmentScreen> createState() => _BookAppointmentScreenState();
}

class _BookAppointmentScreenState extends State<BookAppointmentScreen> {
  Doctor? _selectedDoctor;
  DateTime? _selectedDateTime;
  final _notesController = TextEditingController();

  Future<void> _pickDateTime() async {
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
  }

  Future<void> _bookAppointment() async {
    if (_selectedDoctor == null || _selectedDateTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select doctor and date/time")),
      );
      return;
    }

    final userId = FirebaseAuth.instance.currentUser!.uid;

    final appointment = Appointment(
      id: "",
      userId: userId,
      doctorId: _selectedDoctor!.id,
      dateTime: _selectedDateTime!,
      status: "pending",
      notes: _notesController.text,
    );

    final docRef = FirebaseFirestore.instance.collection("appointments").doc();
    await docRef.set(appointment.toFirestore());
    
    // 🔔 Schedule reminder
    await NotificationService.scheduleAppointment(
      id: docRef.id.hashCode,
      title: "Doctor Appointment",
      body: "You have an appointment with ${_selectedDoctor!.name} at ${DateFormat('hh:mm a, dd MMM').format(_selectedDateTime!)}",
      scheduledDate: _selectedDateTime!.subtract(const Duration(minutes: 30)), // 30 min before
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Appointment booked successfully!")),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Book Appointment")),
body: SingleChildScrollView(
  padding: const EdgeInsets.all(16),
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      FutureBuilder<List<Doctor>>(
        future: DoctorService().getAllDoctors(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const CircularProgressIndicator();
          final doctors = snapshot.data!;
          return DropdownButtonFormField<Doctor>(
            decoration: const InputDecoration(labelText: "Select Doctor"),
            value: _selectedDoctor != null && doctors.contains(_selectedDoctor)
                ? _selectedDoctor
                : null,
            items: doctors.map((doc) {
              return DropdownMenuItem(
                value: doc,
                child: Text("${doc.name} - ${doc.specialization}"),
              );
            }).toList(),
            onChanged: (val) => setState(() => _selectedDoctor = val),
          );
        },
      ),
      const SizedBox(height: 20),
      ListTile(
        title: Text(
          _selectedDateTime != null
              ? DateFormat('dd MMM yyyy, hh:mm a').format(_selectedDateTime!)
              : "Select Date & Time",
        ),
        trailing: const Icon(Icons.calendar_today),
        onTap: _pickDateTime,
      ),
      const SizedBox(height: 20),
      TextField(
        controller: _notesController,
        decoration: const InputDecoration(
          labelText: "Notes (optional)",
          border: OutlineInputBorder(),
        ),
        maxLines: 2,
      ),
      const SizedBox(height: 20),
      ElevatedButton.icon(
        onPressed: _bookAppointment,
        icon: const Icon(Icons.check),
        label: const Text("Book Appointment"),
        style: ElevatedButton.styleFrom(
          minimumSize: const Size.fromHeight(50),
        ),
      ),
    ],
  ),
),

    );
  }
}
