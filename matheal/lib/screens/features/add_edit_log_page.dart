import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:matheal/models/daily_log.dart';
import 'package:matheal/providers/user_provider.dart';
import 'package:matheal/services/tracking_service.dart';
import 'package:matheal/utils/theme.dart';
import 'package:provider/provider.dart';

class AddEditLogScreen extends StatefulWidget {
  final DateTime date;
  final DailyLog? log; // If log is null, we are adding. If it's not, we're editing.

  const AddEditLogScreen({
    super.key,
    required this.date,
    this.log,
  });

  @override
  State<AddEditLogScreen> createState() => _AddEditLogScreenState();
}

class _AddEditLogScreenState extends State<AddEditLogScreen> {
  // State variables to hold the user's input
  MoodType? _selectedMood;
  final List<LoggedSymptom> _selectedSymptoms = [];
  late final TextEditingController _notesController;
  bool _isLoading = false;

  bool get isEditing => widget.log != null;

  @override
  void initState() {
    super.initState();
    // Initialize the state with the existing log's data if we are editing
    if (isEditing) {
      _selectedMood = widget.log!.mood;
      _selectedSymptoms.addAll(widget.log!.symptoms);
      _notesController = TextEditingController(text: widget.log!.notes);
    } else {
      _notesController = TextEditingController();
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  /// Toggles a symptom's selection. If it's already selected, it's removed.
  /// If it's not, it's added with a default severity of 1.
  void _toggleSymptom(SymptomType type) {
    setState(() {
      final index = _selectedSymptoms.indexWhere((s) => s.type == type);
      if (index != -1) {
        _selectedSymptoms.removeAt(index);
      } else {
        _selectedSymptoms.add(LoggedSymptom(type: type, severity: 1));
      }
    });
  }

  /// Updates the severity of a selected symptom.
  void _updateSymptomSeverity(SymptomType type, double severity) {
    setState(() {
      final index = _selectedSymptoms.indexWhere((s) => s.type == type);
      if (index != -1) {
        _selectedSymptoms[index] = LoggedSymptom(
          type: type,
          severity: severity.toInt(),
        );
      }
    });
  }

  Future<void> _saveLog() async {
    if (_selectedMood == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select your mood for the day.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final userId = context.read<UserProvider>().user!.uid;
      final newLog = DailyLog(
        id: widget.log?.id, // Preserve id if editing
        userId: userId,
        date: widget.date,
        mood: _selectedMood!,
        symptoms: _selectedSymptoms,
        notes: _notesController.text.trim(),
      );

      await context.read<TrackingService>().saveDailyLog(newLog);

      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Log for ${DateFormat.yMMMd().format(widget.date)} saved!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving log: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Log' : 'Add Log'),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Colors.white))
                : TextButton(
                    onPressed: () {
                      _saveLog();
                      print("✅ Button was tapped!");
                    },
                    child: const Text(
                      'Save',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Text(
                'Log for ${DateFormat.yMMMMEEEEd().format(widget.date)}',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            const SizedBox(height: 24),
            _buildMoodSelector(),
            const Divider(height: 40),
            _buildSymptomSelector(),
            const Divider(height: 40),
            _buildNotesField(),
          ],
        ),
      ),
    );
  }

  Widget _buildMoodSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'How are you feeling today?',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8.0,
          runSpacing: 8.0,
          children: MoodType.values.map((mood) {
            return ChoiceChip(
              label: Text(mood.name[0].toUpperCase() + mood.name.substring(1)),
              selected: _selectedMood == mood,
              onSelected: (_) => setState(() => _selectedMood = mood),
              selectedColor: Theme.of(context).primaryColor.withOpacity(0.2),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildSymptomSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Any symptoms?',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 12),
        ...SymptomType.values.where((s) => s != SymptomType.other).map((symptom) {
          final isSelected = _selectedSymptoms.any((s) => s.type == symptom);
          final currentSymptom = isSelected ? _selectedSymptoms.firstWhere((s) => s.type == symptom) : null;
          
          return Column(
            children: [
              CheckboxListTile(
                title: Text(symptom.name[0].toUpperCase() + symptom.name.substring(1)),
                value: isSelected,
                onChanged: (_) => _toggleSymptom(symptom),
              ),
              if (isSelected)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    children: [
                      const Text('Mild'),
                      Expanded(
                        child: Slider(
                          value: currentSymptom!.severity.toDouble(),
                          min: 1,
                          max: 5,
                          divisions: 4,
                          label: currentSymptom.severity.toString(),
                          onChanged: (value) => _updateSymptomSeverity(symptom, value),
                        ),
                      ),
                      const Text('Severe'),
                    ],
                  ),
                ),
            ],
          );
        }),
      ],
    );
  }

  Widget _buildNotesField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Notes',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _notesController,
          decoration: const InputDecoration(
            hintText: 'Add any additional details here...',
            border: OutlineInputBorder(),
          ),
          maxLines: 4,
        ),
      ],
    );
  }
}