import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

Future<void> openLink(String url) async {
  if (url.isEmpty) return;

  final Uri uri = Uri.parse(url);

  if (await canLaunchUrl(uri)) {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}

class ServiceDetailsPage extends StatelessWidget {
  final Map<String, dynamic> service;

  const ServiceDetailsPage({super.key, required this.service});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// TOP IMAGE
            Stack(
              children: [
                Container(height: 110, color: Colors.orange.shade900),

                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(30),
                    bottomRight: Radius.circular(30),
                  ),
                  child: Image.network(
                    service["image"] ?? "",
                    width: double.infinity,
                    height: 300,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: double.infinity,
                        height: 300,
                        color: Colors.orange.shade100,
                        child: const Icon(Icons.image, size: 80),
                      );
                    },
                  ),
                ),

                /// BACK BUTTON
                Positioned(
                  top: 50,
                  left: 20,
                  child: CircleAvatar(
                    backgroundColor: Colors.white,
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.black),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 25),

            /// TITLE SECTION
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 25),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    service["title"],
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    service["subtitle"] ?? "",
                    style: TextStyle(fontSize: 18, color: Colors.grey.shade700),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 25),

            /// CONTACT CARD

            /// CONTACT CARD
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),

              padding: const EdgeInsets.all(20),

              decoration: BoxDecoration(
                color: Colors.white,

                borderRadius: BorderRadius.circular(22),

                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),

                    blurRadius: 15,

                    offset: const Offset(0, 8),
                  ),
                ],
              ),

              child: Column(
                children: [
                  /// WHATSAPP
                  if (service["whatsapp"] != null && service["whatsapp"] != "")
                    GestureDetector(
                      onTap: () async {
                        final phone = service["whatsapp"].toString().replaceAll(
                          " ",
                          "",
                        );

                        final Uri uri = Uri.parse("https://wa.me/$phone");

                        if (await canLaunchUrl(uri)) {
                          await launchUrl(
                            uri,

                            mode: LaunchMode.externalApplication,
                          );
                        }
                      },

                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 14,
                        ),

                        decoration: BoxDecoration(
                          color: Colors.green.shade50,

                          borderRadius: BorderRadius.circular(16),
                        ),

                        child: Row(
                          children: [
                            const Icon(Icons.phone, color: Colors.green),

                            const SizedBox(width: 12),

                            Expanded(
                              child: Text(
                                service["whatsapp"],

                                style: const TextStyle(
                                  fontSize: 17,

                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  if ((service["instagram"] != null &&
                          service["instagram"] != "") ||
                      (service["facebook"] != null &&
                          service["facebook"] != ""))
                    const SizedBox(height: 18),

                  /// INSTAGRAM
                  if (service["instagram"] != null &&
                      service["instagram"] != "")
                    GestureDetector(
                      onTap: () {
                        openLink(service["instagram"]);
                      },

                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),

                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),

                        decoration: BoxDecoration(
                          color: Colors.pink.shade50,

                          borderRadius: BorderRadius.circular(16),
                        ),

                        child: Row(
                          children: [
                            Icon(Icons.camera_alt, color: Colors.pink.shade400),

                            const SizedBox(width: 12),

                            Expanded(
                              child: Text(
                                service["instagram"],

                                overflow: TextOverflow.ellipsis,

                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  /// FACEBOOK
                  if (service["facebook"] != null && service["facebook"] != "")
                    GestureDetector(
                      onTap: () {
                        openLink(service["facebook"]);
                      },

                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),

                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,

                          borderRadius: BorderRadius.circular(16),
                        ),

                        child: Row(
                          children: [
                            Icon(Icons.facebook, color: Colors.blue.shade700),

                            const SizedBox(width: 12),

                            Expanded(
                              child: Text(
                                service["facebook"],

                                overflow: TextOverflow.ellipsis,

                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}
