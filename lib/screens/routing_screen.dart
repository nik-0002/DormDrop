import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/database_service.dart';
import 'onboarding_screen.dart';
import 'home_screen.dart';
import 'payment_screen.dart';

class RoutingScreen extends StatefulWidget {
  const RoutingScreen({super.key});

  @override
  State<RoutingScreen> createState() => _RoutingScreenState();
}

class _RoutingScreenState extends State<RoutingScreen> {
  final DatabaseService _databaseService = DatabaseService();

  @override
  void initState() {
    super.initState();
    _routeUser();
  }

  Future<void> _routeUser() async {
    User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      // Should not happen as AuthWrapper protects this screen, but just in case
      return;
    }

    final userData = await _databaseService.getUserData(currentUser.uid);

    if (!mounted) return;

    if (userData == null) {
      // User doesn't exist in Firestore -> Onboarding
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const OnboardingScreen()),
      );
      return;
    }

    final role = userData['role'];
    
    if (role == 'Delivery Boy') {
      // Delivery Boys skip payment wall
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => HomeScreen(userData: userData)),
      );
    } else if (role == 'User') {
      final hasActiveSubscription = userData['hasActiveSubscription'] ?? false;
      
      if (hasActiveSubscription) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => HomeScreen(userData: userData)),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const PaymentScreen()),
        );
      }
    } else {
      // Fallback
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const OnboardingScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Shows while fetching user data
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}
