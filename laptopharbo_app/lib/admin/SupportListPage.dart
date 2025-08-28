import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class SupportListPage extends StatelessWidget {
  const SupportListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Support Messages'),
        backgroundColor: Colors.blue.shade700,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('support_feedback')
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No support messages found.'));
          }

          final messages = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: messages.length,
            itemBuilder: (context, index) {
              final doc = messages[index];
              final data = doc.data() as Map<String, dynamic>;

              return Card(
                elevation: 3,
                margin: const EdgeInsets.only(bottom: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (data['email'] != null)
                        Text("📧 Email: ${data['email']}",
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold)),
                      if (data['phone'] != null)
                        Text("📞 Phone: ${data['phone']}"),
                      if (data['subject'] != null)
                        Text("📌 Subject: ${data['subject']}"),
                      const SizedBox(height: 8),
                      if (data['message'] != null)
                        Text("📝 Message:\n${data['message']}"),
                      const SizedBox(height: 10),
                      if (data['timestamp'] != null)
                        Text(
                          "🕒 ${DateTime.fromMillisecondsSinceEpoch(data['timestamp'].millisecondsSinceEpoch)}",
                          style:
                              const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      const SizedBox(height: 12),
                      Align(
                        alignment: Alignment.centerRight,
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.delete, size: 18),
                          label: const Text('Delete'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                          ),
                          onPressed: () async {
                            bool confirm = await showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text("Delete Message"),
                                content: const Text(
                                    "Are you sure you want to delete this support message?"),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(context, false),
                                    child: const Text("Cancel"),
                                  ),
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(context, true),
                                    child: const Text("Delete",
                                        style: TextStyle(color: Colors.red)),
                                  ),
                                ],
                              ),
                            );

                            if (confirm) {
                              await FirebaseFirestore.instance
                                  .collection('support_feedback')
                                  .doc(doc.id)
                                  .delete();
                            }
                          },
                        ),
                      )
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
