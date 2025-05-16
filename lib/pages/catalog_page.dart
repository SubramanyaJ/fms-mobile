import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'home_page.dart';
import 'select_expense_category_page.dart';
import 'transactions.dart';
import 'savings.dart';

class CatalogPage extends StatefulWidget {
  const CatalogPage({super.key});

  @override
  State<CatalogPage> createState() => _CatalogPageState();
}

class _CatalogPageState extends State<CatalogPage> {
  Future<void> _refresh() async {
    setState(() {}); // triggers rebuild and refetch
    await Future.delayed(const Duration(milliseconds: 500));
  }

  void _showTransferDialog(double balance) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final savingsSnapshot = await FirebaseFirestore.instance
        .collection('savings')
        .where('uid', isEqualTo: uid)
        .get();

    final savingsList = savingsSnapshot.docs;

    String? selectedSavingsId;
    final amountController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1A183A),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Transfer to Savings', style: TextStyle(color: Colors.white)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                dropdownColor: const Color(0xFF1A183A),
                decoration: const InputDecoration(
                  labelText: 'Select Savings',
                  labelStyle: TextStyle(color: Colors.white70),
                ),
                style: const TextStyle(color: Colors.white),
                items: savingsList.map((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final title = data['label'] ?? 'Unnamed';
                  return DropdownMenuItem<String>(
                    value: doc.id,
                    child: Text(title, style: const TextStyle(color: Colors.white)),
                  );
                }).toList(),
                onChanged: (value) => selectedSavingsId = value,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: amountController,
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Amount',
                  labelStyle: TextStyle(color: Colors.white70),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
            ),
            ElevatedButton(
              onPressed: () async {
                final amount = double.tryParse(amountController.text);
                if (selectedSavingsId == null || amount == null || amount <= 0 || amount > balance) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Invalid input')),
                  );
                  return;
                }

                try {
                  final savingsRef = FirebaseFirestore.instance.collection('savings').doc(selectedSavingsId);
                  final savingsDoc = await savingsRef.get();
                  final currentTransfer = (savingsDoc.data()?['transfer'] ?? 0.0) as num;

                  await savingsRef.update({
                    'transfer': currentTransfer + amount,
                  });

                  await FirebaseFirestore.instance.collection('transactions').add({
                    'uid': uid,
                    'type': 'expense',
                    'label': 'Transfer to savings',
                    'amount': amount,
                    'timestamp': Timestamp.now(),
                  });

                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Transfer successful')),
                  );
                  setState(() {}); // Refresh UI
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Transfer failed: $e')),
                  );
                }
              },
              child: const Text('Transfer'),
            ),
          ],
        );
      },
    );
  }



  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      backgroundColor: const Color(0xFF0D0B2D),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D0B2D),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => HomePage.setTab(0),
        ),
        title: const Text(
          'Catalog',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: uid == null
            ? const Stream.empty()
            : FirebaseFirestore.instance
            .collection('transactions')
            .where('uid', isEqualTo: uid)
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error: ${snapshot.error}',
                style: const TextStyle(color: Colors.white),
              ),
            );
          }

          final docs = snapshot.data?.docs ?? [];

          double income = 0.0;
          double expense = 0.0;

          for (final doc in docs) {
            final data = doc.data() as Map<String, dynamic>;
            final type = (data['type'] ?? '').toString().toLowerCase();
            final rawAmount = data['amount'];
            final amount = rawAmount is num
                ? rawAmount.toDouble()
                : double.tryParse(rawAmount.toString()) ?? 0.0;

            if (type == 'income') {
              income += amount;
            } else if (type == 'expense') {
              expense += amount;
            }
          }

          final balance = income - expense;

          if (uid != null) {
            FirebaseFirestore.instance.collection('users').doc(uid).set({
              'balance': balance,
            }, SetOptions(merge: true));
          }

          return RefreshIndicator(
            onRefresh: _refresh,
            color: Colors.lightBlueAccent,
            backgroundColor: const Color(0xFF0D0B2D),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding: const EdgeInsets.symmetric(
                        vertical: 20, horizontal: 16),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: const [
                            Text(
                              'Total Balance',
                              style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white),
                            ),
                            Text(
                              'Total Expense',
                              style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.lightBlueAccent),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '₹${balance.toStringAsFixed(2)}',
                              style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white),
                            ),
                            Text(
                              '-₹${expense.toStringAsFixed(2)}',
                              style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.lightBlueAccent),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 10),

                  SizedBox(
                    width: double.infinity,
                    height: 45,
                    child: ElevatedButton(
                      onPressed: () => _showTransferDialog(balance),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurpleAccent,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: const Text(
                        'Transfer to Savings',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 45,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).push(MaterialPageRoute(
                          builder: (_) => const SavingsPage(),
                        ));
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFB5F12D),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                      ),
                      child: const Text(
                        'Savings',
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black),
                      ),
                    ),
                  ),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.of(context).push(MaterialPageRoute(
                              builder: (_) => const TransactionsPage(
                                  type: 'income', label: 'N/A'),
                            ));
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16)),
                          ),
                          child: const Text(
                            'Income',
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.black),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.of(context).push(MaterialPageRoute(
                              fullscreenDialog: true,
                              builder: (context) =>
                              const SelectExpenseCategoryPage(),
                            ));
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16)),
                          ),
                          child: const Text(
                            'Expense',
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.black),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Recent Transactions',
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 18,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Column(
                    children: docs.take(5).map((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      final type =
                      (data['type'] ?? 'unknown').toString().toLowerCase();
                      final label =
                      (data['label'] ?? 'No Label').toString().trim();
                      final rawAmount = data['amount'];
                      final amount = rawAmount is num
                          ? rawAmount.toDouble()
                          : double.tryParse(rawAmount.toString()) ?? 0.0;
                      final timestamp = data['timestamp'] as Timestamp?;
                      final dateStr = timestamp != null
                          ? DateFormat('dd MMM, hh:mm a')
                          .format(timestamp.toDate())
                          : 'Unknown';

                      final isIncome = type == 'income';
                      final icon =
                      isIncome ? Icons.arrow_downward : Icons.arrow_upward;
                      final iconColor =
                      isIncome ? Colors.greenAccent : Colors.redAccent;

                      return Container(
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1A183A),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: iconColor.withOpacity(0.2),
                              child: Icon(icon, color: iconColor),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    label,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  Text(
                                    dateStr,
                                    style: const TextStyle(
                                        color: Colors.white54, fontSize: 13),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              '${isIncome ? '+' : '-'}₹${amount.toStringAsFixed(2)}',
                              style: TextStyle(
                                color: iconColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
