// ignore_for_file: use_build_context_synchronously

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart'; // For kIsWeb
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;

import 'product_list_page.dart';

class AddProductPage extends StatefulWidget {
  const AddProductPage({super.key});

  @override
  State<AddProductPage> createState() => _AddProductPageState();
}

class _AddProductPageState extends State<AddProductPage> {
  final _formKey = GlobalKey<FormState>();

  final brandController = TextEditingController();
  final nameController = TextEditingController();
  final priceController = TextEditingController();
  final descController = TextEditingController();
  final specController = TextEditingController();
  final ratingController = TextEditingController();

  final List<XFile> pickedImages = [];
  bool isUploading = false;

  final List<String> categories = [
    'Gaming',
    'Business',
    'Student',
    'MacBook',
    '2-in-1',
    'Budget',
  ];
  String? selectedCategory;

  Future<void> pickImages() async {
    final ImagePicker picker = ImagePicker();
    final List<XFile> images = await picker.pickMultiImage();

    if (images.length > 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Only 4 images allowed")),
      );
    } else {
      setState(() {
        pickedImages.clear();
        pickedImages.addAll(images.take(4));
      });
    }
  }

  Future<List<String>> uploadImagesToCloudinary() async {
    List<String> imageUrls = [];

    for (XFile image in pickedImages) {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('https://api.cloudinary.com/v1_1/djf0nppav/upload'),
      );

      request.fields['upload_preset'] = 'ECOMApp';

      if (kIsWeb) {
        Uint8List imageBytes = await image.readAsBytes();
        request.files.add(http.MultipartFile.fromBytes(
          'file',
          imageBytes,
          filename: image.name,
        ));
      } else {
        request.files.add(await http.MultipartFile.fromPath(
          'file',
          image.path,
        ));
      }

      final response = await request.send();
      final result = await response.stream.bytesToString();
      final data = jsonDecode(result);

      if (response.statusCode == 200) {
        imageUrls.add(data['secure_url']);
      } else {
        throw Exception('Image upload failed: ${data['error']['message']}');
      }
    }

    return imageUrls;
  }

  Future<void> submitProduct() async {
    if (_formKey.currentState!.validate()) {
      if (pickedImages.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please select product images")),
        );
        return;
      }

      setState(() => isUploading = true);

      try {
        final uploadedImageUrls = await uploadImagesToCloudinary();

        final docRef = FirebaseFirestore.instance.collection('products').doc();

        await docRef.set({
          'id': docRef.id,
          'brand': brandController.text.trim(),
          'name': nameController.text.trim(),
          'category': selectedCategory,
          'price': 'PKR ${priceController.text.trim()}',
          'description': descController.text.trim(),
          'spec': specController.text.trim(),
          'rating': double.tryParse(ratingController.text) ?? 0.0,
          'images': uploadedImageUrls,
          'createdAt': Timestamp.now(),
          'search_keywords': generateSearchKeywords(
            nameController.text.trim(),
            brandController.text.trim(),
            priceController.text.trim(),
          ),
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Product added successfully!")),
        );

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const ProductListPage()),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e")),
        );
      } finally {
        setState(() => isUploading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Add Product")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: brandController,
                decoration: const InputDecoration(labelText: 'Brand'),
                validator: (val) =>
                    val!.isEmpty ? 'Please enter brand name' : null,
              ),
              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Product Name'),
                validator: (val) =>
                    val!.isEmpty ? 'Please enter product name' : null,
              ),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: 'Laptop Category'),
                value: selectedCategory,
                items: categories
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (val) => setState(() => selectedCategory = val),
                validator: (val) =>
                    val == null ? 'Please select a category' : null,
              ),
              TextFormField(
                controller: priceController,
                decoration: const InputDecoration(labelText: 'Price (PKR)'),
                keyboardType: TextInputType.number,
                validator: (val) =>
                    val!.isEmpty ? 'Please enter product price' : null,
              ),
              TextFormField(
                controller: descController,
                decoration: const InputDecoration(labelText: 'Description'),
                maxLines: 2,
                validator: (val) =>
                    val!.isEmpty ? 'Please enter description' : null,
              ),
              TextFormField(
                controller: specController,
                decoration: const InputDecoration(labelText: 'Specifications'),
                maxLines: 3,
                validator: (val) =>
                    val!.isEmpty ? 'Please enter specifications' : null,
              ),
              TextFormField(
                controller: ratingController,
                decoration: const InputDecoration(labelText: 'Rating (1-5)'),
                keyboardType: TextInputType.number,
                validator: (val) {
                  final rating = double.tryParse(val ?? '');
                  if (rating == null || rating < 1 || rating > 5) {
                    return 'Enter a valid rating between 1 and 5';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  ElevatedButton.icon(
                    onPressed: pickImages,
                    icon: const Icon(Icons.photo),
                    label: const Text("Select Images"),
                  ),
                  const SizedBox(width: 12),
                  Text("${pickedImages.length}/4 selected"),
                ],
              ),
              const SizedBox(height: 12),
              if (pickedImages.isNotEmpty)
                Wrap(
                  spacing: 8,
                  children: pickedImages.map((img) {
                    return kIsWeb
                        ? Image.network(
                            img.path,
                            width: 80,
                            height: 80,
                            fit: BoxFit.cover,
                          )
                        : Image.file(
                            File(img.path),
                            width: 80,
                            height: 80,
                            fit: BoxFit.cover,
                          );
                  }).toList(),
                ),
              const SizedBox(height: 20),
              isUploading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                      onPressed: submitProduct,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurple,
                        minimumSize: const Size.fromHeight(50),
                      ),
                      child: const Text("Submit Product"),
                    ),
            ],
          ),
        ),
      ),
    );
  }

  List<String> generateSearchKeywords(String name, String brand, String price) {
    final keywords = <String>{
      ...name.toLowerCase().split(' '),
      ...brand.toLowerCase().split(' '),
      price.toLowerCase(),
      '${brand.toLowerCase()} $name'.toLowerCase(),
      '${name.toLowerCase()} $brand'.toLowerCase(),
    };
    return keywords.toList();
  }
}
