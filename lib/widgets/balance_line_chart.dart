import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

class BalanceLineChart extends StatefulWidget {
  final String uid;
  const BalanceLineChart({super.key, required this.uid});

  @override
  State<BalanceLineChart> createState() => _BalanceLineChartState();
}

class _BalanceLineChartState extends State<BalanceLineChart> {
  Future<List<FlSpot>> fetchBalanceOverTime() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('transactions')
          .where('uid', isEqualTo: widget.uid)
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
    } catch (e) {
      print("[BalanceLineChart] Error: $e");
      return [];
    }
  }

  List<LineChartBarData> _generateColoredSegments(List<FlSpot> points) {
    List<LineChartBarData> segments = [];

    for (int i = 1; i < points.length; i++) {
      final prev = points[i - 1];
      final curr = points[i];

      final isProfit = curr.y >= prev.y;
      segments.add(
        LineChartBarData(
          spots: [prev, curr],
          isCurved: true,
          color: isProfit ? Colors.greenAccent : Colors.redAccent,
          barWidth: 3,
          dotData: FlDotData(show: false),
        ),
      );
    }

    return segments;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<FlSpot>>(
      future: fetchBalanceOverTime(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 8),
                Text("Loading Balance Chart...", style: TextStyle(color: Colors.white)),
              ],
            ),
          );
        } else if (snapshot.hasError) {
          return const Center(
            child: Text("Error loading chart", style: TextStyle(color: Colors.white)),
          );
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(
            child: Text("No transaction data available", style: TextStyle(color: Colors.white)),
          );
        }

        final points = snapshot.data!;
        final chartSegments = _generateColoredSegments(points);

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Balance Over Time',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
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
                            "• This chart shows your balance over time.\n"
                                "• Green lines show days you made a profit.\n"
                                "• Red lines show days you had a loss.\n"
                                "• Tap and hold on the graph to see exact amounts.",
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
            ),
            AspectRatio(
              aspectRatio: 1.7,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.purpleAccent.withOpacity(0.25),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: LineChart(
                  LineChartData(
                    lineTouchData: LineTouchData(
                      handleBuiltInTouches: true,
                      touchTooltipData: LineTouchTooltipData(
                        getTooltipItems: (touchedSpots) {
                          return touchedSpots.map((touchedSpot) {
                            return LineTooltipItem(
                              '₹${touchedSpot.y.toStringAsFixed(2)}',
                              const TextStyle(color: Colors.white),
                            );
                          }).toList();
                        },
                        getTooltipColor: (_) => Colors.black54,
                      ),
                    ),
                    lineBarsData: chartSegments,
                    titlesData: FlTitlesData(
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 40,
                          getTitlesWidget: (value, _) => Text(
                            '₹${value.toInt()}',
                            style: const TextStyle(color: Colors.white70, fontSize: 10),
                          ),
                        ),
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
              ),
            ),
          ],
        );
      },
    );
  }
}
