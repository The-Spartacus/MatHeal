// lib/screens/alarm_screen.dart
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:matheal/models/medicine_model.dart';
import 'package:matheal/providers/user_provider.dart';
import 'package:matheal/services/firestore_service.dart';
import 'package:provider/provider.dart';

class AlarmScreen extends StatefulWidget {
  final String medicineName;
  final int alarmId; // Added to help identify and potentially cancel the *next* scheduled alarm

  // Updated constructor to accept alarmId
  const AlarmScreen({super.key, required this.medicineName, required this.alarmId});

  @override
  State<AlarmScreen> createState() => _AlarmScreenState();
}

class _AlarmScreenState extends State<AlarmScreen> {
  final AudioPlayer _player = AudioPlayer();

  @override
  void initState() {
    super.initState();
    _playAlarmSound();
  }

  Future<void> _playAlarmSound() async {
    try {
      // Ensure you have this audio file in assets/audio/
      await _player.setAsset('assets/audio/iphone_alarm.mp3'); 
      _player.setLoopMode(LoopMode.one);
      await _player.play();
    } catch (e) {
      debugPrint('Error loading or playing audio: $e');
    }
  }

  void _markAsTakenAndDismiss() async { // 💡 Changed to async
    _player.stop();

    try {
      // 1. Get current user and services via Provider
      final userProvider = context.read<UserProvider>();
      final firestoreService = context.read<FirestoreService>();
      final user = userProvider.user;

      if (user == null) {
        debugPrint("[AlarmScreen] ERROR: User not logged in. Cannot save consumed medicine.");
        // Optionally show a message to the user
        return;
      }
      
      // 2. Create the ConsumedMedicine model
      final consumedMedicine = ConsumedMedicine(
        uid: user.uid,
        reminderId: widget.alarmId.toString(), // Use alarmId as the reminderId (or generate a unique one if needed)
        name: widget.medicineName,
        consumedAt: DateTime.now(),
      );

      // 3. Save the record to Firestore
      await firestoreService.addConsumedMedicine(consumedMedicine);
      
      debugPrint("MEDICINE TAKEN: ${widget.medicineName} saved to Firestore successfully! ✅");

    } catch (e) {
      debugPrint("[AlarmScreen] ERROR saving consumed medicine: $e");
    } finally {
      // Dismiss the alarm screen regardless of save success (after trying to save)
      Navigator.of(context).pop();
    }
  }

// ... rest of the file

  // New method to handle the "Dismiss/Snooze" action
  void _dismissAlarm() {
    _player.stop();
    // ⚠️ Optional: You could implement snooze logic here, but for simplicity, 
    // it just dismisses the screen.
    Navigator.of(context).pop();
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return WillPopScope(
      onWillPop: () async => false, // disable back button
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Header text
                  Text(
                    "Medicine Reminder",
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.teal.shade800,
                      letterSpacing: 1.2,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 24),

                  // Alarm Icon
                  Container(
                    padding: const EdgeInsets.all(30),
                    decoration: BoxDecoration(
                      color: Colors.teal.shade50,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.teal.withOpacity(0.3),
                          blurRadius: 20,
                          spreadRadius: 5,
                        )
                      ],
                    ),
                    child: const Icon(
                      Icons.alarm,
                      size: 100,
                      color: Colors.teal,
                    ),
                  ),

                  const SizedBox(height: 40),

                  // Medicine name
                  Text(
                    widget.medicineName,
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 60),

                  // --- BUTTONS ROW START ---
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // 1. Mark as Taken Button (Primary Action)
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.teal, // Primary color
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 25,
                            vertical: 18,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          elevation: 5,
                        ),
                        onPressed: _markAsTakenAndDismiss, // New method call
                        icon: const Icon(Icons.check_circle_outline, size: 26),
                        label: const Text(
                          'Mark as Taken',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ),
                      
                      const SizedBox(width: 15),

                      // 2. Dismiss Button (Secondary Action)
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.redAccent,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 25,
                            vertical: 18,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          elevation: 5,
                        ),
                        onPressed: _dismissAlarm, // New method call
                        icon: const Icon(Icons.close, size: 26),
                        label: const Text(
                          'Dismiss',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  // --- BUTTONS ROW END ---
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}