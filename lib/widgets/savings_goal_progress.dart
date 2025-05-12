// savings_goal_progress.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SavingsGoalProgress extends StatelessWidget {
  final String uid;
  const SavingsGoalProgress({super.key, required this.uid});

  Future<List<Map<String, dynamic>>> fetchGoals() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('savings')
        .where('uid', isEqualTo: uid)
        .get();

    final transactionsSnapshot = await FirebaseFirestore.instance
        .collection('transactions')
        .where('uid', isEqualTo: uid)
        .where('type', isEqualTo: 'income')
        .get();

    double totalIncome = 0;
    for (var doc in transactionsSnapshot.docs) {
      totalIncome += (doc['amount'] ?? 0).toDouble();
    }

    return snapshot.docs.map((doc) {
      final data = doc.data();
      final goalAmount = (data['amount'] ?? 0).toDouble();
      double progress = totalIncome >= goalAmount
          ? 1
          : totalIncome / goalAmount;

      return {
        'title': data['label'] ?? 'Unnamed Goal',
        'goal': goalAmount,
        'progress': progress,
      };
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: fetchGoals(),
      builder: (context, snapshot) {
        final widgetName = runtimeType.toString();

        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 8),
                Text("Loading $widgetName...", style: const TextStyle(color: Colors.white)),
              ],
            ),
          );
        } else if (snapshot.hasError) {
          return Center(
            child: Text("Error loading $widgetName", style: const TextStyle(color: Colors.white)),
          );
        } else if (!snapshot.hasData ||
            (snapshot.data is Iterable && (snapshot.data as Iterable).isEmpty) ||
            (snapshot.data is Map && (snapshot.data as Map).isEmpty)) {
          return Center(
            child: Text("No data for $widgetName", style: const TextStyle(color: Colors.white)),
          );
        }

        final goals = snapshot.data!;
        if (goals.isEmpty) {
          return const Center(child: Text("No savings goals found."));
        }

        return Column(
          children: goals.map((goal) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16),
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF1A237E), // lighter blue background
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(goal['title'],
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        )),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: goal['progress'],
                      backgroundColor: const Color(0xFF0D0B2D),
                      valueColor:
                      const AlwaysStoppedAnimation<Color>(Colors.lightBlueAccent),
                      minHeight: 10,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '₹${(goal['progress'] * goal['goal']).toStringAsFixed(0)} / ₹${goal['goal'].toStringAsFixed(0)}',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}
