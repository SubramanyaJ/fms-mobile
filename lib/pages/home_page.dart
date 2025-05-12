// /lib/pages/home_page.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'quick_analysis_page.dart';
import 'profile_page.dart';
import 'catalog_page.dart';
import 'report_page.dart';
import '../widgets/pull_to_refresh_wrapper.dart';

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

class HomeMainContent extends StatelessWidget {
  final String uid = FirebaseAuth.instance.currentUser?.uid ?? '';

  Stream<String> _getUserName() {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .snapshots()
        .map((doc) => doc.data()?['full_name'] ?? 'User');
  }

  Stream<String> _getQuote() {
    return FirebaseFirestore.instance
        .collection('quotes')
        .limit(1)
        .snapshots()
        .map((snapshot) => snapshot.docs.isNotEmpty
        ? snapshot.docs.first.data()['text'] ?? ''
        : 'Stay focused and consistent!');
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

  Stream<List<Map<String, dynamic>>> _getReminders() {
    return FirebaseFirestore.instance
        .collection('reminders')
        .where('uid', isEqualTo: uid)
        .orderBy('dueDate')
        .snapshots()
        .map((snap) => snap.docs.map((e) => e.data()).toList());
  }

  void _showAddReminderDialog(BuildContext context) {
    final titleController = TextEditingController();
    final noteController = TextEditingController();
    DateTime? selectedDate;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Add Reminder'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: titleController, decoration: InputDecoration(labelText: 'Title')),
            TextField(controller: noteController, decoration: InputDecoration(labelText: 'Note')),
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
                  selectedDate = picked;
                }
              },
              child: Text('Pick Due Date'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () async {
              if (titleController.text.isNotEmpty && selectedDate != null) {
                await FirebaseFirestore.instance.collection('reminders').add({
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
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PullToRefreshWrapper(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                StreamBuilder<String>(
                  stream: _getUserName(),
                  builder: (_, snapshot) {
                    final name = snapshot.data ?? 'User';
                    return Text(
                      'Welcome, $name 👋',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    );
                  },
                ),
                const SizedBox(height: 4),
                StreamBuilder<String>(
                  stream: _getQuote(),
                  builder: (_, snapshot) {
                    final quote = snapshot.data ?? '';
                    return Text(
                      '"$quote"',
                      style: TextStyle(
                        color: Colors.white70,
                        fontStyle: FontStyle.italic,
                        fontSize: 14,
                      ),
                    );
                  },
                ),
                const SizedBox(height: 24),

                // Smart Alerts
                StreamBuilder<List<Map<String, dynamic>>>(
                  stream: _getTransactions(),
                  builder: (_, snapshot) {
                    final transactions = snapshot.data ?? [];
                    String alert = 'All good!';
                    double monthlyExpense = 0;

                    final now = DateTime.now();
                    for (var tx in transactions) {
                      DateTime txTime =
                      (tx['timestamp'] as Timestamp).toDate();
                      if (tx['type'] == 'expense' &&
                          txTime.month == now.month &&
                          txTime.year == now.year) {
                        monthlyExpense += (tx['amount'] ?? 0).toDouble();
                      }
                    }

                    if (monthlyExpense > 10000) {
                      alert = 'Warning: You\'ve spent over ₹10,000 this month!';
                    }

                    return _buildCard('Smart Alerts + Warnings', alert);
                  },
                ),
                const SizedBox(height: 16),

                // Budget Progress
                StreamBuilder<Map<String, dynamic>?>(
                  stream: _getSavingsGoal(),
                  builder: (_, snapshot) {
                    final data = snapshot.data;
                    if (data == null) {
                      return _buildCard('Budget Goal Progress',
                          'No budget goal set. Add one in Catalog.');
                    }
                    final target = data['amount']?.toDouble() ?? 0;
                    final days = data['days']?.toInt() ?? 1;
                    final start = (data['timestamp'] as Timestamp).toDate();
                    final now = DateTime.now();
                    final elapsedDays = now.difference(start).inDays;
                    final expectedProgress =
                    (elapsedDays / days).clamp(0.0, 1.0);
                    final progress = expectedProgress;

                    return _buildCard(
                      'Budget Goal Progress',
                      'Progress: ${(progress * 100).toStringAsFixed(1)}%',
                      child: LinearProgressIndicator(
                        value: progress,
                        color: Colors.greenAccent,
                        backgroundColor: Colors.white12,
                      ),
                    );
                  },
                ),
                const SizedBox(height: 16),

                // Financial Milestones
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
                    String milestone =
                        'Total Saved: ₹${saved.toStringAsFixed(2)}';
                    return _buildCard('Financial Milestones', milestone);
                  },
                ),
                const SizedBox(height: 16),

                // Upcoming Reminders
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Upcoming Bills/Reminders',
                        style: TextStyle(
                            color: Colors.white70,
                            fontSize: 16,
                            fontWeight: FontWeight.bold)),
                    IconButton(
                      icon: Icon(Icons.add, color: Colors.white),
                      onPressed: () => _showAddReminderDialog(context),
                    ),
                  ],
                ),
                StreamBuilder<List<Map<String, dynamic>>>(
                  stream: _getReminders(),
                  builder: (_, snapshot) {
                    final reminders = snapshot.data ?? [];
                    return Column(
                      children: reminders.map((r) {
                        final dueDate =
                        (r['dueDate'] as Timestamp).toDate();
                        return Container(
                          margin: EdgeInsets.only(bottom: 12),
                          padding: EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Color(0xFF1F1B4A),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ListTile(
                            title: Text(r['title'] ?? '',
                                style: TextStyle(color: Colors.white)),
                            subtitle: Text(
                                '${r['note'] ?? ''}\nDue: ${dueDate.day}/${dueDate.month}/${dueDate.year}',
                                style: TextStyle(
                                    color: Colors.white70, fontSize: 12)),
                          ),
                        );
                      }).toList(),
                    );
                  },
                ),
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
