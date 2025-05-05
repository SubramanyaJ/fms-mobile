import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class YearlyAnalysisView extends StatefulWidget {
  const YearlyAnalysisView({super.key});

  @override
  State<YearlyAnalysisView> createState() => _YearlyAnalysisViewState();
}

class _YearlyAnalysisViewState extends State<YearlyAnalysisView> {
  List<Map<String, dynamic>> allTransactions = [];
  bool isLoading = true;
  String uid = FirebaseAuth.instance.currentUser?.uid ?? '';
  Map<int, double> yearlyExpense = {};

  @override
  void initState() {
    super.initState();
    fetchTransactions();
  }

  Future<void> fetchTransactions() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('transactions')
          .where('uid', isEqualTo: uid)
          .get();

      final List<Map<String, dynamic>> fetched = snapshot.docs
          .map((doc) => doc.data() as Map<String, dynamic>)
          .toList();

      setState(() {
        allTransactions = fetched;
        isLoading = false;
        calculateYearlyExpense();
      });
    } catch (e) {
      debugPrint("Error fetching transactions: $e");
    }
  }

  void calculateYearlyExpense() {
    final Map<int, double> expenseMap = {};

    for (var txn in allTransactions) {
      final timestamp = DateTime.tryParse(txn['timestamp'].toString());
      if (timestamp == null || txn['type'] != 'expense') continue;

      final int year = timestamp.year;
      expenseMap[year] = (expenseMap[year] ?? 0) + txn['amount'];
    }

    setState(() {
      yearlyExpense = expenseMap;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0C0C1E),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Yearly Analysis'),
        centerTitle: true,
        foregroundColor: Colors.white,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: yearlyExpense.entries.map((entry) {
            return Card(
              color: const Color(0xFF1C1C2E),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListTile(
                title: Text(
                  '${entry.key}',
                  style: const TextStyle(color: Colors.white),
                ),
                subtitle: const Text(
                  'Total Expense',
                  style: TextStyle(color: Colors.grey),
                ),
                trailing: Text(
                  '₹${entry.value.toStringAsFixed(2)}',
                  style: const TextStyle(
                    color: Colors.redAccent,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
