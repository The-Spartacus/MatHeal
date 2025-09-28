import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:provider/provider.dart';

import '../../../models/user_model.dart'; // Make sure this path is correct for your project
import '../../../services/firestore_service.dart';

class DoctorDetailScreen extends StatelessWidget {
  final UserModel doctor;
  const DoctorDetailScreen({super.key, required this.doctor});

  /// Shows a dialog for the user to add or update their rating for the doctor.
  void _showRatingDialog(BuildContext context, DoctorRating? existingRating) {
    double ratingValue = existingRating?.rating ?? 3.0;
    final commentController = TextEditingController(text: existingRating?.comment ?? '');
    final user = FirebaseAuth.instance.currentUser;

    // Ensure user is logged in before showing the dialog
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("You must be logged in to rate.")));
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(existingRating == null ? "Rate Dr. ${doctor.name}" : "Update Your Rating"),
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
                itemBuilder: (context, _) => const Icon(Icons.star, color: Colors.amber),
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
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
                            final firestoreService = context.read<FirestoreService>();
              
              // 1. Fetch the current user's profile from Firestore to get their name
              final currentUserModel = await firestoreService.getUser(user.uid);
              final patientName = currentUserModel?.name ?? "Anonymous";
              final newRating = DoctorRating(
                id: existingRating?.id, // FirestoreService handles if this is null
                doctorId: doctor.uid,
                userId: user.uid,
                rating: ratingValue,
                comment: commentController.text.trim(),
                createdAt: DateTime.now(),
                // Display name of the user is saved here
                patientName: patientName,
              );
              await FirestoreService().addOrUpdateDoctorRating(newRating);
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Thank you for your feedback!")));
            },
            child: const Text("Submit"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final firestoreService = FirestoreService();
    final currentUser = FirebaseAuth.instance.currentUser;
    final profile = doctor.doctorProfile;

    return Scaffold(
      appBar: AppBar(title: Text("Dr. ${doctor.name}")),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildDoctorHeader(context),
          const SizedBox(height: 24),

          if (profile != null) ...[
            _buildDetailsCard(context, profile),
            const SizedBox(height: 24),
          ],
          
          Text("Patient Reviews", style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),

          // Button to add/edit review is restored here
          if (currentUser != null)
            FutureBuilder<DoctorRating?>(
              future: firestoreService.getUserRatingForDoctor(currentUser.uid, doctor.uid),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: Padding(
                    padding: EdgeInsets.all(8.0),
                    child: CircularProgressIndicator(),
                  ));
                }
                final existingRating = snapshot.data;
                return Center(
                  child: ElevatedButton.icon(
                    onPressed: () => _showRatingDialog(context, existingRating),
                    icon: Icon(existingRating == null ? Icons.add_comment_outlined : Icons.edit_outlined),
                    label: Text(existingRating == null ? "Add Your Review" : "Edit Your Review"),
                  ),
                );
              },
            ),
          const SizedBox(height: 16),

          // Stream of existing reviews
          StreamBuilder<List<DoctorRating>>(
            stream: firestoreService.getDoctorRatings(doctor.uid),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Center(child: Text("No reviews yet.")));
              }
              final ratings = snapshot.data!;
              return Column(
                children: ratings
                    .map((r) => Card(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          child: ListTile(
                            title: Text(r.patientName),
                            subtitle: r.comment != null && r.comment!.isNotEmpty
                                ? Text(r.comment!)
                                : null,
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(r.rating.toStringAsFixed(1)),
                                const SizedBox(width: 4),
                                const Icon(Icons.star, color: Colors.amber, size: 16),
                              ],
                            ),
                          ),
                        ))
                    .toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  /// Builds the header section with avatar, name, and rating.
  Widget _buildDoctorHeader(BuildContext context) {
    final profile = doctor.doctorProfile;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        CircleAvatar(
          radius: 50,
          backgroundImage: profile?.avatarUrl != null ? NetworkImage(profile!.avatarUrl!) : null,
          child: profile?.avatarUrl == null
              ? const Icon(Icons.person, size: 50)
              : null,
        ),
        const SizedBox(height: 16),
        Text(
          doctor.name,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        if (profile?.specialization != null && profile!.specialization.isNotEmpty)
          Text(
            profile.specialization,
            style: Theme.of(context).textTheme.titleMedium,
            textAlign: TextAlign.center,
          ),
        const SizedBox(height: 4),
        if (profile?.hospitalName != null && profile!.hospitalName.isNotEmpty)
          Text(
            profile.hospitalName,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.grey.shade600),
            textAlign: TextAlign.center,
          ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.star, color: Colors.amber, size: 20),
            const SizedBox(width: 4),
            Text(
              profile?.averageRating.toStringAsFixed(1) ?? 'N/A',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(width: 8),
            Text(
              '(${profile?.totalReviews ?? 0} reviews)',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey.shade600),
            ),
          ],
        ),
      ],
    );
  }

  /// Builds a card with doctor's qualifications, experience, and availability.
  Widget _buildDetailsCard(BuildContext context, DoctorProfile profile) {
    final availableSlots = profile.availableTimings.entries.where((e) => e.value).map((e) => e.key).toList();
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (profile.bio != null && profile.bio!.isNotEmpty) ...[
              Text("About", style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(profile.bio!),
              const Divider(height: 24),
            ],
            if (profile.qualifications != null && profile.qualifications!.isNotEmpty) ...[
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.school_outlined, color: Colors.blueGrey),
                title: const Text("Qualifications", style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(profile.qualifications!),
              ),
            ],
            if (profile.yearsOfExperience != null && profile.yearsOfExperience! > 0) ...[
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.work_history_outlined, color: Colors.blueGrey),
                title: const Text("Experience", style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('${profile.yearsOfExperience} years'),
              ),
            ],
            if (availableSlots.isNotEmpty) ...[
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.watch_later_outlined, color: Colors.blueGrey),
                title: const Text("Availability", style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Wrap(
                    spacing: 8.0,
                    runSpacing: 4.0,
                    children: availableSlots.map((slot) => Chip(
                      label: Text(slot[0].toUpperCase() + slot.substring(1)),
                      backgroundColor: Colors.teal.shade50,
                      labelStyle: TextStyle(color: Colors.teal.shade800),
                      side: BorderSide.none,
                    )).toList(),
                  ),
                ),
              ),
            ]
          ],
        ),
      ),
    );
  }
}