// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:matheal/screens/auth/login_screen.dart';
import 'package:matheal/screens/features/book_appointment_screen.dart';
import 'package:matheal/screens/features/community_screen.dart';
import 'package:matheal/screens/features/medication_calendar_screen.dart';
import 'package:matheal/screens/features/user_appointments_screen.dart';
import 'package:matheal/services/auth_service.dart';
import 'package:matheal/services/firestore_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import '../providers/theme_provider.dart';
import '../utils/theme.dart';
import 'features/medicine_reminders_screen.dart';
import 'features/diet_suggestions_screen.dart';
import 'features/exercise_suggestions_screen.dart';
import 'features/chat_screen.dart';
import 'profile/profile_screen.dart';
import 'features/article_list_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  bool _notificationsEnabled = true;

  // Screens for each bottom nav tab
  late final List<Widget> _screens = [
    _buildHomeTab(), // Home tab
    const MedicineRemindersScreen(),
    const ChatScreen(),
    const ArticleListScreen(), // New Article tab
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }
  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _notificationsEnabled = prefs.getBool('notificationsEnabled') ?? true;
    });
  }

  Future<void> _saveNotificationPreference(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notificationsEnabled', value);
  }

  // 👇 Home dashboard tab
  Widget _buildHomeTab() {
    return RefreshIndicator(
      onRefresh: () async {
        // You can add logic here to refresh user data if needed
        final userProvider = context.read<UserProvider>();
        if (userProvider.user != null) {
          await context.read<FirestoreService>().getProfile(userProvider.user!.uid);
        }
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

  // --- build method and navigation remains the same ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color.fromARGB(0, 59, 169, 243),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Image.asset(
              "assets/images/logo.png",
              width: 25,
              height: 25,
            ),
          ),
        ),
        centerTitle: true,
        title: RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: "Mat",
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: const Color.fromRGBO(59, 170, 243, 1),
                      fontWeight: FontWeight.bold,
                      fontSize: 30,
                    ),
              ),
              TextSpan(
                text: "Heal",
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: const Color.fromARGB(255, 0, 0, 0),
                      fontWeight: FontWeight.bold,
                      fontSize: 30,
                    ),
              ),
            ],
          ),
        ),
        actions: [
          Builder(
            builder: (context) {
              return IconButton(
                icon: const Icon(
                    Icons.menu), // Changed icon to settings
                onPressed: () {
                  Scaffold.of(context).openEndDrawer(); // Opens the end drawer
                },
              );
            },
          ),
        ],
      ),

      endDrawer: _buildDrawer(context), // 👉 Added Drawer

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
            icon: Icon(Icons.home),
            label: "Home",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.alarm),
            label: "Reminders",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.smart_toy_outlined),
            label: "AI",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.article),
            label: "Articles",
          ),
        ],
      ),
    );
  }
  // --- welcome card (UPDATED) ---
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
                colors: [Color.fromARGB(255, 50, 138, 182), Color.fromARGB(255, 142, 221, 226)],
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
                          ? const Icon(Icons.person,
                              color: Colors.white, size: 30)
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
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
                        MaterialPageRoute(
                            builder: (context) => const ProfileScreen()),
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
  // All other widgets (_buildDrawer, _buildFeatureGrid, etc.) remain the same.
  // ... (Paste the rest of the unchanged widgets from your original code here)
  Widget _buildDrawer(BuildContext context) {
  return Drawer(
    child: Column(
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 30.0),
          child: Container(
            height: kToolbarHeight,
            width: double.infinity,
            color: const Color.fromARGB(255, 253, 254, 255),
            alignment: Alignment.center,
            child: const Text('Settings', style: TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold)),
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(8),
            children: [
              _buildSettingsSection('Profile', [_buildProfileTile(context)]),
              _buildSettingsSection('Preferences', [_buildThemeToggle(), _buildNotificationToggle()]),
              const SizedBox(height: 16),
              _buildSettingsSection('Account', [_buildLogoutTile(context)]),
            ],
          ),
        ),
      ],
    ),
  );
}

Widget _buildProfileTile(BuildContext context) {
  return ListTile(
    leading: const Icon(Icons.person, color: AppColors.primary),
    title: const Text('Profile'),
    onTap: () {
      Navigator.of(context).push(MaterialPageRoute(builder: (context) => const ProfileScreen()));
    },
  );
}

Widget _buildSettingsSection(String title, List<Widget> children) {
  return Card(
    elevation: 1,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
          const Divider(height: 16, thickness: 1),
          ...children,
        ],
      ),
    ),
  );
}

Widget _buildThemeToggle() {
  return Consumer<ThemeProvider>(
    builder: (context, themeProvider, child) {
      return SwitchListTile(
        title: const Text('Dark Mode'),
        subtitle: const Text('Switch between light and dark theme'),
        value: themeProvider.isDarkMode,
        onChanged: (_) => themeProvider.toggleTheme(),
        secondary: Icon(themeProvider.isDarkMode ? Icons.dark_mode : Icons.light_mode, color: AppColors.primary),
      );
    },
  );
}

