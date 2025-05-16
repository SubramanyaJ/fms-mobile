// savings_pie_chart.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';

class SavingsPieChart extends StatelessWidget {
  final String uid;
  const SavingsPieChart({super.key, required this.uid});

  Future<Map<String, double>> fetchSavingsVsExpenses() async {
    double savingsTotal = 0;
    double expensesTotal = 0;

    final transactionsSnapshot = await FirebaseFirestore.instance
        .collection('transactions')
        .where('uid', isEqualTo: uid)
        .get();

    for (var doc in transactionsSnapshot.docs) {
      final data = doc.data();
      final type = data['type'];
      final amount = (data['amount'] ?? 0).toDouble();
      if (type == 'expense') {
        expensesTotal += amount;
      } else if (type == 'income') {
        savingsTotal += amount;
      }
    }

    final savingsSnapshot = await FirebaseFirestore.instance
        .collection('savings')
        .where('uid', isEqualTo: uid)
        .get();

    for (var doc in savingsSnapshot.docs) {
      final data = doc.data();
      final goalAmount = (data['amount'] ?? 0).toDouble();
      savingsTotal -= goalAmount;
    }

    return {
      'Savings': savingsTotal < 0 ? 0 : savingsTotal,
      'Expenses': expensesTotal
    };
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, double>>(
      future: fetchSavingsVsExpenses(),
      builder: (context, snapshot) {
        final widgetName = runtimeType.toString();

        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 8),
                Text("Loading $widgetName...", style: const TextStyle(color: Colors.white)),
              ],
            ),
          );
        } else if (snapshot.hasError) {
          return Center(
            child: Text("Error loading $widgetName", style: const TextStyle(color: Colors.white)),
          );
        } else if (!snapshot.hasData ||
            (snapshot.data is Iterable && (snapshot.data as Iterable).isEmpty) ||
            (snapshot.data is Map && (snapshot.data as Map).isEmpty)) {
          return Center(
            child: Text("No data for $widgetName", style: const TextStyle(color: Colors.white)),
          );
        }

        final dataMap = snapshot.data!;
        final colors = [Colors.lightGreenAccent, Colors.redAccent];

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Title and Info Button Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Padding(
                  padding: EdgeInsets.only(bottom: 8.0, left: 8.0),
                  child: Text(
                    'Savings vs Expenses',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white, // Match your dark theme
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.info_outline, color: Colors.white),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text("How to Read the Graph"),
                        content: const Text(
                          "• This chart compares your savings and expenses.\n"
                              "• Green section represents your savings balance.\n"
                              "• Red section represents your total expenses.\n"
                              "• If savings are negative, it's shown as 0.\n"
                              "• Tap and hold on the chart to see exact values.\n\n"
                              "• If Savings > Expenses: You're managing money well and likely achieving your financial goals.\n"
                              "• If Expenses > Savings: You may be overspending or not saving enough. Consider cutting unnecessary expenses and prioritizing savings.",
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: const Text("Got it"),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
            AspectRatio(
              aspectRatio: 1.4,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.cyanAccent.withOpacity(0.25), // 🎯 Set your background color here
                  borderRadius: BorderRadius.circular(12), // optional for rounded edges
                ),
                child: PieChart(
                  PieChartData(
                    sections: List.generate(dataMap.length, (index) {
                      final label = dataMap.keys.elementAt(index);
                      final value = dataMap.values.elementAt(index);
                      return PieChartSectionData(
                        color: colors[index],
                        value: value,
                        title: '${label}\n₹${value.toStringAsFixed(0)}',
                        radius: 70,
                        titleStyle: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      );
                    }),
                    sectionsSpace: 4,
                    centerSpaceRadius: 40,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
