import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:laptopharbo_app/Pages/BuyNowPage.dart';

class ProductDetailScreen extends StatefulWidget {
  final Map<String, dynamic> productData;

  const ProductDetailScreen({super.key, required this.productData});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  double _userRating = 0.0;
  final TextEditingController _reviewController = TextEditingController();

  Future<void> addToCart() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final product = widget.productData;
    final cartRef =
        FirebaseFirestore.instance.collection('carts').doc(user.uid);
    final cartDoc = await cartRef.get();

    List items = [];
    if (cartDoc.exists && cartDoc.data() != null) {
      items = List<Map<String, dynamic>>.from(cartDoc['items']);
    }

    final index = items.indexWhere((item) => item['name'] == product['name']);
    if (index != -1) {
      items[index]['quantity'] += 1;
    } else {
      items.add({
        'name': product['name'],
        'brand': product['brand'],
        'category': product['category'],
        'price': product['price'],
        'rating': product['rating'],
        'image': product['images'][0],
        'quantity': 1,
      });
    }

    await cartRef.set({'items': items});
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Product added to cart!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.productData;
    final images = List<String>.from(data['images'] ?? []);
    final brand = data['brand'] ?? '';
    final name = data['name'] ?? '';
    final category = data['category'] ?? '';
    final description = data['description'] ?? '';
    final spec = data['spec'] ?? '';
    final rating = (data['rating'] ?? 0.0).toDouble();
    final priceString =
        data['price'].toString().replaceAll(RegExp(r'[^\d.]'), '');
    final price = double.tryParse(priceString) ?? 0.0;
    final productId = data['id'];

    return Scaffold(
      appBar: AppBar(
        title: Text(name,
            style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 20)),
        backgroundColor: const Color(0xFF0D47A1),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CarouselSlider(
              items: images.map((url) {
                return ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    url,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                );
              }).toList(),
              options: CarouselOptions(
                  height: 220, autoPlay: true, enlargeCenterPage: true),
            ),
            const SizedBox(height: 16),
            Text("$brand - $name",
                style:
                    const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Text("Category: $category",
                style: const TextStyle(fontSize: 14, color: Colors.grey)),
            const SizedBox(height: 6),
            Row(
              children: List.generate(
                5,
                (i) => Icon(
                  i < rating ? Icons.star : Icons.star_border,
                  size: 18,
                  color: Colors.amber,
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text("Description",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Text(description),
            const SizedBox(height: 12),
            const Text("Specifications",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Text(spec),
            const SizedBox(height: 16),
            Text("Price: PKR ${price.toStringAsFixed(0)}",
                style: const TextStyle(fontSize: 18, color: Colors.green)),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.shopping_cart),
                    label: const Text("Add to Cart"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00C853),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: addToCart,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.shopping_bag),
                    label: const Text("Buy Now"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2962FF),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              BuyNowPage(productData: widget.productData),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 30),
            const Divider(),
            const Text("User Reviews",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('reviews')
                  .where('productId', isEqualTo: productId)
                  .orderBy('date', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Text("No reviews yet.");
                }

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    final review = snapshot.data!.docs[index];
                    final userName = review['userName'];
                    final rating = review['rating'];
                    final comment = review['comment'];
                    final date = (review['date'] as Timestamp).toDate();

                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      child: ListTile(
                        title: Text(userName),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: List.generate(
                                5,
                                (i) => Icon(
                                  i < rating ? Icons.star : Icons.star_border,
                                  size: 16,
                                  color: Colors.amber,
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(comment),
                            Text("${date.toLocal()}".split(' ')[0],
                                style: const TextStyle(
                                    fontSize: 12, color: Colors.grey)),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
            const SizedBox(height: 30),
            const Divider(),
            const Text("Write a Review",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Row(
              children: List.generate(5, (index) {
                return IconButton(
                  onPressed: () {
                    setState(() {
                      _userRating = index + 1.0;
                    });
                  },
                  icon: Icon(
                    Icons.star,
                    color: _userRating > index ? Colors.amber : Colors.grey,
                  ),
                );
              }),
            ),
            TextField(
              controller: _reviewController,
              decoration: const InputDecoration(
                labelText: "Your review",
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () async {
                final currentUser = FirebaseAuth.instance.currentUser;
                if (currentUser == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text("Please log in to submit a review")),
                  );
                  return;
                }

                await FirebaseFirestore.instance.collection('reviews').add({
                  'productId': productId, // ✅ Yeh yahan hona chahiye
                  'userId': currentUser.uid,
                  'userName': currentUser.displayName ?? 'Anonymous',
                  'rating': _userRating,
                  'comment': _reviewController.text,
                  'date': Timestamp.now(),
                });

                _reviewController.clear();
                _userRating = 0.0;

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Review submitted")),
                );
                setState(() {});
              },
              child: const Text("Submit Review"),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}
