import 'package:flutter/material.dart';
import 'package:matheal/providers/theme_provider.dart';
import 'package:matheal/providers/user_provider.dart';
import 'package:matheal/screens/auth/login_screen.dart';
import 'package:matheal/screens/doctor_profile_screen.dart';
import 'package:matheal/services/auth_service.dart';
import 'package:provider/provider.dart';
import '../../../models/user_model.dart';
import 'doctor_appointments_screen.dart';
import 'doctor_article_screen.dart';
import '../../../utils/theme.dart';

class DoctorHomeScreen extends StatefulWidget {
  final UserModel doctor;
  const DoctorHomeScreen({Key? key, required this.doctor}) : super(key: key);

  @override
  State<DoctorHomeScreen> createState() => _DoctorHomeScreenState();
}

class _DoctorHomeScreenState extends State<DoctorHomeScreen> {
  int _selectedIndex = 0;

  late final List<Widget> _screens = [
    _buildHomeTab(),
    DoctorAppointmentsScreen(),
    DoctorArticleScreen(doctorId: widget.doctor.uid),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Widget _buildHomeTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildWelcomeCard(), // Removed parameter, will use Provider
          const SizedBox(height: 24),
          Text(
            "Doctor Dashboard",
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
          ),
          const SizedBox(height: 16),
          _buildFeatureGrid(),
        ],
      ),
    );
  }

  Widget _buildWelcomeCard() {
    // Using Consumer to get live updates from the provider
    return Consumer<UserProvider>(
      builder: (context, userProvider, child) {
        final doctor = userProvider.user;
        if (doctor == null) return const SizedBox.shrink(); // Handle case where doctor might be null briefly

        return Card(
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
            child: Row(
              children: [
                // ✅ UPDATED AVATAR
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.white.withOpacity(0.3),
                  backgroundImage: doctor.avatarUrl != null
                      ? NetworkImage(doctor.avatarUrl!)
                      : null,
                  child: doctor.avatarUrl == null
                      ? const Icon(Icons.medical_services_rounded, color: Colors.white, size: 36)
                      : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Welcome back,', style: TextStyle(color: Colors.white70, fontSize: 14)),
                      Text(
                        'Dr. ${doctor.name}',
                        style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      if (doctor.doctorProfile != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          '${doctor.doctorProfile!.specialization} at ${doctor.doctorProfile!.hospitalName}',
                          style: const TextStyle(color: Colors.white70, fontSize: 12),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // The main build method for Scaffold, AppBar, and BottomNav remains the same
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Image.asset("assets/images/logo.png"),
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
                    fontSize: 30),
              ),
              TextSpan(
                text: "Heal",
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: const Color.fromARGB(255, 0, 0, 0),
                    fontWeight: FontWeight.bold,
                    fontSize: 30),
              ),
            ],
          ),
        ),
        actions: [
          Builder(
            builder: (context) => IconButton(
              icon: const Icon(Icons.settings_outlined),
              onPressed: () => Scaffold.of(context).openEndDrawer(),
            ),
          ),
        ],
      ),
      endDrawer: _buildDrawer(context),
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Appointments'),
          BottomNavigationBarItem(icon: Icon(Icons.article), label: 'Articles'),
        ],
      ),
    );
  }

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 30.0),
            child: SizedBox(
              height: kToolbarHeight,
              child: Center(
                  child: Text('Settings', style: TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold))),
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(8),
              children: [
                _buildSettingsSection('Profile', [_buildProfileTile(context)]), // ✅ Simplified call
                _buildSettingsSection('Preferences', [_buildThemeToggle()]),
                _buildSettingsSection('Account', [_buildLogoutTile(context)]),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileTile(BuildContext context) {
    return Consumer<UserProvider>(
      builder: (context, userProvider, child) {
        final doctor = userProvider.user;
        if (doctor == null) return const ListTile(title: Text('Loading...'));
        
        return ListTile(
          leading: const Icon(Icons.person, color: AppColors.primary),
          title: const Text('Profile'),
          onTap: () {
            Navigator.of(context).pop(); // Close the drawer first
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => DoctorProfileScreen(doctor: doctor), // ✅ Pass doctor from provider
              ),
            );
          },
        );
      },
    );
  }
  
  // _buildFeatureGrid, _buildSettingsSection, etc. remain unchanged.
  // ... (Paste the rest of the unchanged widgets here)
  Widget _buildFeatureGrid() {
    final features = [
      FeatureCard(
        title: 'Appointments', subtitle: 'View & manage appointments', icon: Icons.people,
        color: const Color(0xFFE8F5E8), iconColor: const Color(0xFF388E3C), onTap: () => _onItemTapped(1),
      ),
      FeatureCard(
        title: 'My Articles', subtitle: 'Manage your content', icon: Icons.article,
        color: const Color(0xFFE3F2FD), iconColor: const Color(0xFF1976D2), onTap: () => _onItemTapped(2),
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: features.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 16, mainAxisSpacing: 16, childAspectRatio: 0.9),
      itemBuilder: (context, index) {
        final feature = features[index];
        return Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: InkWell(
            onTap: feature.onTap,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 60, height: 60,
                    decoration: BoxDecoration(color: feature.color, borderRadius: BorderRadius.circular(16)),
                    child: Icon(feature.icon, color: feature.iconColor, size: 32),
                  ),
                  const SizedBox(height: 12),
                  Text(feature.title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: AppColors.textPrimary), textAlign: TextAlign.center),
                  const SizedBox(height: 4),
                  Text(feature.subtitle, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary), textAlign: TextAlign.center),
                ],
              ),
            ),
          ),
        );
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

