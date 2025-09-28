// ignore_for_file: use_build_context_synchronously

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../providers/user_provider.dart';
import '../../services/firestore_service.dart';
import '../../services/image_upload_service.dart';
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
  bool _isUploadingImage = false;
  bool _isEditing = false;

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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final profile = context.read<UserProvider>().profile;
        if (profile != null) {
          _ageController.text = profile.age?.toString() ?? '';
          _weeksController.text = profile.weeksPregnant?.toString() ?? '';
          _selectedConditions.clear();
          _selectedConditions.addAll(profile.conditions);
          setState(() {});
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

  Future<void> _saveProfile({String? newAvatarUrl, bool exitEditMode = true}) async {
    if (_isEditing && !_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final userProvider = context.read<UserProvider>();
      final user = userProvider.user;
      if (user == null) throw Exception('User not found');

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
      if (exitEditMode) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Profile updated successfully!'),
          backgroundColor: AppColors.success,
        ));
      }
      if (mounted && exitEditMode) {
        setState(() => _isEditing = false);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Error updating profile: $e'),
        backgroundColor: AppColors.error,
      ));
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _pickAndUploadImage() async {
    setState(() => _isUploadingImage = true);
    try {
      final image = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 512, maxHeight: 512, imageQuality: 80,
      );
      if (image != null) {
        final imageUrl = await ImageUploadService().uploadImage(File(image.path));
        await _saveProfile(newAvatarUrl: imageUrl, exitEditMode: false);
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
      if (mounted) setState(() => _isUploadingImage = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
        actions: _isEditing
            ? [
                TextButton(
                  onPressed: _isLoading ? null : () {
                    _loadProfileData();
                    setState(() => _isEditing = false);
                  },
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: _isLoading ? null : () => _saveProfile(),
                  child: _isLoading
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('Save'),
                ),
              ]
            : [
                IconButton(
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: () => setState(() => _isEditing = true),
                  tooltip: 'Edit Profile',
                ),
              ],
      ),
      body: _isEditing ? _buildEditView() : _buildDisplayView(),
    );
  }

  // --- WIDGETS FOR DISPLAY (READ-ONLY) MODE ---

  Widget _buildDisplayView() {
    return Consumer<UserProvider>(
      builder: (context, userProvider, child) {
        final user = userProvider.user;
        final profile = userProvider.profile;

        if (user == null) {
          return const Center(child: CircularProgressIndicator());
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              _buildAvatar(), // Avatar is shared between views
              const SizedBox(height: 16),
              Text(
                user.name,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              Text(
                user.email,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 32),
              if (profile != null) _buildDisplayInfoCard(profile),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDisplayInfoCard(UserProfile profile) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          _buildDisplayTile(
            icon: Icons.cake_outlined,
            title: 'Age',
            subtitle: profile.age != null ? '${profile.age} years' : 'Not specified',
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),
          _buildDisplayTile(
            icon: Icons.child_care_outlined,
            title: 'Weeks Pregnant',
            subtitle: profile.weeksPregnant != null ? '${profile.weeksPregnant} weeks' : 'Not specified',
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),
          _buildDisplayConditions(profile.conditions),
        ],
      ),
    );
  }

  Widget _buildDisplayTile({required IconData icon, required String title, required String subtitle}) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primary),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
    );
  }

  Widget _buildDisplayConditions(List<String> conditions) {
    return ListTile(
      leading: const Icon(Icons.monitor_heart_outlined, color: AppColors.primary),
      title: const Text('Health Conditions', style: TextStyle(fontWeight: FontWeight.bold)),
      subtitle: conditions.isEmpty
          ? const Text('None specified')
          : Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Wrap(
                spacing: 8.0,
                runSpacing: 4.0,
                children: conditions.map((condition) => Chip(
                  label: Text(condition),
                  backgroundColor: AppColors.primary.withOpacity(0.1),
                  labelStyle: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w500),
                  side: BorderSide.none,
                )).toList(),
              ),
            ),
    );
  }

  // --- WIDGETS FOR EDITING MODE ---

  Widget _buildEditView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            _buildAvatar(),
            const SizedBox(height: 32),
            _buildBasicInfoForm(),
            const SizedBox(height: 24),
            _buildConditionsForm(),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar() {
    return Consumer<UserProvider>(
      builder: (context, userProvider, child) {
        final avatarUrl = userProvider.profile?.avatarUrl;
        return Stack(
          children: [
            CircleAvatar(
              radius: 50,
              backgroundColor: AppColors.primary.withOpacity(0.1),
              backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
              child: (_isUploadingImage)
                  ? const CircularProgressIndicator()
                  : (avatarUrl == null
                      ? const Icon(Icons.person, size: 50, color: AppColors.primary)
                      : null),
            ),
            if (_isEditing)
              Positioned(
                bottom: 0,
                right: 0,
                child: GestureDetector(
                  onTap: _isUploadingImage ? null : _pickAndUploadImage,
                  child: Container(
                    width: 32, height: 32,
                    decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                    child: const Icon(Icons.camera_alt, color: Colors.white, size: 18),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildBasicInfoForm() {
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
              decoration: const InputDecoration(labelText: 'Age', prefixIcon: Icon(Icons.cake_outlined)),
              validator: (v) => (v != null && v.isNotEmpty && (int.tryParse(v) ?? 0) < 18) ? 'Must be 18 or older' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _weeksController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Weeks Pregnant', prefixIcon: Icon(Icons.child_care_outlined)),
              validator: (v) => (v != null && v.isNotEmpty && (int.tryParse(v) ?? 0) > 42) ? 'Cannot be more than 42' : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConditionsForm() {
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
            Text('Select any conditions that apply.', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary)),
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
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}