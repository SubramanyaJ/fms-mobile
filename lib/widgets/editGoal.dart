import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EditGoalDialog extends StatefulWidget {
  final String goalId;
  final VoidCallback onUpdate;

  const EditGoalDialog({super.key, required this.goalId, required this.onUpdate});

  @override
  _EditGoalDialogState createState() => _EditGoalDialogState();
}

class _EditGoalDialogState extends State<EditGoalDialog> {
  late TextEditingController _descriptionController;
  late TextEditingController _amountController;
  bool _isLoading = true;
  String _goalDescription = '';
  double _goalAmount = 0.0;

  @override
  void initState() {
    super.initState();
    _descriptionController = TextEditingController();
    _amountController = TextEditingController();
    _fetchGoalData();
  }

  Future<void> _fetchGoalData() async {
    try {
      final docSnapshot = await FirebaseFirestore.instance
          .collection('savings')
          .doc(widget.goalId)
          .get();

      if (docSnapshot.exists) {
        final data = docSnapshot.data();
        setState(() {
          _goalDescription = data?['label'] ?? '';
          _goalAmount = (data?['amount'] ?? 0.0).toDouble();
          _descriptionController.text = _goalDescription;
          _amountController.text = _goalAmount.toStringAsFixed(2);
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Goal data not found')));
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _updateGoalData() async {
    if (_descriptionController.text.isEmpty || _amountController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please fill in both fields')),
      );
      return;
    }

    try {
      final updatedDescription = _descriptionController.text;
      final updatedAmount = double.tryParse(_amountController.text);

      if (updatedAmount != null && updatedAmount > 0) {
        await FirebaseFirestore.instance
            .collection('savings')
            .doc(widget.goalId)
            .update({
          'label': updatedDescription,
          'amount': updatedAmount,
        });

        widget.onUpdate(); // Notify parent to refresh the page
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Goal updated successfully')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Please enter a valid amount')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating goal: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Material(
        color: Colors.transparent,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(labelText: 'Goal Description'),
                ),
                TextField(
                  controller: _amountController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Goal Amount'),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _updateGoalData,
                  child: const Text('Update Goal'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
