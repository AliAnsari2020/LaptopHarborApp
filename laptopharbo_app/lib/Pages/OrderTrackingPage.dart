import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class OrderTrackingPage extends StatelessWidget {
  final String orderId;

  const OrderTrackingPage({super.key, required this.orderId});

  final Map<String, int> statusSteps = const {
    'processing': 0,
    'dispatched': 1,
    'shipped': 2,
    'delivered': 3,
    'cancelled': -1,
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Order Tracking"),
        backgroundColor: Colors.deepPurple,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('orders')
            .doc(orderId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text("Order not found."));
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;
          final orderStatus = data['status'] ?? 'Pending';
          final trackingStatus = data['trackingStatus'] ?? 'Processing';

          final trackingStep =
              statusSteps[trackingStatus.toString().toLowerCase()] ?? 0;

          return Padding(
            padding: const EdgeInsets.all(16),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _infoTile("Order ID", data['orderId'] ?? orderId),
                  _infoTile("Order Status", orderStatus.toUpperCase(),
                      color: _getApprovalStatusColor(orderStatus)),
                  _infoTile("Tracking Status", trackingStatus.toUpperCase(),
                      color: _getTrackingColor(trackingStatus)),
                  _infoTile("Courier", data['courierService'] ?? 'N/A'),
                  _infoTile("Delivery Days",
                      "${data['deliveryDays'] ?? 'Unknown'} Days"),
                  const SizedBox(height: 16),
                  _infoTile("Customer Name", data['name'] ?? 'N/A'),
                  _infoTile("Delivery Address", data['address'] ?? 'N/A'),
                  const SizedBox(height: 20),
                  const Text("Products Ordered:",
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 8),
                  ..._buildProductList(data['items'] ?? []),
                  const SizedBox(height: 24),
                  const Text("Tracking Progress",
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 12),
                  _buildProgressTracker(trackingStep),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  /// Info Tile Widget
  Widget _infoTile(String title, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("$title: ", style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: color ?? Colors.grey.shade200,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                value,
                style: TextStyle(
                  color: color != null ? Colors.white : Colors.black,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Product List
  List<Widget> _buildProductList(List items) {
    return items.map((item) {
      final name = item['name'] ?? 'Unknown';
      final qty = item['quantity'] ?? 1;
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            const Icon(Icons.shopping_bag, color: Colors.deepPurple),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                "$name (Qty: $qty)",
                style: const TextStyle(fontSize: 14),
              ),
            ),
          ],
        ),
      );
    }).toList();
  }

  /// Progress Tracker
  Widget _buildProgressTracker(int currentStep) {
    final steps = ['Processing', 'Dispatched', 'Shipped', 'Delivered'];

    return Column(
      children: steps.asMap().entries.map((entry) {
        int index = entry.key;
        String label = entry.value;
        bool isActive = index <= currentStep;

        return Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 400),
              width: 24,
              height: 24,
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: isActive ? Colors.deepPurple : Colors.grey.shade300,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Icon(Icons.check,
                    size: 16,
                    color: isActive ? Colors.white : Colors.grey.shade600),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                color: isActive ? Colors.black87 : Colors.grey,
              ),
            ),
          ],
        );
      }).toList(),
    );
  }

  /// Color logic for order approval
  Color _getApprovalStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  /// Color logic for tracking status
  Color _getTrackingColor(String status) {
    switch (status.toLowerCase()) {
      case 'processing':
        return Colors.orange;
      case 'dispatched':
        return Colors.blue;
      case 'shipped':
        return Colors.indigo;
      case 'delivered':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
