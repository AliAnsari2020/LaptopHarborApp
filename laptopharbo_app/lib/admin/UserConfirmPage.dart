import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class UserConfirmPage extends StatefulWidget {
  final String name;
  final String email;
  final Map<String, dynamic> orderData;

  const UserConfirmPage({
    super.key,
    required this.name,
    required this.email,
    required this.orderData,
  });

  @override
  State<UserConfirmPage> createState() => _UserConfirmPageState();
}

class _UserConfirmPageState extends State<UserConfirmPage> {
  bool _isSending = false;
  bool _isSent = false;

  Future<void> sendEmail() async {
    setState(() {
      _isSending = true;
    });

    const serviceId = 'service_h3m89sr';
    const templateId = 'template_cmsglv6';
    const userId = 'uFu303LB5BRL24g8m';

    final url = Uri.parse('https://api.emailjs.com/api/v1.0/email/send');

    try {
      final response = await http.post(
        url,
        headers: {
          'origin': 'http://localhost',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'service_id': serviceId,
          'template_id': templateId,
          'user_id': userId,
          'template_params': {
            'name': widget.name,
            'email': widget.email,
            'orderId': widget.orderData['orderId'].toString(),
            'status': widget.orderData['status'].toString(),
            'trackingStatus': widget.orderData['trackingStatus'].toString(),
            'courierService': widget.orderData['courierService'].toString(),
            'deliveryDays': widget.orderData['deliveryDays'].toString(),
            'subject':
                'Order Confirmation & Shipping Details - #${widget.orderData['orderId']}',
          },
        }),
      );

      if (response.statusCode == 200) {
        setState(() {
          _isSent = true;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("✅ Email sent successfully")),
        );
      } else {
        debugPrint("❌ Email failed: ${response.body}");
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("❌ Failed to send email")),
        );
      }
    } catch (e) {
      debugPrint("❌ Exception occurred: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("⚠️ Error occurred while sending email")),
      );
    } finally {
      setState(() {
        _isSending = false;
      });
    }
  }

  Widget _buildInfoTile(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Text(
        "$label: $value",
        style: const TextStyle(fontSize: 16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("📨 Confirm & Send Email"),
        backgroundColor: Colors.teal,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Card(
          elevation: 6,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: ListView(
              children: [
                const Text(
                  "📦 Order Confirmation Details",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.teal,
                  ),
                ),
                const SizedBox(height: 12),
                _buildInfoTile("👤 Name", widget.name),
                _buildInfoTile("📧 Email", widget.email),
                const Divider(),
                _buildInfoTile(
                    "🆔 Order ID", widget.orderData['orderId'].toString()),
                _buildInfoTile(
                    "📦 Status", widget.orderData['status'].toString()),
                _buildInfoTile("🚚 Tracking",
                    widget.orderData['trackingStatus'].toString()),
                _buildInfoTile("📦 Courier",
                    widget.orderData['courierService'].toString()),
                _buildInfoTile("⏰ Delivery Days",
                    widget.orderData['deliveryDays'].toString()),
                const SizedBox(height: 20),
                Center(
                  child: ElevatedButton.icon(
                    onPressed: _isSent || _isSending ? null : sendEmail,
                    icon: const Icon(Icons.send),
                    label: Text(_isSent ? "Email Sent" : "Send Email to User"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
