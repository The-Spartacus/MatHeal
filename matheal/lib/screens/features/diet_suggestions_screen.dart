// lib/screens/features/diet_suggestions_screen.dart
// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/user_provider.dart';
import '../../utils/theme.dart';

class DietSuggestionsScreen extends StatelessWidget {
  const DietSuggestionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Diet Suggestions'),
        backgroundColor: AppColors.background,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildPersonalizedSuggestions(),
            const SizedBox(height: 24),
            _buildGeneralTips(),
          ],
        ),
      ),
    );
  }

  Widget _buildPersonalizedSuggestions() {
    return Consumer<UserProvider>(
      builder: (context, userProvider, child) {
        final profile = userProvider.profile;
        final conditions = profile?.conditions ?? [];

        return Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Icon(
                        Icons.person,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Personalized for You',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (conditions.contains('Anemia')) ...[
                  _buildSuggestionTile(
                    'Iron-Rich Foods',
                    'Include spinach, lean meats, lentils, and fortified cereals',
                    Icons.eco,
                    AppColors.success,
                  ),
                  _buildSuggestionTile(
                    'Vitamin C',
                    'Consume citrus fruits with iron-rich meals for better absorption',
                    Icons.local_drink,
                    AppColors.warning,
                  ),
                ],
                if (conditions.contains('Diabetes') || conditions.contains('Gestational diabetes')) ...[
                  _buildSuggestionTile(
                    'Low Glycemic Index',
                    'Choose whole grains, vegetables, and lean proteins',
                    Icons.grain,
                    AppColors.info,
                  ),
                ],
                if (conditions.isEmpty) ...[
                  const Text(
                    'Complete your profile to get personalized diet suggestions based on your health conditions.',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildGeneralTips() {
    final tips = [
      {
        'title': 'Folic Acid',
        'description': 'Essential for baby\'s neural development. Found in leafy greens and fortified grains.',
        'icon': Icons.healing,
        'color': AppColors.primary,
      },
      {
        'title': 'Calcium',
        'description': 'Important for bone development. Include dairy products, fortified plant milks.',
        'icon': Icons.sports_gymnastics,
        'color': AppColors.accent,
      },
      {
        'title': 'Omega-3',
        'description': 'Support brain development. Fish, walnuts, and flaxseeds are great sources.',
        'icon': Icons.water_drop,
        'color': AppColors.info,
      },
      {
        'title': 'Hydration',
        'description': 'Drink 8-10 glasses of water daily to stay properly hydrated.',
        'icon': Icons.local_drink,
        'color': AppColors.success,
      },
    ];

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'General Pregnancy Nutrition',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...tips.map((tip) => _buildSuggestionTile(
              tip['title'] as String,
              tip['description'] as String,
              tip['icon'] as IconData,
              tip['color'] as Color,
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestionTile(String title, String description, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}