// admin_service_shared_widgets.dart
// Shared serviceRow widget for all 4 Admin service pages.
// Replaces the duplicate top-level function that was defined in each admin page.

import 'package:flutter/material.dart';

Widget adminServiceRow({
  required String title,
  required String subtitle,
  required String contact,
  required String imageUrl,
  required VoidCallback onEdit,
  required VoidCallback onDelete,
}) {
  return Container(
    margin: const EdgeInsets.only(bottom: 15),
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
        // IMAGE
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: imageUrl.isNotEmpty
              ? Image.network(
                  imageUrl,
                  width: 70,
                  height: 70,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    width: 70,
                    height: 70,
                    color: Colors.grey.shade200,
                    child: const Icon(Icons.image_not_supported),
                  ),
                )
              : Container(
                  width: 70,
                  height: 70,
                  color: Colors.grey.shade200,
                  child: const Icon(Icons.image_not_supported),
                ),
        ),

        const SizedBox(width: 15),

        // TEXT
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
              Text(subtitle, style: TextStyle(color: Colors.grey.shade600)),
              const SizedBox(height: 8),
              if (contact.isNotEmpty)
                Row(
                  children: [
                    const Icon(Icons.phone, size: 16, color: Colors.green),
                    const SizedBox(width: 5),
                    Text(contact),
                  ],
                ),
            ],
          ),
        ),

        PopupMenuButton(
          icon: Icon(Icons.more_vert, color: Colors.grey.shade700),
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: "edit",
              child: Row(
                children: [
                  Icon(Icons.edit, color: Colors.blue),
                  SizedBox(width: 10),
                  Text("Edit"),
                ],
              ),
            ),
            const PopupMenuItem(
              value: "delete",
              child: Row(
                children: [
                  Icon(Icons.delete, color: Colors.red),
                  SizedBox(width: 10),
                  Text("Delete"),
                ],
              ),
            ),
          ],
          onSelected: (value) {
            if (value == "edit") {
              onEdit();
            } else if (value == "delete") {
              onDelete();
            }
          },
        ),
      ],
    ),
  );
}

Widget addServiceButton({
  required BuildContext context,
  required VoidCallback onTap,
}) {
  return Container(
    width: double.infinity,
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: Colors.blue.shade500,
      borderRadius: BorderRadius.circular(20),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.2),
          blurRadius: 10,
          offset: const Offset(0, 5),
        ),
      ],
    ),
    child: InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.blue.shade300,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Icons.add, color: Colors.white, size: 30),
            ),
          ),
          const SizedBox(width: 15),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Add Service",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  "Create a new service",
                  style: TextStyle(color: Colors.white70, fontSize: 15),
                ),
              ],
            ),
          ),
          const Icon(Icons.arrow_forward_ios, color: Colors.white),
        ],
      ),
    ),
  );
}
