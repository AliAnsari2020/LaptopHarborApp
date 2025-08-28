import 'dart:convert';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;

class ProfileUpdatePage extends StatefulWidget {
  const ProfileUpdatePage({super.key});

  @override
  State<ProfileUpdatePage> createState() => _ProfileUpdatePageState();
}

class _ProfileUpdatePageState extends State<ProfileUpdatePage> {
  final user = FirebaseAuth.instance.currentUser;
  String? imageUrl;
  String? publicId;
  XFile? newImage;
  bool loading = false;

  @override
  void initState() {
    super.initState();
    loadUserProfile();
  }

  Future<void> loadUserProfile() async {
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user!.uid)
        .get();
    final data = doc.data();
    if (data != null) {
      setState(() {
        imageUrl = data['imageurl'];
        publicId = data['public_id'];
      });
    }
  }

  Future<void> pickNewImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() => newImage = picked);
    }
  }

  Future<void> updateProfileImage() async {
    if (newImage == null) return;
    setState(() => loading = true);

    try {
      // ❌ Delete old image from Cloudinary
      final deleteUrl = Uri.parse(
          'https://api.cloudinary.com/v1_1/djf0nppav/delete_by_token');
      final resDelete = await http.post(
        Uri.parse('https://api.cloudinary.com/v1_1/djf0nppav/image/destroy'),
        body: {
          'public_id': publicId,
          'api_key': '476518629499378',
          'timestamp': '${DateTime.now().millisecondsSinceEpoch}',
          'signature': 'SIGNATURE_GENERATED', // optional if unsigned
        },
      );

      // ✅ Upload new image
      final bytes = await newImage!.readAsBytes();
      final uploadReq = http.MultipartRequest(
        'POST',
        Uri.parse("https://api.cloudinary.com/v1_1/djf0nppav/upload"),
      )
        ..fields['upload_preset'] = 'ECOMApp'
        ..files.add(http.MultipartFile.fromBytes(
          'file',
          bytes,
          filename: path.basename(newImage!.path),
        ));

      final uploadRes = await uploadReq.send();
      final body = await uploadRes.stream.bytesToString();
      final result = jsonDecode(body);

      if (uploadRes.statusCode != 200) {
        throw 'Upload failed: ${result['error']['message']}';
      }

      final newImageUrl = result['secure_url'];
      final newPublicId = result['public_id'];

      // 🔁 Update Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .update({
        'imageurl': newImageUrl,
        'public_id': newPublicId,
      });

      setState(() {
        imageUrl = newImageUrl;
        publicId = newPublicId;
        newImage = null;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile image updated successfully')),
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
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Update Profile Picture"),
        backgroundColor: Colors.deepPurple,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Current Image Avatar
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.shade400,
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: CircleAvatar(
                  backgroundImage:
                      imageUrl != null ? NetworkImage(imageUrl!) : null,
                  radius: 60,
                  backgroundColor: Colors.grey[300],
                  child: imageUrl == null
                      ? const Icon(Icons.person, size: 60, color: Colors.grey)
                      : null,
                ),
              ),

              const SizedBox(height: 20),

              // Choose New Image Button
              ElevatedButton.icon(
                onPressed: pickNewImage,
                icon: const Icon(Icons.image),
                label: const Text("Choose New Image"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // New Image Preview
              if (newImage != null)
                FutureBuilder<Uint8List>(
                  future: newImage!.readAsBytes(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.done &&
                        snapshot.hasData) {
                      return Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(100),
                        ),
                        child: ClipOval(
                          child: Image.memory(
                            snapshot.data!,
                            width: 120,
                            height: 120,
                            fit: BoxFit.cover,
                          ),
                        ),
                      );
                    }
                    return const CircularProgressIndicator();
                  },
                ),

              const SizedBox(height: 30),

              // Update Button
              loading
                  ? const CircularProgressIndicator()
                  : SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: updateProfileImage,
                        icon: const Icon(Icons.save),
                        label: const Text("Update Profile"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepPurple,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 14),
                          textStyle: const TextStyle(fontSize: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
