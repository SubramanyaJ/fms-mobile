import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _dobController = TextEditingController();
  final _phoneController = TextEditingController();

  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    final doc = await _firestore.collection('users').doc(uid).get();
    final data = doc.data();
    if (data != null) {
      _nameController.text = data['full_name'] ?? '';
      _emailController.text = data['email'] ?? '';
      _dobController.text = data['dob'] ?? '';
      _phoneController.text = data['phone'] ?? '';
      setState(() {});
    }
  }

  Future<void> _saveChanges() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    setState(() => isLoading = true);

    await _firestore.collection('users').doc(uid).update({
      'full_name': _nameController.text.trim(),
      'email': _emailController.text.trim(),
      'dob': _dobController.text.trim(),
      'phone': _phoneController.text.trim(),
    });

    setState(() => isLoading = false);
    if (context.mounted) Navigator.pop(context);
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.tryParse(_dobController.text) ?? DateTime(2000),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFF1E88E5),
              surface: Color(0xFF0D0B2D),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      _dobController.text = DateFormat('yyyy-MM-dd').format(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0B2D),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D0B2D),
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text("Edit Profile", style: TextStyle(color: Colors.white)),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  _buildInput("Full Name", _nameController),
                  const SizedBox(height: 16),
                  _buildInput("Email", _emailController),
                  const SizedBox(height: 16),
                  GestureDetector(
                    onTap: _selectDate,
                    child: AbsorbPointer(
                      child: _buildInput("Date of Birth", _dobController),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildInput("Phone", _phoneController),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: _saveChanges,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1E88E5),
                      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text("Save Changes", style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInput(String label, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white, fontSize: 14)),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          style: const TextStyle(color: Colors.black),
          decoration: InputDecoration(
            filled: true,
            fillColor: const Color(0xFFd1f0f0),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
      ],
    );
  }
}
