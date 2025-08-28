import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:laptopharbo_app/Pages/AboutScreen.dart';
import 'package:laptopharbo_app/Pages/ChangePasswordPage.dart';
import 'package:laptopharbo_app/Pages/MyOrdersPage.dart';
import 'package:laptopharbo_app/Pages/SearchScreen.dart';
import 'package:laptopharbo_app/Pages/cart_screen.dart';
import 'package:laptopharbo_app/Pages/laptop_compare_page.dart';
import 'package:laptopharbo_app/User/contact_screen.dart';
import 'package:laptopharbo_app/User/faq_screen.dart';
import 'package:laptopharbo_app/support/support_screen.dart';
import 'product_detail_screen.dart';
import 'profile_screen.dart';

import 'wishlist_screen.dart'; // ✅ Add this
import 'package:badges/badges.dart' as badges;

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

int cartItemCount = 0;
bool showNotification = false;

class _MyHomePageState extends State<MyHomePage> {
  final User? user = FirebaseAuth.instance.currentUser;
  int _selectedIndex = 0;
  String selectedCategory = 'All';
  String selectedBrand = 'All';
  String selectedPrice = 'All';
  String selectedRating = 'All';
  bool isDarkMode = false;

  final List<String> bannerImages = [
    'assets/banner1.jpg',
    'assets/banner2.jpg',
    'assets/banner3.jpg',
  ];

  final List<String> categories = ['All', 'Gaming', 'Business', 'Student'];
  final List<String> brands = ['All', 'HP', 'Dell', 'Lenovo', 'Acer', 'Apple'];
  final List<String> priceRanges = [
    'All',
    '< \$500',
    '\$500 - \$1000',
    '>\$1000'
  ];
  final List<String> ratings = ['All', '5', '4', '3'];

  List<Map<String, dynamic>> wishlist = [];
  Map<int, bool> isWishlisted = {};

