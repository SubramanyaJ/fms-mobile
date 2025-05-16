import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'editTransaction.dart';

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

  // Track expanded transaction IDs
  Set<String> expandedTransactions = {};

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

    try {
      final snapshot = await _firestore
          .collection('transactions')
          .where('uid', isEqualTo: uid)
          .get();

      final filteredData = snapshot.docs
          .map((doc) {
        final data = doc.data();
        data['id'] = doc.id; // add doc id for delete/edit use
        return data;
      })
          .where((data) {
        final ts = data['timestamp'];
        if (ts == null || ts is! Timestamp) return false;
        final date = ts.toDate();
        return date.isAfter(startOfMonth.subtract(const Duration(days: 1))) &&
            date.isBefore(endOfMonth.add(const Duration(days: 1)));
      })
          .toList();

      double income = 0.0;
      double expense = 0.0;

      for (var txn in filteredData) {
        final amount = (txn['amount'] ?? 0).toDouble();
        if (txn['type'] == 'income') {
          income += amount;
        } else if (txn['type'] == 'expense') {
          expense += amount;
        }
      }

      setState(() {
        _transactions = filteredData;
        _totalIncome = income;
        _totalExpense = expense;
        _loading = false;
      });
    } catch (e) {
      print('Error loading monthly transactions: $e');
      setState(() {
        _loading = false;
      });
    }
  }

  void _toggleExpanded(String id) {
    setState(() {
      if (expandedTransactions.contains(id)) {
        expandedTransactions.remove(id);
      } else {
        expandedTransactions.add(id);
      }
    });
  }

  Future<void> _deleteTransaction(Map<String, dynamic> tx) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final docId = tx['id'];
      if (docId == null) {
        print('No docId found for this transaction');
        return;
      }

      await _firestore.collection('transactions').doc(docId).delete();

      setState(() {
        _transactions.remove(tx);
        if (tx['type'] == 'income') {
          _totalIncome -= (tx['amount'] ?? 0).toDouble();
        } else {
          _totalExpense -= (tx['amount'] ?? 0).toDouble();
        }
        expandedTransactions.remove(docId);
      });
    } catch (e) {
      print('Error deleting transaction: $e');
    }
  }

  void _editTransaction(Map<String, dynamic> tx) async {
    final result = await Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        pageBuilder: (_, __, ___) => EditTransactionOverlay(transaction: tx),
      ),
    );

    if (result == true) {
      // Reload monthly data after editing
      await _fetchTransactions();
      setState(() {
        expandedTransactions.remove(tx['id']);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B0720), // Dark background to match design
      appBar: AppBar(
        backgroundColor: const Color(0xFF0B0720), // Matching AppBar color
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
            // Total Income
            Text(
              'Income: ₹${_totalIncome.toStringAsFixed(2)}',
              style: const TextStyle(
                  color: Colors.green,
                  fontSize: 16,
                  fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            // Total Expense
            Text(
              'Expense: ₹${_totalExpense.toStringAsFixed(2)}',
              style: const TextStyle(
                  color: Colors.red,
                  fontSize: 16,
                  fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),

            // Transactions Label
            const Text(
              'Transactions:',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
            const SizedBox(height: 8),

            // List of Transactions
            Expanded(
              child: _transactions.isEmpty
                  ? const Center(
                  child: Text(
                    'No transactions this month',
                    style: TextStyle(color: Colors.white54),
                  ))
                  : ListView.builder(
                itemCount: _transactions.length,
                itemBuilder: (context, index) {
                  final txn = _transactions[index];
                  final isExpense = txn['type'] == 'expense';
                  final isExpanded =
                  expandedTransactions.contains(txn['id']);

                  return Container(
                    margin:
                    const EdgeInsets.symmetric(vertical: 6),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E1B2E), // Card bg
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisAlignment:
                      MainAxisAlignment.spaceBetween,
                      children: [
                        // Label & Date wrapped in GestureDetector to collapse if expanded
                        GestureDetector(
                          onTap: () {
                            if (isExpanded) {
                              setState(() {
                                expandedTransactions.remove(txn['id']);
                              });
                            }
                          },
                          child: Column(
                            crossAxisAlignment:
                            CrossAxisAlignment.start,
                            children: [
                              Text(
                                txn['label'] ?? 'No label',
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                DateFormat.yMMMd()
                                    .format(txn['timestamp']
                                    .toDate()),
                                style: const TextStyle(
                                    color: Colors.white54,
                                    fontSize: 12),
                              ),
                            ],
                          ),
                        ),

                        // Expanded actions or amount toggle
                        isExpanded
                            ? Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit,
                                  size: 18,
                                  color: Colors.white),
                              onPressed: () =>
                                  _editTransaction(txn),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete,
                                  color: Colors.redAccent,
                                  size: 20),
                              onPressed: () =>
                                  _deleteTransaction(txn),
                            ),
                          ],
                        )
                            : GestureDetector(
                          onTap: () =>
                              _toggleExpanded(txn['id']),
                          child: Text(
                            '${isExpense ? '-' : '+'}₹${(txn['amount'] ?? 0).toDouble().toStringAsFixed(2)}',
                            style: TextStyle(
                                color: isExpense
                                    ? Colors.redAccent
                                    : Colors.greenAccent,
                                fontWeight: FontWeight.bold,
                                fontSize: 16),
                          ),
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
