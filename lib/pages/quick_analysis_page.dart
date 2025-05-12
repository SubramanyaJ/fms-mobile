import 'home_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'daily_analysis_view.dart';
import 'weekly_analysis_view.dart';
import 'monthly_analysis_view.dart';
import 'yearly_analysis_view.dart';
import '../widgets/pull_to_refresh_wrapper.dart'; // 👈 NEW import

class QuickAnalysisPage extends StatefulWidget {
  const QuickAnalysisPage({super.key});

  @override
  State<QuickAnalysisPage> createState() => _QuickAnalysisPageState();
}

class _QuickAnalysisPageState extends State<QuickAnalysisPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  double totalIncome = 0.0;
  double totalExpense = 0.0;

  final List<Tab> tabs = const [
    Tab(text: 'Daily'),
    Tab(text: 'Weekly'),
    Tab(text: 'Monthly'),
    Tab(text: 'Year'),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: tabs.length, vsync: this);
    fetchTransactionData();
  }

  Future<void> fetchTransactionData() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('transactions')
          .where('uid', isEqualTo: FirebaseAuth.instance.currentUser?.uid)
          .get();

      double income = 0.0;
      double expense = 0.0;

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final rawAmount = data['amount'];
        final type = data['type'];

        double amount = 0.0;
        if (rawAmount is int) {
          amount = rawAmount.toDouble();
        } else if (rawAmount is double) {
          amount = rawAmount;
        }

        if (type == 'income') {
          income += amount;
        } else if (type == 'expense') {
          expense += amount;
        }
      }

      setState(() {
        totalIncome = income;
        totalExpense = expense;
      });
    } catch (e) {
      debugPrint("Error fetching data: $e");
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  double getBalance() => totalIncome - totalExpense;

  @override
  Widget build(BuildContext context) {
    double progress = totalIncome == 0 ? 0 : totalExpense / totalIncome;

    return Scaffold(
      backgroundColor: const Color(0xFF0B0720),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0B0720),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () {
            HomePage.setTab(0); // Back to Home tab
          },
        ),
        title: const Text('Analysis', style: TextStyle(color: Colors.white)),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 12.0),
            child: Icon(Icons.notifications, color: Colors.white),
          ),
        ],
      ),
      body: PullToRefreshWrapper(
        onRefresh: fetchTransactionData, // 👈 Refresh logic here
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildAmountInfo(
                        'Total Balance',
                        '₹${getBalance().toStringAsFixed(2)}',
                      ),
                      _buildAmountInfo(
                        'Total Expense',
                        '-₹${totalExpense.toStringAsFixed(2)}',
                        color: Colors.cyanAccent,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: LinearProgressIndicator(
                      value: progress.clamp(0.0, 1.0),
                      backgroundColor: Colors.white10,
                      valueColor: const AlwaysStoppedAnimation<Color>(
                          Colors.lightGreenAccent),
                      minHeight: 10,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${(progress * 100).toStringAsFixed(0)}% Of Your Expenses, Looks Good.',
                    style: const TextStyle(color: Colors.white60),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF140D38),
                borderRadius: BorderRadius.circular(20),
              ),
              margin: const EdgeInsets.symmetric(horizontal: 20),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: Colors.lightGreenAccent.withOpacity(0.3),
                ),
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white54,
                tabs: tabs,
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: const [
                  DailyAnalysisView(),
                  WeeklyAnalysisView(),
                  MonthlyAnalysisView(),
                  YearlyAnalysisView(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAmountInfo(String label, String value,
      {Color color = Colors.white}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white70)),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
              fontSize: 20, fontWeight: FontWeight.bold, color: color),
        ),
      ],
    );
  }
}
