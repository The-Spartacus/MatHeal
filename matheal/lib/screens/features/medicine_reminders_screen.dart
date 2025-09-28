// lib/screens/features/medicine_reminders_screen.dart

// ignore_for_file: deprecated_member_use, prefer_const_constructors, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

// Models and Services
import '../../services/firestore_service.dart';
import '../../services/notification_service.dart';
import '../../providers/user_provider.dart';
import '../../models/medicine_model.dart';
import 'medication_calendar_screen.dart';
import '../../utils/theme.dart';


class MedicineRemindersScreen extends StatefulWidget {
  const MedicineRemindersScreen({super.key});

  @override
  State<MedicineRemindersScreen> createState() =>
      _MedicineRemindersScreenState();
}

class _MedicineRemindersScreenState extends State<MedicineRemindersScreen> {
  @override
  Widget build(BuildContext context) {
    final user = context.watch<UserProvider>().user;

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Please log in to continue')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Medicine Reminders'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: 'Medication History',
            onPressed: () {
              // vvvvvvvvvv THE NAVIGATION IS UPDATED HERE vvvvvvvvvv
              Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => const MedicationCalendarScreen(), // UPDATED
              ));
              // ^^^^^^^^^^ THE NAVIGATION IS UPDATED HERE ^^^^^^^^^^
            },
          ),
        ],
      ),
      // ... rest of the file remains the same
      body: StreamBuilder<List<MedicineModel>>(
        stream: context.read<FirestoreService>().getMedicines(user.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return _buildEmptyState();
          }
          final medicines = snapshot.data!;
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: medicines.length,
            itemBuilder: (context, index) => _buildMedicineCard(medicines[index]),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showMedicineDialog(),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(60),
              ),
              child: const Icon(
                Icons.medication_liquid,
                size: 64,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 24),
            Text('No Medicine Reminders', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text(
              'Add your first medicine reminder to stay on track.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
             const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => _showMedicineDialog(),
              icon: const Icon(Icons.add),
              label: const Text('Add Reminder'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMedicineCard(MedicineModel medicine) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(radius: 25, child: Icon(_getMedicineIcon(medicine.type))),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(medicine.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 4),
                  Text('Dosage: ${medicine.dosage}', style: TextStyle(color: Colors.grey.shade600)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.access_time, size: 16, color: Colors.grey.shade600),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          medicine.reminderTimes.join(', '),
                          style: TextStyle(color: Colors.grey.shade600),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'edit') _showMedicineDialog(medicine: medicine);
                if (value == 'delete') _deleteMedicine(medicine);
              },
              itemBuilder: (context) => [
                const PopupMenuItem(value: 'edit', child: Text('Edit')),
                const PopupMenuItem(value: 'delete', child: Text('Delete')),
              ],
            ),
          ],
        ),
      ),
    );
  }

  IconData _getMedicineIcon(MedicineType type) {
    switch (type) {
      case MedicineType.pill: return Icons.medication;
      case MedicineType.syrup: return Icons.science;
      case MedicineType.injection: return Icons.vaccines;
      default: return Icons.healing;
    }
  }

  // +++ NEW HELPER FUNCTION TO SAFELY PARSE TIME +++
  TimeOfDay? _parseTimeOfDay(String timeString) {
    try {
      final parts = timeString.split(':');
      if (parts.length != 2) return null;
      final hour = int.tryParse(parts[0]);
      final minute = int.tryParse(parts[1]);
      if (hour == null || minute == null) return null;
      return TimeOfDay(hour: hour, minute: minute);
    } catch (e) {
      debugPrint("Error parsing time string '$timeString': $e");
      return null;
    }
  }

  void _showMedicineDialog({MedicineModel? medicine}) {
    final isEditing = medicine != null;
    final formKey = GlobalKey<FormState>();

    // Controllers and state variables
    final nameController = TextEditingController(text: medicine?.name ?? '');
    final dosageController = TextEditingController(text: medicine?.dosage ?? '');
    final notesController = TextEditingController(text: medicine?.notes ?? '');
    var selectedType = medicine?.type ?? MedicineType.pill;
    
    // vvvvvvvvvv THIS LINE IS NOW SAFER vvvvvvvvvv
    var reminderTimes = medicine != null
        ? medicine.reminderTimes.map(_parseTimeOfDay).whereType<TimeOfDay>().toList()
        : [TimeOfDay(hour: 8, minute: 0)];
    // ^^^^^^^^^^ THIS LINE IS NOW SAFER ^^^^^^^^^^

    if (isEditing && reminderTimes.isEmpty && medicine.reminderTimes.isNotEmpty) {
      // This handles the case where all saved times were badly formatted.
      // We add a default time to prevent the list from being empty.
      reminderTimes.add(TimeOfDay(hour: 8, minute: 0));
       WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not read saved times for "${medicine.name}". Please set them again.'), backgroundColor: Colors.orange),
        );
      });
    }

    var frequency = medicine != null ? List<String>.from(medicine.frequency) : <String>[];
    var startDate = medicine?.startDate ?? DateTime.now();
    var endDate = medicine?.endDate;

    final daysOfWeek = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(isEditing ? 'Edit Medicine' : 'Add Medicine'),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextFormField(controller: nameController, decoration: const InputDecoration(labelText: 'Medicine Name'), validator: (v) => v!.isEmpty ? 'Required' : null),
                  TextFormField(controller: dosageController, decoration: const InputDecoration(labelText: 'Dosage (e.g., 1 pill)'), validator: (v) => v!.isEmpty ? 'Required' : null),
                  DropdownButtonFormField<MedicineType>(
                    value: selectedType,
                    decoration: const InputDecoration(labelText: 'Type'),
                    items: MedicineType.values.map((t) => DropdownMenuItem(value: t, child: Text(t.toString().split('.').last))).toList(),
                    onChanged: (v) => setDialogState(() => selectedType = v!),
                  ),
                  const SizedBox(height: 16),
                  Text('Frequency', style: Theme.of(context).textTheme.labelLarge),
                  Wrap(
                    spacing: 6.0,
                    children: daysOfWeek.map((day) => FilterChip(
                      label: Text(day),
                      selected: frequency.contains(day),
                      onSelected: (selected) => setDialogState(() => selected ? frequency.add(day) : frequency.remove(day)),
                    )).toList(),
                  ),
                  const SizedBox(height: 16),
                  Text('Reminder Times', style: Theme.of(context).textTheme.labelLarge),
                  ...reminderTimes.map((time) => Chip(label: Text(time.format(context)), onDeleted: () => setDialogState(() => reminderTimes.remove(time)))).toList(),
                  ElevatedButton(onPressed: () async {
                    final time = await showTimePicker(context: context, initialTime: TimeOfDay.now());
                    if (time != null && !reminderTimes.contains(time)) setDialogState(() => reminderTimes.add(time));
                  }, child: Text('Add Time')),
                  ListTile(
                    title: Text('Start Date'),
                    subtitle: Text(DateFormat.yMMMd().format(startDate)),
                    onTap: () async {
                      final date = await showDatePicker(context: context, initialDate: startDate, firstDate: DateTime(2020), lastDate: DateTime(2100));
                      if (date != null) setDialogState(() => startDate = date);
                    },
                  ),
                  ListTile(
                    title: Text('End Date (Optional)'),
                    subtitle: Text(endDate == null ? 'Not Set' : DateFormat.yMMMd().format(endDate!)),
                    trailing: endDate == null ? null : IconButton(icon: Icon(Icons.clear), onPressed: () => setDialogState(() => endDate = null)),
                    onTap: () async {
                      final date = await showDatePicker(context: context, initialDate: endDate ?? startDate, firstDate: startDate, lastDate: DateTime(2100));
                      if (date != null) setDialogState(() => endDate = date);
                    },
                  ),
                  TextFormField(controller: notesController, decoration: const InputDecoration(labelText: 'Notes (optional)')),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;

                final uid = context.read<UserProvider>().user!.uid;
                final newMedicine = MedicineModel(
                  id: medicine?.id,
                  userId: uid,
                  name: nameController.text,
                  dosage: dosageController.text,
                  type: selectedType,
                  reminderTimes: reminderTimes.map((t) => '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}').toList(),
                  frequency: frequency,
                  startDate: startDate,
                  endDate: endDate,
                  notes: notesController.text,
                );

                try {
                  final firestore = context.read<FirestoreService>();
                  String docId;

                  if (isEditing) {
                    docId = medicine.id!;
                    await _cancelNotificationsForMedicine(medicine);
                    await firestore.updateMedicine(newMedicine.copyWith(id: docId));
                  } else {
                    final docRef = await firestore.addMedicine(newMedicine);
                    docId = docRef.id;
                  }
                  await _scheduleNotificationsForMedicine(newMedicine.copyWith(id: docId));

                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Medicine ${isEditing ? 'updated' : 'added'}!')),
                  );

                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e')),
                  );
                }
              },
              child: Text(isEditing ? 'Update' : 'Save'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _scheduleNotificationsForMedicine(MedicineModel medicine) async {
    for (final timeStr in medicine.reminderTimes) {
      final timeParts = timeStr.split(':');
      final hour = int.parse(timeParts[0]);
      final minute = int.parse(timeParts[1]);

      await NotificationService.scheduleMedicineNotification(
        id: (medicine.id! + timeStr).hashCode,
        title: 'Medication Reminder: ${medicine.name}',
        body: 'Time to take your ${medicine.dosage} dose.',
        payload: medicine.name, // ✅ THIS IS THE FIX
        hour: hour,
        minute: minute,
        startDate: medicine.startDate,
        endDate: medicine.endDate,
        days: medicine.frequency.map((day) => daysOfWeek.indexOf(day) + 1).toList(),
      );
    }
  }

  Future<void> _cancelNotificationsForMedicine(MedicineModel medicine) async {
    for (final timeStr in medicine.reminderTimes) {
      await NotificationService.cancelNotification((medicine.id! + timeStr).hashCode);
    }
  }

  void _deleteMedicine(MedicineModel medicine) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Medicine'),
        content: Text('Are you sure you want to delete the reminder for "${medicine.name}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _cancelNotificationsForMedicine(medicine);
        await context.read<FirestoreService>().deleteMedicine(medicine.id!);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${medicine.name} deleted.')),
        );
      } catch (e) {
         ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }
}

// Helper list for scheduling
const List<String> daysOfWeek = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];