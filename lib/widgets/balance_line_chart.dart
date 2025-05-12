// balance_line_chart.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

class BalanceLineChart extends StatelessWidget {
  final String uid;
  const BalanceLineChart({super.key, required this.uid});

  Future<List<FlSpot>> fetchBalanceOverTime() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('transactions')
          .where('uid', isEqualTo: uid)
          // .orderBy('timestamp')
          .get();


      Map<String, double> dailyBalance = {};
      double balance = 0;
      final formatter = DateFormat('yyyy-MM-dd');

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final timestamp = (data['timestamp'] as Timestamp?)?.toDate();
        if (timestamp == null) continue;
        final date = formatter.format(timestamp);
        final amount = double.tryParse(data['amount'].toString()) ?? 0.0;
        final type = data['type'];

        if (type == 'income') {
          balance += amount;
        } else if (type == 'expense') {
          balance -= amount;
        }

        dailyBalance[date] = balance;
      }

      final sortedDates = dailyBalance.keys.toList()..sort();
      return List.generate(sortedDates.length, (i) {
        return FlSpot(i.toDouble(), dailyBalance[sortedDates[i]]!);
      });
    } catch (e, stack) {
      print("[BalanceLineChart] fetchBalanceOverTime error: $e");
      print(stack);
      return [];
    }
  }


  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<FlSpot>>(
      future: fetchBalanceOverTime(),
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
          print("[$widgetName] Error: ${snapshot.error}");
          return Center(
            child: Text("Error loading $widgetName", style: TextStyle(color: Colors.white)),
          );
        }
        else if (!snapshot.hasData ||
            (snapshot.data is Iterable && (snapshot.data as Iterable).isEmpty) ||
            (snapshot.data is Map && (snapshot.data as Map).isEmpty)) {
          return Center(
            child: Text("No data for $widgetName", style: const TextStyle(color: Colors.white)),
          );
        }

        final points = snapshot.data!;
        if (points.isEmpty) {
          return const Center(child: Text("No data available"));
        }

        return AspectRatio(
          aspectRatio: 1.7,
          child: LineChart(
            LineChartData(
              lineBarsData: [
                LineChartBarData(
                  spots: points,
                  isCurved: true,
                  color: Colors.lightBlueAccent,
                  barWidth: 3,
                  dotData: FlDotData(show: false),
                ),
              ],
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: true, reservedSize: 40),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                rightTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                topTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
              ),
              gridData: FlGridData(show: false),
              borderData: FlBorderData(show: false),
            ),
          ),
        );
      },
    );
  }
}
