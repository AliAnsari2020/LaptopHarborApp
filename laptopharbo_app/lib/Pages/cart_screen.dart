import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:laptopharbo_app/Pages/CheckoutScreen.dart';
import 'package:laptopharbo_app/Pages/SearchScreen.dart';
import 'package:laptopharbo_app/Pages/home_screen.dart';
import 'package:laptopharbo_app/support/support_screen.dart';
import 'package:badges/badges.dart' as badges;

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

int _selectedIndex = 2;

int cartItemCount = 0;

Color _getSelectedColor(int index) =>
    _selectedIndex == index ? const Color(0xFF42A5F5) : Colors.white;

class _CartScreenState extends State<CartScreen> {
  final User? user = FirebaseAuth.instance.currentUser;
  int _selectedIndex = 2;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    switch (index) {
      case 0:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const MyHomePage(title: 'Home')),
        );
        break;
      case 1:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const SearchScreen()),
        );
        break;
      case 2:
        // Stay on this page (Cart)
        break;
      case 3:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const SupportScreen()),
        );
        break;
    }
  }

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

  double _calculateTotal(List items) {
    double total = 0;
    for (var item in items) {
      final price = _parseDouble(item['price']);
      final quantity = item['quantity'] ?? 1;
      total += price * quantity;
    }
    return total;
  }

  Future<void> _removeItem(String name) async {
    if (user == null) return;
    final cartRef =
        FirebaseFirestore.instance.collection('carts').doc(user!.uid);
    final doc = await cartRef.get();
    if (doc.exists) {
      final data = doc.data();
      if (data != null && data['items'] is List) {
        List<Map<String, dynamic>> items =
            List<Map<String, dynamic>>.from(data['items']);
        items.removeWhere((item) => item['name'] == name);
        await cartRef.set({'items': items});
        setState(() {});
      }
    }
  }

  Future<void> _changeQuantity(String name, int delta) async {
    if (user == null) return;
    final cartRef =
        FirebaseFirestore.instance.collection('carts').doc(user!.uid);
    final doc = await cartRef.get();
    if (doc.exists) {
      final data = doc.data();
      if (data != null && data['items'] is List) {
        List<Map<String, dynamic>> items =
            List<Map<String, dynamic>>.from(data['items']);
        int index = items.indexWhere((item) => item['name'] == name);
        if (index != -1) {
          int currentQty = items[index]['quantity'] ?? 1;
          items[index]['quantity'] = (currentQty + delta).clamp(1, 999);
          await cartRef.set({'items': items});
          setState(() {});
        }
      }
    }
  }

  Future<void> _clearCart() async {
    if (user == null) return;
    await FirebaseFirestore.instance
        .collection('carts')
        .doc(user!.uid)
        .set({'items': []});
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (user == null) {
      return const Scaffold(
        body: Center(child: Text("Please login to view cart.")),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Your Cart"),
        backgroundColor: const Color(0xFF0D47A1),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('carts')
            .doc(user!.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data?.data() as Map<String, dynamic>?;
          final items = data?['items'] as List<dynamic>? ?? [];

          if (items.isEmpty) {
            return const Center(child: Text('Your cart is empty'));
          }

          final total = _calculateTotal(items);

          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    final price = _parseDouble(item['price']);
                    final quantity = item['quantity'] ?? 1;

                    return Card(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      child: ListTile(
                        leading: Image.network(
                          item['image'] ?? '',
                          width: 50,
                          height: 50,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              const Icon(Icons.broken_image),
                        ),
                        title: Text(item['name'] ?? ''),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(item['brand'] ?? ''),
                            const SizedBox(height: 4),
                            Text("Price: PKR ${price.toStringAsFixed(0)}"),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.remove),
                                  onPressed: () =>
                                      _changeQuantity(item['name'], -1),
                                ),
                                Text(quantity.toString(),
                                    style: const TextStyle(fontSize: 16)),
                                IconButton(
                                  icon: const Icon(Icons.add),
                                  onPressed: () =>
                                      _changeQuantity(item['name'], 1),
                                ),
                              ],
                            ),
                          ],
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _removeItem(item['name']),
                        ),
                      ),
                    );
                  },
                ),
              ),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  boxShadow: const [
                    BoxShadow(color: Colors.black12, blurRadius: 6)
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Total: PKR ${total.toStringAsFixed(0)}",
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => CheckoutScreen(
                              cartItems: items.cast<Map<String, dynamic>>(),
                            ),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00C853),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text("Checkout"),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: Container(
        margin: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 10,
                offset: const Offset(0, 5)),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(30),
          child: BottomNavigationBar(
            currentIndex: _selectedIndex,
            onTap: _onItemTapped,
            backgroundColor: const Color(0xFF0D47A1),
            selectedItemColor: Colors.white,
            unselectedItemColor: Colors.white,
            type: BottomNavigationBarType.fixed,
            showUnselectedLabels: true,
            selectedFontSize: 14,
            unselectedFontSize: 12,
            items: [
              BottomNavigationBarItem(
                icon: Icon(Icons.home, color: _getSelectedColor(0)),
                label: 'Home',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.search, color: _getSelectedColor(1)),
                label: 'Search',
              ),
              BottomNavigationBarItem(
                icon: badges.Badge(
                  showBadge: cartItemCount > 0,
                  badgeContent: Text(
                    cartItemCount.toString(),
                    style: const TextStyle(color: Colors.white, fontSize: 10),
                  ),
                  position: badges.BadgePosition.topEnd(top: -6, end: -4),
                  child: Icon(Icons.shopping_cart, color: _getSelectedColor(2)),
                ),
                label: 'Cart',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.support_agent, color: _getSelectedColor(3)),
                label: 'Support',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
