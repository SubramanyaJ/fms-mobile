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

class _QuickAnalysisPageState extends State<QuickAnalysisPage> with SingleTickerProviderStateMixin {
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

        double amount = (rawAmount is int) ? rawAmount.toDouble() : rawAmount;

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
      appBar: _buildAppBar(),
      body: PullToRefreshWrapper(
        onRefresh: fetchTransactionData,
        child: Column(
          children: [
            _buildSummarySection(progress),
            const SizedBox(height: 20),
            _buildTabBar(),
            const SizedBox(height: 20),
            _buildTabBarView(),
          ],
        ),
      ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
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
          padding: EdgeInsets.only(right: 20.0),
          child: Opacity(
            opacity: 1, // 50% opacity
            child: Icon(
              Icons.settings,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSummarySection(double progress) {
    Color progressColor;
    String message;

    if (progress <= 0.5) {
      progressColor = Colors.greenAccent;
      message = "Great! You're spending only ${(progress * 100).toStringAsFixed(0)}% of your income.";
    } else if (progress <= 0.8) {
      progressColor = Colors.orangeAccent;
      message = "Careful! You're spending ${(progress * 100).toStringAsFixed(0)}% of your income.";
    } else {
      progressColor = Colors.redAccent;
      message = progress > 1
          ? "Warning! Your expenses exceed your income!"
          : "Warning! You're spending ${(progress * 100).toStringAsFixed(0)}% of your income.";
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildAmountInfo('Total Balance', '₹${getBalance().toStringAsFixed(2)}'),
              _buildAmountInfo('Total Expense', '-₹${totalExpense.toStringAsFixed(2)}', color: Colors.cyanAccent),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Expense vs Income',
            style: const TextStyle(
              color: Colors.white70,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              backgroundColor: Colors.white10,
              valueColor: AlwaysStoppedAnimation<Color>(progressColor),
              minHeight: 12,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            style: TextStyle(
              color: progressColor.withOpacity(0.8),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF140D38),
          borderRadius: BorderRadius.circular(30),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final tabWidth = constraints.maxWidth / 4;

            return TabBar(
              isScrollable: false,
              controller: _tabController,
              indicator: BoxDecoration(
                color: Colors.cyanAccent.withOpacity(0.4),
                borderRadius: BorderRadius.circular(20),
              ),
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white54,
              tabs: tabs.map((tab) => SizedBox(
                width: tabWidth,
                height: 46,
                child: Center(child: tab),
              )).toList(),
            );
          },
        ),
      ),
    );
  }

  Widget _buildTabBarView() {
    return Expanded(
      child: TabBarView(
        controller: _tabController,
        children: const [
          DailyAnalysisView(),
          WeeklyAnalysisView(),
          MonthlyAnalysisView(),
          YearlyAnalysisView(),
        ],
      ),
    );
  }

  Widget _buildAmountInfo(String label, String value, {Color color = Colors.white}) {
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
