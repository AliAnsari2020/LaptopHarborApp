import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AdminListPage extends StatefulWidget {
  const AdminListPage({super.key});

  @override
  State<AdminListPage> createState() => _AdminListPageState();
}

class _AdminListPageState extends State<AdminListPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Admin List")),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .where('role', isEqualTo: 'admin')
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData)
            return const Center(child: CircularProgressIndicator());
          final admins = snapshot.data!.docs;

          if (admins.isEmpty) {
            return const Center(child: Text("No admins found"));
          }

          return ListView.builder(
            itemCount: admins.length,
            itemBuilder: (context, index) {
              final doc = admins[index];
              return ListTile(
                leading: const Icon(Icons.admin_panel_settings),
                title: Text(doc['email'] ?? "No Email"),
                subtitle: Text("UID: ${doc.id}"),
                trailing: IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text("Delete Admin"),
                        content: const Text(
                            "Are you sure you want to delete this admin?"),
                        actions: [
                          TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text("Cancel")),
                          ElevatedButton(
                              onPressed: () => Navigator.pop(context, true),
                              child: const Text("Delete")),
                        ],
                      ),
                    );

                    if (confirm == true) {
                      await FirebaseFirestore.instance
                          .collection('users')
                          .doc(doc.id)
                          .delete();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Admin deleted")),
                      );
                    }
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
