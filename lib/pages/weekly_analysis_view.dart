import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class WeeklyAnalysisView extends StatefulWidget {
  const WeeklyAnalysisView({super.key});

  @override
  State<WeeklyAnalysisView> createState() => _WeeklyAnalysisViewState();
}

class _WeeklyAnalysisViewState extends State<WeeklyAnalysisView> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  double income = 0.0;
  double expense = 0.0;
  List<Map<String, dynamic>> transactions = [];

  @override
  void initState() {
    super.initState();
    _fetchUserAndLoadData();
  }

  Future<void> _fetchUserAndLoadData() async {
    final user = _auth.currentUser;
    if (user != null) {
      await _loadData(user.uid);
    }
  }

  Future<void> _loadData(String uid) async {
    DateTime now = DateTime.now();
    DateTime startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    DateTime endOfWeek = startOfWeek.add(const Duration(days: 7));

    try {
      QuerySnapshot snapshot = await _firestore
          .collection('transactions')
          .where('uid', isEqualTo: uid)
          .get();

      double totalIncome = 0.0;
      double totalExpense = 0.0;
      List<Map<String, dynamic>> weeklyTransactions = [];

      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        if (data['timestamp'] == null || data['amount'] == null) continue;

        DateTime date = (data['timestamp'] as Timestamp).toDate();
        if (date.isBefore(startOfWeek) || date.isAfter(endOfWeek)) continue;

        double amount = (data['amount'] as num).toDouble();
        String type = data['type'] ?? 'expense';
        String category = data['category'] ?? 'Uncategorized';
        String label = data['label'] ?? 'No label';

        if (type == 'income') {
          totalIncome += amount;
        } else {
          totalExpense += amount;
        }

        weeklyTransactions.add({
          'category': category,
          'amount': amount,
          'timestamp': date,
          'label': label,
          'type': type,
        });
      }

      setState(() {
        income = totalIncome;
        expense = totalExpense;
        transactions = weeklyTransactions;
      });
    } catch (e) {
      print('Error loading weekly data: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF0B0720),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Weekly Analysis',
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white),
            ),
            const SizedBox(height: 10),
            Text(
              'Income: ₹${income.toStringAsFixed(2)}',
              style: const TextStyle(color: Colors.green, fontSize: 16),
            ),
            Text(
              'Expense: ₹${expense.toStringAsFixed(2)}',
              style: const TextStyle(color: Colors.red, fontSize: 16),
            ),
            const SizedBox(height: 16),
            const Text(
              'Transactions:',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: transactions.isEmpty
                  ? const Center(
                child: Text('No transactions',
                    style: TextStyle(color: Colors.white54)),
              )
                  : ListView.builder(
                itemCount: transactions.length,
                itemBuilder: (context, index) {
                  final tx = transactions[index];
                  return Container(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E1B2E),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(tx['label'],
                                style: const TextStyle(
                                    color: Colors.white, fontSize: 16)),
                            const SizedBox(height: 4),
                            Text(
                              DateFormat('EEE, MMM d')
                                  .format(tx['timestamp']),
                              style: const TextStyle(
                                  color: Colors.white54, fontSize: 12),
                            ),
                          ],
                        ),
                        Text(
                          '${tx['type'] == 'income' ? '+' : '-'}₹${tx['amount'].toStringAsFixed(2)}',
                          style: TextStyle(
                              color: tx['type'] == 'income'
                                  ? Colors.greenAccent
                                  : Colors.redAccent,
                              fontWeight: FontWeight.bold,
                              fontSize: 16),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
