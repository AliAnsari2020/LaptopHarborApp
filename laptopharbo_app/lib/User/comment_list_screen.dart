import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class CommentListScreen extends StatelessWidget {
  const CommentListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(title: const Text('My Comments')),
      body: user == null
          ? const Center(child: Text('Please log in to view your comments'))
          : StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('comments')
                  .where('uid', isEqualTo: user.uid)
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('No comments found'));
                }

                final comments = snapshot.data!.docs;

                return ListView.builder(
                  itemCount: comments.length,
                  itemBuilder: (context, index) {
                    final commentData =
                        comments[index].data() as Map<String, dynamic>;

                    return Card(
                      margin: const EdgeInsets.all(10),
                      child: ListTile(
                        leading: commentData['productImage'] != null
                            ? Image.network(commentData['productImage'],
                                width: 50)
                            : const Icon(Icons.comment),
                        title: Text(commentData['productTitle'] ?? 'Product'),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (commentData['rating'] != null)
                              Row(
                                children: List.generate(5, (i) {
                                  return Icon(
                                    i < commentData['rating']
                                        ? Icons.star
                                        : Icons.star_border,
                                    color: Colors.amber,
                                    size: 16,
                                  );
                                }),
                              ),
                            const SizedBox(height: 5),
                            Text(commentData['comment'] ?? 'No comment'),
                            if (commentData['timestamp'] != null)
                              Text(
                                'Posted on: ${DateFormat('dd MMM yyyy – hh:mm a').format(commentData['timestamp'].toDate())}',
                                style: const TextStyle(
                                    fontSize: 12, color: Colors.grey),
                              ),
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
