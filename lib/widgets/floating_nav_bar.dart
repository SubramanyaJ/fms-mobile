import 'package:flutter/material.dart';

class FloatingNavBar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemTapped;

  const FloatingNavBar({
    super.key,
    required this.selectedIndex,
    required this.onItemTapped,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 16, // 16 pixels from bottom
      left: 16,
      right: 16,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12),
        height: 64,
        decoration: BoxDecoration(
          color: Color(0xFF181049), // dark purple background
          borderRadius: BorderRadius.circular(36), // rounded corners
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _navItem(Icons.home, 0),
            _navItem(Icons.bar_chart_rounded, 1),
            _navItem(Icons.swap_horiz_rounded, 2),
            _navItem(Icons.layers_rounded, 3),
            _navItem(Icons.person, 4),
          ],
        ),
      ),
    );
  }

  Widget _navItem(IconData icon, int index) {
    return IconButton(
      onPressed: () => onItemTapped(index),
      icon: Icon(
        icon,
        color: selectedIndex == index ? Colors.white : Colors.white54,
        size: 28,
      ),
    );
  }
}
