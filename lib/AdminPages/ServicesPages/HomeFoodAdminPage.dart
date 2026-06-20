import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../AppFunctionalities/app_strings.dart';
import '../AdminFunctionalities/AddServicePage.dart';
import '../AdminFunctionalities/EditServicePage.dart';
import 'admin_service_shared_widgets.dart'; // FIX: replaces local duplicate serviceRow

class HomeFoodAdminPage extends StatefulWidget {
  const HomeFoodAdminPage({super.key});

  @override
  State<HomeFoodAdminPage> createState() => _HomeFoodAdminPageState();
}

class _HomeFoodAdminPageState extends State<HomeFoodAdminPage> {
  final Color bgLight = const Color(0xFFF4F8FC);

  @override
  Widget build(BuildContext context) {
    String lang = Localizations.localeOf(context).languageCode;

    return Scaffold(
      backgroundColor: bgLight,
      appBar: AppBar(
        backgroundColor: Colors.blue.shade900,
        toolbarHeight: 80,
        title: Text(
          AppStrings.homeFood(lang),
          style: const TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: ListView(
          children: [
            addServiceButton(
              context: context,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const AddServicePage()),
                );
              },
            ),
            const SizedBox(height: 20),
            StreamBuilder(
              stream: FirebaseFirestore.instance
                  .collection("services")
                  .where("type", isEqualTo: "Home Food")
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
                    return adminServiceRow(
                      title: service["title"] ?? "",
                      subtitle: service["subtitle"] ?? "",
                      contact: service["whatsapp"] ?? "",
                      imageUrl: service["image"] ?? "",
                      onEdit: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => EditServicePage(
                              docId: doc.id,
                              oldTitle: service["title"] ?? "",
                              oldSubtitle: service["subtitle"] ?? "",
                              oldContact: "",
                              oldType: service["type"] ?? "",
                              oldImage: service["image"] ?? "",
                              oldWhatsapp: service["whatsapp"] ?? "",
                              oldInstagram: service["instagram"] ?? "",
                              oldFacebook: service["facebook"] ?? "",
                            ),
                          ),
                        );
                      },
                      onDelete: () async {
                        await FirebaseFirestore.instance
                            .collection("services")
                            .doc(doc.id)
                            .delete();
                      },
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

