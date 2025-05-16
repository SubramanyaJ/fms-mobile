import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class SavingsPage extends StatefulWidget {
  const SavingsPage({super.key});

  @override
  State<SavingsPage> createState() => _SavingsPageState();
}

class _SavingsPageState extends State<SavingsPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _labelController = TextEditingController();

  // NEW controllers and variables for duration
  final TextEditingController _durationController = TextEditingController();
  String _durationUnit = 'Months'; // default

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _dateController.text = DateFormat('dd/MM/yyyy').format(now);
  }

  Future<void> _submitSaving() async {
    if (!_formKey.currentState!.validate()) return;

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    try {
      await FirebaseFirestore.instance.collection('savings').add({
        'uid': uid,
        'amount': double.parse(_amountController.text),
        'description': _descriptionController.text.trim(),
        'label': _labelController.text.trim(),
        'date': _dateController.text.trim(),
        'timestamp': Timestamp.now(),

        // NEW duration field
        'duration': {
          'value': int.parse(_durationController.text),
          'unit': _durationUnit.toLowerCase(), // 'months' or 'years'
        },
      });

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Saving added successfully')),
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
        title: const Text(
          'Add Savings',
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Date Input
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

              // Amount Input
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

              // Label Input
              TextFormField(
                controller: _labelController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Label',
                  labelStyle: TextStyle(color: Colors.white70),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.white24),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Label is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // NEW Duration Input Row
              Row(
                children: [
                  // Duration number input
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      controller: _durationController,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: 'Duration',
                        labelStyle: TextStyle(color: Colors.white70),
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.white24),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || int.tryParse(value) == null || int.parse(value) <= 0) {
                          return 'Enter a valid duration';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),

                  // Duration unit dropdown
                  Expanded(
                    flex: 1,
                    child: DropdownButtonFormField<String>(
                      value: _durationUnit,
                      dropdownColor: const Color(0xFF0D0B2D),
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: 'Unit',
                        labelStyle: TextStyle(color: Colors.white70),
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.white24),
                        ),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'Months', child: Text('Months')),
                        DropdownMenuItem(value: 'Years', child: Text('Years')),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _durationUnit = value;
                          });
                        }
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Description Input
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
                onPressed: _submitSaving,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.lightGreenAccent,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: const Text(
                  'Add Saving',
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


