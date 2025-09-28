// lib/screens/features/medication_calendar_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../models/medicine_model.dart';
import '../../providers/user_provider.dart';
import '../../services/firestore_service.dart';
import '../../utils/theme.dart';

class MedicationCalendarScreen extends StatefulWidget {
  const MedicationCalendarScreen({super.key});

  @override
  State<MedicationCalendarScreen> createState() => _MedicationCalendarScreenState();
}

class _MedicationCalendarScreenState extends State<MedicationCalendarScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  late ValueNotifier<List<ConsumedMedicine>> _selectedEvents;

  // Store all consumed medicines fetched from Firestore
  Map<DateTime, List<ConsumedMedicine>> _events = {};

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _selectedEvents = ValueNotifier(_getEventsForDay(_selectedDay!));
  }

  @override
  void dispose() {
    _selectedEvents.dispose();
    super.dispose();
  }

  // Helper method to get events for a specific day
  List<ConsumedMedicine> _getEventsForDay(DateTime day) {
    // Implementation for getting events, normalizing the day to ignore time
    return _events[DateTime(day.year, day.month, day.day)] ?? [];
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    if (!isSameDay(_selectedDay, selectedDay)) {
      setState(() {
        _selectedDay = selectedDay;
        _focusedDay = focusedDay;
      });
      _selectedEvents.value = _getEventsForDay(selectedDay);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<UserProvider>().user;

    if (user == null) {
      return const Scaffold(body: Center(child: Text("Please log in.")));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Medication History"),
        backgroundColor: AppColors.background,
      ),
      body: StreamBuilder<List<ConsumedMedicine>>(
        stream: context.read<FirestoreService>().getConsumedMedicines(user.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(child: Text("Error loading history."));
          }

          final allMedicines = snapshot.data ?? [];
          _events = _groupMedicinesByDay(allMedicines);
          
          // Refresh the events for the currently selected day after data is fetched
          _selectedEvents.value = _getEventsForDay(_selectedDay!);

          return Column(
            children: [
              _buildTableCalendar(),
              const SizedBox(height: 8.0),
              Expanded(child: _buildEventList()),
            ],
          );
        },
      ),
    );
  }

  // Groups the flat list of medicines into a map by day
  Map<DateTime, List<ConsumedMedicine>> _groupMedicinesByDay(List<ConsumedMedicine> medicines) {
    Map<DateTime, List<ConsumedMedicine>> data = {};
    for (var med in medicines) {
      DateTime date = DateTime(med.consumedAt.year, med.consumedAt.month, med.consumedAt.day);
      if (data[date] == null) data[date] = [];
      data[date]!.add(med);
    }
    return data;
  }

  Widget _buildTableCalendar() {
    return Card(
      margin: const EdgeInsets.all(8.0),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: TableCalendar<ConsumedMedicine>(
        firstDay: DateTime.utc(2020, 1, 1),
        lastDay: DateTime.utc(2030, 12, 31),
        focusedDay: _focusedDay,
        selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
        onDaySelected: _onDaySelected,
        eventLoader: _getEventsForDay,
        calendarStyle: CalendarStyle(
          todayDecoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.5),
            shape: BoxShape.circle,
          ),
          selectedDecoration: const BoxDecoration(
            color: AppColors.primary,
            shape: BoxShape.circle,
          ),
          markerDecoration: const BoxDecoration(
            color: AppColors.accent,
            shape: BoxShape.circle,
          ),
        ),
        headerStyle: const HeaderStyle(
          formatButtonVisible: false,
          titleCentered: true,
        ),
        onPageChanged: (focusedDay) {
          _focusedDay = focusedDay;
        },
      ),
    );
  }

  Widget _buildEventList() {
    return ValueListenableBuilder<List<ConsumedMedicine>>(
      valueListenable: _selectedEvents,
      builder: (context, value, _) {
        if (value.isEmpty) {
          return const Center(
            child: Text(
              "No medicines taken on this day.",
              style: TextStyle(color: AppColors.textSecondary, fontSize: 16),
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          itemCount: value.length,
          itemBuilder: (context, index) {
            final medicine = value[index];
            return Card(
              margin: const EdgeInsets.symmetric(vertical: 4.0),
              child: ListTile(
                leading: const CircleAvatar(
                  backgroundColor: AppColors.success,
                  child: Icon(Icons.check, color: AppColors.success),
                ),
                title: Text(medicine.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(
                  "Taken at: ${DateFormat.jm().format(medicine.consumedAt)}",
                ),
              ),
            );
          },
        );
      },
    );
  }
}