import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:laptopharbo_app/admin/UpdateProductPage.dart';

class ProductListPage extends StatelessWidget {
  const ProductListPage({super.key});

  Future<void> deleteProduct(String docId, BuildContext context) async {
    try {
      await FirebaseFirestore.instance
          .collection('products')
          .doc(docId)
          .delete();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Product deleted successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting product: $e')),
      );
    }
  }

  void editProduct(DocumentSnapshot doc, BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => UpdateProductPage(productDoc: doc),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Product List")),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('products')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final products = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: products.length,
            itemBuilder: (context, index) {
              final doc = products[index];
              final data = doc.data() as Map<String, dynamic>;
              final images = data['images'] as List<dynamic>? ?? [];

              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (images.isNotEmpty)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.network(
                            images[0],
                            height: 180,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        ),
                      const SizedBox(height: 10),
                      Text(
                        data['name'] ?? '',
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 6),
                      Text("Brand: ${data['brand'] ?? ''}",
                          style: const TextStyle(fontSize: 15)),
                      Text("Category: ${data['category'] ?? ''}",
                          style: const TextStyle(fontSize: 15)),
                      const SizedBox(height: 6),
                      Text("Price: ${data['price']}",
                          style: const TextStyle(fontSize: 16)),
                      const SizedBox(height: 6),
                      Text("Specs: ${data['spec']}",
                          style: const TextStyle(fontSize: 15)),
                      const SizedBox(height: 6),
                      RatingBarIndicator(
                        rating: (data['rating'] ?? 0).toDouble(),
                        itemBuilder: (context, _) => const Icon(
                          Icons.star,
                          color: Colors.amber,
                        ),
                        itemCount: 5,
                        itemSize: 22.0,
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.blue),
                            onPressed: () => editProduct(doc, context),
                          ),
                          IconButton(
                            onPressed: () => deleteProduct(doc.id, context),
                            icon: const Icon(Icons.delete, color: Colors.red),
                          ),
                        ],
                      )
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
