// lib/screens/settings/settings_screen.dart
// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/theme_provider.dart';
import '../../providers/user_provider.dart';
import '../../services/auth_service.dart';
import '../../utils/theme.dart';
import '../auth/login_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: AppColors.background,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSettingsSection(
            'Preferences',
            [
              _buildThemeToggle(),
              _buildNotificationToggle(),
              _buildLanguageSelector(context),
            ],
          ),
          const SizedBox(height: 24),
          _buildSettingsSection(
            'Account',
            [
              _buildLogoutTile(context),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsSection(String title, List<Widget> children) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
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
          secondary: Icon(
            themeProvider.isDarkMode ? Icons.dark_mode : Icons.light_mode,
            color: AppColors.primary,
          ),
        );
      },
    );
  }

  Widget _buildNotificationToggle() {
    return SwitchListTile(
      title: const Text('Notifications'),
      subtitle: const Text('Receive health reminders and updates'),
      value: true, // TODO: Implement notification preferences
      onChanged: (value) {
        // TODO: Handle notification toggle
      },
      secondary: const Icon(
        Icons.notifications,
        color: AppColors.primary,
      ),
    );
  }

  Widget _buildLanguageSelector(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.language, color: AppColors.primary),
      title: const Text('Language'),
      subtitle: const Text('English (Coming Soon)'),
      onTap: () {
        // TODO: Implement language selection
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Language selection coming soon'),
          ),
        );
      },
    );
  }

  Widget _buildLogoutTile(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.logout, color: AppColors.error),
      title: const Text(
        'Logout',
        style: TextStyle(color: AppColors.error),
      ),
      onTap: () async {
        final shouldLogout = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Logout'),
            content: const Text('Are you sure you want to logout?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
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