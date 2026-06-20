import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../AppFunctionalities/app_strings.dart';

import '_service_details_page.dart';

class CleanUpCustomerPage extends StatefulWidget {
  const CleanUpCustomerPage({super.key});

  @override
  State<CleanUpCustomerPage> createState() => _CleanUpCustomerPageState();
}

class _CleanUpCustomerPageState extends State<CleanUpCustomerPage> {
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
          AppStrings.cleanUp(lang),
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
                  .where("type", isEqualTo: "Clean Up")
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

    borderRadius:
    BorderRadius.circular(24),

    onTap: onTap,

    child: Container(

      margin:
      const EdgeInsets.only(
        bottom: 18,
      ),

      padding:
      const EdgeInsets.symmetric(

        horizontal: 14,
        vertical: 12,
      ),

      decoration: BoxDecoration(

        color: Colors.white,

        borderRadius:
        BorderRadius.circular(24),

        boxShadow: [

          BoxShadow(

            color:
            Colors.black.withOpacity(0.05),

            blurRadius: 12,

            offset:
            const Offset(0, 6),
          ),
        ],
      ),

      child: Row(

        children: [

          /// IMAGE
          ClipRRect(

            borderRadius:
            BorderRadius.circular(18),

            child: Image.network(

              imageUrl,

              width: 90,
              height: 90,

              fit: BoxFit.cover,

              errorBuilder:
                  (
                  context,
                  error,
                  stackTrace,
                  ) {

                return Container(

                  width: 75,
                  height: 75,

                  color:
                  Colors.grey.shade200,

                  child: const Icon(
                    Icons.image,
                    size: 35,
                  ),
                );
              },
            ),
          ),

          const SizedBox(width: 16),

          /// CENTER
          Expanded(

            child: Column(

              crossAxisAlignment:
              CrossAxisAlignment.start,

              children: [

                /// TITLE
                Text(

                  title,

                  maxLines: 1,

                  overflow:
                  TextOverflow.ellipsis,

                  style:
                  const TextStyle(

                    fontSize: 20,

                    fontWeight:
                    FontWeight.bold,

                    color:
                    Color(0xff1B1F3B),
                  ),
                ),

                const SizedBox(height: 8),

                /// DESCRIPTION

                const SizedBox(height: 12),

                /// PHONE
                /// CONTACT + SOCIALS
                Row(

                  children: [

                    /// PHONE
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

                    const SizedBox(width: 8),

                    Text(

                      contact,

                      style:
                      const TextStyle(

                        fontSize: 15,

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

          const SizedBox(width: 10),

          /// RIGHT BUTTON

        ],
      ),
    ),
  );
}

