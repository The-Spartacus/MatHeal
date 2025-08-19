// lib/screens/features/exercise_suggestions_screen.dart
// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import '../../utils/theme.dart';

class ExerciseSuggestionsScreen extends StatelessWidget {
  const ExerciseSuggestionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Exercise Suggestions'),
        backgroundColor: AppColors.background,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildExerciseCategory(
              'First Trimester (Weeks 1-12)',
              [
                'Walking - Low impact cardio',
                'Swimming - Full body workout',
                'Prenatal yoga - Flexibility and relaxation',
                'Light strength training',
              ],
              Icons.directions_walk,
              AppColors.success,
            ),
            const SizedBox(height: 16),
            _buildExerciseCategory(
              'Second Trimester (Weeks 13-26)',
              [
                'Modified planks and squats',
                'Pelvic tilts for back pain',
                'Arm and leg exercises',
                'Breathing exercises',
              ],
              Icons.fitness_center,
              AppColors.primary,
            ),
            const SizedBox(height: 16),
            _buildExerciseCategory(
              'Third Trimester (Weeks 27-40)',
              [
                'Gentle stretching',
                'Wall push-ups',
                'Seated exercises',
                'Birth preparation exercises',
              ],
              Icons.self_improvement,
              AppColors.accent,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExerciseCategory(String title, List<String> exercises, IconData icon, Color color) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ExpansionTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Icon(icon, color: color),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        children: exercises.map((exercise) => ListTile(
          leading: const Icon(Icons.circle, size: 8),
          title: Text(exercise),
          dense: true,
        )).toList(),
      ),
    );
  }
}