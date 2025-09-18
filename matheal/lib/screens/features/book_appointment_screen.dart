import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../../models/user_model.dart';
import '../../models/appointment_model.dart';
import '../../services/firestore_service.dart';
import '../../services/notification_service.dart';
import '../../services/appointment_service.dart';
import '../../utils/theme.dart';

class BookAppointmentScreen extends StatefulWidget {
  const BookAppointmentScreen({super.key});

  @override
  State<BookAppointmentScreen> createState() => _BookAppointmentScreenState();
}

class _BookAppointmentScreenState extends State<BookAppointmentScreen> {
  final AppointmentService _appointmentService = AppointmentService();
  DateTime? _selectedDateTime;
  final _notesController = TextEditingController();
  final _searchController = TextEditingController();

  String? _filterSpecialization;
  String? _filterHospital;
  String _searchQuery = "";

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });
  }
  
  @override
  void dispose() {
    _searchController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDateTimeAndBook(UserModel doctor) async {
    final now = DateTime.now();
    final date = await showDatePicker(context: context, initialDate: now, firstDate: now, lastDate: now.add(const Duration(days: 365)));
    if (date == null) return;
    final time = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(now));
    if (time == null) return;

    setState(() => _selectedDateTime = DateTime(date.year, date.month, date.day, time.hour, time.minute));

    if (!mounted) return;
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => _buildConfirmationSheet(doctor),
    );

    if (confirmed == true) {
      await _bookAppointment(doctor);
    }
  }

  Future<void> _bookAppointment(UserModel doctor) async {
    if (_selectedDateTime == null) return;
    final userId = FirebaseAuth.instance.currentUser!.uid;

    final appointment = Appointment(
      id: '', // Firestore will generate this
      userId: userId,
      doctorId: doctor.uid,
      dateTime: _selectedDateTime!,
      status: "pending",
      notes: _notesController.text,
    );

    await _appointmentService.createAppointment(appointment);

    await NotificationService.scheduleAppointment(
      id: UniqueKey().hashCode,
      title: "Appointment Reminder",
      body: "Your appointment with Dr. ${doctor.name} is tomorrow.",
      scheduledDate: _selectedDateTime!.subtract(const Duration(days: 1)),
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Appointment requested successfully!")));
      Navigator.of(context).pop();
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Book an Appointment"),
        actions: [
          // ✅ FILTER BUTTON
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
              const PopupMenuDivider(),
              const PopupMenuItem(value: "Spec:Psychologist", child: Text("Psychologist")),
              const PopupMenuItem(value: "Spec:Medicine", child: Text("Medicine")),
              const PopupMenuItem(value: "Spec:Orthopedic", child: Text("Orthopedic")),
              const PopupMenuDivider(),
              const PopupMenuItem(value: "Hosp:General Hospital", child: Text("General Hospital")),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // ✅ SEARCH BAR
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: "Search doctors, specialization...",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey.shade200,
              ),
            ),
          ),
          Expanded(
            child: FutureBuilder<List<UserModel>>(
              future: FirestoreService().getAllDoctors(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) return Center(child: Text("Error: ${snapshot.error}"));
                if (!snapshot.hasData || snapshot.data!.isEmpty) return const Center(child: Text("No doctors available."));
                
                // ✅ FILTERING AND SEARCHING LOGIC
                var doctors = snapshot.data!;
                if (_filterSpecialization != null) {
                  doctors = doctors.where((d) => d.specialization == _filterSpecialization).toList();
                }
                if (_filterHospital != null) {
                  doctors = doctors.where((d) => d.hospitalName == _filterHospital).toList();
                }
                if (_searchQuery.isNotEmpty) {
                  doctors = doctors.where((d) {
                    final name = d.name.toLowerCase();
                    final spec = (d.specialization ?? "").toLowerCase();
                    return name.contains(_searchQuery) || spec.contains(_searchQuery);
                  }).toList();
                }

                if (doctors.isEmpty) {
                  return const Center(child: Text("No doctors found matching your criteria."));
                }
                
                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: doctors.length,
                  itemBuilder: (context, index) {
                    final doctor = doctors[index];
                    return _buildDoctorCard(doctor);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDoctorCard(UserModel doctor) {
    return Container(
      height: 120,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: GestureDetector(
        onTap: () => _pickDateTimeAndBook(doctor),
        child: Stack(
          children: [
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
            Positioned(
              right: 0,
              bottom: 0,
              top: 0,
              child: ClipRRect(
                borderRadius: const BorderRadius.only(topRight: Radius.circular(20), bottomRight: Radius.circular(20)),
                child: doctor.avatarUrl != null
                    ? Image.network(doctor.avatarUrl!, width: 110, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.person, size: 80, color: Colors.white54))
                    : const SizedBox(width: 110, child: Icon(Icons.medical_services_outlined, size: 80, color: Colors.white54)),
              ),
            ),
            Positioned.fill(
              right: 110,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text("Dr. ${doctor.name}", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                    const SizedBox(height: 4),
                    Text(doctor.specialization ?? "Specialist", style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 14)),
                    const SizedBox(height: 4),
                    Text(doctor.hospitalName ?? "Clinic", style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 12)),
                  ],
                ),
              ),
            ),
            Positioned(
              bottom: 8,
              right: 120,
              child: Icon(Icons.arrow_forward_ios, color: Colors.white.withOpacity(0.5), size: 16),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildConfirmationSheet(UserModel doctor) {
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 16, 16, MediaQuery.of(context).viewInsets.bottom + 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text("Confirm Appointment", style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          Text("Request an appointment with Dr. ${doctor.name} for ${DateFormat('dd MMM yyyy, hh:mm a').format(_selectedDateTime!)}?"),
          const SizedBox(height: 16),
          TextField(controller: _notesController, decoration: const InputDecoration(labelText: "Notes (optional)")),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: OutlinedButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel"))),
              const SizedBox(width: 12),
              Expanded(child: ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text("Confirm Request"))),
            ],
          )
        ],
      ),
    );
  }
}

