import 'package:flutter/material.dart';
import '../../main.dart';
import '../AppFunctionalities/app_strings.dart';

class AdminHomePage extends StatefulWidget {
  const AdminHomePage({super.key});

  @override
  State<AdminHomePage> createState() => _AdminHomePageState();
}

class _AdminHomePageState extends State<AdminHomePage> {

  int currentIndex = 0;

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

      drawer: Drawer(
        child: ListView(
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(color: Color(0xFF1565C0)),
              child: Text(
                AppStrings.menu(lang),
                style: const TextStyle(color: Colors.white, fontSize: 24),
              ),
            ),
            // FIX: drawer ListTiles now have onTap handlers for navigation
            ListTile(
              leading: const Icon(Icons.home),
              title: Text(AppStrings.home(lang)),
              onTap: () {
                Navigator.pop(context); // close drawer
                // already on home — just close the drawer
              },
            ),
            ListTile(
              leading: const Icon(Icons.person),
              title: Text(AppStrings.profile(lang)),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/AdminProfile');
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: Text(AppStrings.settings(lang)),
              onTap: () {
                Navigator.pop(context);
                // Settings page not yet implemented — show a snackbar
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Settings coming soon")),
                );
              },
            ),
          ],
        ),
      ),

      body: Column(
        children: [

          /// Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.only(
                top: 50, bottom: 40, left: 20, right: 20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.blue.shade900,
                  Colors.blue.shade800,
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

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [

                    Builder(
                      builder: (context) => GestureDetector(
                        onTap: () => Scaffold.of(context).openDrawer(),
                        child: const Icon(Icons.menu,
                            color: Colors.white, size: 28),
                      ),
                    ),

                    Row(
                      children: [
                        const Icon(Icons.favorite, color: Colors.white70),
                        const SizedBox(width: 10),
                        const Icon(Icons.notifications_active,
                            color: Colors.white70),

                        IconButton(
                          icon: const Icon(Icons.language,
                              color: Colors.white),
                          onPressed: () {
                            if (lang == 'en') {
                              MyApp.setLocale(context, const Locale('ar'));
                            } else {
                              MyApp.setLocale(context, const Locale('en'));
                            }
                          },
                        ),
                      ],
                    )
                  ],
                ),

                const SizedBox(height: 20),

                Image.asset('assets/Logo2.png',
                    width: 100, height: 100),

                const SizedBox(height: 10),

                Text(
                  AppStrings.admin(lang),
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),


          Expanded(
            child: GridView.count(
              padding: const EdgeInsets.symmetric(
                  horizontal: 20, vertical: 30),
              crossAxisCount: 2,
              crossAxisSpacing: 20,
              mainAxisSpacing: 25,
              childAspectRatio: 0.95,
              children: [

                _card(
                  AppStrings.manageServices(lang),
                  Icons.miscellaneous_services,
                  Colors.greenAccent,
                  textDark,
                      () {
                    Navigator.pushNamed(context, '/ManageServicesPage');
                  },
                ),

                _card(
                  AppStrings.report(lang),
                  Icons.report,
                  Colors.red,
                  textDark,
                      () {
                    Navigator.pushNamed(context, '/ReportsPage');
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),
        ],
      ),

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        selectedItemColor: Colors.blue.shade500,
        unselectedItemColor: textGrey,
        type: BottomNavigationBarType.fixed,
        onTap: (index) {
          if (index == currentIndex) return;
          setState(() {
            currentIndex = index;
          });

          if (index == 1) {
            Navigator.pushNamed(context, '/ManageServicesPage');
          } else if (index == 2) {
            Navigator.pushNamed(context, '/ReportsPage');
          } else if (index == 3) {
            Navigator.pushNamed(context, '/AdminProfile');
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

  Widget _card(String title, IconData icon, Color color, Color textColor,
      VoidCallback onTap) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 20,
            offset: const Offset(0, 10),
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
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 40, color: color),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
