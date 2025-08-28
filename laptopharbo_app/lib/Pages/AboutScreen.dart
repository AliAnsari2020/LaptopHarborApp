import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
// ✅ Import added

class AboutLaptopHarbor extends StatelessWidget {
  const AboutLaptopHarbor({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.indigo,
        title: const Text(
          "About Laptop Harbor",
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Lottie.asset(
                'assets/images/laptop.json',
                height: 180,
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              "Laptop Harbor",
              style: GoogleFonts.poppins(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: Colors.indigo[800],
              ),
            ),
            const SizedBox(height: 6),
            Text(
              "Your One-Stop Laptop Destination",
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 20),
            Text(
              "Laptop Harbor is your trusted partner for high-quality laptops at unbeatable prices. "
              "Whether you're a student, professional, or gamer – we offer brand-new and certified used laptops "
              "to match every need and budget.\n\n"
              "Founded with a passion for technology and service, our mission is to deliver not just devices, "
              "but a complete customer experience. Every product is carefully tested and guaranteed for quality.\n\n"
              "Join thousands of satisfied customers who trust Laptop Harbor for performance, value, and support.",
              style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[800]),
              textAlign: TextAlign.justify,
            ),
            const SizedBox(height: 30),
            Text("Contact Us",
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.indigo,
                )),
            const SizedBox(height: 12),
            Row(
              children: const [
                Icon(Icons.phone, color: Colors.indigo),
                SizedBox(width: 8),
                Text("+92 300 1234567"),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: const [
                Icon(Icons.email, color: Colors.indigo),
                SizedBox(width: 8),
                Text("support@laptopharbor.com"),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: const [
                Icon(Icons.web, color: Colors.indigo),
                SizedBox(width: 8),
                Text("www.laptopharbor.com"),
              ],
            ),
            const SizedBox(height: 30),
            Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: const FaIcon(FontAwesomeIcons.facebook,
                        color: Colors.indigo),
                    onPressed: () {},
                  ),
                  IconButton(
                    icon: const FaIcon(FontAwesomeIcons.instagram,
                        color: Colors.pink),
                    onPressed: () {},
                  ),
                  IconButton(
                    icon: const FaIcon(FontAwesomeIcons.twitter,
                        color: Colors.blue),
                    onPressed: () {},
                  ),
                  IconButton(
                    icon: const FaIcon(FontAwesomeIcons.linkedin,
                        color: Colors.blueAccent),
                    onPressed: () {},
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Center(
              child: Text(
                "Trusted by Tech Enthusiasts Across Pakistan!",
                style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontStyle: FontStyle.italic,
                    color: Colors.indigo[700]),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
