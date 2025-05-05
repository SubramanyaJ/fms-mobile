// /lib/pages/home_page.dart

import 'package:flutter/material.dart';
import 'quick_analysis_page.dart'; // Make sure this path is correct

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    HomeMainContent(),
    QuickAnalysisPage(),
    Center(child: Text("Transactions", style: TextStyle(color: Colors.white))),
    Center(child: Text("Layers", style: TextStyle(color: Colors.white))),
    Center(child: Text("Profile", style: TextStyle(color: Colors.white))),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF0D0B2D),
      body: SafeArea(child: _pages[_selectedIndex]),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Color(0xFF0D0B2D),
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white38,
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: ''),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: ''),
          BottomNavigationBarItem(icon: Icon(Icons.swap_horiz), label: ''),
          BottomNavigationBarItem(icon: Icon(Icons.layers), label: ''),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: ''),
        ],
      ),
    );
  }
}

class HomeMainContent extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Hi, Welcome Back',
                    style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'Good Morning',
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ],
              ),
              Icon(Icons.notifications_none, color: Colors.white),
            ],
          ),
        ),

        // Balance section
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildBalanceCard('Total Balance', '₹7,783.00'),
              _buildBalanceCard('Total Expense', '-₹1,187.40', isExpense: true),
            ],
          ),
        ),

        // Progress bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              LinearProgressIndicator(
                value: 0.3,
                minHeight: 8,
                backgroundColor: Colors.white10,
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6CF6E8)),
              ),
              SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('30%', style: TextStyle(color: Colors.white)),
                  Text('₹20,000.00', style: TextStyle(color: Colors.white)),
                ],
              ),
              SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.check_box, color: Colors.white70, size: 16),
                  SizedBox(width: 4),
                  Text(
                    '30% Of Your Expenses, Looks Good.',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
        ),
        SizedBox(height: 16),

        // Savings card
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Container(
            decoration: BoxDecoration(
              color: Color(0xFFB5F12D),
              borderRadius: BorderRadius.circular(24),
            ),
            padding: EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Column(
                  children: [
                    Icon(Icons.directions_car, size: 32, color: Colors.black87),
                    SizedBox(height: 8),
                    Text('Savings\nOn Goals', textAlign: TextAlign.center, style: TextStyle(color: Colors.black87)),
                  ],
                ),
                VerticalDivider(color: Colors.black54, thickness: 1),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Revenue Last Week', style: TextStyle(color: Colors.black87)),
                    Text('₹4,000.00', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
                    SizedBox(height: 8),
                    Text('Food Last Week', style: TextStyle(color: Colors.black87)),
                    Text('-₹100.00', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
                  ],
                ),
              ],
            ),
          ),
        ),
        SizedBox(height: 16),

        // Toggle Tabs
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildTabButton('Daily', false),
              _buildTabButton('Weekly', false),
              _buildTabButton('Monthly', true),
            ],
          ),
        ),
        SizedBox(height: 16),

        // Transactions
        Expanded(
          child: ListView(
            padding: EdgeInsets.symmetric(horizontal: 24),
            children: [
              _buildTransactionItem('Salary', '18:27 - April 30', 'Monthly', '₹4,000.00', Icons.attach_money),
              _buildTransactionItem('Groceries', '17:00 - April 24', 'Pantry', '-₹100.00', Icons.shopping_cart),
              _buildTransactionItem('Rent', '8:30 - April 15', 'Rent', '-₹674.40', Icons.home),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBalanceCard(String label, String value, {bool isExpense = false}) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(color: Colors.white54, fontSize: 12)),
          SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: isExpense ? Colors.lightBlueAccent : Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton(String label, bool isActive) {
    return Expanded(
      child: Container(
        alignment: Alignment.center,
        padding: EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? Color(0xFF1E88E5) : Colors.transparent,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Text(
          label,
          style: TextStyle(color: Colors.white, fontWeight: isActive ? FontWeight.bold : FontWeight.normal),
        ),
      ),
    );
  }

  Widget _buildTransactionItem(String title, String time, String category, String amount, IconData icon) {
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Color(0xFF1D1A40),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: Colors.blue[100],
            child: Icon(icon, color: Colors.blue[900]),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                Text(time, style: TextStyle(color: Colors.white70, fontSize: 12)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(category, style: TextStyle(color: Colors.tealAccent, fontSize: 12)),
              Text(amount, style: TextStyle(color: amount.startsWith('-') ? Colors.red : Colors.white)),
            ],
          ),
        ],
      ),
    );
  }
}