  @override
  void initState() {
    super.initState();
    listenToOrderUpdates();
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      _getCartItemCount(currentUser.uid);
    }
  }

  void listenToOrderUpdates() {
    FirebaseFirestore.instance
        .collection('orders')
        .where('userId', isEqualTo: FirebaseAuth.instance.currentUser!.uid)
        .snapshots()
        .listen((snapshot) {
      for (var doc in snapshot.docs) {
        var data = doc.data();
        Timestamp updatedAt = data['updatedAt'];
        Timestamp createdAt = data['createdAt'];

        // Agar updatedAt bad mein ho createdAt se => order update hua hai
        if (updatedAt != null &&
            createdAt != null &&
            updatedAt.toDate().isAfter(createdAt.toDate())) {
          setState(() {
            showNotification = true;
          });
          break;
        }
      }
    });
  }

  void _getCartItemCount(String uid) {
    FirebaseFirestore.instance
        .collection('carts')
        .doc(uid)
        .snapshots()
        .listen((doc) {
      if (doc.exists && doc.data() != null) {
        final data = doc.data() as Map<String, dynamic>;
        final items = data['items'] as List<dynamic>? ?? [];
        setState(() {
          cartItemCount = items.length;
        });
      } else {
        setState(() {
          cartItemCount = 0;
        });
      }
    });
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    switch (index) {
      case 0:
        // Stay on home screen, no push
        break;
      case 1:
        Navigator.push(
            context, MaterialPageRoute(builder: (_) => SearchScreen()));
        break;
      case 2:
        Navigator.push(
            context, MaterialPageRoute(builder: (_) => CartScreen()));
        break;
      case 3:
        Navigator.push(
            context, MaterialPageRoute(builder: (_) => SupportScreen()));
        break;
    }
  }

  Color _getSelectedColor(int index) =>
      _selectedIndex == index ? const Color(0xFF42A5F5) : Colors.white;

  void clearFilters() => setState(() {
        selectedBrand = 'All';
        selectedCategory = 'All';
        selectedPrice = 'All';
        selectedRating = 'All';
      });

  Query _buildProductQuery() {
    Query query = FirebaseFirestore.instance.collection('products');
    if (selectedCategory != 'All')
      query = query.where('category', isEqualTo: selectedCategory);
    if (selectedBrand != 'All')
      query = query.where('brand', isEqualTo: selectedBrand);
    if (selectedPrice != 'All') {
      if (selectedPrice == '< \$500')
        query = query.where('price', isLessThan: 500);
      else if (selectedPrice == '\$500 - \$1000') {
        query = query
            .where('price', isGreaterThanOrEqualTo: 500)
            .where('price', isLessThanOrEqualTo: 1000);
      } else if (selectedPrice == '>\$1000')
        query = query.where('price', isGreaterThan: 1000);
    }
    if (selectedRating != 'All')
      query = query.where('rating',
          isGreaterThanOrEqualTo: int.parse(selectedRating));
    return query;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: Drawer(
        backgroundColor: const Color(0xFF0D47A1),
        child: StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(user!.uid)
              .snapshots(),
          builder: (context, snapshot) {
            final data = snapshot.data?.data() as Map<String, dynamic>?;
            final imageUrl = data != null && data.containsKey('imageurl')
                ? data['imageurl']
                : null;
            final username = data?['username'] ?? 'User';
            return ListView(
              padding: EdgeInsets.zero,
              children: [
                UserAccountsDrawerHeader(
                  accountName: Text(username),
                  accountEmail: Text(user?.email ?? 'No email'),
                  currentAccountPicture: CircleAvatar(
                    backgroundImage:
                        imageUrl != null ? NetworkImage(imageUrl) : null,
                    child: imageUrl == null
                        ? const Icon(Icons.person,
                            size: 40, color: Colors.white)
                        : null,
                  ),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                        colors: [Color(0xFF1A237E), Color(0xFF2979FF)]),
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.person, color: Colors.white),
                  title: const Text('User Profile',
                      style: TextStyle(color: Colors.white)),
                  onTap: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const ProfileScreen())),
                ),
                ListTile(
                  leading: const Icon(Icons.favorite, color: Colors.white),
                  title: const Text('User Order',
                      style: TextStyle(color: Colors.white)),
                  onTap: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const MyOrdersPage())),
                ),
                ListTile(
                    leading: const Icon(Icons.favorite, color: Colors.white),
                    title: const Text('AboutLaptopHarbor',
                        style: TextStyle(color: Colors.white)),
                    onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const AboutLaptopHarbor()),
                        )),
                ListTile(
                  leading:
                      const Icon(Icons.compare_arrows, color: Colors.white),
                  title: const Text('Compare Laptops',
                      style: TextStyle(color: Colors.white)),
                  onTap: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => LaptopComparePage())),
                ),
                ListTile(
                  leading: const Icon(Icons.contact_mail, color: Colors.white),
                  title: const Text('Contact Us',
                      style: TextStyle(color: Colors.white)),
                  onTap: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const ContactScreen())),
                ),
                ListTile(
                  leading: const Icon(Icons.help_outline, color: Colors.white),
                  title:
                      const Text('FAQ', style: TextStyle(color: Colors.white)),
                  onTap: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const FAQScreen())),
                ),
                ListTile(
                  leading: const Icon(Icons.lock, color: Colors.white),
                  title: const Text('Change Password',
                      style: TextStyle(color: Colors.white)),
                  onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const ChangePasswordPage())),
                ),
                ListTile(
                  leading: const Icon(Icons.logout, color: Colors.white),
                  title: const Text('Logout',
                      style: TextStyle(color: Colors.white)),
                  onTap: () async {
                    await FirebaseAuth.instance.signOut();
                    if (mounted)
                      Navigator.pushNamedAndRemoveUntil(
                          context, '/login', (route) => false);
                  },
                ),
              ],
            );
          },
        ),
      ),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D47A1),
        elevation: 4,
        iconTheme: const IconThemeData(color: Colors.white),
        title: StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(user!.uid)
              .snapshots(),
          builder: (context, snapshot) {
            final userData = snapshot.data?.data() as Map<String, dynamic>?;
            final username = userData?['username'] ?? 'User';
            return Row(
              children: [
                Text('Welcome back, $username 👋',
                    style: const TextStyle(color: Colors.white, fontSize: 16)),
                const Spacer(),

                /// 🔵 Filter Icon
                IconButton(
                  icon: const Icon(Icons.filter_alt, color: Colors.white),
                  onPressed: clearFilters,
                ),

                /// 🔴 Notifications Badge
                // StreamBuilder<QuerySnapshot>(
                //   stream: FirebaseFirestore.instance
                //       .collection('notifications')
                //       .doc(user!.uid)
                //       .collection('items')
                //       .where('isRead', isEqualTo: false)
                //       .snapshots(),
                //   builder: (context, snapshot) {
                //     int count = snapshot.data?.docs.length ?? 0;

                //     return badges.Badge(
                //       badgeContent: Text(
                //         count.toString(),
                //         style:
                //             const TextStyle(color: Colors.white, fontSize: 12),
                //       ),
                //       position: badges.BadgePosition.topEnd(top: -6, end: -4),
                //       showBadge: count > 0,
                //       child: IconButton(
                //         icon: const Icon(Icons.notifications,
                //             color: Colors.white),
                //         onPressed: () async {
                //           await Navigator.push(
                //             context,
                //             MaterialPageRoute(
                //                 builder: (_) => const NotificationsScreen()),
                //           );
                //           setState(() {}); // refresh after return
                //         },
                //       ),
                //     );
                //   },
                // ),

                /// ❤️ Wishlist Badge
                StreamBuilder<DocumentSnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('wishlists')
                      .doc(user!.uid)
                      .snapshots(),
                  builder: (context, snapshot) {
                    int count = 0;
                    if (snapshot.hasData && snapshot.data!.exists) {
                      final data =
                          snapshot.data!.data() as Map<String, dynamic>;
                      final items = data['items'] as List<dynamic>? ?? [];
                      count = items.length;
                    }

                    return badges.Badge(
                      badgeContent: Text(
                        count.toString(),
                        style:
                            const TextStyle(color: Colors.white, fontSize: 12),
                      ),
                      position: badges.BadgePosition.topEnd(top: -6, end: -4),
                      showBadge: count > 0,
                      child: IconButton(
                        icon: const Icon(Icons.favorite_rounded,
                            color: Colors.white),
                        onPressed: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const WishlistScreen()),
                          );
                          setState(() {});
                        },
                      ),
                    );
                  },
                ),
              ],
            );
          },
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CarouselSlider(
              items: bannerImages.map((img) {
                return ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.asset(img,
                      fit: BoxFit.cover, width: double.infinity),
                );
              }).toList(),
              options: CarouselOptions(
                height: 180,
                autoPlay: true,
                enlargeCenterPage: true,
                viewportFraction: 0.9,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              children: [
                DropdownButton<String>(
                  value: selectedCategory,
                  items: categories
                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
                  onChanged: (val) => setState(() => selectedCategory = val!),
                ),
                DropdownButton<String>(
                  value: selectedBrand,
                  items: brands
                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
                  onChanged: (val) => setState(() => selectedBrand = val!),
                ),
                DropdownButton<String>(
                  value: selectedPrice,
                  items: priceRanges
                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
                  onChanged: (val) => setState(() => selectedPrice = val!),
                ),
                DropdownButton<String>(
                  value: selectedRating,
                  items: ratings
                      .map((e) => DropdownMenuItem(
                          value: e, child: Text(e == 'All' ? 'All' : "$e+")))
                      .toList(),
                  onChanged: (val) => setState(() => selectedRating = val!),
                ),
              ],
            ),
            const SizedBox(height: 10),
            StreamBuilder<QuerySnapshot>(
              stream: _buildProductQuery().snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData)
                  return const Center(child: CircularProgressIndicator());
                final products = snapshot.data!.docs;
                if (products.isEmpty)
                  return const Center(child: Text('No products found.'));
                return GridView.builder(
                  shrinkWrap: true,
                  primary: false,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: products.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: 0.63,
                  ),
                  itemBuilder: (context, index) {
                    final data = products[index].data() as Map<String, dynamic>;
                    final name = data['name'] ?? '';
                    final brand = data['brand'] ?? '';
                    final category = data['category'] ?? '';
                    final price = data['price'] ?? '';
                    final rating = (data['rating'] ?? 0).toDouble();
                    final images = List<String>.from(data['images'] ?? []);
                    final currentUser = FirebaseAuth.instance.currentUser;
                    bool isWished = false;

                    if (currentUser != null) {
                      final wishlistDoc = FirebaseFirestore.instance
                          .collection('wishlists')
                          .doc(currentUser.uid);

                      wishlistDoc.get().then((doc) {
                        if (doc.exists) {
                          final items = List<Map<String, dynamic>>.from(
                              doc['items'] ?? []);
                          final already =
                              items.any((element) => element['name'] == name);
                          setState(() {
                            isWishlisted[index] = already;
                          });
                        }
                      });
                    }

                    isWished = isWishlisted[index] ?? false;

                    return GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) =>
                                ProductDetailScreen(productData: data)),
                      ),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(color: Colors.black12, blurRadius: 5)
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Stack(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(
                                    images.isNotEmpty ? images[0] : '',
                                    height: 100,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                Positioned(
                                  top: 8,
                                  right: 8,
                                  child: GestureDetector(
                                    onTap: () async {
                                      final currentUser =
                                          FirebaseAuth.instance.currentUser;
                                      if (currentUser == null) return;

                                      final item = {
                                        'name': name,
                                        'brand': brand,
                                        'category': category,
                                        'price': price,
                                        'rating': rating,
                                        'image':
                                            images.isNotEmpty ? images[0] : '',
                                        'quantity': 1,
                                      };

                                      final wishlistRef = FirebaseFirestore
                                          .instance
                                          .collection('wishlists')
                                          .doc(currentUser.uid);

                                      final doc = await wishlistRef.get();

                                      List items = [];
                                      if (doc.exists &&
                                          doc.data() != null &&
                                          doc.data()!.containsKey('items')) {
                                        items = List<Map<String, dynamic>>.from(
                                            doc['items']);
                                      }

                                      final isAlreadyInWishlist = items.any(
                                          (element) =>
                                              element['name'] == item['name']);

                                      if (isAlreadyInWishlist) {
                                        items.removeWhere((element) =>
                                            element['name'] == item['name']);
                                        setState(
                                            () => isWishlisted[index] = false);
                                      } else {
                                        items.add(item);
                                        setState(
                                            () => isWishlisted[index] = true);
                                      }

                                      await wishlistRef.set({'items': items});
                                    },
                                    child: AnimatedSwitcher(
                                      duration:
                                          const Duration(milliseconds: 300),
                                      transitionBuilder: (child, animation) =>
                                          ScaleTransition(
                                        scale: animation,
                                        child: child,
                                      ),
                                      child: Icon(
                                        isWished
                                            ? Icons.favorite
                                            : Icons.favorite_border,
                                        key: ValueKey<bool>(isWished),
                                        color: Colors.red,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text("$brand - $name",
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    fontSize: 14, fontWeight: FontWeight.bold)),
                            Text("Category: $category",
                                style: const TextStyle(
                                    fontSize: 12, color: Colors.grey)),
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
                            Text("\$$price",
                                style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.green)),
                            const Spacer(),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: () async {
                                  final currentUser =
                                      FirebaseAuth.instance.currentUser;
                                  if (currentUser == null) return;

                                  final cartRef = FirebaseFirestore.instance
                                      .collection('carts')
                                      .doc(currentUser.uid);
                                  final cartDoc = await cartRef.get();

                                  final item = {
                                    'name': name,
                                    'brand': brand,
                                    'category': category,
                                    'price': price,
                                    'rating': rating,
                                    'image': images.isNotEmpty ? images[0] : '',
                                    'quantity': 1,
                                  };

                                  List items = [];
                                  if (cartDoc.exists &&
                                      cartDoc.data() != null) {
                                    items = List<Map<String, dynamic>>.from(
                                        cartDoc['items']);
                                  }

                                  final index = items
                                      .indexWhere((e) => e['name'] == name);
                                  if (index != -1) {
                                    items[index]['quantity'] += 1;
                                  } else {
                                    items.add(item);
                                  }

                                  await cartRef.set({'items': items});

                                  // ✅ Show snackbar, no navigation
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content: Text("Product added to cart")),
                                  );
                                },
                                icon: const Icon(Icons.shopping_cart, size: 16),
                                label: const Text("Add"),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF00C853),
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 10),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
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
