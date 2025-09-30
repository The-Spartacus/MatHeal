import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:matheal/models/daily_log.dart';

class TrackingService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference<DailyLog> _getDailyLogsCollection() {
    return _db.collection('daily_logs').withConverter<DailyLog>(
          fromFirestore: (snapshot, _) => DailyLog.fromFirestore(snapshot),
          toFirestore: (log, _) => log.toFirestore(),
        );
  }

  /// Normalize date to start of day (local)
  DateTime _startOfDay(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  /// Normalize date to end of day (local)
  DateTime _endOfDay(DateTime date) =>
      DateTime(date.year, date.month, date.day, 23, 59, 59);

  /// Save or update a log
  Future<void> saveDailyLog(DailyLog log) async {
    final start = _startOfDay(log.date);
    final end = _endOfDay(log.date);

    final querySnapshot = await _getDailyLogsCollection()
        .where('userId', isEqualTo: log.userId)
        .where('date', isGreaterThanOrEqualTo: start)
        .where('date', isLessThanOrEqualTo: end)
        .orderBy('date', descending: true) // ensure index uses the same field as range
        .limit(1)
        .get();

    if (querySnapshot.docs.isNotEmpty) {
      final docId = querySnapshot.docs.first.id;
      await _getDailyLogsCollection().doc(docId).update(log.toFirestore());
    } else {
      await _getDailyLogsCollection().add(log);
    }
  }

  /// Stream logs for a user in a date range
  Stream<List<DailyLog>> getDailyLogsInDateRange(
      String userId, DateTime startDate, DateTime endDate) {
    final start = _startOfDay(startDate);
    final end = _endOfDay(endDate);

    return _getDailyLogsCollection()
        .where('userId', isEqualTo: userId)
        .where('date', isGreaterThanOrEqualTo: start)
        .where('date', isLessThanOrEqualTo: end)
        .orderBy('date', descending: true) // matches our index
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
  }

  /// Fetch a single log for a date
  Future<DailyLog?> getDailyLogForDate(String userId, DateTime date) async {
    final start = _startOfDay(date);
    final end = _endOfDay(date);

    final querySnapshot = await _getDailyLogsCollection()
        .where('userId', isEqualTo: userId)
        .where('date', isGreaterThanOrEqualTo: start)
        .where('date', isLessThanOrEqualTo: end)
        .orderBy('date') // required for range query
        .limit(1)
        .get();

    if (querySnapshot.docs.isEmpty) return null;
    return querySnapshot.docs.first.data();
  }

  /// Delete a log by ID
  Future<void> deleteDailyLog(String logId) async {
    await _getDailyLogsCollection().doc(logId).delete();
  }
}
