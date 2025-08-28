import 'package:flutter/material.dart';

class LaptopComparePage extends StatefulWidget {
  const LaptopComparePage({super.key});

  @override
  State<LaptopComparePage> createState() => _LaptopComparePageState();
}

class _LaptopComparePageState extends State<LaptopComparePage> {
  final List<Map<String, dynamic>> laptops = [
    {
      'name': 'HP Pavilion 15',
      'brand': 'HP',
      'price': 215000,
      'image': 'assets/laptop/laptop1.png',
      'processor': 'Intel Core i7',
      'ram': '16GB',
      'storage': '512GB SSD',
      'rating': 4.5
    },
    {
      'name': 'Dell Inspiron 14',
      'brand': 'Dell',
      'price': 189000,
      'image': 'assets/laptop/laptop2.png',
      'processor': 'Intel Core i5',
      'ram': '8GB',
      'storage': '256GB SSD',
      'rating': 4.0
    },
    {
      'name': 'Lenovo Ideapad 3',
      'brand': 'Lenovo',
      'price': 165000,
      'image': 'assets/laptop/laptop3.png',
      'processor': 'AMD Ryzen 5',
      'ram': '8GB',
      'storage': '512GB SSD',
      'rating': 4.2
    },
    {
      'name': 'Acer Aspire 7',
      'brand': 'Acer',
      'price': 185000,
      'image': 'assets/laptop/laptop4.png',
      'processor': 'Intel Core i5',
      'ram': '16GB',
      'storage': '1TB HDD',
      'rating': 4.3
    },
    {
      'name': 'Asus VivoBook 15',
      'brand': 'Asus',
      'price': 172000,
      'image': 'assets/laptop/laptop5.png',
      'processor': 'Intel Core i3',
      'ram': '8GB',
      'storage': '256GB SSD',
      'rating': 4.0
    },
    {
      'name': 'MSI GF63',
      'brand': 'MSI',
      'price': 248000,
      'image': 'assets/laptop/laptop6.png',
      'processor': 'Intel Core i7',
      'ram': '16GB',
      'storage': '512GB SSD',
      'rating': 4.6
    },
    {
      'name': 'Apple MacBook Air M1',
      'brand': 'Apple',
      'price': 289999,
      'image': 'assets/laptop/laptop7.png',
      'processor': 'Apple M1',
      'ram': '8GB',
      'storage': '256GB SSD',
      'rating': 4.8
    },
    {
      'name': 'Apple MacBook Pro M2',
      'brand': 'Apple',
      'price': 425000,
      'image': 'assets/laptop/laptop8.png',
      'processor': 'Apple M2',
      'ram': '16GB',
      'storage': '512GB SSD',
      'rating': 4.9
    },
    {
      'name': 'HP Envy x360',
      'brand': 'HP',
      'price': 265000,
      'image': 'assets/laptop/laptop9.png',
      'processor': 'AMD Ryzen 7',
      'ram': '16GB',
      'storage': '1TB SSD',
      'rating': 4.7
    },
    {
      'name': 'Dell XPS 13',
      'brand': 'Dell',
      'price': 399000,
      'image': 'assets/laptop/laptop10.png',
      'processor': 'Intel Core i7',
      'ram': '16GB',
      'storage': '512GB SSD',
      'rating': 4.9
    },
  ];

  Map<String, dynamic>? selectedLaptop1;
  Map<String, dynamic>? selectedLaptop2;

  Widget _buildSpecRow(String label, String? value1, String? value2) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
              flex: 2,
              child: Text(label,
                  style: const TextStyle(fontWeight: FontWeight.bold))),
          Expanded(
              flex: 4, child: Text(value1 ?? '-', textAlign: TextAlign.center)),
          Expanded(
              flex: 4, child: Text(value2 ?? '-', textAlign: TextAlign.center)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Laptop Comparison'),
        backgroundColor: Colors.blue.shade900,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Dropdowns for selection
            Row(
              children: [
                Expanded(
                  child: DropdownButton<Map<String, dynamic>>(
                    hint: const Text('Select Laptop 1'),
                    isExpanded: true,
                    value: selectedLaptop1,
                    items: laptops.map((laptop) {
                      return DropdownMenuItem<Map<String, dynamic>>(
                        value: laptop,
                        child: Text(laptop['name']),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedLaptop1 = value;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButton<Map<String, dynamic>>(
                    hint: const Text('Select Laptop 2'),
                    isExpanded: true,
                    value: selectedLaptop2,
                    items: laptops.map((laptop) {
                      return DropdownMenuItem<Map<String, dynamic>>(
                        value: laptop,
                        child: Text(laptop['name']),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedLaptop2 = value;
                      });
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            if (selectedLaptop1 != null && selectedLaptop2 != null)
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      Row(
                        children: [
                          const Spacer(flex: 2),
                          Expanded(
                            flex: 4,
                            child: Image.asset(selectedLaptop1!['image'],
                                height: 100),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            flex: 4,
                            child: Image.asset(selectedLaptop2!['image'],
                                height: 100),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _buildSpecRow("Name", selectedLaptop1!['name'],
                          selectedLaptop2!['name']),
                      _buildSpecRow("Brand", selectedLaptop1!['brand'],
                          selectedLaptop2!['brand']),
                      _buildSpecRow("Price", "PKR ${selectedLaptop1!['price']}",
                          "PKR ${selectedLaptop2!['price']}"),
                      _buildSpecRow("Processor", selectedLaptop1!['processor'],
                          selectedLaptop2!['processor']),
                      _buildSpecRow("RAM", selectedLaptop1!['ram'],
                          selectedLaptop2!['ram']),
                      _buildSpecRow("Storage", selectedLaptop1!['storage'],
                          selectedLaptop2!['storage']),
                      _buildSpecRow("Rating", "${selectedLaptop1!['rating']}⭐",
                          "${selectedLaptop2!['rating']}⭐"),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text("Comparison completed")),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green.shade700,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 40, vertical: 12),
                        ),
                        child: const Text("Compare Now",
                            style: TextStyle(fontSize: 16)),
                      ),
                    ],
                  ),
                ),
              )
            else
              const Text(
                'Please select two laptops to compare',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
          ],
        ),
      ),
    );
  }
}
