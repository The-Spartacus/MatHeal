// lib/screens/features/consumed_medicines_screen.dart
// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/firestore_service.dart';
import '../../providers/user_provider.dart';
import '../../models/user_model.dart';
import '../../utils/theme.dart';

class ConsumedMedicinesScreen extends StatelessWidget {
  const ConsumedMedicinesScreen({super.key});

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
        title: const Text('Consumed Medicines'),
        backgroundColor: AppColors.background,
      ),
      body: StreamBuilder<List<ConsumedMedicine>>(
        stream: context.read<FirestoreService>().getConsumedMedicines(user.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return const Center(child: Text('Error loading consumed medicines'));
          }

          final medicines = snapshot.data ?? [];

          if (medicines.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(50),
                    ),
                    child: const Icon(
                      Icons.history,
                      size: 50,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'No consumed medicines yet',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Your medicine history will appear here',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: medicines.length,
            itemBuilder: (context, index) {
              final medicine = medicines[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: AppColors.success.withOpacity(0.1),
                    child: const Icon(Icons.check, color: AppColors.success),
                  ),
                  title: Text(medicine.name),
                  subtitle: Text(
                    'Taken on ${medicine.consumedAt.day}/${medicine.consumedAt.month}/${medicine.consumedAt.year} at ${medicine.consumedAt.hour.toString().padLeft(2, '0')}:${medicine.consumedAt.minute.toString().padLeft(2, '0')}',
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}







