import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ChangePasswordPage extends StatefulWidget {
  const ChangePasswordPage({super.key});

  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  final currentPassController = TextEditingController();
  final newPassController = TextEditingController();
  final usernameController = TextEditingController();

  bool showCurrentPass = false;
  bool showNewPass = false;
  bool loading = false;

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? user;
  String? oldUsername;
  String? userEmail;

  @override
  void initState() {
    super.initState();
    user = _auth.currentUser;
    if (user != null) {
      userEmail = user!.email;
      getUserData();
    }
  }

  Future<void> getUserData() async {
    try {
      final doc = await _firestore.collection('users').doc(user!.uid).get();
      if (doc.exists) {
        setState(() {
          oldUsername = doc['username'];
          usernameController.text = oldUsername!;
        });
      }
    } catch (e) {
      print('Error fetching user data: $e');
    }
  }

  Future<void> updateUsernameAndPassword() async {
    setState(() => loading = true);

    final currentPassword = currentPassController.text.trim();
    final newPassword = newPassController.text.trim();
    final newUsername = usernameController.text.trim();

    try {
      // 🔒 Reauthenticate user
      final credential = EmailAuthProvider.credential(
        email: userEmail!,
        password: currentPassword,
      );
      await user!.reauthenticateWithCredential(credential);

      // 🔁 Update password if new one provided
      if (newPassword.isNotEmpty) {
        await user!.updatePassword(newPassword);
      }

      // 📝 Update username in Firestore
      await _firestore.collection('users').doc(user!.uid).update({
        'username': newUsername,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed: $e')),
      );
    } finally {
      setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Change Password"),
        backgroundColor: Colors.deepPurple,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // 🧑 Username Field
            TextField(
              controller: usernameController,
              decoration: const InputDecoration(
                labelText: "New Username",
                prefixIcon: Icon(Icons.person),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),

            // 🔐 Current Password Field with Eye
            TextField(
              controller: currentPassController,
              obscureText: !showCurrentPass,
              decoration: InputDecoration(
                labelText: "Current Password",
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  icon: Icon(showCurrentPass
                      ? Icons.visibility_off
                      : Icons.visibility),
                  onPressed: () {
                    setState(() {
                      showCurrentPass = !showCurrentPass;
                    });
                  },
                ),
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),

            // 🔐 New Password Field with Eye
            TextField(
              controller: newPassController,
              obscureText: !showNewPass,
              decoration: InputDecoration(
                labelText: "New Password",
                prefixIcon: const Icon(Icons.lock),
                suffixIcon: IconButton(
                  icon: Icon(
                      showNewPass ? Icons.visibility_off : Icons.visibility),
                  onPressed: () {
                    setState(() {
                      showNewPass = !showNewPass;
                    });
                  },
                ),
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 30),

            // 🔘 Update Button
            loading
                ? const CircularProgressIndicator()
                : ElevatedButton.icon(
                    onPressed: updateUsernameAndPassword,
                    icon: const Icon(Icons.save),
                    label: const Text("Update"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
                      minimumSize: const Size.fromHeight(50),
                    ),
                  )
          ],
        ),
      ),
    );
  }
}
