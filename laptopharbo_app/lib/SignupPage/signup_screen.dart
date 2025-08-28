import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui';
import 'package:bcrypt/bcrypt.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;
import 'package:lottie/lottie.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final _formKey = GlobalKey<FormState>();
  final userData = {'username': '', 'email': '', 'password': ''};
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  XFile? _imgFile;
  bool loading = false;
  bool obscure = true;

  // ✅ Role Dropdown
  final List<String> roles = ['user', 'admin'];
  String? selectedRole;

  Future<void> pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked != null) setState(() => _imgFile = picked);
  }

  Future<void> uploadAndRegister() async {
    if (!_formKey.currentState!.validate()) return;
    if (_imgFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a profile image')),
      );
      return;
    }
    if (selectedRole == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a role')),
      );
      return;
    }

    try {
      setState(() => loading = true);

      // 🔒 Check if admin already created
      if (selectedRole == 'admin') {
        final adminDoc = await FirebaseFirestore.instance
            .collection('config')
            .doc('admin')
            .get();

        if (adminDoc.exists && adminDoc.data()?['adminCreated'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Admin account already exists')),
          );
          setState(() => loading = false);
          return;
        }
      }

      final bytes = await _imgFile!.readAsBytes();
      final uri = Uri.parse("https://api.cloudinary.com/v1_1/djf0nppav/upload");

      final req = http.MultipartRequest('POST', uri)
        ..fields['upload_preset'] = 'ECOMApp'
        ..files.add(
          http.MultipartFile.fromBytes(
            'file',
            bytes,
            filename: path.basename(_imgFile!.path),
          ),
        );

      final res = await req.send();
      final body = await res.stream.bytesToString();
      final result = jsonDecode(body);
      if (res.statusCode != 200) {
        throw 'Image upload failed: ${result['error']['message']}';
      }

      final imgUrl = result['secure_url'];
      final pubId = result['public_id'];
      final hashedPass = BCrypt.hashpw(userData['password']!, BCrypt.gensalt());

      final userCred =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: userData['email']!,
        password: userData['password']!,
      );
      final uid = userCred.user!.uid;

      await userCred.user!.updateDisplayName(userData['username']);
      await userCred.user!.reload();

      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'uid': uid,
        'username': userData['username'],
        'email': userData['email'],
        'password': hashedPass,
        'imageurl': imgUrl,
        'public_id': pubId,
        'role': selectedRole,
        'createdAt': DateTime.now(),
      });

      // ✅ Mark admin as created
      if (selectedRole == 'admin') {
        await FirebaseFirestore.instance
            .collection('config')
            .doc('admin')
            .set({'adminCreated': true});
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Signup successful")),
      );
      Navigator.pushReplacementNamed(context, '/login');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Signup failed: $e")),
      );
    } finally {
      setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          SizedBox.expand(
            child: Image.asset('assets/bg.png', fit: BoxFit.cover),
          ),
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
            child: Container(color: Colors.black.withOpacity(0.3)),
          ),
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withOpacity(0.2)),
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          SizedBox(
                            height: 90, // 👈 Kam kar diya 120 se
                            child: Lottie.asset(
                              'assets/images/signup.json',
                              repeat: true,
                              reverse: false,
                              animate: true,
                            ),
                          ),

                          const Text(
                            "Create Account",
                            style: TextStyle(fontSize: 28, color: Colors.white),
                          ),
                          const SizedBox(height: 20),
                          _buildInput(
                            "Username",
                            onChanged: (v) => userData['username'] = v,
                          ),
                          const SizedBox(height: 10),
                          _buildInput(
                            "Email",
                            onChanged: (v) {
                              userData['email'] = v;
                              emailController.text = v;
                            },
                          ),
                          const SizedBox(height: 10),
                          _buildInput(
                            "Password",
                            isPassword: true,
                            onChanged: (v) {
                              userData['password'] = v;
                              passwordController.text = v;
                            },
                          ),
                          const SizedBox(height: 20),

                          // 🔽 Role Dropdown
                          DropdownButtonFormField<String>(
                            value: selectedRole,
                            items: roles.map((role) {
                              return DropdownMenuItem(
                                value: role,
                                child: Text(
                                  role.toUpperCase(),
                                  style: const TextStyle(color: Colors.white),
                                ),
                              );
                            }).toList(),
                            onChanged: (value) async {
                              if (value == 'admin') {
                                final adminDoc = await FirebaseFirestore
                                    .instance
                                    .collection('config')
                                    .doc('admin')
                                    .get();

                                if (adminDoc.exists &&
                                    adminDoc.data()?['adminCreated'] == true) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                          'Admin already exists. Please select USER.'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                  return;
                                }
                              }
                              setState(() => selectedRole = value);
                            },
                            decoration: const InputDecoration(
                              labelText: "Select Role",
                              labelStyle: TextStyle(color: Colors.white),
                              enabledBorder: UnderlineInputBorder(
                                borderSide: BorderSide(color: Colors.white60),
                              ),
                              focusedBorder: UnderlineInputBorder(
                                borderSide: BorderSide(color: Colors.amber),
                              ),
                            ),
                            dropdownColor: Colors.black,
                            style: const TextStyle(color: Colors.white),
                            validator: (val) =>
                                val == null ? 'Select a role' : null,
                          ),

                          const SizedBox(height: 20),
                          ElevatedButton.icon(
                            onPressed: pickImage,
                            icon: const Icon(Icons.image),
                            label: Text(
                              _imgFile == null ? "Select Image" : "Change",
                            ),
                          ),
                          const SizedBox(height: 10),
                          if (_imgFile != null)
                            FutureBuilder<Uint8List>(
                              future: _imgFile!.readAsBytes(),
                              builder: (context, snapshot) {
                                if (snapshot.connectionState ==
                                        ConnectionState.done &&
                                    snapshot.hasData) {
                                  return ClipOval(
                                    child: Image.memory(
                                      snapshot.data!,
                                      width: 90,
                                      height: 90,
                                      fit: BoxFit.cover,
                                    ),
                                  );
                                }
                                return const CircularProgressIndicator();
                              },
                            ),
                          const SizedBox(height: 30),
                          loading
                              ? const CircularProgressIndicator(
                                  color: Colors.white,
                                )
                              : ElevatedButton(
                                  onPressed: uploadAndRegister,
                                  child: const Text("Sign Up"),
                                ),
                          const SizedBox(height: 10),
                          TextButton(
                            onPressed: () => Navigator.pushReplacementNamed(
                              context,
                              '/login',
                            ),
                            child: const Text(
                              "Already have an account? Login",
                              style: TextStyle(color: Colors.amber),
                            ),
                          ),
                          TextButton(
                            onPressed: () async {
                              if (emailController.text.isEmpty ||
                                  !emailController.text.contains('@')) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                        "Enter a valid email to reset password"),
                                  ),
                                );
                                return;
                              }
                              await FirebaseAuth.instance
                                  .sendPasswordResetEmail(
                                email: emailController.text,
                              );
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text("Password reset email sent!"),
                                ),
                              );
                            },
                            child: const Text(
                              "Forgot Password?",
                              style: TextStyle(color: Colors.white70),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInput(
    String label, {
    bool isPassword = false,
    required Function(String) onChanged,
  }) {
    return TextFormField(
      obscureText: isPassword ? obscure : false,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white),
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(
                  obscure ? Icons.visibility : Icons.visibility_off,
                  color: Colors.white70,
                ),
                onPressed: () => setState(() => obscure = !obscure),
              )
            : null,
        enabledBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.white60),
        ),
        focusedBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.amber),
        ),
      ),
      validator: (val) {
        if (val == null || val.isEmpty) return 'Enter $label';
        if (label == "Password" && val.length < 6) {
          return 'Password must be at least 6 characters';
        }
        if (label == "Email" && !val.contains('@')) {
          return 'Enter a valid email';
        }
        return null;
      },
      onChanged: onChanged,
    );
  }
}
