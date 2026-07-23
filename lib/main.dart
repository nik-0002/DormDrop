import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'screens/auth_wrapper.dart';
import 'theme/theme_provider.dart';

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
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeProvider.themeMode,
      builder: (context, ThemeMode currentMode, child) {
        return MaterialApp(
          title: 'DormDrop',
          debugShowCheckedModeBanner: false,

          // This allows the UI to manually or automatically switch between
          // Navy Dark Mode and Light Mode.
          themeMode: currentMode,
          theme: ThemeData(
            brightness: Brightness.light,
            primarySwatch: Colors.orange,
            scaffoldBackgroundColor: const Color(0xFFF4F6F9),
          ),
          darkTheme: ThemeData(
            brightness: Brightness.dark,
            primarySwatch: Colors.orange,
            scaffoldBackgroundColor: AppColors.navyDarkest,
          ),

          // Use AuthWrapper to decide which screen to show
          home: const AuthWrapper(),
        );
      },
    );
  }
}
