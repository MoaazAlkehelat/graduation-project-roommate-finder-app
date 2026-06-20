import 'package:flutter/material.dart';
import 'package:gp2homepage2/UserPages/ProfileFunctionalities/edit_profile.dart';
import '../../AppFunctionalities/app_strings.dart';
import 'package:firebase_auth/firebase_auth.dart';

// FIX: logout now calls FirebaseAuth.instance.signOut() before navigating
// FIX: Removed unused import of main.dart (not needed here)

class AdminProfile extends StatefulWidget {
  const AdminProfile({super.key});

  @override
  State<AdminProfile> createState() => _AdminProfileState();
}

class _AdminProfileState extends State<AdminProfile> {
  int currentIndex = 3;

  final Color primaryBlue = const Color(0xFF1565C0);
  final Color lightBlue = const Color(0xFF42A5F5);
  final Color bgLight = const Color(0xFFF4F8FC);
  final Color secondaryBlue = const Color(0xFF1565C0);
  final Color textGrey = const Color(0xFFA0A0A0);

  @override
  Widget build(BuildContext context) {
    String lang = Localizations.localeOf(context).languageCode;

    return Scaffold(
      backgroundColor: bgLight,

      body: Column(
        children: [
          /// HEADER
          Container(
            width: double.infinity,
            padding: const EdgeInsets.only(top: 60, bottom: 30),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.blue.shade900,
                  Colors.blue.shade700,
                  Colors.blue.shade400,
                ],
              ),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
            ),
            child: Column(
              children: [
                const CircleAvatar(
                  radius: 45,
                  backgroundImage:
                      AssetImage('assets/DefaultProfilePicture.png'),
                ),
                const SizedBox(height: 10),
                const Text(
                  "Admin",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  AppStrings.admin(lang),
                  style: TextStyle(color: Colors.white.withOpacity(0.8)),
                ),
                const SizedBox(height: 15),
              ],
            ),
          ),

          const SizedBox(height: 20),

          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              children: [
                const SizedBox(height: 20),

                // FIX: logout now signs out from FirebaseAuth before navigating
                ListTile(
                  leading: const Icon(Icons.logout, color: Colors.blue),
                  title: Text(
                    AppStrings.logout(lang),
                    style: const TextStyle(color: Colors.blue),
                  ),
                  onTap: () async {
                    await FirebaseAuth.instance.signOut();
                    if (!mounted) return;
                    Navigator.pushNamedAndRemoveUntil(
                      context,
                      '/login',
                      (route) => false,
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        selectedItemColor: primaryBlue,
        unselectedItemColor: textGrey,
        type: BottomNavigationBarType.fixed,
        onTap: (index) {
          if (index == currentIndex) return;

          if (index == 0) {
            Navigator.pushReplacementNamed(context, '/AdminHomePage');
          } else if (index == 1) {
            Navigator.pushNamed(context, '/ManageServicesPage');
          } else if (index == 2) {
            Navigator.pushNamed(context, '/ReportsPage');
          }
        },
        items: [
          BottomNavigationBarItem(
              icon: const Icon(Icons.home), label: AppStrings.home(lang)),
          BottomNavigationBarItem(
              icon: const Icon(Icons.miscellaneous_services),
              label: AppStrings.services(lang)),
          BottomNavigationBarItem(
              icon: const Icon(Icons.report), label: AppStrings.report(lang)),
          BottomNavigationBarItem(
              icon: const Icon(Icons.person),
              label: AppStrings.profile(lang)),
        ],
      ),
    );
  }
}
