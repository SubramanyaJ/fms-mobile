import 'package:flutter/material.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';


class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool isDarkMode = false;
  bool isCalendarSyncEnabled = true;
  String selectedCurrency = '₹';
  String selectedDateFormat = 'DD/MM/YYYY';
  int autoLogoutTimer = 10; // Default timer value

  final List<String> currencies = ['₹', '\$', '€', '£'];
  final List<String> dateFormats = ['MM/DD/YYYY', 'DD/MM/YYYY', 'YYYY-MM-DD'];

  // Function to show the currency selection dialog
  // Function to show the currency selection in a rounded box
  void _showCurrencyDialog() {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return Dialog(
          backgroundColor: const Color(0xFF2E2A44),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0),
          ),
          child: Builder( // This provides a local context for pop
            builder: (BuildContext localContext) {
              return Container(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Select Currency',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18.0,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 16.0),
                    Column(
                      children: currencies.map((currency) {
                        bool isSelected = selectedCurrency == currency;

                        return Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(10.0),
                            onTap: () async {
                              setState(() {
                                selectedCurrency = currency;
                              });

                              User? user = FirebaseAuth.instance.currentUser;
                              if (user != null) {
                                try {
                                  await FirebaseFirestore.instance
                                      .collection('users')
                                      .doc(user.uid)
                                      .update({'currency': selectedCurrency});

                                  if (mounted) {
                                    Navigator.pop(localContext); // This closes ONLY the dialog
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text("Currency updated!")),
                                    );
                                  }
                                } catch (e) {
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text("Failed to update currency")),
                                    );
                                  }
                                }
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 14.0),
                              margin: const EdgeInsets.symmetric(vertical: 6.0),
                              decoration: BoxDecoration(
                                color: isSelected ? Colors.blueAccent : Colors.transparent,
                                border: Border.all(color: Colors.white24),
                                borderRadius: BorderRadius.circular(10.0),
                              ),
                              child: Row(
                                children: [
                                  const SizedBox(width: 12),
                                  Text(
                                    currency,
                                    style: TextStyle(
                                      color: isSelected ? Colors.white : Colors.white70,
                                      fontSize: 16.0,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const Spacer(),
                                  if (isSelected)
                                    const Icon(Icons.check, color: Colors.white),
                                ],
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  // Function to show the date format selection dialog
  void _showDateFormatDialog() {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E1B38),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          title: const Text(
            'Select Date Format',
            style: TextStyle(color: Colors.white),
          ),
          content: Builder(
            builder: (BuildContext localContext) {
              return SingleChildScrollView(
                child: Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: dateFormats.map((format) {
                    final bool isSelected = selectedDateFormat == format;

                    return Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () async {
                          setState(() {
                            selectedDateFormat = format;
                          });

                          User? user = FirebaseAuth.instance.currentUser;
                          if (user != null) {
                            try {
                              await FirebaseFirestore.instance
                                  .collection('users')
                                  .doc(user.uid)
                                  .update({'dateFormat': selectedDateFormat});

                              if (mounted) {
                                Navigator.pop(localContext); // Only dismisses dialog
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text("Date format updated!")),
                                );
                              }
                            } catch (e) {
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text("Failed to update date format")),
                                );
                              }
                            }
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                          decoration: BoxDecoration(
                            color: isSelected ? Colors.blueAccent : Colors.transparent,
                            border: Border.all(
                              color: isSelected ? Colors.blueAccent : Colors.white30,
                              width: 1.5,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            format,
                            style: TextStyle(
                              color: isSelected ? Colors.white : Colors.white70,
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              );
            },
          ),
        );
      },
    );
  }

  // Function to show the PIN/Passcode dialog
  void _showPinSetupDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1E1B38),
        title: const Text('Set PIN/Passcode', style: TextStyle(color: Colors.white)),
        content: const Text("Enter your new PIN/Passcode", style: TextStyle(color: Colors.white)),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // You can handle PIN setup logic here (e.g., save it securely)
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
            child: const Text("Set PIN"),
          )
        ],
      ),
    );
  }

  // Function to show the auto-logout timer selection
  void _showAutoLogoutDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1E1B38),
        title: const Text('Select Auto-Logout Timer', style: TextStyle(color: Colors.white)),
        content: SizedBox(
          height: 180,
          child: ListView(
            children: [5, 10, 15, 30, 60].map((duration) {
              return RadioListTile<int>(
                title: Text("$duration mins", style: const TextStyle(color: Colors.white)),
                value: duration,
                groupValue: autoLogoutTimer,
                onChanged: (value) {
                  setState(() => autoLogoutTimer = value!);
                  Navigator.pop(context);
                },
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  // Function to simulate exporting account data (can be adapted to export to cloud or file)
  void _exportAccountData() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Account data exported successfully!")),
    );
  }

  // Function to simulate account data deletion (can be linked to actual data removal)
  void _deleteAccountData() {
    // Perform data deletion from the backend/database here
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Account data deleted successfully!")),
    );
  }

  // Function to clear local app data
  void _clearLocalData() {
    // Perform local data clearing (such as clearing shared preferences or local database)
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Local app data cleared!")),
    );
  }

  // Confirmation dialog to show before performing sensitive actions like deletion
  void _showConfirmationDialog(String message, VoidCallback onConfirm) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1E1B38),
        title: Text("Confirm", style: const TextStyle(color: Colors.white)),
        content: Text(message, style: const TextStyle(color: Colors.white)),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text("Cancel", style: TextStyle(color: Colors.white)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              onConfirm();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text("Confirm", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Settings", style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
        backgroundColor: const Color(0xFF0D0B2D),
      ),
      backgroundColor: const Color(0xFF0D0B2D),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: ListView(
            children: [
              SwitchListTile(
                title: const Text("Dark Mode", style: TextStyle(color: Colors.white)),
                value: isDarkMode,
                onChanged: (bool value) => setState(() => isDarkMode = value),
                activeColor: const Color(0xFF1E88E5),
                inactiveThumbColor: Colors.white30,
                inactiveTrackColor: Colors.white24,
              ),
              ListTile(
                title: const Text("Default Currency", style: TextStyle(color: Colors.white)),
                subtitle: Text(selectedCurrency, style: const TextStyle(color: Colors.white70)),
                trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white38),
                onTap: _showCurrencyDialog,
              ),
              ListTile(
                title: const Text("Date Format", style: TextStyle(color: Colors.white)),
                subtitle: Text(selectedDateFormat, style: const TextStyle(color: Colors.white70)),
                trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white38),
                onTap: _showDateFormatDialog,
              ),
              SwitchListTile(
                title: const Text("Calendar Sync", style: TextStyle(color: Colors.white)),
                value: isCalendarSyncEnabled,
                onChanged: (bool value) => setState(() => isCalendarSyncEnabled = value),
                activeColor: const Color(0xFF1E88E5),
                inactiveThumbColor: Colors.white30,
                inactiveTrackColor: Colors.white24,
              ),
              const Divider(color: Colors.white24),
              ListTile(
                title: const Text("Auto-Logout Timer", style: TextStyle(color: Colors.white)),
                subtitle: Text("$autoLogoutTimer mins", style: const TextStyle(color: Colors.white70)),
                trailing: const Icon(Icons.timer, color: Colors.white38),
                onTap: _showAutoLogoutDialog,
              ),
              ListTile(
                title: const Text("Export Account Data", style: TextStyle(color: Colors.white)),
                trailing: const Icon(Icons.file_download, color: Colors.white38),
                onTap: _exportAccountData,
              ),
              ListTile(
                title: const Text("Delete Account Data", style: TextStyle(color: Colors.white)),
                trailing: const Icon(Icons.delete_forever, color: Colors.redAccent),
                onTap: () {
                  _showConfirmationDialog("Delete all account data?", _deleteAccountData);
                },
              ),
              ListTile(
                title: const Text("Clear Local App Data", style: TextStyle(color: Colors.white)),
                trailing: const Icon(Icons.cleaning_services, color: Colors.orange),
                onTap: () {
                  _showConfirmationDialog("Clear all locally stored data?", _clearLocalData);
                },
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showPinSetupDialog,  // Trigger the PIN setup dialog
        backgroundColor: const Color(0xFF1E88E5),
        child: const Icon(Icons.lock_outline),
      ),
    );
  }
}
