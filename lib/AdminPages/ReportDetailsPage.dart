import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ReportDetailsPage extends StatelessWidget {
  final Map<String, dynamic> reportData;
  final String reportId;

  const ReportDetailsPage({
    super.key,
    required this.reportData,
    required this.reportId,
  });

  @override
  Widget build(BuildContext context) {
    final firestore = FirebaseFirestore.instance;

    final String name = reportData["reportedUserName"] ?? "Unknown";

    final String reason = reportData["reason"] ?? "";

    final String message = reportData["messageText"] ?? "";

    final String imageUrl = reportData["imageUrl"] ?? "";

    final String messageType = reportData["messageType"] ?? "text";

    final String reportedUserId = reportData["reportedUserId"] ?? "";

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.orange.shade900,
        title: const Text(
          "Report Details",
          style: TextStyle(color: Colors.white),
        ),
      ),

      body: Padding(
        padding: const EdgeInsets.all(20),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,

          children: [
            Text(
              name,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 10),

            Text("Reason: $reason", style: const TextStyle(fontSize: 18)),

            const SizedBox(height: 20),

            const Text(
              "Reported Content",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 15),

            if (messageType == "image")
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.network(imageUrl),
              ),

            if (messageType == "text")
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(15),

                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(16),
                ),

                child: Text(message, style: const TextStyle(fontSize: 18)),
              ),

            const Spacer(),

            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                minimumSize: const Size(double.infinity, 55),
              ),

              onPressed: () async {
                await firestore.collection("users").doc(reportedUserId).update({
                  "isBanned": true,
                });

                await firestore.collection("reports").doc(reportId).update({
                  "status": "Blocked",
                });

                if (context.mounted) {
                  showDialog(
                    context: context,
                    builder:
                        (_) => AlertDialog(
                          title: const Text("User Blocked"),

                          content: const Text(
                            "User has been blocked successfully.",
                          ),

                          actions: [
                            TextButton(
                              onPressed: () {
                                Navigator.pop(context);
                              },

                              child: const Text("OK"),
                            ),
                          ],
                        ),
                  );
                }
              },

              icon: const Icon(Icons.block),

              label: const Text("Block User", style: TextStyle(fontSize: 18)),
            ),
          ],
        ),
      ),
    );
  }
}
