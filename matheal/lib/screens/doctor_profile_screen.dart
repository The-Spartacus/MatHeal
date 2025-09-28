// ignore_for_file: use_build_context_synchronously
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../models/user_model.dart';
import '../providers/user_provider.dart';
import '../services/firestore_service.dart';
import '../services/image_upload_service.dart';
import '../utils/theme.dart';

class DoctorProfileScreen extends StatefulWidget {
  final UserModel doctor;
  const DoctorProfileScreen({super.key, required this.doctor});

  @override
  State<DoctorProfileScreen> createState() => _DoctorProfileScreenState();
}

class _DoctorProfileScreenState extends State<DoctorProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _specializationController;
  late TextEditingController _hospitalController;
  late TextEditingController _bioController;
  late TextEditingController _qualificationsController;
  late TextEditingController _experienceController;
  late Map<String, bool> _availableTimings;

  bool _isLoading = false;
  bool _isUploading = false;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    final profile = widget.doctor.doctorProfile;
    _specializationController = TextEditingController(text: profile?.specialization ?? '');
    _hospitalController = TextEditingController(text: profile?.hospitalName ?? '');
    _bioController = TextEditingController(text: profile?.bio ?? '');
    _qualificationsController = TextEditingController(text: profile?.qualifications ?? '');
    _experienceController = TextEditingController(text: profile?.yearsOfExperience?.toString() ?? '');
    _availableTimings = Map<String, bool>.from(profile?.availableTimings ??
        {'morning': false, 'afternoon': false, 'evening': false});
  }

  @override
  void dispose() {
    _specializationController.dispose();
    _hospitalController.dispose();
    _bioController.dispose();
    _qualificationsController.dispose();
    _experienceController.dispose();
    super.dispose();
  }

  Future<void> _pickAndUploadImage() async {
    setState(() => _isUploading = true);
    try {
      final image = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 80,
      );

      if (image != null) {
        final imageUrl = await ImageUploadService().uploadImage(File(image.path));
        // Pass the new URL to the save function but don't exit edit mode
        await _saveProfile(newAvatarUrl: imageUrl, exitEditMode: false);
        HapticFeedback.lightImpact();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Profile picture updated!'),
          backgroundColor: AppColors.success,
        ));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Error updating image: $e'),
        backgroundColor: AppColors.error,
      ));
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  Future<void> _saveProfile({String? newAvatarUrl, bool exitEditMode = true}) async {
    // Only validate if we are in edit mode and saving the form
    if (_isEditing && !_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final userProvider = context.read<UserProvider>();
      final firestoreService = context.read<FirestoreService>();
      
      final currentUser = userProvider.user;
      if (currentUser == null) throw Exception("User not found");

      final updatedDoctorProfile = (currentUser.doctorProfile ?? DoctorProfile(
          specialization: '', hospitalName: ''
      )).copyWith(
        specialization: _specializationController.text.trim(),
        hospitalName: _hospitalController.text.trim(),
        bio: _bioController.text.trim(),
        qualifications: _qualificationsController.text.trim(),
        yearsOfExperience: int.tryParse(_experienceController.text.trim()),
        availableTimings: _availableTimings,
        avatarUrl: newAvatarUrl ?? currentUser.avatarUrl,
      );

      await firestoreService.updateDoctorProfile(currentUser.uid, updatedDoctorProfile);
      final updatedUser = currentUser.copyWith(doctorProfile: updatedDoctorProfile);
      userProvider.setUser(updatedUser);

      // Exit edit mode upon successful save
      if (exitEditMode && mounted) {
        setState(() => _isEditing = false);
      }
      
      HapticFeedback.lightImpact();
      // Only show the general "updated" snackbar for form edits, not image uploads
      if (newAvatarUrl == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Profile updated successfully!'),
          backgroundColor: AppColors.success,
        ));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Error saving profile: $e'),
        backgroundColor: AppColors.error,
      ));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(''),
        elevation: 0,
        backgroundColor: Colors.transparent,
        actions: [
          TextButton(
            onPressed: (_isLoading || _isUploading) ? null : () {
              if (_isEditing) {
                _saveProfile();
              } else {
                setState(() => _isEditing = true);
              }
            },
            child: _isEditing
                ? _isLoading
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Save')
                : const Text('Edit'),
          ),
        ],
      ),
      // Conditionally build the UI based on the editing state
      body: _isEditing ? _buildEditView() : _buildDisplayView(),
    );
  }

  // --- DISPLAY MODE WIDGETS ---

  /// Builds the read-only profile card view.
  Widget _buildDisplayView() {
    return Consumer<UserProvider>(
      builder: (context, userProvider, child) {
        final doctor = userProvider.user;
        final profile = doctor?.doctorProfile;

        if (doctor == null) {
          return const Center(child: CircularProgressIndicator());
        }
        if (profile == null) {
          return const Center(child: Text("No profile data. Please edit to add details."));
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _buildAvatar(),
              const SizedBox(height: 16),
              Text(
                doctor.name,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              if (profile.specialization.isNotEmpty)
                Text(
                  profile.specialization,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(color: AppColors.primary),
                  textAlign: TextAlign.center,
                ),
              const SizedBox(height: 4),
              if (profile.hospitalName.isNotEmpty)
                Text(
                  profile.hospitalName,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.grey.shade700),
                  textAlign: TextAlign.center,
                ),
              const SizedBox(height: 24),
              _buildInfoCard(profile),
            ],
          ),
        );
      },
    );
  }

  /// Creates the main card holding the doctor's detailed information.
  Widget _buildInfoCard(DoctorProfile profile) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          // Only show bio if it exists
          if (profile.bio != null && profile.bio!.isNotEmpty) ...[
            _buildDisplayTile(
              icon: Icons.info_outline,
              title: 'About',
              subtitle: profile.bio!,
            ),
            const Divider(height: 1, indent: 16, endIndent: 16),
          ],
          // Only show qualifications if they exist
          if (profile.qualifications != null && profile.qualifications!.isNotEmpty) ...[
            _buildDisplayTile(
              icon: Icons.school_outlined,
              title: 'Qualifications',
              subtitle: profile.qualifications!,
            ),
            const Divider(height: 1, indent: 16, endIndent: 16),
          ],
          // Only show experience if it exists
          if (profile.yearsOfExperience != null && profile.yearsOfExperience! > 0) ...[
            _buildDisplayTile(
              icon: Icons.work_history_outlined,
              title: 'Experience',
              subtitle: '${profile.yearsOfExperience} years',
            ),
             const Divider(height: 1, indent: 16, endIndent: 16),
          ],
          _buildAvailabilitySection(profile.availableTimings),
        ],
      ),
    );
  }

  /// A helper to create consistent ListTiles for the display card.
  Widget _buildDisplayTile({required IconData icon, required String title, required String subtitle}) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primary),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
    );
  }

  /// A helper to display available time slots using chips.
  Widget _buildAvailabilitySection(Map<String, bool> timings) {
    final availableSlots = timings.entries.where((e) => e.value).map((e) => e.key).toList();

    return ListTile(
      leading: const Icon(Icons.watch_later_outlined, color: AppColors.primary),
      title: const Text('Availability', style: TextStyle(fontWeight: FontWeight.bold)),
      subtitle: availableSlots.isEmpty
          ? const Text('Timings not specified')
          : Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Wrap(
                spacing: 8.0,
                runSpacing: 4.0,
                children: availableSlots.map((slot) {
                  // Capitalize first letter
                  final slotText = slot[0].toUpperCase() + slot.substring(1); 
                  return Chip(
                    label: Text(slotText),
                    backgroundColor: AppColors.primary.withOpacity(0.1),
                    labelStyle: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w500),
                    side: BorderSide.none,
                  );
                }).toList(),
              ),
            ),
    );
  }
  
  // --- EDIT MODE WIDGETS ---

  /// Builds the editable form view.
  Widget _buildEditView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            _buildAvatar(),
            const SizedBox(height: 24),
            _buildProfileForm(),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar() {
    return Consumer<UserProvider>(
      builder: (context, userProvider, child) {
        final avatarUrl = userProvider.user?.avatarUrl;
        return Center(
          child: Stack(
            children: [
              CircleAvatar(
                radius: 50,
                backgroundColor: AppColors.primary.withOpacity(0.1),
                backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
                child: (_isUploading)
                    ? const CircularProgressIndicator(color: AppColors.primary)
                    : (avatarUrl == null
                        ? const Icon(Icons.medical_services, size: 50, color: AppColors.primary)
                        : null),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                // The edit icon is only visible when in edit mode
                child: Visibility(
                  visible: _isEditing,
                  child: GestureDetector(
                    onTap: _isUploading ? null : _pickAndUploadImage,
                    child: Container(
                      width: 32, height: 32,
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.camera_alt, color: Colors.white, size: 18),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildProfileForm() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextFormField(
              controller: _specializationController,
              enabled: _isEditing, // Controlled by edit mode
              decoration: const InputDecoration(labelText: 'Specialization *'),
              validator: (value) => value == null || value.isEmpty ? 'Cannot be empty' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _hospitalController,
              enabled: _isEditing, // Controlled by edit mode
              decoration: const InputDecoration(labelText: 'Hospital Name *'),
              validator: (value) => value == null || value.isEmpty ? 'Cannot be empty' : null,
            ),
            const SizedBox(height: 16),
             TextFormField(
              controller: _experienceController,
              enabled: _isEditing, // Controlled by edit mode
              decoration: const InputDecoration(labelText: 'Years of Experience'),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _bioController,
              enabled: _isEditing, // Controlled by edit mode
              decoration: const InputDecoration(labelText: 'Bio / About', alignLabelWithHint: true),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _qualificationsController,
              enabled: _isEditing, // Controlled by edit mode
              decoration: const InputDecoration(labelText: 'Qualifications (e.g., MBBS, MD)'),
            ),
            const SizedBox(height: 24),
            Text('Available Timings', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            CheckboxListTile(
              title: const Text('Morning (9 AM - 12 PM)'),
              value: _availableTimings['morning'] ?? false,
              // Checkboxes are only changeable in edit mode
              onChanged: _isEditing 
                  ? (bool? value) => setState(() => _availableTimings['morning'] = value!) 
                  : null,
            ),
            CheckboxListTile(
              title: const Text('Afternoon (1 PM - 5 PM)'),
              value: _availableTimings['afternoon'] ?? false,
              onChanged: _isEditing
                  ? (bool? value) => setState(() => _availableTimings['afternoon'] = value!)
                  : null,
            ),
            CheckboxListTile(
              title: const Text('Evening (6 PM - 9 PM)'),
              value: _availableTimings['evening'] ?? false,
              onChanged: _isEditing
                  ? (bool? value) => setState(() => _availableTimings['evening'] = value!)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}