import 'package:flutter/material.dart';
import 'transactions.dart';

class SelectExpenseCategoryPage extends StatelessWidget {
  const SelectExpenseCategoryPage({super.key});

  final List<Map<String, dynamic>> categories = const [
    {'label': 'Food', 'icon': Icons.restaurant_menu},
    {'label': 'Transport', 'icon': Icons.directions_bus},
    {'label': 'Medicine', 'icon': Icons.medical_services},
    {'label': 'Groceries', 'icon': Icons.shopping_basket},
    {'label': 'Rent', 'icon': Icons.key},
    {'label': 'Gifts', 'icon': Icons.card_giftcard},
    {'label': 'Savings', 'icon': Icons.savings},
    {'label': 'Entertainment', 'icon': Icons.movie},
    {'label': 'More', 'icon': Icons.add},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0B2D),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D0B2D),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Categories',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Center(
        child: SizedBox(
          width: double.infinity,
          height: 600, // 👈 adjust height if needed
          child: GridView.count(
            crossAxisCount: 3,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            padding: const EdgeInsets.all(16),
            children: categories.map((category) {
              return GestureDetector(
                onTap: () {
                  Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => TransactionsPage(type: 'expense', label: category['label']),
                  ));
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.lightBlueAccent.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(category['icon'], color: Colors.white, size: 36),
                        const SizedBox(height: 5),
                        Text(
                          category['label'],
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}
