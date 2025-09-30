// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:intl/intl.dart';
import 'package:matheal/models/appointment_model.dart';
import 'package:matheal/services/appointment_service.dart';
import 'package:matheal/services/notification_service.dart';
import 'package:provider/provider.dart';

import '../../../models/user_model.dart';
import '../../../services/firestore_service.dart';
import '../../../utils/theme.dart';

class DoctorDetailScreen extends StatefulWidget {
  final UserModel doctor;
  const DoctorDetailScreen({super.key, required this.doctor});

  @override
  State<DoctorDetailScreen> createState() => _DoctorDetailScreenState();
}

class _DoctorDetailScreenState extends State<DoctorDetailScreen> {
  final AppointmentService _appointmentService = AppointmentService();
  final _notesController = TextEditingController();

  DateTime _selectedDate = DateTime.now();
  String? _selectedTimeSlot;

  // --- ALL YOUR EXISTING LOGIC METHODS ARE PRESERVED ---

  Future<void> _bookAppointment() async {
    if (_selectedTimeSlot == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please select a time slot.")));
      return;
    }

    final userId = FirebaseAuth.instance.currentUser!.uid;

    // Combine selected date and time
    final timeParts = _selectedTimeSlot!.split(RegExp(r'[:\s]')); // Handles "10:00 AM"
    int hour = int.parse(timeParts[0]);
    final int minute = int.parse(timeParts[1]);
    if (timeParts.last.toUpperCase() == 'PM' && hour != 12) {
      hour += 12;
    }
    if (timeParts.last.toUpperCase() == 'AM' && hour == 12) {
      hour = 0; // Midnight case
    }

    final finalDateTime = DateTime(_selectedDate.year, _selectedDate.month,
        _selectedDate.day, hour, minute);

    final appointment = Appointment(
      id: '', // Firestore will generate this
      userId: userId,
      doctorId: widget.doctor.uid,
      dateTime: finalDateTime,
      status: "pending",
      notes: _notesController.text,
    );

    await _appointmentService.createAppointment(appointment);

    // Schedule a reminder for the day before
    await NotificationService.scheduleAppointment(
      id: UniqueKey().hashCode,
      title: "Appointment Reminder",
      body: "Your appointment with Dr. ${widget.doctor.name} is tomorrow.",
      scheduledDate: finalDateTime.subtract(const Duration(days: 1)),
    );

    ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Appointment requested successfully!")));
  }

