import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../main.dart';
import '../../AppFunctionalities/app_strings.dart';

import 'HomeFoodCustomerPage.dart';
import 'DryCleanCustomerPage.dart';
import 'CleanUpCustomerPage.dart';
import 'OthersCustomerPage.dart';
import '../ChatFolder/chats_page.dart';

class Services extends StatefulWidget {
  const Services({super.key});

  @override
  State<Services> createState() => _ServicesState();
}

class _ServicesState extends State<Services> {
  // FIX: set currentIndex = 0 because Services is reached from the home screen,
  // not via the bottom nav. Keep 0 highlighted as "Home" to avoid a glitch.
  // (Services has its own back arrow so the bottom nav is just for navigation.)
  int currentIndex = 0;

  final Color textGrey = const Color(0xFFA0A0A0);

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String _firstName = "";

  @override
  void initState() {
    super.initState();
    _loadUserName();
  }

  Future<void> _loadUserName() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    final doc = await _firestore.collection("users").doc(uid).get();
    if (doc.exists && mounted) {
      setState(() {
        _firstName = (doc.data()?["firstName"] as String? ?? "").trim();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    String lang = Localizations.localeOf(context).languageCode;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,

      appBar: AppBar(
        backgroundColor: Colors.orange.shade900,
        toolbarHeight: 80,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white, size: 30),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        actions: [
          // FIX: notifications bell is now an IconButton (tappable) that navigates
          IconButton(
            onPressed: () {
              Navigator.pushNamed(context, '/notifications');
            },
            icon: const Icon(
              Icons.notifications_active,
              color: Colors.white,
              size: 30,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.language, color: Colors.white),
            onPressed: () {
              if (lang == 'en') {
                MyApp.setLocale(context, const Locale('ar'));
              } else {
                MyApp.setLocale(context, const Locale('en'));
              }
            },
          ),
        ],
      ),

      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                // FIX: pass the real user's first name to AppStrings.hi()
                AppStrings.hi(lang, _firstName.isEmpty ? "" : _firstName),
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                AppStrings.question(lang),
                style: TextStyle(
                  fontSize: 16,
                  color: Theme.of(context).textTheme.bodyMedium?.color,
                ),
              ),
            ),

            const SizedBox(height: 20),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(25),
                child: Image.asset(
                  'assets/room.png',
                  height: 180,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
            ),

            const SizedBox(height: 25),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 15,
                mainAxisSpacing: 15,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _card(
                    context,
                    AppStrings.homeFood(lang),
                    'assets/food2.png',
                    () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const HomeFoodCustomerPage(),
                        ),
                      );
                    },
                  ),
                  _card(
                    context,
                    AppStrings.dryClean(lang),
                    'assets/dryclean1.png',
                    () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const DryCleanCustomerPage(),
                        ),
                      );
                    },
                  ),
                  _card(
                    context,
                    AppStrings.cleanUp(lang),
                    'assets/cleanup1.png',
                    () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const CleanUpCustomerPage(),
                        ),
                      );
                    },
                  ),
                  _card(
                    context,
                    AppStrings.others(lang),
                    'assets/others1.png',
                    () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const OthersCustomerPage(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        selectedItemColor: Colors.orange.shade900,
        unselectedItemColor: textGrey,
        type: BottomNavigationBarType.fixed,
        onTap: (index) {
          if (index == currentIndex) return;

          // FIX: use pushReplacementNamed where possible; use MaterialPageRoute
          // for ChatsPage since /chats route does not exist in main.dart
          if (index == 0) {
            Navigator.pushReplacementNamed(context, '/');
          } else if (index == 1) {
            Navigator.pushReplacementNamed(context, '/post');
          } else if (index == 2) {
            // FIX: was pushNamed('/chats') which caused a "route not found" crash
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const ChatsPage(),
              ),
            );
          } else if (index == 3) {
            Navigator.pushReplacementNamed(context, '/profile');
          }
        },
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.home),
            label: AppStrings.home(lang),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.add_circle_outline),
            label: AppStrings.post(lang),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.chat_bubble_outline),
            label: AppStrings.chat(lang),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.person_outline),
            label: AppStrings.profile(lang),
          ),
        ],
      ),
    );
  }
}

Widget _card(
    BuildContext context,
    String title,
    String imagePath,
    VoidCallback onTap,
    ) {
  return Container(
    decoration: BoxDecoration(
      color: Theme.of(context).cardColor,
      borderRadius: BorderRadius.circular(20),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.08),
          blurRadius: 15,
          offset: const Offset(0, 8),
        ),
      ],
    ),
    child: Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(imagePath, width: 90, height: 90, fit: BoxFit.contain),
            const SizedBox(height: 10),
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).textTheme.bodyLarge?.color,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
