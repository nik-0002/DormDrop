import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'screens/auth_wrapper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp();

  runApp(const DormDropApp());
}

class DormDropApp extends StatelessWidget {
  const DormDropApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DormDrop',
      debugShowCheckedModeBanner: false,

      // This allows the UI to automatically switch between the Navy Dark Mode
      // and Light Mode based on the user's system settings.
      themeMode: ThemeMode.system,
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),

      // Use AuthWrapper to decide which screen to show
      home: const AuthWrapper(),
    );
  }
}
