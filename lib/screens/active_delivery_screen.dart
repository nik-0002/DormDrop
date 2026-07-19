import 'package:flutter/material.dart';
import '../services/database_service.dart';
import '../utils/fee_calculator.dart';

class ActiveDeliveryScreen extends StatefulWidget {
  final String orderId;
  final Map<String, dynamic> orderData;

  const ActiveDeliveryScreen({
    super.key,
    required this.orderId,
    required this.orderData,
  });

  @override
  State<ActiveDeliveryScreen> createState() => _ActiveDeliveryScreenState();
}

class _ActiveDeliveryScreenState extends State<ActiveDeliveryScreen> {
  final DatabaseService _databaseService = DatabaseService();
  bool _isCompleting = false;

  void _completeDelivery() async {
    setState(() {
      _isCompleting = true;
    });

    try {
      await _databaseService.completeOrder(widget.orderId);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Delivery Completed Successfully!')),
      );

      // Go back to the dashboard
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to complete delivery.')),
      );
      setState(() {
        _isCompleting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final double productCost = (widget.orderData['estimatedCost'] ?? 0).toDouble();
    final double deliveryFee = (widget.orderData['deliveryFee'] ?? FeeCalculator.calculateFee(productCost)).toDouble();
    final double totalAmount = productCost + deliveryFee;

    final String room = widget.orderData['roomNumber'] ?? 'Unknown Room';
    final String items = widget.orderData['items'] ?? '';
    final String userName = widget.orderData['userName'] ?? 'User';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Active Delivery'),
        // Prevent going back accidentally without completing or cancelling (for now just complete)
        automaticallyImplyLeading: false, 
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.delivery_dining, size: 80, color: Colors.deepPurple),
            const SizedBox(height: 20),
            Text(
              'Deliver to: $userName (Room $room)',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            const Text(
              'Items to buy:',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            Text(
              items,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
            ),
            const Divider(height: 48, thickness: 2),
            const Text(
              'Payment Collection',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Estimated Product Cost:', style: TextStyle(fontSize: 16)),
                Text('₹$productCost', style: const TextStyle(fontSize: 16)),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Delivery Fee:', style: TextStyle(fontSize: 16)),
                Text('₹$deliveryFee', style: const TextStyle(fontSize: 16)),
              ],
            ),
            const Divider(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Total to Collect:', 
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Text('₹$totalAmount', 
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.green)),
              ],
            ),
            const Spacer(),
            ElevatedButton(
              onPressed: _isCompleting ? null : _completeDelivery,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
              child: _isCompleting
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Complete Delivery & Collect Cash/UPI', style: TextStyle(fontSize: 18)),
            ),
          ],
        ),
      ),
    );
  }
}
