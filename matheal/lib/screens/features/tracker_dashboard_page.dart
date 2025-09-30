// lib/pages/tracker_dashboard_page.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:matheal/providers/user_provider.dart'; // Ensure this path is correct
import '../../models/daily_log.dart';
import '../../services/tracking_service.dart';
import 'add_edit_log_page.dart'; // Renamed to match the class name
import 'package:intl/intl.dart'; // For date formatting

class TrackerDashboardPage extends StatefulWidget {
  const TrackerDashboardPage({super.key});

  @override
  State<TrackerDashboardPage> createState() => _TrackerDashboardPageState();
}

class _TrackerDashboardPageState extends State<TrackerDashboardPage> {
  String? _currentUserId;
  final TrackingService _trackingService = TrackingService();

  // State for the calendar
  Stream<List<DailyLog>>? _logsStream;
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Initialize once when dependencies change
    if (_currentUserId == null) {
      final userProvider = context.read<UserProvider>();
      _currentUserId = userProvider.user!.uid;
      _updateStreamForMonth(_focusedDay);
    }
  }

  /// Updates the stream to fetch logs for the month containing the given day.
  void _updateStreamForMonth(DateTime day) {
    final firstDayOfMonth = DateTime.utc(day.year, day.month, 1);
    final lastDayOfMonth = DateTime.utc(day.year, day.month + 1, 0);
    setState(() {
      _logsStream = _trackingService.getDailyLogsInDateRange(
        _currentUserId!,
        firstDayOfMonth,
        lastDayOfMonth,
      );
    });
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    if (!isSameDay(_selectedDay, selectedDay)) {
      setState(() {
        _selectedDay = selectedDay;
        _focusedDay = focusedDay;
      });
    }
  }

  void _navigateToAddEditPage(DailyLog? existingLog) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AddEditLogScreen(
          date: _selectedDay,
          log: existingLog,
        ),
      ),
    );
    // No need to refresh manually; the StreamBuilder listens automatically
  }

  @override
  Widget build(BuildContext context) {
    // If stream is not yet initialized (before didChangeDependencies runs)
    if (_logsStream == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return StreamBuilder<List<DailyLog>>(
      stream: _logsStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            appBar: AppBar(title: const Text('Symptom & Mood Tracker')),
            body: const Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasError) {
          return Scaffold(
            appBar: AppBar(title: const Text('Symptom & Mood Tracker')),
            body: Center(child: Text('Error: ${snapshot.error}')),
          );
        }

        final logs = snapshot.data ?? [];
        final logsByDate = {
          for (var log in logs)
            DateTime.utc(log.date.year, log.date.month, log.date.day): log
        };

        final selectedLog = logsByDate[DateTime.utc(
          _selectedDay.year,
          _selectedDay.month,
          _selectedDay.day,
        )];

        return Scaffold(
          appBar: AppBar(
            title: const Text('Symptom & Mood Tracker'),
          ),
          body: Column(
            children: [
              TableCalendar<DailyLog>(
                firstDay: DateTime.utc(2022, 1, 1),
                lastDay: DateTime.utc(2030, 12, 31),
                focusedDay: _focusedDay,
                selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                onDaySelected: _onDaySelected,
                eventLoader: (day) {
                  final log = logsByDate[DateTime.utc(
                    day.year,
                    day.month,
                    day.day,
                  )];
                  return log != null ? [log] : [];
                },
                calendarBuilders: CalendarBuilders(
                  markerBuilder: (context, date, events) {
                    if (events.isNotEmpty) {
                      return Positioned(
                        right: 1,
                        bottom: 1,
                        child: Text(
                          (events.first as DailyLog).mood.emoji,
                          style: const TextStyle(fontSize: 12),
                        ),
                      );
                    }
                    return null;
                  },
                ),
                onPageChanged: (focusedDay) {
                  setState(() => _focusedDay = focusedDay);
                  _updateStreamForMonth(focusedDay);
                },
              ),
              const Divider(height: 1),
              Expanded(
                child: selectedLog != null
                    ? LogDetailsView(log: selectedLog)
                    : const Center(
                        child: Text(
                          'No log for this day.\nTap the button below to add one!',
                          textAlign: TextAlign.center,
                        ),
                      ),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () {
              final logForSelectedDay = logsByDate[DateTime.utc(
                _selectedDay.year,
                _selectedDay.month,
                _selectedDay.day,
              )];
              _navigateToAddEditPage(logForSelectedDay);
            },
            tooltip: 'Add or Edit Log',
            child: const Icon(Icons.add),
          ),
        );
      },
    );
  }
}

// A simple widget to display the log details
class LogDetailsView extends StatelessWidget {
  final DailyLog log;
  const LogDetailsView({super.key, required this.log});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        Text(
          'Your Log for ${DateFormat.yMMMMEEEEd().format(log.date)}',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 16),
        ListTile(
          leading: Text(log.mood.emoji, style: const TextStyle(fontSize: 32)),
          title: Text(
            'Mood: ${log.mood.displayName}',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        const Divider(),
        const SizedBox(height: 8),
        Text('Symptoms Reported:',
            style: Theme.of(context).textTheme.titleMedium),
        if (log.symptoms.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8.0),
            child: Text('No symptoms reported.'),
          )
        else
          ...log.symptoms.map(
            (symptom) => ListTile(
              title: Text(symptom.type.displayName),
              trailing: Text('Severity: ${symptom.severity}/5'),
            ),
          ),
        if (log.notes != null && log.notes!.isNotEmpty) ...[
          const Divider(),
          const SizedBox(height: 8),
          Text('Notes:', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(log.notes!),
        ]
      ],
    );
  }
}
