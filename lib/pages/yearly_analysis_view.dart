import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'editTransaction.dart';

class YearlyAnalysisView extends StatefulWidget {
  const YearlyAnalysisView({super.key});

  @override
  State<YearlyAnalysisView> createState() => _YearlyAnalysisViewState();
}

class _YearlyAnalysisViewState extends State<YearlyAnalysisView> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  double income = 0.0;
  double expense = 0.0;
  List<Map<String, dynamic>> transactions = [];

  Set<String> expandedTransactions = {};
  bool isLoading = true;

  int currentYear = DateTime.now().year;

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
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('transactions')
          .where('uid', isEqualTo: uid)
          .get();

      double totalIncome = 0.0;
      double totalExpense = 0.0;
      List<Map<String, dynamic>> yearlyTransactions = [];

      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;

        if (data['timestamp'] == null || data['amount'] == null) continue;

        DateTime date = (data['timestamp'] as Timestamp).toDate();
        if (date.year != currentYear) continue;

        double amount = (data['amount'] as num).toDouble();
        String type = data['type'] ?? 'expense';
        String category = data['category'] ?? 'Uncategorized';
        String label = data['label'] ?? 'No label';

        if (type == 'income') {
          totalIncome += amount;
        } else {
          totalExpense += amount;
        }

        yearlyTransactions.add({
          'id': doc.id,
          'category': category,
          'amount': amount,
          'timestamp': date,
          'label': label,
          'type': type,
        });
      }

      // Sort transactions by timestamp descending (most recent first)
      yearlyTransactions.sort((a, b) =>
          (b['timestamp'] as DateTime).compareTo(a['timestamp'] as DateTime));

      setState(() {
        income = totalIncome;
        expense = totalExpense;
        transactions = yearlyTransactions;
        isLoading = false;
      });
    } catch (e) {
      print('Error loading yearly data: $e');
      setState(() {
        isLoading = false;
      });
    }
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
        transactions.remove(tx);
        if (tx['type'] == 'income') {
          income -= tx['amount'];
        } else {
          expense -= tx['amount'];
        }
        expandedTransactions.remove(tx['id']);
      });
    } catch (e) {
      print('Error deleting transaction: $e');
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

  void _editTransaction(Map<String, dynamic> tx) async {
    final result = await Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        pageBuilder: (_, __, ___) => EditTransactionOverlay(transaction: tx),
      ),
    );

    if (result == true) {
      final user = _auth.currentUser;
      if (user != null) {
        await _loadData(user.uid);
      }
      setState(() {
        expandedTransactions.remove(tx['id']);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B0720),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0B0720),
        title: const Text('Yearly Analysis'),
        foregroundColor: Colors.white,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
                  final isExpanded =
                  expandedTransactions.contains(tx['id']);
                  return Container(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E1B2E),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisAlignment:
                      MainAxisAlignment.spaceBetween,
                      children: [
                        GestureDetector(
                          onTap: () {
                            if (isExpanded) {
                              setState(() {
                                expandedTransactions.remove(tx['id']);
                              });
                            }
                          },
                          child: Column(
                            crossAxisAlignment:
                            CrossAxisAlignment.start,
                            children: [
                              Text(tx['label'],
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16)),
                              const SizedBox(height: 4),
                              Text(
                                DateFormat('MMM d, yyyy')
                                    .format(tx['timestamp']),
                                style: const TextStyle(
                                    color: Colors.white54,
                                    fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                        isExpanded
                            ? Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit,
                                  size: 18,
                                  color: Colors.white),
                              onPressed: () =>
                                  _editTransaction(tx),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete,
                                  color: Colors.redAccent,
                                  size: 20),
                              onPressed: () =>
                                  _deleteTransaction(tx),
                            ),
                          ],
                        )
                            : GestureDetector(
                          onTap: () =>
                              _toggleExpanded(tx['id']),
                          child: Text(
                            '${tx['type'] == 'income' ? '+' : '-'}₹${tx['amount'].toStringAsFixed(2)}',
                            style: TextStyle(
                                color: tx['type'] == 'income'
                                    ? Colors.greenAccent
                                    : Colors.redAccent,
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
