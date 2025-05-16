import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class TransactionsPage extends StatefulWidget {
  final String type;
  final String label;

  const TransactionsPage({super.key, required this.type, required this.label});

  @override
  State<TransactionsPage> createState() => _TransactionsPageState();
}

class _TransactionsPageState extends State<TransactionsPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _labelController = TextEditingController();

  double _currentBalance = 0.0; // To store the user's current balance

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _dateController.text = DateFormat('dd/MM/yyyy').format(now);

    _fetchUserBalance();  // Fetch balance on page load
  }

  Future<void> _fetchUserBalance() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    try {
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      if (userDoc.exists) {
        final data = userDoc.data();
        setState(() {
          _currentBalance = (data?['balance'] ?? 0).toDouble();
        });
      }
    } catch (e) {
      // Handle errors if needed, e.g. print or log
    }
  }

  Future<void> _submitTransaction() async {
    if (!_formKey.currentState!.validate()) return;

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final amount = double.parse(_amountController.text);

    // Check if expense amount > balance
    if (widget.type == 'expense' && amount > _currentBalance) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Expense amount cannot exceed current balance ₹${_currentBalance.toStringAsFixed(2)}',
          ),
        ),
      );
      return; // Prevent submission if expense too high
    }

    final String label = widget.type == 'income'
        ? (_labelController.text.trim().isEmpty ? 'N/A' : _labelController.text.trim())
        : widget.label;

    try {
      await FirebaseFirestore.instance.collection('transactions').add({
        'uid': uid,
        'type': widget.type,
        'label': label,
        'amount': amount,
        'description': _descriptionController.text.trim(),
        'date': _dateController.text.trim(),
        'timestamp': Timestamp.now(),
      });

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Transaction added successfully')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0B2D),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D0B2D),
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          '${widget.type[0].toUpperCase()}${widget.type.substring(1)} Transaction',
          style: const TextStyle(color: Colors.white),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Date
              TextFormField(
                controller: _dateController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Date (DD/MM/YYYY)',
                  labelStyle: TextStyle(color: Colors.white70),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.white24),
                  ),
                ),
                validator: (value) {
                  if (value == null || !RegExp(r'^\d{2}/\d{2}/\d{4}$').hasMatch(value)) {
                    return 'Enter date in DD/MM/YYYY';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Amount
              TextFormField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Amount',
                  labelStyle: TextStyle(color: Colors.white70),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.white24),
                  ),
                ),
                validator: (value) {
                  if (value == null || double.tryParse(value) == null) {
                    return 'Enter a valid number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Label (only for income)
              if (widget.type == 'income') ...[
                TextFormField(
                  controller: _labelController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Label (e.g., Salary)',
                    labelStyle: TextStyle(color: Colors.white70),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.white24),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Label is required for income';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
              ],

              // Description
              TextFormField(
                controller: _descriptionController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Description (optional)',
                  labelStyle: TextStyle(color: Colors.white70),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.white24),
                  ),
                ),
              ),
              const Spacer(),

              // Submit Button
              ElevatedButton(
                onPressed: _submitTransaction,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.lightGreenAccent,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: const Text(
                  'Add Transaction',
                  style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
