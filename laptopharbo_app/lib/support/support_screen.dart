import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:laptopharbo_app/Pages/cart_screen.dart';
import 'package:badges/badges.dart' as badges;
import 'package:laptopharbo_app/Pages/home_screen.dart';

class SupportScreen extends StatefulWidget {
  const SupportScreen({super.key});

  @override
  State<SupportScreen> createState() => _SupportScreenState();
}

int _selectedIndex = 1;
int cartItemCount = 0;

Color _getSelectedColor(int index) =>
    _selectedIndex == index ? const Color(0xFF42A5F5) : Colors.white;

class _SupportScreenState extends State<SupportScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController subjectController = TextEditingController();
  final TextEditingController messageController = TextEditingController();

  final user = FirebaseAuth.instance.currentUser;

  Future<void> _submitSupportForm() async {
    if (!_formKey.currentState!.validate()) return;

    await FirebaseFirestore.instance.collection('support_feedback').add({
      'uid': user?.uid,
      'name': user?.displayName ?? 'Static Name',
      'email': user?.email,
      'phone': phoneController.text.trim(),
      'subject': subjectController.text.trim(),
      'message': messageController.text.trim(),
      'timestamp': FieldValue.serverTimestamp(),
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Support request submitted successfully')),
    );

    phoneController.clear();
    subjectController.clear();
    messageController.clear();
  }

  // 0 = Home, 1 = Support (current), 2 = Profile
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
    final name = user?.displayName ?? 'Static Name';
    final email = user?.email ?? 'user@example.com';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Support & Feedback'),
        backgroundColor: const Color(0xFF0D47A1),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                initialValue: name,
                decoration: const InputDecoration(
                  labelText: 'Your Name',
                  border: OutlineInputBorder(),
                ),
                enabled: false,
              ),
              const SizedBox(height: 10),
              TextFormField(
                initialValue: email,
                decoration: const InputDecoration(
                  labelText: 'Your Email',
                  border: OutlineInputBorder(),
                ),
                enabled: false,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: phoneController,
                decoration: const InputDecoration(
                  labelText: 'Phone Number',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.phone,
                maxLength: 11,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                ],
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter phone number';
                  } else if (value.length != 11) {
                    return 'Phone number must be exactly 11 digits';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: subjectController,
                decoration: const InputDecoration(
                  labelText: 'Subject/Issue Title',
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                    value!.isEmpty ? 'Please enter a subject' : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: messageController,
                maxLines: 5,
                decoration: const InputDecoration(
                  labelText: 'Describe your issue',
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                    value!.isEmpty ? 'Please describe your issue' : null,
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _submitSupportForm,
                icon: const Icon(Icons.send),
                label: const Text("Submit Support Request"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00C853),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
            ],
          ),
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
