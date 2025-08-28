import 'package:flutter/material.dart';

class ThankYouScreen extends StatelessWidget {
  final String orderId;
  const ThankYouScreen({super.key, required this.orderId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Order Placed")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle_outline,
                color: Colors.green, size: 100),
            const SizedBox(height: 20),
            const Text("Thank you for your order!",
                style: TextStyle(fontSize: 20)),
            const SizedBox(height: 10),
            Text("Order ID: $orderId", style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context)
                    .popUntil((route) => route.isFirst); // go home
              },
              child: const Text("Go to Home"),
            )
          ],
        ),
      ),
    );
  }
}
