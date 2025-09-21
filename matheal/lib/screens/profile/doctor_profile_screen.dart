// ignore_for_file: use_build_context_synchronously
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../models/user_model.dart';

import '../../providers/user_provider.dart';

import '../../services/firestore_service.dart';

import '../../services/image_upload_service.dart';

import '../../utils/theme.dart';


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

  bool _isLoading = false;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _specializationController = TextEditingController(text: widget.doctor.doctorProfile?.specialization ?? '');
    _hospitalController = TextEditingController(text: widget.doctor.doctorProfile?.hospitalName ?? '');
  }

  @override
  void dispose() {
    _specializationController.dispose();
    _hospitalController.dispose();
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
        await _saveProfile(newAvatarUrl: imageUrl);
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

  Future<void> _saveProfile({String? newAvatarUrl}) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final userProvider = context.read<UserProvider>();
      final firestoreService = context.read<FirestoreService>();
      
      // Get the most current user data from the provider
      final currentUser = userProvider.user;
      if (currentUser == null) throw Exception("User not found");

      // Update the DoctorProfile using the latest data from the provider
      final updatedDoctorProfile = currentUser.doctorProfile?.copyWith(
            specialization: _specializationController.text,
            hospitalName: _hospitalController.text,
            avatarUrl: newAvatarUrl ?? currentUser.avatarUrl, // Use provider's avatarUrl as fallback
          ) ??
          DoctorProfile(
            specialization: _specializationController.text,
            hospitalName: _hospitalController.text,
            avatarUrl: newAvatarUrl,
          );

      await firestoreService.updateDoctorProfile(currentUser.uid, updatedDoctorProfile);

      // Create a new UserModel with the updated DoctorProfile and set it in the provider
      final updatedUser = currentUser.copyWith(doctorProfile: updatedDoctorProfile);
      userProvider.setUser(updatedUser);

      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Profile updated successfully!'),
        backgroundColor: AppColors.success,
      ));
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
        title: const Text('Edit Doctor Profile'),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : () => _saveProfile(),
            child: _isLoading
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Save'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _buildAvatar(),
              const SizedBox(height: 24),
              _buildFormFields(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar() {
    // Using a Consumer to get the latest profile data from the provider
    return Consumer<UserProvider>(
      builder: (context, userProvider, child) {
      final currentDoctor = userProvider.user; // Get the most up-to-date doctor model
      return Center(
        child: Stack(
          children: [
            CircleAvatar(
              radius: 50,
              backgroundColor: AppColors.primary.withOpacity(0.1),
              backgroundImage: currentDoctor?.avatarUrl != null
                  ? NetworkImage(currentDoctor!.avatarUrl!)
                  : null,
              child: (_isUploading)
                  ? const CircularProgressIndicator()
                  : (currentDoctor?.avatarUrl == null
                      ? const Icon(Icons.medical_services, size: 50, color: AppColors.primary)
                      : null),
            ),
            Positioned(
              bottom: 0,
              right: 0,
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
          ],
        ),
      );
      }
    );
  }

  Widget _buildFormFields() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextFormField(
              controller: _specializationController,
              decoration: const InputDecoration(labelText: 'Specialization'),
              validator: (value) => value == null || value.isEmpty ? 'Cannot be empty' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _hospitalController,
              decoration: const InputDecoration(labelText: 'Hospital Name'),
              validator: (value) => value == null || value.isEmpty ? 'Cannot be empty' : null,
            ),
          ],
        ),
      ),
    );
  }
}

