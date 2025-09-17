// ignore_for_file: use_build_context_synchronously

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../providers/user_provider.dart';
import '../../services/firestore_service.dart';
import '../../services/image_upload_service.dart'; // Import the new service
import '../../models/user_model.dart';
import '../../utils/theme.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _ageController = TextEditingController();
  final _weeksController = TextEditingController();
  final List<String> _selectedConditions = [];
  bool _isLoading = false;
  bool _isUploadingImage = false; // New state for image upload

  final List<String> _availableConditions = [
    'Anemia', 'Diabetes', 'Hypertension', 'Gestational diabetes',
    'Morning sickness', 'Back pain', 'Swelling', 'Heartburn', 'Constipation', 'Other',
  ];

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  void _loadProfileData() {
    // Use post-frame callback to ensure context is available
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final userProvider = context.read<UserProvider>();
        final profile = userProvider.profile;

        if (profile != null) {
          _ageController.text = profile.age?.toString() ?? '';
          _weeksController.text = profile.weeksPregnant?.toString() ?? '';
          // Clear and add to avoid duplicates on rebuilds
          _selectedConditions.clear();
          _selectedConditions.addAll(profile.conditions);
        }
      }
    });
  }

  @override
  void dispose() {
    _ageController.dispose();
    _weeksController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile({String? newAvatarUrl}) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final userProvider = context.read<UserProvider>();
      final user = userProvider.user;
      if (user == null) throw Exception('User not found');

      // Use existing avatarUrl unless a new one is provided
      final finalAvatarUrl = newAvatarUrl ?? userProvider.profile?.avatarUrl;

      final updatedProfile = UserProfile(
        uid: user.uid,
        age: int.tryParse(_ageController.text),
        weeksPregnant: int.tryParse(_weeksController.text),
        conditions: _selectedConditions,
        avatarUrl: finalAvatarUrl,
      );

      await context.read<FirestoreService>().createOrUpdateProfile(updatedProfile);
      userProvider.updateProfile(updatedProfile);

      HapticFeedback.lightImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile updated successfully!'),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating profile: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _pickAndUploadImage() async {
    setState(() => _isUploadingImage = true);
    try {
      final picker = ImagePicker();
      final image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512, maxHeight: 512, imageQuality: 80,
      );

      if (image != null) {
        final imageFile = File(image.path);
        // Instantiate and use the upload service
        final imageUrl = await ImageUploadService().uploadImage(imageFile);

        // Save the profile with the new URL
        await _saveProfile(newAvatarUrl: imageUrl);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile picture updated!'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating image: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if(mounted) {
        setState(() => _isUploadingImage = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Main build method remains largely the same
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: AppColors.background,
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
              _buildProfileHeader(),
              const SizedBox(height: 32),
              _buildBasicInfo(),
              const SizedBox(height: 24),
              _buildConditionsSection(),
              // ... Rest of the UI remains the same
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Consumer<UserProvider>(
      builder: (context, userProvider, child) {
        final user = userProvider.user;
        final profile = userProvider.profile;

        return Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: AppColors.primary.withOpacity(0.1),
                      backgroundImage: profile?.avatarUrl != null
                          ? NetworkImage(profile!.avatarUrl!)
                          : null,
                      child: (profile?.avatarUrl == null && !_isUploadingImage)
                          ? const Icon(Icons.person, size: 50, color: AppColors.primary)
                          : (_isUploadingImage
                              ? const CircularProgressIndicator()
                              : null),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: _isUploadingImage ? null : _pickAndUploadImage,
                        child: Container(
                          width: 32, height: 32,
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.camera_alt, color: Colors.white, size: 18,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  user?.name ?? 'User',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                Text(
                  user?.email ?? '',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // _buildBasicInfo, _buildConditionsSection, and other widgets remain unchanged.
  // ... (Paste the rest of the unchanged widgets from your original code here)
  Widget _buildBasicInfo() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Basic Information', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            TextFormField(
              controller: _ageController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Age', prefixIcon: Icon(Icons.cake), suffixText: 'years'),
              validator: (value) {
                if (value != null && value.isNotEmpty) {
                  final age = int.tryParse(value);
                  if (age == null || age < 16 || age > 50) {
                    return 'Please enter a valid age (16-50)';
                  }
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _weeksController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Weeks Pregnant', prefixIcon: Icon(Icons.child_care), suffixText: 'weeks'),
              validator: (value) {
                if (value != null && value.isNotEmpty) {
                  final weeks = int.tryParse(value);
                  if (weeks == null || weeks < 1 || weeks > 42) {
                    return 'Please enter valid pregnancy weeks (1-42)';
                  }
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConditionsSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Health Conditions', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('Select any conditions that apply. This helps us provide personalized recommendations.', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary)),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8, runSpacing: 8,
              children: _availableConditions.map((condition) {
                final isSelected = _selectedConditions.contains(condition);
                return FilterChip(
                  label: Text(condition),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _selectedConditions.add(condition);
                      } else {
                        _selectedConditions.remove(condition);
                      }
                    });
                    HapticFeedback.selectionClick();
                  },
                  backgroundColor: Colors.grey.shade100,
                  selectedColor: AppColors.primary.withOpacity(0.2),
                  checkmarkColor: AppColors.primary,
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}
