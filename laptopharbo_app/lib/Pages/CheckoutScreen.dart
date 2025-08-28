import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:laptopharbo_app/Pages/MyOrdersPage.dart';
import 'package:laptopharbo_app/Pages/home_screen.dart';
import 'package:flutter/services.dart';

class CheckoutScreen extends StatefulWidget {
  final List<dynamic> cartItems;
  const CheckoutScreen({super.key, required this.cartItems});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final user = FirebaseAuth.instance.currentUser;
  final _formKey = GlobalKey<FormState>();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
  final TextEditingController deliveryInstructionsController =
      TextEditingController();

  String paymentMethod = 'COD';
  bool isPlacingOrder = false;

  final List<Map<String, dynamic>> shippingMethods = [
    {'title': 'Standard Delivery - 3-5 Days', 'charge': 500},
    {'title': 'Express Delivery - 1-2 Days', 'charge': 900},
    {'title': 'Free Pickup - Store Only', 'charge': 0},
  ];

  String selectedShippingTitle = 'Standard Delivery - 3-5 Days';
  int selectedShippingCharge = 500;

  double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is int) return value.toDouble();
    if (value is double) return value;
    if (value is String) {
      final cleaned = value.replaceAll(RegExp(r'[^\d.]'), '');
      return double.tryParse(cleaned) ?? 0.0;
    }
    return 0.0;
  }

  double _calculateSubtotal() {
    double total = 0;
    for (var item in widget.cartItems) {
      final price = _parseDouble(item['price']);
      final quantity = item['quantity'] ?? 1;
      total += price * quantity;
    }
    return total;
  }

  Future<void> _placeOrder() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isPlacingOrder = true);

    final orderId = DateTime.now().millisecondsSinceEpoch.toString();
    final subtotal = _calculateSubtotal();
    final shipping = selectedShippingCharge;
    final tax = subtotal * 0.13;
    final total = subtotal + shipping + tax;

    final orderData = {
      'orderId': orderId,
      'userId': user!.uid,
      'name': user!.displayName ?? 'User',
      'email': user!.email,
      'phone': phoneController.text,
      'address': addressController.text,
      'deliveryInstructions': deliveryInstructionsController.text.trim(),
      'paymentMethod': paymentMethod,
      'shippingMethod': selectedShippingTitle,
      'status': 'pending',
      'subtotal': subtotal,
      'shipping': shipping,
      'tax': tax,
      'total': total,
      'items': widget.cartItems,
      'createdAt': Timestamp.now(),
      'cancelledAt': null,
      'deliveredAt': null,
    };

    await FirebaseFirestore.instance
        .collection('orders')
        .doc(orderId)
        .set(orderData);

    await FirebaseFirestore.instance
        .collection('carts')
        .doc(user!.uid)
        .delete();

    phoneController.clear();
    addressController.clear();
    deliveryInstructionsController.clear();
    widget.cartItems.clear();

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => ThankYouScreen(orderId: orderId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final subtotal = _calculateSubtotal();
    final shipping = selectedShippingCharge;
    final tax = subtotal * 0.13;
    final total = subtotal + shipping + tax;

    return Scaffold(
      appBar: AppBar(title: const Text('Checkout')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // 🟢 Contact & Delivery Details
            const Text("Contact & Delivery Details",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            Text("Name: ${user?.displayName ?? 'User'}"),
            Text("Email: ${user?.email ?? ''}"),
            const SizedBox(height: 8),

            TextFormField(
              controller: phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'Phone Number'),
              inputFormatters: [
                FilteringTextInputFormatter
                    .digitsOnly, // ✅ Sirf digits allow karega
                LengthLimitingTextInputFormatter(
                    11), // ✅ Max 11 digits allow karega
              ],
              validator: (val) {
                if (val == null || val.isEmpty)
                  return 'Phone number is required';
                if (val.length != 11) return 'Enter valid 11-digit number';
                return null;
              },
            ),

            TextFormField(
              controller: addressController,
              decoration: const InputDecoration(labelText: 'Delivery Address'),
              validator: (val) =>
                  val == null || val.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: deliveryInstructionsController,
              decoration: const InputDecoration(
                labelText: 'Delivery Instructions (Optional)',
                hintText: 'e.g. Leave at reception, Call before arrival',
              ),
              maxLines: 2,
            ),

            // 🟢 Shipping Method Section
            const SizedBox(height: 16),
            const Text("Shipping Method",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            DropdownButtonFormField<String>(
              value: selectedShippingTitle,
              items: shippingMethods.map((method) {
                return DropdownMenuItem<String>(
                  value: method['title'],
                  child: Text("${method['title']} - PKR ${method['charge']}"),
                );
              }).toList(),
              onChanged: (value) {
                final selected = shippingMethods
                    .firstWhere((method) => method['title'] == value);
                setState(() {
                  selectedShippingTitle = selected['title'];
                  selectedShippingCharge = selected['charge'];
                });
              },
            ),

            // 🟢 Payment Method Section
            const SizedBox(height: 16),
            const Text("Payment Method",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ListTile(
              title: const Text("Cash on Delivery (COD)"),
              leading: Radio(
                value: 'COD',
                groupValue: paymentMethod,
                onChanged: (value) => setState(() => paymentMethod = value!),
              ),
            ),
            // 🟢 Order Items
            const Divider(),
            const Text("Your Items",
                style: TextStyle(fontWeight: FontWeight.bold)),
            ...widget.cartItems.map((item) => ListTile(
                  leading: item['image'] != null
                      ? Image.network(item['image'],
                          width: 50, height: 50, fit: BoxFit.cover)
                      : const Icon(Icons.image_not_supported),
                  title: Text(item['name'] ?? ''),
                  subtitle: Text(
                      "Qty: ${item['quantity']} | PKR ${_parseDouble(item['price']).toStringAsFixed(0)}"),
                  trailing: Text(
                      "PKR ${(item['quantity'] * _parseDouble(item['price'])).toStringAsFixed(0)}"),
                )),

            // 🟢 Order Summary
            const Divider(),
            const Text("Order Summary",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            Text("Subtotal: PKR ${subtotal.toStringAsFixed(0)}"),
            Text("Shipping Charges: PKR ${shipping.toStringAsFixed(0)}"),
            Text("Tax (13%): PKR ${tax.toStringAsFixed(0)}"),
            Text("Total Payable: PKR ${total.toStringAsFixed(0)}",
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),

            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: isPlacingOrder ? null : _placeOrder,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              child: isPlacingOrder
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text("Place Order"),
            )
          ],
        ),
      ),
    );
  }
}

// ✅ Thank You Page remains unchanged
class ThankYouScreen extends StatelessWidget {
  final String orderId;
  const ThankYouScreen({super.key, required this.orderId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.check_circle, color: Colors.green, size: 100),
              const SizedBox(height: 20),
              const Text(
                "Thank you for your order!",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Text("Your Order ID: $orderId"),
              const SizedBox(height: 30),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const MyOrdersPage()),
                  );
                },
                icon: const Icon(Icons.history),
                label: const Text("My Orders"),
              ),
              const SizedBox(height: 10),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                        builder: (context) =>
                            const MyHomePage(title: 'LaptopHarbo Home')),
                    (route) => false,
                  );
                },
                icon: const Icon(Icons.home),
                label: const Text("Go to Home"),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
