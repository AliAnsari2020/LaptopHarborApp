import 'package:flutter/material.dart';

class FAQScreen extends StatelessWidget {
  const FAQScreen({super.key});

  final List<Map<String, String>> faqs = const [
    {
      'question': '1. What is the warranty period for laptops?',
      'answer':
          'All laptops come with a minimum 1-year brand warranty. Some models offer up to 2 years of extended warranty.'
    },
    {
      'question': '2. Do you sell used or refurbished laptops?',
      'answer':
          'No, we only sell 100% brand-new and sealed laptops with complete documentation.'
    },
    {
      'question': '3. How many days does delivery take after ordering?',
      'answer':
          'Delivery usually takes 2–5 business days, depending on your location and courier service.'
    },
    {
      'question': '4. What payment methods are available?',
      'answer':
          'We accept Cash on Delivery (COD), Bank Transfer, and EasyPaisa/JazzCash.'
    },
    {
      'question': '5. Do you offer laptops on installment?',
      'answer':
          'Yes, monthly installment options are available on selected products. Please contact support for more information.'
    },
    {
      'question':
          '6. What is the difference between gaming and business laptops?',
      'answer':
          'Gaming laptops have powerful GPUs, advanced cooling systems, and high-refresh-rate displays. Business laptops are lightweight, offer long battery life, and focus on security features.'
    },
    {
      'question': '7. How can I cancel my order?',
      'answer':
          'If the order hasn’t been dispatched, you can cancel it by messaging our support team through the support section.'
    },
    {
      'question': '8. Can I check the laptop at the time of delivery?',
      'answer':
          'Yes, you can open the box to verify the product during delivery. Our team also records proof of delivery.'
    },
    {
      'question': '9. Can I track my order in the app?',
      'answer':
          'Yes, once you place the order, you will receive a tracking ID which you can use to check the delivery status inside the app.'
    },
    {
      'question': '10. How can I contact the support team?',
      'answer':
          'You can contact us by filling out the feedback form in the Support section or email us at support@laptopharbor.com'
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Frequently Asked Questions'),
        backgroundColor: const Color(0xFF0D47A1),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: faqs.length,
        itemBuilder: (context, index) {
          final item = faqs[index];
          return Card(
            margin: const EdgeInsets.symmetric(vertical: 8),
            elevation: 3,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Theme(
              data:
                  Theme.of(context).copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                leading:
                    const Icon(Icons.help_outline, color: Colors.blueAccent),
                title: Text(
                  item['question']!,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                children: [
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Text(
                      item['answer']!,
                      style:
                          const TextStyle(fontSize: 15, color: Colors.black87),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
