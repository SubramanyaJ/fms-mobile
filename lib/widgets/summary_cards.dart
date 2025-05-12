// summary_cards.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class SummaryCards extends StatelessWidget {
  final String uid;
  const SummaryCards({super.key, required this.uid});

  Future<Map<String, dynamic>> fetchSummary() async {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);

    final transactionSnapshot = await FirebaseFirestore.instance
        .collection('transactions')
        .where('uid', isEqualTo: uid)
        .get();

    final savingsSnapshot = await FirebaseFirestore.instance
        .collection('savings')
        .where('uid', isEqualTo: uid)
        .get();

    double income = 0;
    double expense = 0;
    int transactionCount = 0;

    for (var doc in transactionSnapshot.docs) {
      final data = doc.data();
      final ts = data['timestamp']?.toDate();
      if (ts != null && ts.isAfter(startOfMonth)) {
        transactionCount++;
      }

      if (data['type'] == 'income') {
        income += data['amount'] * 1.0;
      } else if (data['type'] == 'expense') {
        expense += data['amount'] * 1.0;
      }
    }

    double totalGoal = 0;
    for (var doc in savingsSnapshot.docs) {
      final data = doc.data();
      totalGoal += data['amount'] * 1.0;
    }

    final currentBalance = income - expense;

    return {
      'income': income,
      'expense': expense,
      'balance': currentBalance,
      'transactionCount': transactionCount,
      'totalGoal': totalGoal,
    };
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.simpleCurrency(locale: 'en_IN');

    return FutureBuilder<Map<String, dynamic>>(
      future: fetchSummary(),
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

        final data = snapshot.data!;

        final cards = [
          _buildCard('Income', currencyFormat.format(data['income']), Colors.greenAccent),
          _buildCard('Expenses', currencyFormat.format(data['expense']), Colors.redAccent),
          _buildCard('Balance', currencyFormat.format(data['balance']), Colors.blueAccent),
          _buildCard('Transactions (This Month)', data['transactionCount'].toString(), Colors.orangeAccent),
          _buildCard('Savings Goal', currencyFormat.format(data['totalGoal']), Colors.tealAccent),
        ];

        return SizedBox(
          height: 130,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: cards.length,
            separatorBuilder: (context, index) => const SizedBox(width: 12),
            itemBuilder: (context, index) => cards[index],
          ),
        );
      },
    );
  }

  Widget _buildCard(String title, String value, Color color) {
    return Container(
      width: 200,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(title, style: const TextStyle(color: Colors.white70, fontSize: 14)),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
