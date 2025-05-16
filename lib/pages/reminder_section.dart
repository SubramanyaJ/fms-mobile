import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class ReminderSection extends StatefulWidget {
  final String uid;

  const ReminderSection({required this.uid, Key? key}) : super(key: key);

  @override
  State<ReminderSection> createState() => _ReminderSectionState();
}

class _ReminderSectionState extends State<ReminderSection> {
  Stream<List<Map<String, dynamic>>> _getReminders() {
    return FirebaseFirestore.instance
        .collection('reminders')
        .where('uid', isEqualTo: widget.uid)
        //.orderBy('dueDate')
        .snapshots()
        .map((snap) => snap.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id;
      return data;
    }).toList());
  }

  Future<void> showReminderDialog(BuildContext context, [Map<String, dynamic>? reminder]) async {
    final _formKey = GlobalKey<FormState>();
    String title = reminder?['title'] ?? '';
    String note = reminder?['note'] ?? '';
    String amount = reminder?['amount']?.toString() ?? '';
    DateTime? dueDate = reminder != null ? (reminder['dueDate'] as Timestamp).toDate() : null;

    // To pick a date
    Future<void> pickDueDate() async {
      final picked = await showDatePicker(
        context: context,
        initialDate: dueDate ?? DateTime.now(),
        firstDate: DateTime.now(),
        lastDate: DateTime.now().add(Duration(days: 365 * 5)),
      );
      if (picked != null) {
        setState(() {
          dueDate = picked;
        });
      }
    }

    await showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              backgroundColor: Color(0xFF2A2767),
              title: Text(reminder == null ? 'Add Reminder' : 'Edit Reminder', style: TextStyle(color: Colors.white)),
              content: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        initialValue: title,
                        style: TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: 'Title',
                          labelStyle: TextStyle(color: Colors.white70),
                          enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white54)),
                        ),
                        validator: (val) => val == null || val.trim().isEmpty ? 'Title is required' : null,
                        onChanged: (val) => title = val,
                      ),
                      TextFormField(
                        initialValue: note,
                        style: TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: 'Note',
                          labelStyle: TextStyle(color: Colors.white70),
                          enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white54)),
                        ),
                        maxLines: 2,
                        onChanged: (val) => note = val,
                      ),
                      TextFormField(
                        initialValue: amount,
                        style: TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: 'Amount (₹)',
                          labelStyle: TextStyle(color: Colors.white70),
                          enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white54)),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) return null;
                          return double.tryParse(val) == null ? 'Enter valid amount' : null;
                        },
                        onChanged: (val) => amount = val,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Text(
                            dueDate == null ? 'Select due date' : DateFormat('dd MMM yyyy').format(dueDate!),
                            style: TextStyle(color: Colors.white70),
                          ),
                          Spacer(),
                          TextButton(
                            onPressed: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: dueDate ?? DateTime.now(),
                                firstDate: DateTime.now(),
                                lastDate: DateTime.now().add(Duration(days: 365 * 5)),
                              );
                              if (picked != null) {
                                setStateDialog(() {
                                  dueDate = picked;
                                });
                              }
                            },
                            child: Text('Pick Date', style: TextStyle(color: Colors.lightBlueAccent)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: Text('Cancel', style: TextStyle(color: Colors.white70)),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (_formKey.currentState!.validate() && dueDate != null) {
                      final reminderData = {
                        'uid': widget.uid,
                        'title': title.trim(),
                        'note': note.trim(),
                        'amount': amount.trim().isEmpty ? null : double.parse(amount),
                        'dueDate': Timestamp.fromDate(dueDate!),
                      };
                      final collection = FirebaseFirestore.instance.collection('reminders');
                      if (reminder == null) {
                        // Add new reminder
                        await collection.add(reminderData);
                      } else {
                        // Update existing reminder
                        await collection.doc(reminder['id']).update(reminderData);
                      }
                      Navigator.of(ctx).pop();
                    }
                  },
                  child: Text(reminder == null ? 'Add' : 'Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Upcoming Bills / Reminders',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            Spacer(),
            IconButton(
              icon: Icon(Icons.add, color: Colors.white70, size: 20),
              onPressed: () => showReminderDialog(context),
            ),
          ],
        ),
        const SizedBox(height: 8),
        StreamBuilder<List<Map<String, dynamic>>>(
          stream: _getReminders(),
          builder: (context, snapshot) {
            final reminders = snapshot.data ?? [];
            if (reminders.isEmpty) {
              return Text(
                'No reminders yet.',
                style: TextStyle(color: Colors.white38, fontSize: 13),
              );
            }

            return SizedBox(
              height: 350, // or whatever height fits your layout
              child: ListView(
                physics: BouncingScrollPhysics(),
                children: reminders.map((reminder) {
                  final dueDate = (reminder['dueDate'] as Timestamp).toDate();
                  final formattedDate = DateFormat('dd MMM yyyy').format(dueDate);
                  final title = reminder['title'] ?? '';
                  final note = reminder['note'] ?? '';
                  final amount = reminder['amount']?.toString() ?? '';

                  return Dismissible(
                    key: ValueKey(reminder['id']),
                    background: Container(
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      alignment: Alignment.centerLeft,
                      padding: EdgeInsets.only(left: 20),
                      child: Icon(Icons.delete, color: Colors.white),
                    ),
                    secondaryBackground: Container(
                      decoration: BoxDecoration(
                        color: Colors.blue,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      alignment: Alignment.centerRight,
                      padding: EdgeInsets.only(right: 20),
                      child: Icon(Icons.edit, color: Colors.white),
                    ),
                    confirmDismiss: (direction) async {
                      if (direction == DismissDirection.startToEnd) {
                        // Delete
                        await FirebaseFirestore.instance
                            .collection('reminders')
                            .doc(reminder['id'])
                            .delete();
                        return true;
                      } else {
                        // Edit
                        await showReminderDialog(context, reminder);
                        return false;
                      }
                    },
                    child: Card(
                      color: const Color(0xFF1F1B4A),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        title: Text(title,
                            style: TextStyle(color: Colors.white, fontSize: 14)),
                        subtitle: Text(
                          note.isNotEmpty ? '$note\nDue: $formattedDate' : 'Due: $formattedDate',
                          style: TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                        trailing: amount.isNotEmpty
                            ? Text(
                          '₹$amount',
                          style: TextStyle(color: Colors.greenAccent),
                        )
                            : null,
                      ),
                    ),
                  );
                }).toList(),
              ),
            );
          },
        ),
      ],
    );
  }
}
