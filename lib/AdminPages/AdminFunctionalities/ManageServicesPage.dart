import 'package:flutter/material.dart';
import '../../AppFunctionalities/app_strings.dart';
import '../../UserPages/AccommodationPages/post_accommodation.dart';
import '../../UserPages/RoommatesPages/post_roommate.dart';
import '../ServicesPages/HomeFoodAdminPage.dart';
import 'AddServicePage.dart';
import '../ServicesPages/DryCleanAdminPage.dart';
import '../ServicesPages/CleanUpAdminPage.dart';
import '../ServicesPages/OthersAdminPage.dart';

class ManageServicesPage extends StatefulWidget {
  const ManageServicesPage({super.key});

  @override
  State<ManageServicesPage> createState() => _ManageServicesPageState();
}

class _ManageServicesPageState extends State<ManageServicesPage> {
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
        backgroundColor: Colors.blue.shade900,
        toolbarHeight: 80,
        title: Text(
          AppStrings.manageServices(lang),
          style: const TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),

      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 20),

            ///1. HomeFood Service
            serviceRow(
              imagePath: "assets/food2.png",
              title: AppStrings.homeFood(lang),
              subtitle: "Food delivery service",
              icon: Icons.restaurant,
              color: Colors.blue,
              contact: "",
              onEdit: () {

                Navigator.push(

                  context,

                  MaterialPageRoute(
                    builder: (context) =>
                    const HomeFoodAdminPage(),
                  ),
                );
              },
              onDelete: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text("Delete Service"),

                    content: const Text(
                      "Are you sure you want to delete this service?",
                    ),

                    actions: [
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        child: const Text("Cancel"),
                      ),

                      TextButton(
                        onPressed: () {
                          /// DELETE FROM DATABASE HERE

                          Navigator.pop(context);
                        },

                        child: const Text(
                          "Delete",
                          style: TextStyle(color: Colors.blue),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),

            const SizedBox(height: 15),

            ///2. Dry Clean
            serviceRow(
              imagePath: "assets/dryclean1.png",
              title: AppStrings.dryClean(lang),
              subtitle: "Laundry & cleaning",
              icon: Icons.local_laundry_service,
              color: Colors.blue,
              contact: "",
              onEdit: () {
                Navigator.push(

                  context,

                  MaterialPageRoute(
                    builder: (context) =>
                    const DryCleanAdminPage(),
                  ),
                );},
              onDelete: () {},
            ),

            const SizedBox(height: 15),

            ///3. Clean Up
            serviceRow(
              imagePath: "assets/cleanup1.png",
              title: AppStrings.cleanUp(lang),
              subtitle: "House cleaning service",
              icon: Icons.cleaning_services,
              color: Colors.green,
              contact: "",
              onEdit: () {
                Navigator.push(

                  context,

                  MaterialPageRoute(
                    builder: (context) =>
                    const CleanUpAdminPage(),
                  ),
                ); },
              onDelete: () {},
            ),

            const SizedBox(height: 15),

            ///4. Other
            serviceRow(
              imagePath: "assets/others1.png",
              title: AppStrings.others(lang),
              subtitle: "others",
              icon: Icons.cleaning_services,
              color: Colors.green,
              contact: "",
              onEdit: () {
                Navigator.push(

                  context,

                  MaterialPageRoute(
                    builder: (context) =>
                    const OthersAdminPage(),
                  ),
                ); },
              onDelete: () {},
            ),
          ],
        ),
      ),

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        selectedItemColor: Colors.blue.shade500,
        unselectedItemColor: textGrey,
        type: BottomNavigationBarType.fixed,

        onTap: (index) {
          setState(() {
            currentIndex = index;
          });

          if (index == 0) {
            Navigator.pushNamed(context, '/AdminHomePage');
          } else if (index == 2) {
            Navigator.pushNamed(context, '/ReportsPage');
          } else if (index == 3) {
            Navigator.pushNamed(context, '/AdminProfile');
          }
        },

        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.home),
            label: AppStrings.home(lang),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.miscellaneous_services),
            label: AppStrings.services(lang),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.report),
            label: AppStrings.report(lang),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.person),
            label: AppStrings.profile(lang),
          ),
        ],
      ),
    );
  }
}

Widget serviceRow({
  required String title,
  required String subtitle,
  required IconData icon,
  required Color color,
  required String contact,
  required String imagePath,
  required VoidCallback onEdit,
  required VoidCallback onDelete,
}) {
  return Container(
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

          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),

            image: DecorationImage(
              image: AssetImage(imagePath),
              fit: BoxFit.cover,
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

    IconButton(
      onPressed: onEdit,

          icon: Container(
            padding: const EdgeInsets.all(8),

            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(12),
            ),

            child:Icon(
              Icons.arrow_forward_ios_rounded,
              color: Colors.blue.shade400,
              size: 20,
            ),
          ),
        ),
      ],
    ),
  );
}
