import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class BuyNowPage extends StatefulWidget {
  final Map<String, dynamic> productData;

  const BuyNowPage({super.key, required this.productData});

  @override
  State<BuyNowPage> createState() => _BuyNowPageState();
}

class _BuyNowPageState extends State<BuyNowPage> {
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  bool isPlacingOrder = false;

  Future<void> placeOrder() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final product = widget.productData;

    if (_addressController.text.trim().isEmpty ||
        _phoneController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please enter both address and phone number.')),
      );
      return;
    }

    setState(() => isPlacingOrder = true);

    try {
      final orderId = "ORDER-${DateTime.now().millisecondsSinceEpoch}";

      final rawPrice = product['price'].toString();
      final cleanedPrice = rawPrice.replaceAll(RegExp(r'[^\d.]'), '');
      final total = double.tryParse(cleanedPrice) ?? 0.0;

      await FirebaseFirestore.instance
          .collection('orders')
          .doc(orderId) // 🔥 IMPORTANT: now using doc(orderId)
          .set({
        'orderId': orderId,
        'userId': user.uid,
        'name': user.displayName ?? 'No Name',
        'email': user.email ?? 'No Email',
        'items': [
          {
            'name': product['name'],
            'brand': product['brand'],
            'category': product['category'],
            'price': total,
            'image': product['images'][0],
            'quantity': 1,
          }
        ],
        'address': _addressController.text.trim(),
        'phone': _phoneController.text.trim(),
        'total': total,
        'status': 'processing', // for admin
        'trackingStatus': 'processing', // for tracking
        'courierService': 'TCS',
        'deliveryDays': '3',
        'createdAt': Timestamp.now(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Order placed successfully!')),
      );

      Navigator.pop(context); // Ya redirect to MyOrdersPage
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Error placing order: $e')),
      );
    }

    setState(() => isPlacingOrder = false);
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.productData;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Confirm Purchase'),
        backgroundColor: Colors.deepPurple,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                leading: Image.network(
                  product['images'][0],
                  width: 60,
                  height: 60,
                  fit: BoxFit.cover,
                ),
                title: Text(
                  product['name'],
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
                subtitle: Text(
                  "PKR ${product['price']}",
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text("Delivery Address",
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            TextField(
              controller: _addressController,
              maxLines: 3,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: "Enter your delivery address",
              ),
            ),
            const SizedBox(height: 16),
            const Text("Phone Number",
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: "03XXXXXXXXX",
              ),
            ),
            const SizedBox(height: 30),
            ElevatedButton.icon(
              onPressed: isPlacingOrder ? null : placeOrder,
              icon: const Icon(Icons.check_circle),
              label: isPlacingOrder
                  ? const Text("Placing Order...")
                  : const Text("Confirm Order"),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                backgroundColor: Colors.deepPurple,
              ),
            )
          ],
        ),
      ),
    );
  }
}
