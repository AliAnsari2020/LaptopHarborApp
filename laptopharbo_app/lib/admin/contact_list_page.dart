import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ContactListPage extends StatelessWidget {
  const ContactListPage({super.key});

  Future<void> _deleteContact(String docId, BuildContext context) async {
    await FirebaseFirestore.instance
        .collection('user_contact_queries')
        .doc(docId)
        .delete();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Query deleted")),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("User Contact Queries"),
        backgroundColor: Colors.blue.shade700,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('user_contact_queries')
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No queries submitted yet."));
          }

          final queries = snapshot.data!.docs;

          return ListView.builder(
            itemCount: queries.length,
            padding: const EdgeInsets.all(16),
            itemBuilder: (context, index) {
              final data = queries[index].data() as Map<String, dynamic>;
              final docId = queries[index].id;

              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 4,
                child: ListTile(
                  title: Text(data['subject'] ?? 'No Subject',
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text("📧 ${data['email'] ?? ''}"),
                      Text("👤 ${data['name'] ?? 'Anonymous'}"),
                      const SizedBox(height: 8),
                      Text("💬 ${data['message'] ?? ''}"),
                      const SizedBox(height: 8),
                      Row(
                        children: List.generate(
                          5,
                          (i) => Icon(
                            i < (data['rating'] ?? 0)
                                ? Icons.star
                                : Icons.star_border,
                            size: 18,
                            color: Colors.orangeAccent,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        data['timestamp'] != null
                            ? _formatDateTime(
                                (data['timestamp'] as Timestamp).toDate())
                            : '',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                  isThreeLine: true,
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _deleteContact(docId, context),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return "${dateTime.day}/${dateTime.month}/${dateTime.year} at ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}";
  }
}