Widget _buildNotificationToggle() {
  return SwitchListTile(
    title: const Text('Notifications'),
    subtitle: const Text('Receive health reminders and updates'),
    value: _notificationsEnabled,
    onChanged: (value) {
      setState(() => _notificationsEnabled = value);
      _saveNotificationPreference(value);
    },
    secondary: const Icon(Icons.notifications, color: AppColors.primary),
  );
}

Widget _buildLogoutTile(BuildContext context) {
  return ListTile(
    leading: const Icon(Icons.logout, color: AppColors.error),
    title: const Text('Logout', style: TextStyle(color: AppColors.error)),
    onTap: () async {
      final shouldLogout = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Logout'),
          content: const Text('Are you sure you want to logout?'),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
              child: const Text('Logout'),
            ),
          ],
        ),
      );

      if (shouldLogout == true && context.mounted) {
        await context.read<AuthService>().signOut();
        context.read<UserProvider>().clear();
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
        );
      }
    },
  );
}

/// A simple data model for a feature card on the home screen.

Widget _buildFeatureGrid(BuildContext context) {
  final titleStyle = Theme.of(context).textTheme.titleSmall?.copyWith(
        fontWeight: FontWeight.bold,
        color: const Color.fromARGB(255, 85, 172, 255),
      );

  final subtitleStyle = Theme.of(context).textTheme.bodySmall?.copyWith(
        color: const Color.fromARGB(255, 148, 199, 247),
      );

  final features = [
    _Feature(
      title: 'Medicine Reminders',
      subtitle: 'Track your medications',
      icon: Icons.medication_outlined,
      backgroundColor: const Color(0xFFE3F2FD),
      iconColor: const Color(0xFF1976D2),
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const MedicineRemindersScreen())),
    ),
    _Feature(
      title: 'Medication History',
      subtitle: 'View consumption log',
      icon: Icons.history_edu_outlined,
      backgroundColor: const Color(0xFFF3E5F5),
      iconColor: const Color(0xFF7B1FA2),
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const MedicationCalendarScreen())),
    ),
    _Feature(
      title: 'Your Appointments',
      subtitle: 'Manage scheduled visits',
      icon: Icons.calendar_month_outlined,
      backgroundColor: const Color(0xFFE8F5E8),
      iconColor: const Color(0xFF388E3C),
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const UserAppointmentsScreen())),
    ),
    _Feature(
      title: 'Book an Appointment',
      subtitle: 'Find a specialist',
      icon: Icons.edit_calendar_outlined,
      backgroundColor: const Color(0xFFE0F7FA),
      iconColor: const Color(0xFF00838F),
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const BookAppointmentScreen())),
    ),
    _Feature(
      title: 'MatCommunity',
      subtitle: 'Share your moments',
      icon: Icons.connect_without_contact_outlined,
      backgroundColor: const Color(0xFFFFF3E0),
      iconColor: const Color(0xFFF57C00),
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const CommunityScreen())),
    ),
    _Feature(
      title: 'Diet Suggestions',
      subtitle: 'Personalized nutrition',
      icon: Icons.restaurant_menu_outlined,
      backgroundColor: const Color(0xFFF1F8E9),
      iconColor: const Color(0xFF689F38),
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const DietSuggestionsScreen())),
    ),
    _Feature(
      title: 'Exercise Guide',
      subtitle: 'Pregnancy-safe workouts',
      icon: Icons.fitness_center_outlined,
      backgroundColor: const Color(0xFFE0F2F1),
      iconColor: const Color(0xFF00695C),
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ExerciseSuggestionsScreen())),
    ),
     _Feature(
      title: 'AI Health Assistant',
      subtitle: 'Ask health questions',
      icon: Icons.assistant_outlined,
      backgroundColor: const Color(0xFFEDE7F6),
      iconColor: const Color(0xFF5E35B1),
      onTap: () {}, // Add navigation later
    ),
  ];

  // The GridView is replaced with a horizontally scrolling ListView.
  return SizedBox(
    height: 170, // Constrain the height of the horizontal list
    child: ListView.separated(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16), // Padding at the start and end of the list
      itemCount: features.length,
      separatorBuilder: (context, index) => const SizedBox(width: 12), // Adds space between items
      itemBuilder: (context, index) {
        final feature = features[index];
        // Each item in the list is now a SizedBox with a fixed width.
        return SizedBox(
          width: 150,
          child: Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: feature.onTap,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: feature.backgroundColor,
                    child: Icon(feature.icon, color: feature.iconColor, size: 28),
                  ),
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: Text(
                      feature.title,
                      style: titleStyle,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: Text(
                      feature.subtitle,
                      style: subtitleStyle,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    ),
  );
}
}
class _Feature {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color backgroundColor;
  final Color iconColor;
  final VoidCallback onTap;

  const _Feature({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.backgroundColor,
    required this.iconColor,
    required this.onTap,
  });
}

