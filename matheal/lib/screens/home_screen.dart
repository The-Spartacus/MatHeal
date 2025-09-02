// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import '../utils/theme.dart';
import 'features/medicine_reminders_screen.dart';
import 'features/consumed_medicines_screen.dart';
import 'features/appointments_screen.dart';
import 'features/feeding_reminders_screen.dart';
import 'features/diet_suggestions_screen.dart';
import 'features/exercise_suggestions_screen.dart';
import 'features/chat_screen.dart';
import 'profile/profile_screen.dart';
import 'settings/settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  // Screens for each bottom nav tab
  late final List<Widget> _screens = [
    _buildHomeTab(), // Home tab = original dashboard with feature grid
    const MedicineRemindersScreen(),
    const ChatScreen(),
    const SettingsScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  // 👇 Home dashboard tab
  Widget _buildHomeTab() {
    return RefreshIndicator(
      onRefresh: () async {
        await Future.delayed(const Duration(seconds: 1));
      },
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildWelcomeCard(),
            const SizedBox(height: 24),
            Text(
              'Your Health Hub',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
            ),
            const SizedBox(height: 16),
            _buildFeatureGrid(context),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.health_and_safety,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'MatHeal',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.background,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Notifications feature coming soon')),
              );
            },
          ),
          IconButton( 
            icon: const Icon(Icons.account_circle_outlined),
             onPressed: () { 
              Navigator.of(context).push( 
                MaterialPageRoute(builder: (context) => const ProfileScreen()), 
                ); 
              }, 
          ),
        ],
      ),
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: Colors.blueAccent,
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            label: "Home",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.medication_outlined),
            label: "Reminders",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.smart_toy_outlined),
            label: "AI",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_outlined),
            label: "Settings",
          ),
        ],
      ),
    );
  }

  // --- welcome card
  Widget _buildWelcomeCard() {
    return Consumer<UserProvider>(
      builder: (context, userProvider, child) {
        final user = userProvider.user;
        final profile = userProvider.profile;

        return Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primary, Color(0xFF66BB6A)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 25,
                      backgroundColor: Colors.white.withOpacity(0.2),
                      backgroundImage: profile?.avatarUrl != null
                          ? NetworkImage(profile!.avatarUrl!)
                          : null,
                      child: profile?.avatarUrl == null
                          ? const Icon(Icons.person, color: Colors.white, size: 30)
                          : null,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Welcome back,',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            user?.name ?? 'User',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (profile?.weeksPregnant != null) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Week ${profile!.weeksPregnant} of pregnancy',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ] else ...[
                  TextButton.icon(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (context) => const ProfileScreen()),
                      );
                    },
                    icon: const Icon(Icons.edit, color: Colors.white, size: 16),
                    label: const Text(
                      'Complete your profile',
                      style: TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  // --- feature grid
  Widget _buildFeatureGrid(BuildContext context) {
    final features = [
      FeatureCard(
        title: 'Medicine Reminders',
        subtitle: 'Track your medications',
        icon: Icons.medication,
        color: const Color(0xFFE3F2FD),
        iconColor: const Color(0xFF1976D2),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (context) => const MedicineRemindersScreen()),
        ),
      ),
      FeatureCard(
        title: 'Consumed Medicines',
        subtitle: 'View medication history',
        icon: Icons.history,
        color: const Color(0xFFF3E5F5),
        iconColor: const Color(0xFF7B1FA2),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (context) => const ConsumedMedicinesScreen()),
        ),
      ),
      FeatureCard(
        title: 'Doctor Appointments',
        subtitle: 'Schedule & track visits',
        icon: Icons.local_hospital,
        color: const Color(0xFFE8F5E8),
        iconColor: const Color(0xFF388E3C),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (context) => const AppointmentsScreen()),
        ),
      ),
      FeatureCard(
        title: 'Feeding Reminders',
        subtitle: 'Nutrition tracking',
        icon: Icons.restaurant,
        color: const Color(0xFFFFF3E0),
        iconColor: const Color(0xFFF57C00),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (context) => const FeedingRemindersScreen()),
        ),
      ),
      FeatureCard(
        title: 'Diet Suggestions',
        subtitle: 'Personalized nutrition',
        icon: Icons.dining,
        color: const Color(0xFFF1F8E9),
        iconColor: const Color(0xFF689F38),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (context) => const DietSuggestionsScreen()),
        ),
      ),
      FeatureCard(
        title: 'Exercise Suggestions',
        subtitle: 'Safe workouts',
        icon: Icons.fitness_center,
        color: const Color(0xFFE0F2F1),
        iconColor: const Color(0xFF00695C),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (context) => const ExerciseSuggestionsScreen()),
        ),
      ),
      FeatureCard(
        title: 'AI Health Assistant',
        subtitle: 'Ask health questions',
        icon: Icons.psychology,
        color: const Color(0xFFFCE4EC),
        iconColor: const Color(0xFFC2185B),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (context) => const ChatScreen()),
        ),
      ),
      FeatureCard(
        title: 'Profile Settings',
        subtitle: 'Manage your info',
        icon: Icons.person,
        color: const Color(0xFFE8EAF6),
        iconColor: const Color(0xFF3F51B5),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (context) => const ProfileScreen()),
        ),
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.9,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: features.length,
      itemBuilder: (context, index) {
        final feature = features[index];
        return Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: InkWell(
            onTap: feature.onTap,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: feature.color,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      feature.icon,
                      color: feature.iconColor,
                      size: 32,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    feature.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: AppColors.textPrimary,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    feature.subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class FeatureCard {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final Color iconColor;
  final VoidCallback onTap;

  FeatureCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.iconColor,
    required this.onTap,
  });
}
