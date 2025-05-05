import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'firebase_options.dart';
import 'pages/login_page.dart';
import 'pages/home_page.dart';
import 'pages/create_account_page.dart';
import 'pages/forgot_password_page.dart';
import 'pages/quick_analysis_page.dart';
import 'pages/daily_analysis_view.dart';
import 'pages/analysis_view_base.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(FMSApp());
}

class FMSApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FMS App',
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        fontFamily: 'Roboto',
      ),
      // Now uses AuthGate as root
      home: AuthGate(),
      routes: {
        '/home': (context) => HomePage(),
        '/create-account': (context) => CreateAccountPage(),
        '/forgot-password': (context) => ForgotPasswordPage(),
        '/quick-analysis': (context) => QuickAnalysisPage(),
        '/daily-analysis': (context) => DailyAnalysisView(),
        '/analysis-view': (context) => AnalysisViewBase(),
        // Add more as needed
      },
    );
  }
}

class AuthGate extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          // Optional: Add splash screen here
          return Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        } else if (snapshot.hasData) {
          return HomePage(); // User is signed in
        } else {
          return LoginPage(); // Not signed in
        }
      },
    );
  }
}
