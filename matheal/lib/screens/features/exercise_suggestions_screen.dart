// lib/screens/features/exercise_suggestions_screen.dart
// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../utils/theme.dart';

class ExerciseSuggestionsScreen extends StatelessWidget {
  const ExerciseSuggestionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Sections: title + exercise list
    const sections = [
      (
        "First Trimester (Weeks 1–12)",
        firstTrimesterExercises
      ),
      (
        "Second Trimester (Weeks 13–26)",
        secondTrimesterExercises
      ),
      (
        "Third Trimester (Weeks 27–40)",
        thirdTrimesterExercises
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text("Exercise Suggestions"),
        backgroundColor: AppColors.background,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: sections.length,
        itemBuilder: (context, index) {
          final (title, list) = sections[index];
          return _TrimesterCard(title: title, exercises: list);
        },
      ),
    );
  }
}

/* ----------------------------- Data model ----------------------------- */

class ExerciseItem {
  final String name;
  final String notes; // sets/reps, safety note, duration, etc.
  final String videoUrl; // YouTube or https URL

  const ExerciseItem({
    required this.name,
    required this.notes,
    required this.videoUrl,
  });
}

/* ----------------------------- Data (const) ----------------------------- */
/* You can swap any of these URLs for your own videos. These are generic,
   safe prenatal resources. */

const List<ExerciseItem> firstTrimesterExercises = [
  ExerciseItem(
    name: "Walking",
    notes: "Low-impact cardio 20–30 min, 3–5×/week. Supportive shoes.",
    videoUrl: "https://www.youtube.com/watch?v=V3YvXcZ8B4I",
  ),
  ExerciseItem(
    name: "Swimming",
    notes: "Full-body, very joint-friendly. 15–30 min.",
    videoUrl: "https://www.youtube.com/watch?v=cF1p4i5xV_A",
  ),
  ExerciseItem(
    name: "Prenatal Yoga",
    notes: "Gentle flows; avoid hot yoga. 15–25 min.",
    videoUrl: "https://www.youtube.com/watch?v=3z8K0lL9sT8",
  ),
  ExerciseItem(
    name: "Strength Training",
    notes: "Light weights; avoid lying flat on back.",
    videoUrl: "https://www.youtube.com/watch?v=pr2BpOF7i-w",
  ),
  ExerciseItem(
    name: "Stationary Cycling",
    notes: "Great balance-safe cardio alternative.",
    videoUrl: "https://www.youtube.com/watch?v=kGRszN6wo3g",
  ),
  ExerciseItem(
    name: "Prenatal Pilates",
    notes: "Core stability; avoid back/stomach lying.",
    videoUrl: "https://www.youtube.com/watch?v=8dXyRDPYQ0A",
  ),
];

const List<ExerciseItem> secondTrimesterExercises = [
  ExerciseItem(
    name: "All Fours – Core Activation",
    notes: "2 sets × 10 slow lifts, 15s rest.",
    videoUrl: "https://www.youtube.com/watch?v=1bzYvUlTZzM",
  ),
  ExerciseItem(
    name: "Side Plank Lifts",
    notes: "2 sets × 10 reps/side, 15s rest.",
    videoUrl: "https://www.youtube.com/watch?v=K2zjz3gmFQM",
  ),
  ExerciseItem(
    name: "Clams",
    notes: "2 sets × 10 reps/side, 15s rest.",
    videoUrl: "https://www.youtube.com/watch?v=9kFl6o6Wc5w",
  ),
  ExerciseItem(
    name: "Glute Side Lifts",
    notes: "2 sets × 10 reps/side, 15s rest.",
    videoUrl: "https://www.youtube.com/watch?v=Kav5_14WQJQ",
  ),
  ExerciseItem(
    name: "Bridge",
    notes: "2 sets × 10 reps, slow and controlled.",
    videoUrl: "https://www.youtube.com/watch?v=YR1UIU6jztE",
  ),
  ExerciseItem(
    name: "Swimming / Water Aerobics",
    notes: "Low joint impact, 15–30 min.",
    videoUrl: "https://www.youtube.com/watch?v=mh1HjH0MHsM",
  ),
  ExerciseItem(
    name: "Prenatal Yoga – Pelvic Tilts",
    notes: "Breathing + mobility focus.",
    videoUrl: "https://www.youtube.com/watch?v=JHOfUAtdD10",
  ),
];

const List<ExerciseItem> thirdTrimesterExercises = [
  ExerciseItem(
    name: "Gentle Stretching",
    notes: "Daily mobility; focus on hips/low back.",
    videoUrl: "https://www.youtube.com/watch?v=5nmcZp9oJpE",
  ),
  ExerciseItem(
    name: "Wall Push-Ups",
    notes: "2–3 sets × 8–12 reps.",
    videoUrl: "https://www.youtube.com/watch?v=RZ1Bp1DgRr0",
  ),
  ExerciseItem(
    name: "Seated Leg Lifts",
    notes: "2–3 sets × 8–12 reps/side.",
    videoUrl: "https://www.youtube.com/watch?v=1cfqzuJBJDo",
  ),
  ExerciseItem(
    name: "Pelvic Floor (Kegels)",
    notes: "10–15 reps, 3×/day, slow and controlled.",
    videoUrl: "https://www.youtube.com/watch?v=G1z57wu-O6Y",
  ),
  ExerciseItem(
    name: "Breathing Exercises",
    notes: "Relaxation for labor; 5–10 min.",
    videoUrl: "https://www.youtube.com/watch?v=Ht1SXtthjU8",
  ),
  ExerciseItem(
    name: "Walking – Short, Frequent",
    notes: "5–15 min as comfortable.",
    videoUrl: "https://www.youtube.com/watch?v=8yKuUj8QZ9U",
  ),
  ExerciseItem(
    name: "Birth Prep – Cat-Cow, Hip Circles",
    notes: "Mobilize spine + pelvis.",
    videoUrl: "https://www.youtube.com/watch?v=n7dG6Zp6sVw",
  ),
];

/* ----------------------------- UI widgets ----------------------------- */

class _TrimesterCard extends StatelessWidget {
  final String title;
  final List<ExerciseItem> exercises;

  const _TrimesterCard({
    required this.title,
    required this.exercises,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ExpansionTile(
        leading: const Icon(Icons.fitness_center, color: AppColors.primary),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        children: exercises
            .map((e) => _ExerciseTile(item: e))
            .toList(),
      ),
    );
  }
}

class _ExerciseTile extends StatelessWidget {
  final ExerciseItem item;
  const _ExerciseTile({required this.item});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.check_circle_outline, size: 22),
            title: Text(item.name),
            subtitle: Text(item.notes),
            dense: true,
          ),
          // Video placeholder with button
          Container(
            height: 160,
            margin: const EdgeInsets.only(top: 8),
            decoration: BoxDecoration(
              color: Colors.black12,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: ElevatedButton.icon(
                onPressed: () async {
                  final uri = Uri.parse(item.videoUrl);
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Couldn't open video.")),
                    );
                  }
                },
                icon: const Icon(Icons.play_circle_fill, size: 28),
                label: const Text("Watch Video"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
