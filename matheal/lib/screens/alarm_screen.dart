// lib/screens/alarm_screen.dart
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
class AlarmScreen extends StatefulWidget {
  const AlarmScreen({super.key});

  @override
  State<AlarmScreen> createState() => _AlarmScreenState();
}

class _AlarmScreenState extends State<AlarmScreen> {
  final _player = AudioPlayer();

  @override
  void initState() {
    super.initState();
    _playAlarmSound();
  }

  Future<void> _playAlarmSound() async {
    try {
      // The path must match the one in your pubspec.yaml
      await _player.setAsset('assets/audio/iphone_alarm.mp3');
      _player.setLoopMode(LoopMode.one); // Loop the sound
      _player.play();
    } catch (e) {
      debugPrint("Error loading audio source: $e");
    }
  }

  @override
  void dispose() {
    _player.dispose(); // Release the player resources
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.alarm,
                size: 128,
                color: Colors.red,
              ),
              const SizedBox(height: 32),
              Text(
                'Alarm!',
                style: Theme.of(context).textTheme.headlineLarge,
              ),
              const SizedBox(height: 48),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                ),
                onPressed: () {
                  _player.stop();
                  Navigator.pop(context); // Close the alarm screen
                },
                icon: const Icon(Icons.stop_circle_outlined),
                label: const Text('Dismiss', style: TextStyle(fontSize: 20)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}