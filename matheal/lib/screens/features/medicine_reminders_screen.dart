// ignore_for_file: deprecated_member_use, prefer_const_constructors, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../services/firestore_service.dart';
import '../../services/notification_service.dart';
import '../../providers/user_provider.dart';
import '../../models/user_model.dart';
import '../../utils/theme.dart';

class MedicineRemindersScreen extends StatefulWidget {
  const MedicineRemindersScreen({super.key});

  @override
  State<MedicineRemindersScreen> createState() => _MedicineRemindersScreenState();
}

class _MedicineRemindersScreenState extends State<MedicineRemindersScreen> {
  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<UserProvider>();
    final user = userProvider.user;

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Please log in to continue')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Medicine Reminders'),
        backgroundColor: AppColors.background,
      ),
      body: StreamBuilder<List<ReminderModel>>(
        stream: context.read<FirestoreService>().getReminders(user.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 64,
                    color: AppColors.error,
                  ),
                  const SizedBox(height: 16),
                  const Text('Error loading reminders'),
                  TextButton(
                    onPressed: () => setState(() {}),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          final reminders = snapshot.data?.where((r) => r.type == 'medicine').toList() ?? [];

          if (reminders.isEmpty) {
            return _buildEmptyState();
          }

          return RefreshIndicator(
            onRefresh: () async {
              setState(() {});
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: reminders.length,
              itemBuilder: (context, index) {
                return _buildReminderCard(reminders[index]);
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddReminderDialog,
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
            Text(
              'No Medicine Reminders',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Add your first medicine reminder to stay on track with your medications.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _showAddReminderDialog,
              icon: const Icon(Icons.add),
              label: const Text('Add Reminder'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReminderCard(ReminderModel reminder) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onLongPress: () => _showConsumedDialog(reminder),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(25),
                ),
                child: const Icon(
                  Icons.medication,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      reminder.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    if (reminder.notes.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        reminder.notes,
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 14,
                        ),
                      ),
                    ],
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          size: 16,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${reminder.time.hour.toString().padLeft(2, '0')}:${reminder.time.minute.toString().padLeft(2, '0')}',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 14,
                          ),
                        ),
                        if (reminder.repeatInterval != 'none') ...[
                          const SizedBox(width: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.accent.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              reminder.repeatInterval,
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              PopupMenuButton(
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit, size: 20),
                        SizedBox(width: 8),
                        Text('Edit'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'consumed',
                    child: Row(
                      children: [
                        Icon(Icons.check, size: 20),
                        SizedBox(width: 8),
                        Text('Mark as Taken'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete, size: 20, color: AppColors.error),
                        SizedBox(width: 8),
                        Text('Delete', style: TextStyle(color: AppColors.error)),
                      ],
                    ),
                  ),
                ],
                onSelected: (value) {
                  switch (value) {
                    case 'edit':
                      _showEditReminderDialog(reminder);
                      break;
                    case 'consumed':
                      _showConsumedDialog(reminder);
                      break;
                    case 'delete':
                      _deleteReminder(reminder);
                      break;
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddReminderDialog() {
    _showReminderDialog();
  }

  void _showEditReminderDialog(ReminderModel reminder) {
    _showReminderDialog(reminder: reminder);
  }

  void _showReminderDialog({ReminderModel? reminder}) {
    final isEditing = reminder != null;
    final titleController = TextEditingController(text: reminder?.title ?? '');
    final notesController = TextEditingController(text: reminder?.notes ?? '');
    TimeOfDay selectedTime = reminder != null 
        ? TimeOfDay.fromDateTime(reminder.time)
        : TimeOfDay.now();
    String selectedRepeat = reminder?.repeatInterval ?? 'daily';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(isEditing ? 'Edit Reminder' : 'Add Medicine Reminder'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: 'Medicine Name',
                    prefixIcon: Icon(Icons.medication),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: notesController,
                  decoration: const InputDecoration(
                    labelText: 'Notes (optional)',
                    prefixIcon: Icon(Icons.note),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading: const Icon(Icons.access_time),
                  title: const Text('Time'),
                  subtitle: Text(selectedTime.format(context)),
                  onTap: () async {
                    final time = await showTimePicker(
                      context: context,
                      initialTime: selectedTime,
                    );
                    if (time != null) {
                      setDialogState(() => selectedTime = time);
                    }
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedRepeat,
                  decoration: const InputDecoration(
                    labelText: 'Repeat',
                    prefixIcon: Icon(Icons.repeat),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'none', child: Text('None')),
                    DropdownMenuItem(value: 'daily', child: Text('Daily')),
                    DropdownMenuItem(value: 'weekly', child: Text('Weekly')),
                  ],
                  onChanged: (value) {
                    setDialogState(() => selectedRepeat = value ?? 'daily');
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (titleController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter medicine name')),
                  );
                  return;
                }

                final now = DateTime.now();
                final reminderTime = DateTime(
                  now.year,
                  now.month,
                  now.day,
                  selectedTime.hour,
                  selectedTime.minute,
                );

                final reminderModel = ReminderModel(
                  id: reminder?.id,
                  uid: context.read<UserProvider>().user!.uid,
                  type: 'medicine',
                  title: titleController.text.trim(),
                  notes: notesController.text.trim(),
                  time: reminderTime,
                  repeatInterval: selectedRepeat,
                );

                try {
                  final firestoreService = context.read<FirestoreService>();
                  
                  if (isEditing) {
                    await firestoreService.updateReminder(reminder.id!, reminderModel);
                  } else {
                    final id = await firestoreService.addReminder(reminderModel);
                    
                    // Schedule notification
                    await NotificationService.scheduleNotification(
                      id: id.hashCode,
                      title: 'Medicine Reminder',
                      body: 'Time to take ${titleController.text.trim()}',
                      scheduledDate: reminderTime,
                    );
                  }

                  HapticFeedback.lightImpact();
                  Navigator.of(context).pop();
                  
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(isEditing 
                          ? 'Reminder updated successfully' 
                          : 'Reminder added successfully'),
                      backgroundColor: AppColors.success,
                    ),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error: $e'),
                      backgroundColor: AppColors.error,
                    ),
                  );
                }
              },
              child: Text(isEditing ? 'Update' : 'Add'),
            ),
          ],
        ),
      ),
    );
  }

  void _showConsumedDialog(ReminderModel reminder) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Mark as Taken'),
        content: Text('Mark "${reminder.title}" as consumed?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                final consumedMedicine = ConsumedMedicine(
                  uid: reminder.uid,
                  reminderId: reminder.id!,
                  name: reminder.title,
                  consumedAt: DateTime.now(),
                );

                await context.read<FirestoreService>().addConsumedMedicine(consumedMedicine);
                
                HapticFeedback.lightImpact();
                Navigator.of(context).pop();
                
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Medicine marked as taken'),
                    backgroundColor: AppColors.success,
                  ),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error: $e'),
                    backgroundColor: AppColors.error,
                  ),
                );
              }
            },
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }

  void _deleteReminder(ReminderModel reminder) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Reminder'),
        content: Text('Are you sure you want to delete "${reminder.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await context.read<FirestoreService>().deleteReminder(reminder.id!);
                
                // Cancel notification
                await NotificationService.cancelNotification(reminder.id.hashCode);
                
                HapticFeedback.lightImpact();
                Navigator.of(context).pop();
                
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Reminder deleted'),
                    backgroundColor: AppColors.success,
                  ),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error: $e'),
                    backgroundColor: AppColors.error,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}