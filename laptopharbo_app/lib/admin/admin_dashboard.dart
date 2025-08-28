import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:laptopharbo_app/Pages/OrderTrackingPage.dart';
import 'package:laptopharbo_app/SignupPage/login_screen.dart';
import 'package:laptopharbo_app/admin/Add_Product.dart';
import 'package:laptopharbo_app/admin/AdminOrderPage.dart';
import 'package:laptopharbo_app/admin/SupportListPage.dart';
import 'package:laptopharbo_app/admin/TotalUsersPage.dart';
import 'package:laptopharbo_app/admin/admin_change_password_page.dart';
import 'package:laptopharbo_app/admin/adminlogin_list.dart';
import 'package:laptopharbo_app/admin/contact_list_page.dart';
import 'package:laptopharbo_app/admin/product_list_page.dart';

// ✅ New import

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int userCount = 0;
  int productCount = 0;
  int contactCount = 0;
  int adminCount = 0;
  int orderCount = 0;
  int supportCount = 0;

  String profileImageUrl = "";

  @override
  void initState() {
    super.initState();
    fetchCounts();
    fetchProfileImage();
  }

  Future<void> fetchCounts() async {
    try {
      final usersSnapshot =
          await FirebaseFirestore.instance.collection('users').get();
      final productsSnapshot =
          await FirebaseFirestore.instance.collection('products').get();
      final contactsSnapshot = await FirebaseFirestore.instance
          .collection('user_contact_queries')
          .get();
      final ordersSnapshot =
          await FirebaseFirestore.instance.collection('orders').get();
      final supportSnapshot =
          await FirebaseFirestore.instance.collection('support_feedback').get();

      final allUsers = usersSnapshot.docs;

      final normalUsers = allUsers
          .where((doc) =>
              doc.data().containsKey('role') &&
              doc['role'].toString().toLowerCase() == 'user')
          .length;

      final admins = allUsers
          .where((doc) =>
              doc.data().containsKey('role') &&
              doc['role'].toString().toLowerCase() == 'admin')
          .length;

      setState(() {
        userCount = normalUsers;
        adminCount = admins;
        productCount = productsSnapshot.size;
        contactCount = contactsSnapshot.size;
        orderCount = ordersSnapshot.size;
        supportCount = supportSnapshot.size;
      });
    } catch (e) {
      print("⚠️ Error fetching counts: $e");
    }
  }

  Future<void> fetchProfileImage() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) {
        final doc =
            await FirebaseFirestore.instance.collection('users').doc(uid).get();
        if (doc.exists && doc.data()!.containsKey('imageUrl')) {
          setState(() {
            profileImageUrl = doc['imageUrl'];
          });
        }
      }
    } catch (e) {
      print("⚠️ Failed to fetch profile image: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final User? user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      drawer: Drawer(
        child: ListView(
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: Colors.blue),
              child: Center(
                child: Text(
                  "Admin Panel",
                  style: TextStyle(color: Colors.white, fontSize: 24),
                ),
              ),
            ),
            _drawerItem(Icons.dashboard, "Dashboard"),
            _drawerItem(Icons.production_quantity_limits, "Products"),
            _drawerItem(Icons.people, "Total Signup"),
            _drawerItem(Icons.message, "Contacts"),
            _drawerItem(Icons.admin_panel_settings, "Admin List"),
            _drawerItem(Icons.add_box, "Add Product"),
            _drawerItem(Icons.list_alt, "Product List"), // ✅ Connected properly
            _drawerItem(Icons.list_alt, "Support List"), // ✅ Connected properly
            _drawerItem(Icons.list_alt, "Admin Order"),
            _drawerItem(Icons.lock, "Change Password"),

            // ✅ Connected properly
          ],
        ),
      ),
      appBar: AppBar(
        title: const Text("Admin Dashboard"),
        backgroundColor: Colors.blue.shade700,
        actions: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundImage: profileImageUrl.isNotEmpty
                    ? NetworkImage(profileImageUrl)
                    : const AssetImage("assets/default_avatar.png")
                        as ImageProvider,
              ),
              const SizedBox(width: 8),
              Text(
                user?.email ?? "No Email",
                style: const TextStyle(color: Colors.white),
              ),
              IconButton(
                icon: const Icon(Icons.logout),
                onPressed: () async {
                  await FirebaseAuth.instance.signOut();
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                    (route) => false,
                  );
                },
              ),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Dashboard Overview",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                _buildStatCard("Total Signup", userCount, Colors.blue),
                _buildStatCard("Total Admins", adminCount, Colors.orange),
                _buildStatCard("Products Added", productCount, Colors.green),
                _buildStatCard("Orders", orderCount, Colors.purple),
                _buildStatCard("Contacts", contactCount, Colors.teal),
                _buildStatCard("Support Requests", supportCount, Colors.red),
              ],
            ),
            // const SizedBox(height: 30),
            // const Text(
            //   "User Activity (Sample Graph)",
            //   style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            // ),
            // const SizedBox(height: 200, child: _BarChartSample()),
          ],
        ),
      ),
    );
  }

  Widget _drawerItem(IconData icon, String label) {
    return ListTile(
      leading: Icon(icon),
      title: Text(label),
      onTap: () {
        Navigator.pop(context);
        if (label == "Admin List") {
          Navigator.push(context,
              MaterialPageRoute(builder: (_) => const AdminListPage()));
        } else if (label == "Total Signup") {
          Navigator.push(context,
              MaterialPageRoute(builder: (_) => const TotalUsersPage()));
        } else if (label == "Add Product") {
          Navigator.push(context,
              MaterialPageRoute(builder: (_) => const AddProductPage()));
        } else if (label == "Product List") {
          Navigator.push(context,
              MaterialPageRoute(builder: (_) => const ProductListPage()));
        } else if (label == "Contacts") {
          Navigator.push(context,
              MaterialPageRoute(builder: (_) => const ContactListPage()));
        } else if (label == "Support List") {
          Navigator.push(context,
              MaterialPageRoute(builder: (_) => const SupportListPage()));
        } else if (label == "Admin Order") {
          Navigator.push(context,
              MaterialPageRoute(builder: (_) => const AdminOrdersPage()));
        }
        
        
         else if (label == "Change Password") {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AdminChangePasswordPage()),
          );
        } else {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text("$label clicked")));
        }
      },
    );
  }

  Widget _buildStatCard(String title, int count, Color color) {
    return Container(
      width: 180,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(fontSize: 16, color: color)),
          const SizedBox(height: 10),
          Text(
            count.toString(),
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _BarChartSample extends StatelessWidget {
  const _BarChartSample();

  @override
  Widget build(BuildContext context) {
    return BarChart(
      BarChartData(
        borderData: FlBorderData(show: false),
        barGroups: [
          BarChartGroupData(
              x: 1, barRods: [BarChartRodData(toY: 5, color: Colors.blue)]),
          BarChartGroupData(
              x: 2, barRods: [BarChartRodData(toY: 8, color: Colors.green)]),
          BarChartGroupData(
              x: 3, barRods: [BarChartRodData(toY: 3, color: Colors.orange)]),
          BarChartGroupData(
              x: 4, barRods: [BarChartRodData(toY: 7, color: Colors.red)]),
        ],
      ),
    );
  }
}
