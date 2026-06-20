import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../AppFunctionalities/app_strings.dart';
import 'ReportDetailsPage.dart';

// FIX: replaced hardcoded dummy data with a live Firestore stream from the
// "reports" collection. Expected document fields:
//   reportedUserName: String  — the name of the reported user
//   reason:           String  — reason for the report
//   status:           String  — "Pending" | "Reviewed" | "Blocked"
//   createdAt:        Timestamp

class ReportsPage extends StatefulWidget {
  const ReportsPage({super.key});

  @override
  State<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage> {

  int currentIndex = 2;

  final Color primaryBlue = const Color(0xFF1565C0);
  final Color lightBlue = const Color(0xFF42A5F5);
  final Color textGrey = const Color(0xFFA0A0A0);
  final Color bgLight = const Color(0xFFF4F8FC);

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {

    String lang = Localizations.localeOf(context).languageCode;

    return Scaffold(
      backgroundColor: bgLight,

      appBar: AppBar(
        backgroundColor: primaryBlue,
        toolbarHeight: 80,
        title: Text(
          AppStrings.report(lang),
          style: const TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),

      // FIX: body is now a StreamBuilder fetching real reports from Firestore
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection("reports")
            .orderBy("createdAt", descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }

          final docs = snapshot.data?.docs ?? [];

          if (docs.isEmpty) {
            return const Center(
              child: Text(
                "No reports yet",
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(20),
            itemCount: docs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 20),
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              final String name   = data["reportedUserName"] ?? "Unknown";
              final String reason = data["reason"] ?? "";
              final String status = data["status"] ?? "Pending";

              return GestureDetector(

                onTap: () {

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ReportDetailsPage(
                        reportData: data,
                        reportId: docs[index].id,
                      ),
                    ),
                  );
                },

                child: reportRow(
                  name: name,
                  reason: reason,
                  status: status,

                  onChat: () {},

                  onCall: () {},
                ),
              );
            },
          );
        },
      ),

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        selectedItemColor: primaryBlue,
        unselectedItemColor: textGrey,
        type: BottomNavigationBarType.fixed,

        onTap: (index) {
          if (index == currentIndex) return;
          setState(() {
            currentIndex = index;
          });

          if (index == 0) {
            Navigator.pushReplacementNamed(context, '/AdminHomePage');
          } else if (index == 1) {
            Navigator.pushReplacementNamed(context, '/ManageServicesPage');
          } else if (index == 3) {
            Navigator.pushReplacementNamed(context, '/AdminProfile');
          }
        },

        items: [
          BottomNavigationBarItem(
              icon: const Icon(Icons.home),
              label: AppStrings.home(lang)),
          BottomNavigationBarItem(
              icon: const Icon(Icons.miscellaneous_services),
              label: AppStrings.services(lang)),
          BottomNavigationBarItem(
              icon: const Icon(Icons.report),
              label: AppStrings.report(lang)),
          BottomNavigationBarItem(
              icon: const Icon(Icons.person),
              label: AppStrings.profile(lang)),
        ],
      ),
    );
  }
}

/// Report card widget
Widget reportRow({
  required String name,
  required String reason,
  required String status,
  required VoidCallback onChat,
  required VoidCallback onCall,
}) {
  return Container(
    width: double.infinity,
    padding: const EdgeInsets.all(14),

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

    child: Row(
      children: [

        /// Avatar placeholder
        Container(
          width: 80,
          height: 80,

          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(18),
          ),

          child: const Icon(
            Icons.person,
            size: 40,
            color: Colors.black54,
          ),
        ),

        const SizedBox(width: 15),

        /// Text
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              Text(
                name,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 8),

              Text(
                reason,
                style: TextStyle(
                  color: Colors.grey.shade700,
                  fontSize: 16,
                ),
              ),

              const SizedBox(height: 8),

              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),

                decoration: BoxDecoration(
                  color: status == "Pending"
                      ? Colors.blue.withOpacity(0.15)
                      : status == "Blocked"
                      ? Colors.red.withOpacity(0.15)
                      : Colors.green.withOpacity(0.15),

                  borderRadius: BorderRadius.circular(12),
                ),

                child: Text(
                  status,
                  style: TextStyle(
                    color: status == "Pending"
                        ? Colors.blue.shade800
                        : status == "Blocked"
                        ? Colors.red
                        : Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),

        /// Action buttons
        Column(
          children: [

            IconButton(
              onPressed: onChat,
              icon: const Icon(
                Icons.chat_bubble_outline,
                size: 28,
              ),
            ),

            IconButton(
              onPressed: onCall,
              icon: const Icon(
                Icons.call_outlined,
                size: 28,
              ),
            ),
          ],
        ),
      ],
    ),
  );
}
