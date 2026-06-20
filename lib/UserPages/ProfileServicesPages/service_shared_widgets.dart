// shared_service_widgets.dart
// Extract the duplicate serviceRow function into one shared file.
// Import this file in all 8 service pages instead of defining it locally.

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

Future<void> openLink(String url) async {
  if (url.isEmpty) return;

  final Uri uri = Uri.parse(url);

  if (await canLaunchUrl(uri)) {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}

Widget serviceRow({
  required Map<String, dynamic> service,
  required VoidCallback onTap,
}) {
  return GestureDetector(
    onTap: onTap,
    child: Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          // Image
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child:
                service["image"] != null && service["image"] != ""
                    ? Image.network(
                      service["image"],
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                      errorBuilder:
                          (_, __, ___) => Container(
                            width: 80,
                            height: 80,
                            color: Colors.orange.shade50,
                            child: const Icon(
                              Icons.broken_image_outlined,
                              color: Colors.orange,
                            ),
                          ),
                    )
                    : Container(
                      width: 80,
                      height: 80,
                      color: Colors.orange.shade50,
                      child: const Icon(
                        Icons.home_repair_service_outlined,
                        color: Colors.orange,
                        size: 35,
                      ),
                    ),
          ),

          const SizedBox(width: 15),

          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,

              children: [
                /// TITLE
                Text(
                  service["title"] ?? "",

                  maxLines: 1,

                  overflow: TextOverflow.ellipsis,

                  style: const TextStyle(
                    fontSize: 18,

                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 10),

                /// PHONE + SOCIALS
                /// PHONE + SOCIALS
                Wrap(
                  spacing: 10,
                  runSpacing: 10,

                  crossAxisAlignment: WrapCrossAlignment.center,

                  children: [
                    /// PHONE
                    if (service["whatsapp"] != null &&
                        service["whatsapp"] != "")
                      Row(
                        mainAxisSize: MainAxisSize.min,

                        children: [
                          Container(
                            padding: const EdgeInsets.all(7),

                            decoration: BoxDecoration(
                              color: Colors.green.shade50,

                              shape: BoxShape.circle,
                            ),

                            child: const Icon(
                              Icons.phone,

                              size: 16,

                              color: Colors.green,
                            ),
                          ),

                          const SizedBox(width: 8),

                          Text(
                            service["whatsapp"],

                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),

                    /// INSTAGRAM
                    if (service["instagram"] != null &&
                        service["instagram"] != "")
                      GestureDetector(
                        onTap: () {
                          openLink(service["instagram"]);
                        },

                        child: Container(
                          padding: const EdgeInsets.all(7),

                          decoration: BoxDecoration(
                            color: Colors.pink.shade50,

                            shape: BoxShape.circle,
                          ),

                          child: Icon(
                            Icons.camera_alt,

                            size: 16,

                            color: Colors.pink.shade400,
                          ),
                        ),
                      ),

                    /// FACEBOOK
                    if (service["facebook"] != null &&
                        service["facebook"] != "")
                      GestureDetector(
                        onTap: () {
                          openLink(service["facebook"]);
                        },

                        child: Container(
                          padding: const EdgeInsets.all(7),

                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,

                            shape: BoxShape.circle,
                          ),

                          child: Icon(
                            Icons.facebook,

                            size: 16,

                            color: Colors.blue.shade700,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),

          const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
        ],
      ),
    ),
  );
}
