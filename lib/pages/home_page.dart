import 'dart:async';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'quick_analysis_page.dart';
import 'profile_page.dart';
import 'catalog_page.dart';
import 'report_page.dart';
import '../widgets/pull_to_refresh_wrapper.dart';
import 'reminder_section.dart'; // ✅ NEW IMPORT

class HomePage extends StatefulWidget {
  static final ValueNotifier<int> tabNotifier = ValueNotifier<int>(0);

  static void setTab(int index) {
    tabNotifier.value = index;
  }

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final List<GlobalKey<NavigatorState>> _navigatorKeys =
  List.generate(5, (_) => GlobalKey<NavigatorState>());

  void _onItemTapped(int index) {
    if (HomePage.tabNotifier.value == index) {
      _navigatorKeys[index].currentState?.popUntil((route) => route.isFirst);
    } else {
      HomePage.setTab(index);
    }
  }

  Future<bool> _onWillPop() async {
    final currentNavigator =
    _navigatorKeys[HomePage.tabNotifier.value].currentState!;
    if (currentNavigator.canPop()) {
      currentNavigator.pop();
      return false;
    }
    return true;
  }

  Widget _buildOffstageNavigator(int index, Widget child) {
    return Offstage(
      offstage: HomePage.tabNotifier.value != index,
      child: Navigator(
        key: _navigatorKeys[index],
        onGenerateRoute: (_) => MaterialPageRoute(builder: (_) => child),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: HomePage.tabNotifier,
      builder: (context, selectedIndex, _) {
        return WillPopScope(
          onWillPop: _onWillPop,
          child: Scaffold(
            backgroundColor: const Color(0xFF0D0B2D),
            body: Stack(
              children: [
                _buildOffstageNavigator(0, HomeMainContent()),
                _buildOffstageNavigator(1, QuickAnalysisPage()),
                _buildOffstageNavigator(2, ReportPage()),
                _buildOffstageNavigator(3, CatalogPage()),
                _buildOffstageNavigator(4, ProfilePage()),
              ],
            ),
            bottomNavigationBar: BottomNavigationBar(
              backgroundColor: const Color(0xFF0D0B2D),
              selectedItemColor: Colors.white,
              unselectedItemColor: Colors.white38,
              type: BottomNavigationBarType.fixed,
              currentIndex: selectedIndex,
              onTap: _onItemTapped,
              items: const [
                BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
                BottomNavigationBarItem(
                    icon: Icon(Icons.swap_horiz), label: 'Transactions'),
                BottomNavigationBarItem(
                    icon: Icon(Icons.bar_chart), label: 'Analysis'),
                BottomNavigationBarItem(
                    icon: Icon(Icons.payment), label: 'Catalog'),
                BottomNavigationBarItem(
                    icon: Icon(Icons.person), label: 'Profile'),
              ],
            ),
          ),
        );
      },
    );
  }
}

class RotatingQuoteWidget extends StatefulWidget {
  @override
  _RotatingQuoteWidgetState createState() => _RotatingQuoteWidgetState();
}

class _RotatingQuoteWidgetState extends State<RotatingQuoteWidget> {
  final List<String> _quotes = [
    "Stay focused and consistent!",
    "Small steps lead to big changes.",
    "Track your money, shape your future.",
    "Discipline is the bridge to financial freedom.",
    "A budget is telling your money where to go.",
    "Save now, enjoy later.",
    "Wealth grows when habits change."
  ];

  int _currentIndex = 0;
  late final Timer _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(Duration(seconds: 5), (_) {
      setState(() {
        _currentIndex = (_currentIndex + 1) % _quotes.length;
      });
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: Duration(milliseconds: 500),
      child: Text(
        '"${_quotes[_currentIndex]}"',
        key: ValueKey(_currentIndex),
        style: TextStyle(
          color: Colors.white70,
          fontStyle: FontStyle.italic,
          fontSize: 14,
        ),
      ),
    );
  }
}


class HomeMainContent extends StatelessWidget {
  final String uid = FirebaseAuth.instance.currentUser?.uid ?? '';

  Stream<String> _getUserName() {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .snapshots()
        .map((doc) => doc.data()?['full_name'] ?? 'User');
  }

  Stream<List<Map<String, dynamic>>> _getTransactions() {
    return FirebaseFirestore.instance
        .collection('transactions')
        .where('uid', isEqualTo: uid)
        .snapshots()
        .map((snap) => snap.docs.map((e) => e.data()).toList());
  }

  Stream<Map<String, dynamic>?> _getSavingsGoal() {
    return FirebaseFirestore.instance
        .collection('savings')
        .where('uid', isEqualTo: uid)
        .limit(1)
        .snapshots()
        .map((snap) => snap.docs.isNotEmpty ? snap.docs.first.data() : null);
  }

