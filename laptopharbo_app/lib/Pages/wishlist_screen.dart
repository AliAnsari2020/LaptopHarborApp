import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'cart_screen.dart';

class WishlistScreen extends StatefulWidget {
  const WishlistScreen({super.key});

  @override
  State<WishlistScreen> createState() => _WishlistScreenState();
}

class _WishlistScreenState extends State<WishlistScreen> {
  List<Map<String, dynamic>> wishlistItems = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadWishlistItems();
  }

  Future<void> loadWishlistItems() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final docSnapshot = await FirebaseFirestore.instance
          .collection('wishlists')
          .doc(user.uid)
          .get();

      if (docSnapshot.exists) {
        final data = docSnapshot.data();
        if (data != null && data['items'] != null) {
          setState(() {
            wishlistItems = List<Map<String, dynamic>>.from(data['items']);
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading wishlist: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> saveWishlist() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await FirebaseFirestore.instance
        .collection('wishlists')
        .doc(user.uid)
        .set({'items': wishlistItems});
  }

  void removeItem(int index) {
    setState(() {
      wishlistItems.removeAt(index);
    });
    saveWishlist();
  }

  double parsePrice(dynamic priceRaw) {
    try {
      final priceStr = priceRaw.toString().replaceAll(RegExp(r'[^\d.]'), '');
      return double.tryParse(priceStr) ?? 0;
    } catch (e) {
      return 0;
    }
  }

  Future<void> addToCart(int index) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final item = wishlistItems[index];
    final cartRef =
        FirebaseFirestore.instance.collection('carts').doc(user.uid);
    final cartDoc = await cartRef.get();

    List<Map<String, dynamic>> items = [];

    if (cartDoc.exists) {
      final data = cartDoc.data();
      if (data != null && data['items'] is List) {
        items = List<Map<String, dynamic>>.from(data['items']);
      }
    }

    final itemIndex = items.indexWhere((e) => e['name'] == item['name']);

    if (itemIndex != -1) {
      items[itemIndex]['quantity'] =
          (items[itemIndex]['quantity'] ?? 1) + 1; // ✅ safe quantity
    } else {
      items.add({
        'name': item['name'],
        'brand': item['brand'],
        'category': item['category'],
        'price': item['price'],
        'rating': item['rating'],
        'image': item['image'],
        'quantity': 1,
      });
    }

    // ✅ merge = true to prevent overwriting
    await cartRef.set({'items': items}, SetOptions(merge: true));

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("${item['name']} added to cart"),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: const Text("My Wishlist"),
        backgroundColor: const Color(0xFF0D47A1),
      ),
      body: SafeArea(
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  Expanded(
                    child: wishlistItems.isEmpty
                        ? const Center(child: Text("Your wishlist is empty."))
                        : ListView.builder(
                            itemCount: wishlistItems.length,
                            itemBuilder: (context, index) {
                              final item = wishlistItems[index];
                              final unitPrice = parsePrice(item['price']);

                              return Card(
                                margin: const EdgeInsets.all(10),
                                elevation: 3,
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Image.network(
                                        item['image'] ?? '',
                                        width: 60,
                                        height: 60,
                                        fit: BoxFit.cover,
                                        errorBuilder:
                                            (context, error, stackTrace) =>
                                                const Icon(Icons.broken_image),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              item['name'] ?? '',
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.bold),
                                            ),
                                            Text(
                                                "Brand: ${item['brand'] ?? ''}"),
                                            Text(
                                                "Price: PKR ${unitPrice.toStringAsFixed(0)}"),
                                          ],
                                        ),
                                      ),
                                      Column(
                                        children: [
                                          IconButton(
                                            icon: const Icon(Icons.cancel,
                                                color: Colors.red),
                                            onPressed: () => removeItem(index),
                                          ),
                                          ElevatedButton(
                                            onPressed: () => addToCart(index),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.green,
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 12,
                                                      vertical: 6),
                                              minimumSize: const Size(70, 30),
                                            ),
                                            child: const Text("Add",
                                                style: TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.white)),
                                          ),
                                        ],
                                      )
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                  if (wishlistItems.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => const CartScreen()),
                          );
                        },
                        icon: const Icon(Icons.shopping_cart),
                        label: const Text("View Cart"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF00C853),
                          padding: const EdgeInsets.symmetric(
                              vertical: 14, horizontal: 24),
                          textStyle: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
      ),
    );
  }
}
