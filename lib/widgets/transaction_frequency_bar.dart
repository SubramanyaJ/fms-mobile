import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

class TransactionFrequencyChart extends StatelessWidget {
  final String uid;
  const TransactionFrequencyChart({super.key, required this.uid});

  Future<Map<String, int>> fetchDailyFrequencies() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('transactions')
          .where('uid', isEqualTo: uid)
          .get();

      final formatter = DateFormat('EEE');
      Map<String, int> dayCount = {
        'Mon': 0, 'Tue': 0, 'Wed': 0, 'Thu': 0, 'Fri': 0, 'Sat': 0, 'Sun': 0,
      };

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final timestamp = (data['timestamp'] as Timestamp?)?.toDate();
        if (timestamp == null) continue;
        final weekday = formatter.format(timestamp);
        if (dayCount.containsKey(weekday)) {
          dayCount[weekday] = dayCount[weekday]! + 1;
        }
      }
      return dayCount;
    } catch (e, stack) {
      print("[TransactionFrequencyChart] fetchDailyFrequencies error: $e");
      print(stack);
      return {};
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, int>>(
      future: fetchDailyFrequencies(),
      builder: (context, snapshot) {
        final widgetName = runtimeType.toString();

        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingIndicator(widgetName);
        } else if (snapshot.hasError) {
          return _buildErrorText(widgetName);
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return _buildNoDataText(widgetName);
        }

        final dayMap = snapshot.data!;
        final labels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

        return _buildChartContainer(dayMap, labels);
      },
    );
  }

  Widget _buildLoadingIndicator(String widgetName) {
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
  }

  Widget _buildErrorText(String widgetName) {
    return Center(
      child: Text("Error loading $widgetName", style: const TextStyle(color: Colors.white)),
    );
  }

  Widget _buildNoDataText(String widgetName) {
    return Center(
      child: Text("No data for $widgetName", style: const TextStyle(color: Colors.white)),
    );
  }

  Widget _buildChartContainer(Map<String, int> dayMap, List<String> labels) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.lightBlue[50],
        borderRadius: BorderRadius.circular(16),
      ),
      child: Center(
        child: AspectRatio(
          aspectRatio: 1.6,
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              barTouchData: BarTouchData(enabled: true),
              titlesData: FlTitlesData(
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      const labels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
                      final index = value.toInt();
                      if (index < 0 || index >= labels.length) return const SizedBox.shrink();

                      return SideTitleWidget(
                        meta: meta,
                        space: 8,
                        child: Text(
                          labels[index],
                          style: const TextStyle(fontSize: 12, color: Colors.black),
                        ),
                      );
                    },
                    reservedSize: 32,
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 40,
                    getTitlesWidget: (value, meta) {
                      return SideTitleWidget(
                        meta: meta,
                        space: 8,
                        child: Text(
                          value.toInt().toString(),
                          style: const TextStyle(fontSize: 14, color: Colors.black),
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
              gridData: FlGridData(
                show: true,
                getDrawingHorizontalLine: (value) => FlLine(color: Colors.grey, strokeWidth: 0.8),
                getDrawingVerticalLine: (value) => FlLine(color: Colors.grey, strokeWidth: 0.8),
              ),
              borderData: FlBorderData(
                show: true,
                border: const Border(
                  left: BorderSide(color: Colors.black, width: 1),
                  bottom: BorderSide(color: Colors.black, width: 1),
                  right: BorderSide(color: Colors.transparent), // hide right
                  top: BorderSide(color: Colors.transparent),   // hide top
                ),
              ),
              barGroups: List.generate(labels.length, (i) {
                return BarChartGroupData(
                  x: i,
                  barRods: [
                    BarChartRodData(
                      toY: dayMap[labels[i]]!.toDouble(),
                      width: 18,
                      color: Colors.lightBlueAccent,
                    ),
                  ],
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}
