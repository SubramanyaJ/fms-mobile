import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class MonthlyAnalysisView extends StatefulWidget {
  const MonthlyAnalysisView({Key? key}) : super(key: key);

  @override
  State<MonthlyAnalysisView> createState() => _MonthlyAnalysisViewState();
}

class _MonthlyAnalysisViewState extends State<MonthlyAnalysisView> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<Map<String, dynamic>> _transactions = [];
  double _totalIncome = 0.0;
  double _totalExpense = 0.0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchTransactions();
  }

  Future<void> _fetchTransactions() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final endOfMonth = DateTime(now.year, now.month + 1, 0);

    final snapshot = await _firestore
        .collection('transactions')
        .where('uid', isEqualTo: uid)
        .get();

    final filteredData = snapshot.docs.map((doc) => doc.data()).where((data) {
      final ts = data['timestamp'];
      if (ts == null || ts is! Timestamp) return false;
      final date = ts.toDate();
      return date.isAfter(startOfMonth.subtract(const Duration(days: 1))) &&
          date.isBefore(endOfMonth.add(const Duration(days: 1)));
    }).toList();

    double income = 0.0;
    double expense = 0.0;

    for (var txn in filteredData) {
      if (txn['type'] == 'income') {
        income += txn['amount'] ?? 0.0;
      } else if (txn['type'] == 'expense') {
        expense += txn['amount'] ?? 0.0;
      }
    }

    setState(() {
      _transactions = filteredData;
      _totalIncome = income;
      _totalExpense = expense;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('Monthly Analysis'),
        foregroundColor: Colors.white,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Income: ₹${_totalIncome.toStringAsFixed(2)}',
              style: const TextStyle(color: Colors.green, fontSize: 18),
            ),
            const SizedBox(height: 8),
            Text(
              'Expense: ₹${_totalExpense.toStringAsFixed(2)}',
              style: const TextStyle(color: Colors.red, fontSize: 18),
            ),
            const SizedBox(height: 24),
            const Text(
              'Transactions:',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                itemCount: _transactions.length,
                itemBuilder: (context, index) {
                  final txn = _transactions[index];
                  final isExpense = txn['type'] == 'expense';
                  return ListTile(
                    tileColor: Colors.grey[900],
                    title: Text(
                      txn['label'] ?? 'No label',
                      style: const TextStyle(color: Colors.white),
                    ),
                    subtitle: Text(
                      DateFormat.yMMMd().format(txn['timestamp'].toDate()),
                      style: const TextStyle(color: Colors.grey),
                    ),
                    trailing: Text(
                      (isExpense ? '-' : '+') + '₹${txn['amount'].toString()}',
                      style: TextStyle(
                        color: isExpense ? Colors.red : Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
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
