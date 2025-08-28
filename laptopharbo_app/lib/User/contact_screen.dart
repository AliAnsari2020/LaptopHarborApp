import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ContactScreen extends StatefulWidget {
  const ContactScreen({super.key});

  @override
  State<ContactScreen> createState() => _ContactScreenState();
}

class _ContactScreenState extends State<ContactScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController messageController = TextEditingController();
  int _selectedRating = 0;
  String? _selectedSubject;

  @override
  void initState() {
    super.initState();
    // 🔁 Reload to get updated displayName
    FirebaseAuth.instance.currentUser?.reload();
  }

  Future<void> _submitForm() async {
    final user = FirebaseAuth.instance.currentUser;

    if (!_formKey.currentState!.validate()) return;

    if (_selectedSubject == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a subject')),
      );
      return;
    }

    await FirebaseFirestore.instance.collection('user_contact_queries').add({
      'uid': user?.uid,
      'name': user?.displayName ?? 'Anonymous',
      'email': user?.email ?? 'No Email',
      'subject': _selectedSubject,
      'message': messageController.text.trim(),
      'rating': _selectedRating,
      'timestamp': FieldValue.serverTimestamp(),
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Your message has been sent!')),
    );

    messageController.clear();
    setState(() {
      _selectedRating = 0;
      _selectedSubject = null;
    });
  }

  Widget _buildRatingStars() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Rate Your Experience',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(5, (index) {
            return IconButton(
              icon: Icon(
                index < _selectedRating ? Icons.star : Icons.star_border,
                size: 30,
                color: Colors.orangeAccent,
              ),
              onPressed: () {
                setState(() {
                  _selectedRating = index + 1;
                });
              },
            );
          }),
        ),
      ],
    );
  }

  Widget _buildSubjectDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedSubject,
      decoration: const InputDecoration(
        labelText: 'Subject',
        border: OutlineInputBorder(),
      ),
      items: const [
        DropdownMenuItem(value: 'Feedback', child: Text('Feedback')),
        DropdownMenuItem(value: 'Suggestion', child: Text('Suggestion')),
        DropdownMenuItem(value: 'Bug Report', child: Text('Bug Report')),
      ],
      onChanged: (value) {
        setState(() => _selectedSubject = value);
      },
      validator: (value) => value == null ? 'Please select a subject' : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final name = user?.displayName ?? 'Your Name';
    final email = user?.email ?? 'your@email.com';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Contact Us'),
        backgroundColor: const Color(0xFF0D47A1),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              const Text(
                'Get in touch with us!',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              TextFormField(
                initialValue: name,
                enabled: false,
                decoration: const InputDecoration(
                  labelText: 'Name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              TextFormField(
                initialValue: email,
                enabled: false,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              _buildSubjectDropdown(),
              const SizedBox(height: 10),
              TextFormField(
                controller: messageController,
                maxLines: 5,
                decoration: const InputDecoration(
                  labelText: 'Your Message',
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                    value!.isEmpty ? 'Please enter your message' : null,
              ),
              const SizedBox(height: 20),
              _buildRatingStars(),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                icon: const Icon(Icons.send),
                label: const Text("Submit"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00C853),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                onPressed: _submitForm,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