  void _showBookingConfirmationSheet() {
    if (_selectedTimeSlot == null) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(
            16, 16, 16, MediaQuery.of(context).viewInsets.bottom + 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("Confirm Appointment",
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            Text(
                "Request an appointment with Dr. ${widget.doctor.name} for ${DateFormat('dd MMM yyyy').format(_selectedDate)} at $_selectedTimeSlot?"),
            const SizedBox(height: 16),
            TextField(
                controller: _notesController,
                decoration: const InputDecoration(labelText: "Notes (optional)")),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                    child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text("Cancel"))),
                const SizedBox(width: 12),
                Expanded(
                    child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context); // Close the sheet first
                          _bookAppointment();
                        },
                        child: const Text("Confirm Request"))),
              ],
            )
          ],
        ),
      ),
    );
  }

  void _showRatingDialog(BuildContext context, DoctorRating? existingRating) {
    // This method's internal logic is completely unchanged.
    double ratingValue = existingRating?.rating ?? 3.0;
    final commentController =
        TextEditingController(text: existingRating?.comment ?? '');
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("You must be logged in to rate.")),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(existingRating == null
            ? "Rate Dr. ${widget.doctor.name}"
            : "Update Your Rating"),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RatingBar.builder(
                initialRating: ratingValue,
                minRating: 1,
                direction: Axis.horizontal,
                itemCount: 5,
                itemPadding: const EdgeInsets.symmetric(horizontal: 4.0),
                itemBuilder: (context, _) =>
                    const Icon(Icons.star, color: Colors.amber),
                onRatingUpdate: (rating) => ratingValue = rating,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: commentController,
                decoration: const InputDecoration(
                  labelText: "Comment (optional)",
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              final firestoreService = context.read<FirestoreService>();
              final currentUserModel = await firestoreService.getUser(user.uid);
              final patientName = currentUserModel?.name ?? "Anonymous";
              final newRating = DoctorRating(
                id: existingRating?.id,
                doctorId: widget.doctor.uid,
                userId: user.uid,
                rating: ratingValue,
                comment: commentController.text.trim(),
                createdAt: DateTime.now(),
                patientName: patientName,
              );
              await firestoreService.addOrUpdateDoctorRating(newRating);
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Thank you for your feedback!")),
              );
            },
            child: const Text("Submit"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              _buildSliverAppBar(),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildDetailsSection(),
                      const SizedBox(height: 24),
                      _buildScheduleSection(),
                      const SizedBox(height: 24),
                      _buildAvailableSlotsSection(),
                      const SizedBox(height: 24),
                      _buildReviewsSection(),
                      const SizedBox(
                          height: 100), // Space for the floating button
                    ],
                  ),
                ),
              ),
            ],
          ),
          _buildBookNowButton(),
        ],
      ),
    );
  }
  
  // --- UI HELPER WIDGETS ---

  Widget _buildSliverAppBar() {
    final profile = widget.doctor.doctorProfile;
    return SliverAppBar(
      expandedHeight: 250.0,
      backgroundColor: Colors.white,
      elevation: 0,
      pinned: true,
      stretch: true,
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            Image.network(
              profile?.avatarUrl ?? 'https://via.placeholder.com/400',
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) =>
                  Container(color: Colors.grey.shade200),
            ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black.withOpacity(0.7)],
                ),
              ),
            ),
            Positioned(
              bottom: 16,
              left: 16,
              right: 16,
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Dr. ${widget.doctor.name}",
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 24,
                          ),
                        ),
                        Text(
                          profile?.specialization ?? 'Specialist',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: Colors.white.withOpacity(0.2),
                        child: IconButton(
                          icon: const Icon(Icons.chat_bubble_outline, color: Colors.white),
                          onPressed: () {},
                        ),
                      ),
                      const SizedBox(width: 8),
                       CircleAvatar(
                        backgroundColor: Colors.white.withOpacity(0.2),
                        child: IconButton(
                          icon: const Icon(Icons.call_outlined, color: Colors.white),
                          onPressed: () {},
                        ),
                      ),
                    ],
                  )
                ],
              ),
            )
          ],
        ),
      ),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => Navigator.of(context).pop(),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 16.0),
          child: CircleAvatar(
            backgroundColor: Colors.white.withOpacity(0.2),
            child: IconButton(
              icon: const Icon(Icons.favorite_border, color: Colors.white),
              onPressed: () {},
            ),
          ),
        ),
      ],
    );
  }
  
  Widget _buildDetailsSection() {
    final profile = widget.doctor.doctorProfile;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Details",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          profile?.bio ?? "No bio available.",
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(color: Colors.grey.shade600, height: 1.5),
        ),
      ],
    );
  }

  Widget _buildScheduleSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Schedules",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 60,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: 100,
            separatorBuilder: (context, index) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final date = DateTime.now().add(Duration(days: index));
              final isSelected = date.day == _selectedDate.day && date.month == _selectedDate.month;
              return GestureDetector(
                onTap: () => setState(() => _selectedDate = date),
                child: Container(
                  width: 50,
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primary : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        DateFormat('E').format(date).substring(0, 3),
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.black54,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        DateFormat('d').format(date),
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.black,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildAvailableSlotsSection() {
    final availableSlots = ['10:00 AM', '11:00 AM', '01:00 PM', '02:00 PM', '04:00 PM'];
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Available Slot - ${DateFormat('d MMMM, EEEE').format(_selectedDate)}",
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12.0,
          runSpacing: 12.0,
          children: availableSlots.map((slot) {
            final isSelected = _selectedTimeSlot == slot;
            return ChoiceChip(
              label: Text(slot),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  _selectedTimeSlot = selected ? slot : null;
                });
              },
              backgroundColor: Colors.grey.shade100,
              selectedColor: AppColors.primary.withOpacity(0.2),
              labelStyle: TextStyle(
                color: isSelected ? AppColors.primary : Colors.black,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(
                  color: isSelected ? AppColors.primary : Colors.grey.shade300,
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildReviewsSection() {
    final firestoreService = context.read<FirestoreService>();
    final currentUser = FirebaseAuth.instance.currentUser;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Patient Reviews",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        if (currentUser != null)
          FutureBuilder<DoctorRating?>(
            future: firestoreService.getUserRatingForDoctor(currentUser.uid, widget.doctor.uid),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              final existingRating = snapshot.data;
              return Center(
                child: OutlinedButton.icon(
                  onPressed: () => _showRatingDialog(context, existingRating),
                  icon: Icon(existingRating == null ? Icons.add_comment_outlined : Icons.edit_outlined),
                  label: Text(existingRating == null ? "Add Your Review" : "Edit Your Review"),
                ),
              );
            },
          ),
        const SizedBox(height: 16),
        StreamBuilder<List<DoctorRating>>(
          stream: firestoreService.getDoctorRatings(widget.doctor.uid),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(child: Text("No reviews yet. Be the first!"));
            }
            final ratings = snapshot.data!;
            return ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: ratings.length,
              separatorBuilder: (context, index) => const Divider(),
              itemBuilder: (context, index) {
                final r = ratings[index];
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(r.patientName, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: r.comment != null && r.comment!.isNotEmpty ? Text(r.comment!) : null,
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(r.rating.toStringAsFixed(1)),
                      const SizedBox(width: 4),
                      const Icon(Icons.star, color: Colors.amber, size: 16),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }


  Widget _buildBookNowButton() {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        padding: const EdgeInsets.all(16.0),
        color: Colors.white.withOpacity(0.9),
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _selectedTimeSlot == null
                ? null
                : _showBookingConfirmationSheet,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              "Book Now",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ),
    );
  }
}
