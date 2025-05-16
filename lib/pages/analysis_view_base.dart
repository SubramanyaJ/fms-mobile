import 'home_page.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class AnalysisViewBase extends StatefulWidget {
  const AnalysisViewBase({super.key});

  @override
  State<AnalysisViewBase> createState() => _AnalysisViewBaseState();
}

class _AnalysisViewBaseState extends State<AnalysisViewBase> {
  bool isEditingMode = false;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  double totalIncome = 0.0;
  double totalExpense = 0.0;
  int transactionCount = 0;
  double foodExpense = 0.0;
  List<Map<String, dynamic>> transactions = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchOverviewData();
  }

  // Fetching the data from Firestore
  Future<void> fetchOverviewData() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    try {
      final snapshot = await _firestore
          .collection('transactions')
          .where('uid', isEqualTo: uid)
          .get();

      double income = 0.0;
      double expense = 0.0;
      double food = 0.0;
      List<Map<String, dynamic>> fetched = [];

      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        if (data['amount'] == null || data['type'] == null) continue;

        double amount = (data['amount'] as num).toDouble();
        String type = data['type'];
        String category = data['category'] ?? '';
        DateTime date = (data['timestamp'] as Timestamp).toDate();

        if (type == 'income') {
          income += amount;
        } else {
          expense += amount;
          if (category == 'Food') food += amount;
        }

        fetched.add({
          'id': doc.id,
          'amount': amount,
          'type': type,
          'label': data['label'] ?? '',
          'timestamp': date,
          'category': category
        });
      }

      setState(() {
        totalIncome = income;
        totalExpense = expense;
        foodExpense = food;
        transactionCount = fetched.length;
        transactions = fetched;
        isLoading = false;
      });
    } catch (e) {
      debugPrint('Error fetching overview: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0C0C1E),
      appBar: AppBar(
        title: const Text('Overview'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () {
            HomePage.setTab(0);
          },
        ),
        actions: [
          IconButton(
            icon: Icon(isEditingMode ? Icons.close : Icons.settings),
            onPressed: () {
              setState(() {
                isEditingMode = !isEditingMode; // Toggle edit mode
              });
            },
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                buildStatCard('Total Income', '+₹${totalIncome.toStringAsFixed(2)}', Colors.greenAccent),
                const SizedBox(width: 16),
                buildStatCard('Total Expense', '-₹${totalExpense.toStringAsFixed(2)}', Colors.redAccent),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                buildStatCard('Transactions', '$transactionCount', Colors.blueAccent),
                const SizedBox(width: 16),
                buildStatCard('Food Expense', '-₹${foodExpense.toStringAsFixed(2)}', Colors.orangeAccent),
              ],
            ),
            const SizedBox(height: 24),
            Expanded(
              child: transactions.isEmpty
                  ? const Center(
                child: Text(
                  'No transactions found.',
                  style: TextStyle(color: Colors.white70),
                ),
              )
                  : ListView.builder(
                itemCount: transactions.length,
                itemBuilder: (context, index) {
                  final tx = transactions[index];

                  return GestureDetector(
                    child: Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      color: const Color(0xFF1C1C2E),
                      child: ListTile(
                        leading: Icon(
                          Icons.category,
                          color: tx['type'] == 'income'
                              ? Colors.greenAccent
                              : Colors.redAccent,
                        ),
                        title: Text(
                          tx['label'],
                          style: const TextStyle(color: Colors.white),
                        ),
                        subtitle: Text(
                          DateFormat('MMM dd, yyyy – hh:mm a').format(tx['timestamp']),
                          style: const TextStyle(color: Colors.white70),
                        ),
                        trailing: Text(
                          '${tx['type'] == 'income' ? '+' : '-'}₹${tx['amount'].toStringAsFixed(2)}',
                          style: TextStyle(
                            color: tx['type'] == 'income'
                                ? Colors.greenAccent
                                : Colors.redAccent,
                          ),
                        ),
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

  Widget buildStatCard(String title, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1C1C2E),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Text(
              title,
              style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(color: color, fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
