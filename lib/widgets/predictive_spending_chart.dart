// predictive_spending_chart.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'dart:math';

class PredictiveSpendingChart extends StatelessWidget {
  final String uid;
  const PredictiveSpendingChart({super.key, required this.uid});

  Future<List<FlSpot>> fetchAndPredict() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('transactions')
        .where('uid', isEqualTo: uid)
        .get();

    Map<String, double> dailyExpenses = {};

    for (var doc in snapshot.docs) {
      final data = doc.data();
      if (data['type'] == 'expense' && data['timestamp'] != null) {
        final date = (data['timestamp'] as Timestamp).toDate();
        final key = DateFormat('yyyy-MM-dd').format(date);
        dailyExpenses[key] = (dailyExpenses[key] ?? 0) + (data['amount'] ?? 0).toDouble();
      }
    }

    final sortedKeys = dailyExpenses.keys.toList()..sort();
    List<FlSpot> actualSpots = [];
    for (int i = 0; i < sortedKeys.length; i++) {
      actualSpots.add(FlSpot(i.toDouble(), dailyExpenses[sortedKeys[i]]!));
    }

    // Simple linear regression for prediction (last + avg delta)
    if (actualSpots.length >= 2) {
      double lastY = actualSpots.last.y;
      double deltaSum = 0;
      for (int i = 1; i < actualSpots.length; i++) {
        deltaSum += actualSpots[i].y - actualSpots[i - 1].y;
      }
      double avgDelta = deltaSum / (actualSpots.length - 1);

      for (int i = 1; i <= 5; i++) {
        actualSpots.add(FlSpot(
          actualSpots.length.toDouble(),
          max(0, lastY + i * avgDelta),
        ));
      }
    }

    return actualSpots;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<FlSpot>>(
      future: fetchAndPredict(),
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

        final spots = snapshot.data!;
        return AspectRatio(
          aspectRatio: 1.6,
          child: LineChart(
            LineChartData(
              lineBarsData: [
                LineChartBarData(
                  spots: spots,
                  isCurved: true,
                  dotData: FlDotData(show: false),
                  color: Colors.lightBlueAccent,
                  belowBarData: BarAreaData(show: true, color: Colors.lightBlueAccent.withOpacity(0.3)),
                ),
              ],
              gridData: FlGridData(show: false),
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true)),
                bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              borderData: FlBorderData(show: false),
            ),
          ),
        );
      },
    );
  }
}
