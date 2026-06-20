import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../AppFunctionalities/app_strings.dart';

import '_service_details_page.dart';

class DryCleanCustomerPage extends StatefulWidget {
  const DryCleanCustomerPage({super.key});

  @override
  State<DryCleanCustomerPage> createState() => _DryCleanCustomerPageState();
}

class _DryCleanCustomerPageState extends State<DryCleanCustomerPage> {
  int currentIndex = 1;

  final Color bgLight = const Color(0xFFF4F8FC);
  final Color textDark = const Color(0xFF5A5A5A);
  final Color textGrey = const Color(0xFFA0A0A0);
  final Color iconTeal = const Color(0xFF67C2A6);

  final Color primaryBlue = const Color(0xFF1565C0);
  final Color lightBlue = const Color(0xFF42A5F5);

  final Color secondaryBlue = const Color(0xFF1565C0);
  final Color blueColor = Colors.blue;

  @override
  Widget build(BuildContext context) {
    String lang = Localizations.localeOf(context).languageCode;

    return Scaffold(
      backgroundColor: bgLight,

      appBar: AppBar(
        backgroundColor: Colors.orange.shade900,
        toolbarHeight: 80,
        title: Text(
          AppStrings.dryClean(lang),
          style: const TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),

      body: Padding(
        padding: const EdgeInsets.all(20),
        child: ListView(
          children: [
            StreamBuilder(
              stream: FirebaseFirestore.instance
                  .collection("services")
                  .where("type", isEqualTo: "Dry Clean")
                  .snapshots(),

              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text("No Services Yet"));
                }

                final services = snapshot.data!.docs;

                return Column(
                  children: services.map((doc) {
                    final service = doc.data();

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 15),

                      child: serviceRow(

                        title:
                        service["title"] ?? "",

                        instagram:
                        service["instagram"] ?? "",

                        facebook:
                        service["facebook"] ?? "",

                        contact:
                        service["whatsapp"] ?? "",

                        imageUrl:
                        service["image"] ?? "",

                        icon: Icons.home,

                        color: Colors.blue,

                        onTap: () {

                          Navigator.push(

                            context,

                            MaterialPageRoute(

                              builder: (context) =>
                                  ServiceDetailsPage(

                                    service: service,
                                  ),
                            ),
                          );
                        },
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

Widget serviceRow({
  required String title,
  required String instagram,
  required String facebook,
  required IconData icon,
  required Color color,
  required String contact,
  required String imageUrl,
  required VoidCallback onTap,
}) {
  return InkWell(
    borderRadius: BorderRadius.circular(20),

    onTap: onTap,

    child: Container(
      padding: const EdgeInsets.all(16),

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),

      child: Row(
        children: [
          /// IMAGE
          Container(
            width: 70,
            height: 70,

            decoration: BoxDecoration(borderRadius: BorderRadius.circular(16)),

            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),

              child: Image.network(
                imageUrl,

                fit: BoxFit.cover,

                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.grey.shade200,

                    child: const Icon(Icons.image_not_supported),
                  );
                },
              ),
            ),
          ),

          const SizedBox(width: 15),

          /// TEXT
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 5),

                const SizedBox(height: 8),

                Row(

                  children: [

                    /// PHONE
                    if(contact.isNotEmpty)

                      Container(

                        padding:
                        const EdgeInsets.all(7),

                        decoration: BoxDecoration(

                          color:
                          Colors.green.shade50,

                          shape:
                          BoxShape.circle,
                        ),

                        child: const Icon(

                          Icons.phone,

                          size: 16,

                          color:
                          Colors.green,
                        ),
                      ),

                    if(contact.isNotEmpty)

                      const SizedBox(width: 8),

                    if(contact.isNotEmpty)

                      Text(

                        contact,

                        style:
                        const TextStyle(

                          fontWeight:
                          FontWeight.w600,
                        ),
                      ),

                    const SizedBox(width: 12),

                    /// INSTAGRAM
                    if(instagram.isNotEmpty)

                      Container(

                        padding:
                        const EdgeInsets.all(7),

                        decoration: BoxDecoration(

                          color:
                          Colors.pink.shade50,

                          shape:
                          BoxShape.circle,
                        ),

                        child: Icon(

                          Icons.camera_alt,

                          size: 16,

                          color:
                          Colors.pink.shade400,
                        ),
                      ),

                    if(instagram.isNotEmpty)

                      const SizedBox(width: 8),

                    /// FACEBOOK
                    if(facebook.isNotEmpty)

                      Container(

                        padding:
                        const EdgeInsets.all(7),

                        decoration: BoxDecoration(

                          color:
                          Colors.blue.shade50,

                          shape:
                          BoxShape.circle,
                        ),

                        child: Icon(

                          Icons.facebook,

                          size: 16,

                          color:
                          Colors.blue.shade700,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}
