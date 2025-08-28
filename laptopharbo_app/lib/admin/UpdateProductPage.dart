import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;

class UpdateProductPage extends StatefulWidget {
  final DocumentSnapshot productDoc;

  const UpdateProductPage({super.key, required this.productDoc});

  @override
  State<UpdateProductPage> createState() => _UpdateProductPageState();
}

class _UpdateProductPageState extends State<UpdateProductPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController brandController;
  late TextEditingController nameController;
  late TextEditingController priceController;
  late TextEditingController descController;
  late TextEditingController specController;
  late TextEditingController ratingController;
  late String selectedCategory;

  List<XFile> newImages = [];
  bool isUploading = false;

  @override
  void initState() {
    super.initState();
    final data = widget.productDoc.data() as Map<String, dynamic>;

    brandController = TextEditingController(text: data['brand']);
    nameController = TextEditingController(text: data['name']);
    priceController = TextEditingController(
        text: data['price'].toString().replaceAll('PKR ', ''));
    descController = TextEditingController(text: data['description']);
    specController = TextEditingController(text: data['spec']);
    ratingController = TextEditingController(text: data['rating'].toString());
    selectedCategory = data['category'] ?? 'Student';
  }

  @override
  void dispose() {
    brandController.dispose();
    nameController.dispose();
    priceController.dispose();
    descController.dispose();
    specController.dispose();
    ratingController.dispose();
    super.dispose();
  }

  Future<void> pickImages() async {
    final picker = ImagePicker();
    final picked = await picker.pickMultiImage();

    if (picked.length > 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Only 4 images allowed")),
      );
    } else {
      setState(() {
        newImages = picked.take(4).toList();
      });
    }
  }

  Future<List<String>> uploadNewImages() async {
    const cloudName = 'djf0nppav';
    const uploadPreset = 'ECOMApp';

    List<String> urls = [];

    for (XFile image in newImages) {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('https://api.cloudinary.com/v1_1/$cloudName/image/upload'),
      )..fields['upload_preset'] = uploadPreset;

      if (kIsWeb) {
        Uint8List imageBytes = await image.readAsBytes();
        request.files.add(http.MultipartFile.fromBytes(
          'file',
          imageBytes,
          filename: image.name,
        ));
      } else {
        request.files
            .add(await http.MultipartFile.fromPath('file', image.path));
      }

      final res = await request.send();
      final result = await res.stream.bytesToString();
      final data = jsonDecode(result);

      if (res.statusCode == 200) {
        urls.add(data['secure_url']);
      } else {
        throw Exception('Upload failed: ${data['error']['message']}');
      }
    }

    return urls;
  }

  String extractPublicId(String imageUrl) {
    final uri = Uri.parse(imageUrl);
    final segments = uri.pathSegments;
    final filename = segments.last;
    return filename.split('.').first;
  }

  Future<void> deleteCloudinaryImage(String publicId) async {
    // ⚠️ Needs a secure backend function — skipping actual implementation
    debugPrint("Request to delete Cloudinary image with public ID: $publicId");
  }

  Future<void> updateProduct() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isUploading = true);
    try {
      final oldImages = List<String>.from(widget.productDoc['images']);

      List<String> imageUrls = oldImages;

      if (newImages.isNotEmpty) {
        for (final url in oldImages) {
          await deleteCloudinaryImage(extractPublicId(url));
        }

        imageUrls = await uploadNewImages();
      }

      final data = {
        'brand': brandController.text.trim(),
        'name': nameController.text.trim(),
        'category': selectedCategory,
        'price': 'PKR ${priceController.text.trim()}',
        'description': descController.text.trim(),
        'spec': specController.text.trim(),
        'rating': double.tryParse(ratingController.text.trim()) ?? 0,
        'images': imageUrls,
        'updatedAt': Timestamp.now(),
        'search_keywords': generateSearchKeywords(
          nameController.text.trim(),
          brandController.text.trim(),
          priceController.text.trim(),
        ),
      };

      await widget.productDoc.reference.update(data);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Product updated successfully')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    } finally {
      setState(() => isUploading = false);
    }
  }

  List<String> generateSearchKeywords(String name, String brand, String price) {
    final allWords = <String>{
      ...name.toLowerCase().split(' '),
      ...brand.toLowerCase().split(' '),
      price,
      '${brand.toLowerCase()} $name'.toLowerCase(),
    };
    return allWords.toList();
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.productDoc.data() as Map<String, dynamic>;

    return Scaffold(
      appBar: AppBar(title: const Text("Update Product")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                  controller: brandController,
                  decoration: const InputDecoration(labelText: 'Brand'),
                  validator: (v) => v!.isEmpty ? "Enter brand" : null),
              TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Name'),
                  validator: (v) => v!.isEmpty ? "Enter name" : null),
              TextFormField(
                  controller: priceController,
                  decoration: const InputDecoration(labelText: 'Price'),
                  keyboardType: TextInputType.number,
                  validator: (v) => v!.isEmpty ? "Enter price" : null),
              DropdownButtonFormField(
                value: selectedCategory,
                items: [
                  'Gaming',
                  'Business',
                  'Student',
                  'MacBook',
                  '2-in-1',
                  'Budget'
                ]
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (val) => setState(() => selectedCategory = val!),
              ),
              TextFormField(
                  controller: descController,
                  decoration: const InputDecoration(labelText: 'Description')),
              TextFormField(
                  controller: specController,
                  decoration:
                      const InputDecoration(labelText: 'Specifications')),
              TextFormField(
                  controller: ratingController,
                  decoration: const InputDecoration(labelText: 'Rating'),
                  keyboardType: TextInputType.number),
              const SizedBox(height: 12),
              Row(
                children: [
                  ElevatedButton.icon(
                    onPressed: pickImages,
                    icon: const Icon(Icons.image),
                    label: const Text("Select Images"),
                  ),
                  const SizedBox(width: 10),
                  Text("${newImages.length}/4 selected"),
                ],
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                children: (newImages.isNotEmpty
                        ? newImages.map((img) => kIsWeb
                            ? Image.network(img.path, width: 80, height: 80)
                            : Image.file(File(img.path), width: 80, height: 80))
                        : (data['images'] as List<dynamic>).map(
                            (url) => Image.network(url, width: 80, height: 80)))
                    .toList()
                    .cast<Widget>(),
              ),
              const SizedBox(height: 20),
              isUploading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                      onPressed: updateProduct,
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size.fromHeight(50),
                        backgroundColor: Colors.deepPurple,
                      ),
                      child: const Text("Update Product"),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
