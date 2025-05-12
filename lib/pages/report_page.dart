import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../widgets/summary_cards.dart';
import '../widgets/expense_bar_chart.dart';
import '../widgets/balance_line_chart.dart';
import '../widgets/savings_pie_chart.dart';
import '../widgets/savings_goal_progress.dart';
import '../widgets/predictive_spending_chart.dart';
import '../widgets/transaction_frequency_bar.dart';

class ReportPage extends StatefulWidget {
  const ReportPage({Key? key}) : super(key: key);

  @override
  _ReportPageState createState() => _ReportPageState();
}

class _ReportPageState extends State<ReportPage> {
  late String uid;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    uid = FirebaseAuth.instance.currentUser!.uid;
  }

  // Fetch Firestore data when user clicks refresh button
  Future<void> _fetchDataFromFirestore() async {
    setState(() {
      isLoading = true; // Set loading to true when fetching
    });

    try {
      var snapshot = await FirebaseFirestore.instance
          .collection('transactions')
          .where('uid', isEqualTo: uid)
          .get();

      print("Fetched data: ${snapshot.docs.length}");

    } catch (e) {
      print("Error fetching data: $e");
    } finally {
      setState(() {
        isLoading = false; // Set loading to false when finished
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0B2D),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D0B2D),
        title: const Text(
          "Insights & Reports",
          style: TextStyle(color: Colors.white),
        ),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _fetchDataFromFirestore, // Trigger the refresh on press
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator()) // Show loading while fetching
          : ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        children: [
          SummaryCards(uid: uid),
          const SizedBox(height: 24),
          ExpenseBarChart(uid: uid),
          const SizedBox(height: 24),
          BalanceLineChart(uid: uid),
          const SizedBox(height: 24),
          SavingsPieChart(uid: uid),
          const SizedBox(height: 24),
          SavingsGoalProgress(uid: uid),
          const SizedBox(height: 24),
          PredictiveSpendingChart(uid: uid),
          const SizedBox(height: 24),
          TransactionFrequencyChart(uid: uid),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
