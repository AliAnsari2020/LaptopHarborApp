import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:laptopharbo_app/admin/UserConfirmPage.dart';

class AdminOrdersPage extends StatefulWidget {
  const AdminOrdersPage({super.key});

  @override
  State<AdminOrdersPage> createState() => _AdminOrdersPageState();
}

class _AdminOrdersPageState extends State<AdminOrdersPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final List<String> sortOptions = ['Latest First', 'Oldest First'];
  String selectedSortOrder = 'Latest First';

  final List<String> statusOptions = ['All', 'Pending', 'Approved', 'Rejected'];
  final List<String> trackingOptions = [
    'Processing',
    'Dispatched',
    'Shipped',
    'Delivered'
  ];
  final List<String> courierOptions = [
    'TCS',
    'Leopard',
    'Pakistan Post',
    'DHL'
  ];
  final List<String> deliveryDaysOptions = [
    '2 Days',
    '3 Days',
    '5 Days',
    '7 Days'
  ];

  String selectedStatusFilter = 'All';

  String toTitleCase(String input) {
    if (input.isEmpty) return input;
    return input[0].toUpperCase() + input.substring(1).toLowerCase();
  }

  void _deleteOrder(String orderId) async {
    try {
      await _firestore.collection('orders').doc(orderId).delete();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Order deleted successfully")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to delete order: $e")),
      );
    }
  }

  Future<void> _updateOrderStatus(
      String orderId, String newStatus, String oldStatus) async {
    try {
      await _firestore.collection('orders').doc(orderId).update({
        'status': newStatus,
        'updatedAt': FieldValue.serverTimestamp(),
        'previousStatus': oldStatus,
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('✅ Status updated to "$newStatus"')),
      );
    } catch (e) {
      print('❌ Error updating status: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('❌ Failed to update status')),
      );
    }
  }

  Future<void> _updateOrderField(
      String orderId, String field, String value) async {
    try {
      final docRef = _firestore.collection('orders').doc(orderId);
      final snapshot = await docRef.get();
      final data = snapshot.data() as Map<String, dynamic>;

      Map<String, dynamic> updateData = {
        field: value,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (field == 'trackingStatus') {
        updateData['previousTrackingStatus'] = data['trackingStatus'] ?? 'N/A';
      }

      await docRef.update(updateData);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("✅ $field updated to $value")),
      );
      setState(() {}); // Rebuild UI
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ Failed to update $field: $e")),
      );
    }
  }

  Widget _buildDropdownField({
    required String title,
    required String currentValue,
    required List<String> options,
    required ValueChanged<String?> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(flex: 3, child: Text(title)),
          const SizedBox(width: 8),
          Expanded(
            flex: 5,
            child: DropdownButtonFormField<String>(
              value: currentValue,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              items: options.map((option) {
                return DropdownMenuItem<String>(
                  value: option,
                  child: Text(option),
                );
              }).toList(),
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("🛒 Admin Orders")),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Icon(Icons.filter_list, color: Colors.black87),
                const SizedBox(width: 10),
                const Text(
                  'Status:',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: selectedStatusFilter,
                    decoration: InputDecoration(
                      labelText: 'Select Status',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 12),
                    ),
                    items: statusOptions.map((status) {
                      return DropdownMenuItem<String>(
                        value: status,
                        child: Text(
                          status,
                          style: const TextStyle(fontSize: 14),
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedStatusFilter = value!;
                      });
                    },
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('orders')
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Center(child: Text("❌ Error loading orders"));
                }
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final allOrders = snapshot.data!.docs;
                final filteredOrders = selectedStatusFilter == 'All'
                    ? allOrders
                    : allOrders.where((order) {
                        final data = order.data() as Map<String, dynamic>;
                        final status = toTitleCase(data['status'] ?? '');
                        return status == selectedStatusFilter;
                      }).toList();

                if (filteredOrders.isEmpty) {
                  return const Center(child: Text("📭 No orders found."));
                }

                return ListView.builder(
                  itemCount: filteredOrders.length,
                  itemBuilder: (context, index) {
                    final order = filteredOrders[index];
                    final data = order.data() as Map<String, dynamic>;

                    String currentStatus =
                        toTitleCase(data['status']?.toString() ?? 'Pending');
                    String previousStatus = toTitleCase(
                        data['previousStatus']?.toString() ?? 'N/A');

                    return Card(
                      elevation: 4,
                      margin: const EdgeInsets.all(10),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('👤 ${data['name']}',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 18)),
                            const SizedBox(height: 4),
                            Text('📧 ${data['email']}'),
                            Text('💰 Total: ${data['total']}'),
                            const SizedBox(height: 8),
                            Text('🆔 Order ID: ${order.id}'),
                            const Divider(height: 20),

                            Row(
                              children: [
                                const Icon(Icons.cancel, color: Colors.red),
                                const SizedBox(width: 4),
                                const Text('Old Status: ',
                                    style:
                                        TextStyle(fontWeight: FontWeight.w600)),
                                Text(previousStatus,
                                    style: const TextStyle(
                                        color: Colors.redAccent)),
                              ],
                            ),
                            const SizedBox(height: 6),

                            Row(
                              children: [
                                const Icon(Icons.check_circle,
                                    color: Colors.green),
                                const SizedBox(width: 4),
                                const Text('Current Status: ',
                                    style:
                                        TextStyle(fontWeight: FontWeight.w600)),
                                Text(currentStatus,
                                    style:
                                        const TextStyle(color: Colors.green)),
                              ],
                            ),
                            const SizedBox(height: 10),

                            // 🔄 Tracking Status Dropdown
                            _buildDropdownField(
                              title: '🚚 Tracking Status:',
                              currentValue: trackingOptions.contains(
                                      toTitleCase(data['trackingStatus'] ??
                                          'Processing'))
                                  ? toTitleCase(
                                      data['trackingStatus'] ?? 'Processing')
                                  : trackingOptions.first,
                              options: trackingOptions,
                              onChanged: (value) {
                                if (value != null) {
                                  _updateOrderField(
                                      order.id, 'trackingStatus', value);
                                }
                              },
                            ),

                            // 🚛 Courier Service Dropdown
                            _buildDropdownField(
                              title: '📦 Courier Service:',
                              currentValue: courierOptions.contains(toTitleCase(
                                      data['courierService'] ?? 'TCS'))
                                  ? toTitleCase(data['courierService'] ?? 'TCS')
                                  : courierOptions.first,
                              options: courierOptions,
                              onChanged: (value) {
                                if (value != null) {
                                  _updateOrderField(
                                      order.id, 'courierService', value);
                                }
                              },
                            ),

                            // ⏰ Delivery Days Dropdown
                            _buildDropdownField(
                              title: '⏰ Delivery Days:',
                              currentValue: deliveryDaysOptions.contains(
                                      toTitleCase(
                                          data['deliveryDays'] ?? '3 Days'))
                                  ? toTitleCase(
                                      data['deliveryDays'] ?? '3 Days')
                                  : deliveryDaysOptions.first,
                              options: deliveryDaysOptions,
                              onChanged: (value) {
                                if (value != null) {
                                  _updateOrderField(
                                      order.id, 'deliveryDays', value);
                                }
                              },
                            ),
                            const SizedBox(height: 10),

                            // Status Dropdown
                            Row(
                              children: [
                                const Text('📦 Update Status:',
                                    style:
                                        TextStyle(fontWeight: FontWeight.w600)),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: DropdownButtonFormField<String>(
                                    value: statusOptions.contains(currentStatus)
                                        ? currentStatus
                                        : 'Pending',
                                    decoration: const InputDecoration(
                                      border: OutlineInputBorder(),
                                      contentPadding: EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 6),
                                    ),
                                    items: statusOptions
                                        .where((s) => s != 'All')
                                        .map((status) {
                                      return DropdownMenuItem<String>(
                                        value: status,
                                        child: Text(status),
                                      );
                                    }).toList(),
                                    onChanged: (currentStatus == 'Approved' ||
                                            currentStatus == 'Rejected')
                                        ? null
                                        : (newStatus) {
                                            if (newStatus != null &&
                                                newStatus != currentStatus) {
                                              _updateOrderStatus(order.id,
                                                  newStatus, currentStatus);
                                            }
                                          },
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 12),

                            // Delete Button
                            Align(
                              alignment: Alignment.centerRight,
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => UserConfirmPage(
                                        name: data['name'] ?? '',
                                        email: data['email'] ?? '',
                                        orderData: {
                                          'orderId': order.id,
                                          'status': data['status'] ?? '',
                                          'trackingStatus':
                                              data['trackingStatus'] ?? '',
                                          'courierService':
                                              data['courierService'] ?? '',
                                          'deliveryDays':
                                              data['deliveryDays'] ?? '',
                                        },
                                      ),
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.mail_outline,
                                    color: Colors.white),
                                label: const Text("View & Send Email"),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blueGrey,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 10),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            ElevatedButton.icon(
                              onPressed: () async {
                                final confirm = await showDialog(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text("Confirm Delete"),
                                    content: const Text(
                                        "Are you sure you want to delete this order?"),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.of(context).pop(false),
                                        child: const Text("Cancel"),
                                      ),
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.of(context).pop(true),
                                        child: const Text("Delete",
                                            style:
                                                TextStyle(color: Colors.red)),
                                      ),
                                    ],
                                  ),
                                );
                                if (confirm == true) {
                                  _deleteOrder(order.id);
                                }
                              },
                              icon:
                                  const Icon(Icons.delete, color: Colors.white),
                              label: const Text('Delete Order'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 10),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
