import 'package:flutter/material.dart';
import 'package:matheal/providers/user_provider.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/medicine_model.dart';
import '../../services/firestore_service.dart';

class MedicineHistoryScreen extends StatelessWidget {
  const MedicineHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final userId = context.watch<UserProvider>().user!.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Medication History"),
      ),
      body: StreamBuilder<List<ConsumedMedicine>>(
        stream: context.read<FirestoreService>().getConsumedMedicines(userId),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          if (snapshot.data!.isEmpty) return const Center(child: Text("No medication history found."));
          
          final history = snapshot.data!;

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: history.length,
            itemBuilder: (context, index) {
              final item = history[index];
              return Card(
                child: ListTile(
                  leading: const Icon(Icons.check_circle, color: Colors.green),
                  title: Text(item.name),
                  subtitle: Text("Taken at: ${DateFormat.yMd().add_jm().format(item.consumedAt)}"),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
