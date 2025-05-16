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
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Padding(
          padding: EdgeInsets.only(bottom: 8.0),
          child: Center(
            child: Text(
              'Transaction Frequency by Day',
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
                barGroups: List.generate(labels.length, (index) {
                  return BarChartGroupData(
                    x: index,
                    barRods: [
                      BarChartRodData(
                        toY: dayMap[labels[index]]!.toDouble(),
                        color: Colors.redAccent,
                        width: 16,
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ],
                  );
                }),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        if (value.toInt() < labels.length) {
                          return Text(
                            labels[value.toInt()],
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
      ],
    );
  }
}
