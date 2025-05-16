import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class CalendarAnalysisView extends StatefulWidget {
  const CalendarAnalysisView({super.key});

  @override
  State<CalendarAnalysisView> createState() => _CalendarAnalysisViewState();
}

class _CalendarAnalysisViewState extends State<CalendarAnalysisView> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<Map<String, dynamic>> allTransactions = [];
  Map<String, List<Map<String, dynamic>>> groupedByDate = {};
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchTransactions();
  }

  Future<void> fetchTransactions() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    try {
      final snapshot = await _firestore
          .collection('transactions')
          .where('uid', isEqualTo: uid)
          .get();

      final List<Map<String, dynamic>> fetched = snapshot.docs
          .map((doc) => doc.data() as Map<String, dynamic>)
          .toList();

      groupByDate(fetched);
      setState(() {
        allTransactions = fetched;
        isLoading = false;
      });
    } catch (e) {
      debugPrint('Error: $e');
    }
  }

  void groupByDate(List<Map<String, dynamic>> transactions) {
    final Map<String, List<Map<String, dynamic>>> map = {};

    for (var tx in transactions) {
      final DateTime date =
      (tx['timestamp'] as Timestamp).toDate();
      final String formattedDate = DateFormat('yyyy-MM-dd').format(date);

      map.putIfAbsent(formattedDate, () => []).add(tx);
    }

    setState(() {
      groupedByDate = map;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0C0C1E),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Calendar View'),
        centerTitle: true,
        foregroundColor: Colors.white,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : groupedByDate.isEmpty
          ? const Center(
        child: Text(
          "No transactions available.",
          style: TextStyle(color: Colors.white70),
        ),
      )
          : ListView(
        padding: const EdgeInsets.all(16.0),
        children: groupedByDate.entries.map((entry) {
          final date = entry.key;
          final txList = entry.value;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                DateFormat('MMMM dd, yyyy')
                    .format(DateTime.parse(date)),
                style: const TextStyle(
                    color: Colors.white70,
                    fontWeight: FontWeight.bold,
                    fontSize: 14),
              ),
              const SizedBox(height: 8),
              ...txList.map((tx) => Card(
                color: const Color(0xFF1C1C2E),
                child: ListTile(
                  title: Text(
                    tx['label'],
                    style: const TextStyle(color: Colors.white),
                  ),
                  subtitle: Text(
                    tx['category'],
                    style: const TextStyle(color: Colors.grey),
                  ),
                  trailing: Text(
                    '${tx['type'] == 'income' ? '+' : '-'}₹${tx['amount'].toStringAsFixed(2)}',
                    style: TextStyle(
                      color: tx['type'] == 'income'
                          ? Colors.greenAccent
                          : Colors.redAccent,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              )),
              const SizedBox(height: 12),
            ],
          );
        }).toList(),
      ),
    );
  }
}
