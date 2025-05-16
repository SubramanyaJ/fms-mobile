// expense_bar_chart.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';

class ExpenseBarChart extends StatelessWidget {
  final String uid;
  const ExpenseBarChart({super.key, required this.uid});

  Future<Map<String, double>> fetchExpensesByCategory() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('transactions')
        .where('uid', isEqualTo: uid)
        .where('type', isEqualTo: 'expense')
        .get();

    final Map<String, double> categoryTotals = {};

    for (var doc in snapshot.docs) {
      final data = doc.data();
      final category = data['label'] ?? 'Others';
      final amount = (data['amount'] ?? 0).toDouble();

      if (categoryTotals.containsKey(category)) {
        categoryTotals[category] = categoryTotals[category]! + amount;
      } else {
        categoryTotals[category] = amount;
      }
    }

    final sorted = categoryTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final top5 = Map.fromEntries(sorted.take(5));
    return top5;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, double>>(
      future: fetchExpensesByCategory(),
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

        final categoryData = snapshot.data!;
        final categories = categoryData.keys.toList();
        final values = categoryData.values.toList();

        return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
        const Padding(
        padding: EdgeInsets.only(bottom: 8.0),
        child: Center(
        child: Text(
        'Top 5 Expense Categories',
        style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: Colors.white, // Match your dark theme
        ),
        ),
        ),
        ),

          AspectRatio(
            aspectRatio: 1.5,
            child: Container(
            padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
        color: Colors.cyanAccent.withOpacity(0.25), // 🎯 Set your background color here
        borderRadius: BorderRadius.circular(12), // optional for rounded edges
        ),
          child: BarChart(
            BarChartData(
              barGroups: List.generate(categories.length, (index) {
                return BarChartGroupData(
                  x: index,
                  barRods: [
                    BarChartRodData(
                      toY: values[index],
                      color: Colors.redAccent,
                      width: 16,
                      borderRadius: BorderRadius.circular(8),
                    )
                  ],
                );
              }),
              titlesData: FlTitlesData(
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      if (value.toInt() < categories.length) {
                        final category = categories[value.toInt()];
                        final displayLabel = category.length > 5 ? category[0].toUpperCase() : category;
                        return Text(
                          displayLabel,
                          style: const TextStyle(fontSize: 12, color: Colors.white),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                ),

                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 40,
                    getTitlesWidget: (value, meta) {
                      return Text(
                        value.toInt().toString(),
                        style: const TextStyle(
                          color: Colors.white, // 👈 Set your desired color
                          fontSize: 12,
                        ),
                      );
                    },
                  ),
                ),
                rightTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                topTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
              ),
              borderData: FlBorderData(show: false),
              gridData: FlGridData(show: false),
            ),
          ),
        ),
        ),
        ]
        );
      },
    );
  }
}
