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
        final colors = [Colors.lightBlueAccent, Colors.redAccent];

        return AspectRatio(
          aspectRatio: 1.4,
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
        );
      },
    );
  }
}
