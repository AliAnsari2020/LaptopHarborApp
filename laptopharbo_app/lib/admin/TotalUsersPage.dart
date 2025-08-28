import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;

class TotalUsersPage extends StatefulWidget {
  const TotalUsersPage({super.key});

  @override
  State<TotalUsersPage> createState() => _TotalUsersPageState();
}

void _updateUserRole(
    BuildContext context, String userId, String newRole) async {
  await FirebaseFirestore.instance.collection('users').doc(userId).update({
    'role': newRole,
  });

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text("User role updated to $newRole")),
  );
}

class _TotalUsersPageState extends State<TotalUsersPage> {
  String? currentUserRole;

  @override
  void initState() {
    super.initState();
    _getCurrentUserRole();
  }

  Future<void> _getCurrentUserRole() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      setState(() {
        currentUserRole = doc['role'];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("All Registered Users"),
        backgroundColor: Colors.blue.shade700,
      ),
      body: currentUserRole == null
          ? const Center(child: CircularProgressIndicator())
          : StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text("No users found."));
                }

                final users = snapshot.data!.docs;

                return ListView.builder(
                  itemCount: users.length,
                  padding: const EdgeInsets.all(16),
                  itemBuilder: (context, index) {
                    final userDoc = users[index];
                    final user = userDoc.data() as Map<String, dynamic>;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 4,
                      child: ListTile(
                        leading: user['imageurl'] != null
                            ? CircleAvatar(
                                backgroundImage: NetworkImage(user['imageurl']),
                                radius: 25,
                              )
                            : const CircleAvatar(
                                child: Icon(Icons.person),
                              ),
                        title: Text(
                          user['username'] ?? 'No Name',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("📧 ${user['email'] ?? 'N/A'}"),
                            Text("🛡️ Role: ${user['role'] ?? 'user'}"),
                          ],
                        ),
                        trailing: currentUserRole == 'admin'
                            ? DropdownButton<String>(
                                value: user['role'],
                                underline: Container(),
                                items: ['user', 'admin'].map((role) {
                                  return DropdownMenuItem(
                                    value: role,
                                    child: Text(role),
                                  );
                                }).toList(),
                                onChanged: (newRole) {
                                  if (newRole != null) {
                                    _updateUserRole(
                                        context, userDoc.id, newRole);
                                  }
                                },
                              )
                            : null,
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}
