import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:laptopharbo_app/Pages/cart_screen.dart';
import 'package:laptopharbo_app/support/support_screen.dart';
import 'product_detail_screen.dart';
import 'home_screen.dart'; // 👈 Replace with your actual home screen import // 👈 Replace with your orders screen
import 'package:badges/badges.dart'
    as badges; // 👈 Replace with your profile screen

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

int _selectedIndex = 1;
int cartItemCount = 0;

Color _getSelectedColor(int index) =>
    _selectedIndex == index ? const Color(0xFF42A5F5) : Colors.white;

class _SearchScreenState extends State<SearchScreen> {
  String searchText = '';
  int _selectedIndex = 1; // 👈 default selected index (Search)

  Stream<QuerySnapshot> _getSearchResults() {
    return FirebaseFirestore.instance.collection('products').snapshots();
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    switch (index) {
      case 0:
        Navigator.pushReplacement(context,
            MaterialPageRoute(builder: (_) => const MyHomePage(title: 'Home')));
        break;
      case 1:
        // Already on Search, do nothing or pop to refresh
        break;
      case 2:
        Navigator.push(
            context, MaterialPageRoute(builder: (_) => const CartScreen()));
        break;
      case 3:
        Navigator.push(
            context, MaterialPageRoute(builder: (_) => const SupportScreen()));
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D47A1),
        elevation: 0,
        title: TextField(
          autofocus: true,
          onChanged: (value) {
            setState(() {
              searchText = value.trim().toLowerCase();
            });
          },
          decoration: const InputDecoration(
            hintText: 'Search by name, brand, specs...',
            hintStyle: TextStyle(color: Colors.white70),
            border: InputBorder.none,
          ),
          style: const TextStyle(color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _getSearchResults(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text('No laptops found', style: TextStyle(fontSize: 16)),
            );
          }

          final allProducts = snapshot.data!.docs;

          final filteredProducts = allProducts.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final name = (data['name'] ?? '').toString().toLowerCase();
            final brand = (data['brand'] ?? '').toString().toLowerCase();
            return name.startsWith(searchText) || brand.startsWith(searchText);
          }).toList();

          if (filteredProducts.isEmpty) {
            return const Center(
              child: Text('No laptops found', style: TextStyle(fontSize: 16)),
            );
          }

          return ListView.builder(
            itemCount: filteredProducts.length,
            itemBuilder: (context, index) {
              final data =
                  filteredProducts[index].data() as Map<String, dynamic>;
              final images = List<String>.from(data['images'] ?? []);
              final imageUrl = images.isNotEmpty ? images[0] : '';

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                elevation: 4,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(12),
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: imageUrl.isNotEmpty
                        ? Image.network(
                            imageUrl,
                            width: 60,
                            height: 60,
                            fit: BoxFit.cover,
                          )
                        : const Icon(Icons.image_not_supported),
                  ),
                  title: Text(data['name'] ?? 'No name'),
                  subtitle: Text(
                    'Brand: ${data['brand'] ?? 'N/A'}\nRs. ${data['price'].toString()}',
                    style: const TextStyle(fontSize: 12),
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ProductDetailScreen(productData: data),
                      ),
                    );
                  },
                ),
              );
            },
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