  void _showAddReminderDialog(BuildContext context) {
    final titleController = TextEditingController();
    final noteController = TextEditingController();
    DateTime? selectedDate;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Add Reminder'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: titleController,
                    decoration: InputDecoration(labelText: 'Title'),
                  ),
                  TextField(
                    controller: noteController,
                    decoration: InputDecoration(labelText: 'Note'),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          selectedDate != null
                              ? 'Due: ${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}'
                              : 'No date selected',
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                      TextButton(
                        onPressed: () async {
                          final now = DateTime.now();
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: now,
                            firstDate: now,
                            lastDate: DateTime(now.year + 5),
                          );
                          if (picked != null) {
                            setState(() {
                              selectedDate = picked;
                            });
                          }
                        },
                        child: Text('Pick Date'),
                      ),
                    ],
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () async {
                    if (titleController.text.isNotEmpty &&
                        selectedDate != null) {
                      await FirebaseFirestore.instance
                          .collection('reminders')
                          .add({
                        'uid': uid,
                        'title': titleController.text,
                        'note': noteController.text,
                        'dueDate': Timestamp.fromDate(selectedDate!),
                      });
                      Navigator.of(context).pop();
                    }
                  },
                  child: Text('Add'),
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
    final screenHeight = MediaQuery.of(context).size.height;

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: () async {
          // Add your refresh logic here (e.g., force setState or reload Firebase data)
          await Future.delayed(Duration(milliseconds: 500));
        },
        backgroundColor: const Color(0xFF0D0B2D),
        color: Colors.lightBlueAccent,
        child: SingleChildScrollView(
          physics: AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Your existing children...
                StreamBuilder<String>(
                  stream: _getUserName(),
                  builder: (_, snapshot) {
                    final name = snapshot.data ?? 'User';
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Welcome, $name 👋',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        RotatingQuoteWidget(),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 4),

                const SizedBox(height: 24),

                StreamBuilder<List<Map<String, dynamic>>>(
                  stream: _getTransactions(),
                  builder: (_, snapshot) {
                    final transactions = snapshot.data ?? [];
                    double monthlyExpense = 0;
                    double incomeThisMonth = 0;

                    final now = DateTime.now();
                    for (var tx in transactions) {
                      DateTime txTime = (tx['timestamp'] as Timestamp).toDate();
                      if (txTime.month == now.month && txTime.year == now.year) {
                        final amount = (tx['amount'] ?? 0).toDouble();
                        if (tx['type'] == 'expense') {
                          monthlyExpense += amount;
                        } else if (tx['type'] == 'income') {
                          incomeThisMonth += amount;
                        }
                      }
                    }

                    String alert;
                    if (monthlyExpense > 20000) {
                      alert = '🚨 High Alert: You\'ve spent over ₹20,000 this month!';
                    } else if (monthlyExpense > 15000) {
                      alert = '⚠️ Careful! You\'re nearing ₹20k in monthly expenses.';
                    } else if (monthlyExpense > 10000) {
                      alert = '🧾 Heads up: Expenses crossed ₹10k this month.';
                    } else {
                      alert = '✅ All good! You\'re spending wisely this month.';
                    }

                    String details =
                        'Expenses: ₹${monthlyExpense.toStringAsFixed(0)} | Income: ₹${incomeThisMonth.toStringAsFixed(0)}';

                    return _buildCard(
                      'Smart Alerts + Warnings',
                      '$alert\n$details',
                    );
                  },
                ),

                const SizedBox(height: 16),

                StreamBuilder<Map<String, dynamic>?>(
                  stream: _getSavingsGoal(),
                  builder: (_, snapshot) {
                    final data = snapshot.data;
                    if (data == null) {
                      return _buildCard(
                          'Budget Goal Progress', 'No budget goal set. Add one in Catalog.');
                    }
                    final double targetAmount = data['amount']?.toDouble() ?? 1;
                    final Map<String, dynamic>? duration = data['duration'] as Map<String, dynamic>?;

// Calculate total days from duration
                    int totalDays = 1;
                    if (duration != null) {
                      final unit = duration['unit'] as String? ?? 'months';
                      final value = duration['value'] as int? ?? 1;
                      if (unit == 'months') {
                        totalDays = (value * 30); // approx 30 days per month
                      } else if (unit == 'years') {
                        totalDays = (value * 365); // approx 365 days per year
                      }
                    }

                    final DateTime startDate = (data['timestamp'] as Timestamp).toDate();
                    final DateTime now = DateTime.now();

                    final int elapsedDays = now.difference(startDate).inDays.clamp(0, totalDays);

// Assuming you have a 'saved' field in the savings doc that tracks how much saved so far
                    final double amountSaved = data['transfer']?.toDouble() ?? 0;

// Calculate progress by time and amount saved
                    final double timeProgress = elapsedDays / totalDays;
                    final double amountProgress = (amountSaved / targetAmount).clamp(0.0, 1.0);

                    final double combinedProgress = (timeProgress + amountProgress) / 2;
                    final progressPercent = (combinedProgress * 100).clamp(0, 100);

                    return _buildCard(
                      'Budget Goal Progress',
                      'Progress: ${progressPercent.toStringAsFixed(1)}%',
                      child: LinearProgressIndicator(
                        value: combinedProgress.clamp(0.0, 1.0),
                        color: Colors.greenAccent,
                        backgroundColor: Colors.white12,
                      ),
                    );


                  },
                ),
                const SizedBox(height: 16),

                StreamBuilder<List<Map<String, dynamic>>>(
                  stream: _getTransactions(),
                  builder: (_, snapshot) {
                    final txns = snapshot.data ?? [];
                    double saved = 0;
                    for (var tx in txns) {
                      if (tx['type'] == 'income') {
                        saved += (tx['amount'] ?? 0).toDouble();
                      }
                    }
                    String milestone = 'Total Saved: ₹${saved.toStringAsFixed(2)}';
                    return _buildCard('Financial Milestones', milestone);
                  },
                ),
                const SizedBox(height: 16),

                // Reminder Section
                ReminderSection(uid: uid),  // pass current user UID here
              ],
            ),
          ),
        ),
      ),
    );
  }




  Widget _buildCard(String title, String content, {Widget? child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1F1B4A),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: TextStyle(
                  color: Colors.white70,
                  fontWeight: FontWeight.bold,
                  fontSize: 16)),
          const SizedBox(height: 8),
          Text(content,
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
              )),
          if (child != null) ...[
            const SizedBox(height: 12),
            child,
          ]
        ],
      ),
    );
  }
}




