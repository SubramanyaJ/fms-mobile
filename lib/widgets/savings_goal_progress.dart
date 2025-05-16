import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'editGoal.dart';

class SavingsGoalProgress extends StatefulWidget {
  final String uid;
  const SavingsGoalProgress({super.key, required this.uid});

  @override
  _SavingsGoalProgressState createState() => _SavingsGoalProgressState();
}

class _SavingsGoalProgressState extends State<SavingsGoalProgress> {
  late Future<List<Map<String, dynamic>>> _goalsFuture;

  @override
  void initState() {
    super.initState();
    _goalsFuture = fetchGoals();
  }

  Future<List<Map<String, dynamic>>> fetchGoals() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('savings')
        .where('uid', isEqualTo: widget.uid)
        .get();

    return snapshot.docs.map((doc) {
      final data = doc.data();
      final goalAmount = (data['amount'] ?? 0).toDouble();
      final transferred = (data['transfer'] ?? 0).toDouble();

      // Ensure we avoid division by zero and clamp progress to 1
      double progress = (goalAmount > 0)
          ? (transferred / goalAmount).clamp(0.0, 1.0)
          : 0.0;

      return {
        'id': doc.id,
        'title': data['label'] ?? 'Unnamed Goal',
        'goal': goalAmount,
        'progress': progress,
      };
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _goalsFuture,
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
            String status = "In Progress";
            if (goal['progress'] == 1) {
              status = "Completed";
            } else if (goal['progress'] > 0.5) {
              status = "Almost there!";
            }

            return Dismissible(
              key: Key(goal['id']),
              direction: DismissDirection.horizontal,
              onDismissed: (direction) async {
                if (direction == DismissDirection.endToStart) {
                  // Fetch the goal doc again to get 'transfer' value just before deletion
                  final docRef = FirebaseFirestore.instance.collection('savings').doc(goal['id']);
                  final docSnapshot = await docRef.get();
                  if (docSnapshot.exists) {
                    final data = docSnapshot.data()!;
                    final double transferred = (data['transfer'] ?? 0).toDouble();

                    if (transferred > 0) {
                      // Add back the transferred amount as income transaction
                      await FirebaseFirestore.instance.collection('transactions').add({
                        'amount': transferred,
                        'date': DateTime.now().toIso8601String().split('T')[0], // e.g. "2025-05-16"
                        'description': '',
                        'label': 'Refund',
                        'timestamp': Timestamp.now(),
                        'type': 'income',
                        'uid': widget.uid,
                      });
                    }

                    // Now delete the goal document
                    await docRef.delete();

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Goal deleted and transfer refunded')),
                    );
                  }
                } else if (direction == DismissDirection.startToEnd) {
                  _showEditGoalDialog(context, goal['id']);
                }
              },
              background: Container(
                alignment: Alignment.centerLeft,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: const Icon(Icons.edit, color: Colors.white),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              secondaryBackground: Container(
                alignment: Alignment.centerRight,
                child: const Icon(Icons.delete, color: Colors.white),
                padding: const EdgeInsets.symmetric(horizontal: 20),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16),
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A237E),
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
                      const SizedBox(height: 8),
                      Text(
                        status,
                        style: TextStyle(
                          color: goal['progress'] == 1
                              ? Colors.green
                              : Colors.amber,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  void _showEditGoalDialog(BuildContext context, String goalId) {
    showDialog(
      context: context,
      builder: (context) {
        return EditGoalDialog(
          goalId: goalId,
          onUpdate: () async {
            // After updating, refresh the goal data by calling setState
            setState(() {
              _goalsFuture = fetchGoals(); // Re-fetch the data to update the widget
            });
            Navigator.of(context).pop();
          },
        );
      },
    );
  }
}
