import 'package:flutter/material.dart';
import 'package:gp2homepage2/UserPages/ProfileFunctionalities/edit_profile.dart';
import '../../AppFunctionalities/app_strings.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gp2homepage2/UserPages/ProfileFunctionalities/my_posts.dart';
import 'package:gp2homepage2/UserPages/ProfileFunctionalities/favorites.dart';
import '../ChatFolder/chats_page.dart';
import 'settings_page.dart';

// FIX: Removed unused imports: dart:io, image_picker, main.dart
// FIX: logout now calls FirebaseAuth.instance.signOut() before navigating
// FIX: getFavoritesCount() now sums both favoritesAccommodation AND favoritesRoommates

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  int currentIndex = 3;

  final Color primaryCoral = const Color(0xFFE65100);
  final Color bgLight = const Color(0xFFF6F3F1);
  final Color textGrey = const Color(0xFFA0A0A0);

  final FirebaseAuth auth = FirebaseAuth.instance;
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  Map<String, dynamic>? userData;
  int postsCount = 0;
  int favoritesCount = 0;

  Future getPostsCount() async {
    String uid = auth.currentUser!.uid;

    var accommodation = await firestore
        .collection("roomListings")
        .where("userId", isEqualTo: uid)
        .get();

    var roommate = await firestore
        .collection("roommateRequests")
        .where("userId", isEqualTo: uid)
        .get();

    setState(() {
      postsCount = accommodation.docs.length + roommate.docs.length;
    });
  }

  // FIX: Now counts both favoritesAccommodation and favoritesRoommates
  Future getFavoritesCount() async {
    String uid = auth.currentUser!.uid;

    var favAccommodation = await firestore
        .collection("favoritesAccommodation")
        .where("userId", isEqualTo: uid)
        .get();

    var favRoommates = await firestore
        .collection("favoritesRoommates")
        .where("userId", isEqualTo: uid)
        .get();

    setState(() {
      favoritesCount = favAccommodation.docs.length + favRoommates.docs.length;
    });
  }

  Future getUserData() async {
    String uid = auth.currentUser!.uid;

    DocumentSnapshot doc =
    await firestore.collection("users").doc(uid).get();

    setState(() {
      userData = doc.data() as Map<String, dynamic>;
    });
  }

  @override
  void initState() {
    super.initState();
    getUserData();
    getPostsCount();
    getFavoritesCount();
  }

  @override
  Widget build(BuildContext context) {
    String lang = Localizations.localeOf(context).languageCode;

    return Scaffold(
      backgroundColor: bgLight,

      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.only(top: 60, bottom: 30),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.orange.shade900,
                  Colors.orange.shade700,
                ],
              ),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
            ),
            child: Column(
              children: [
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 45,
                      backgroundColor: Colors.white,
                      backgroundImage:
                      userData?["profileImage"] != null &&
                          userData!["profileImage"] != ""
                          ? NetworkImage(userData!["profileImage"])
                          : null,
                      child: userData?["profileImage"] == null ||
                          userData!["profileImage"] == ""
                          ? const Icon(Icons.person, size: 40, color: Colors.grey)
                          : null,
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                Text(
                  userData == null
                      ? ""
                      : "${userData!["firstName"]} ${userData!["lastName"]}",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 5),

                Text(
                  userData?["bio"] ?? "",
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white.withOpacity(0.85)),
                ),

                const SizedBox(height: 15),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _stat(postsCount.toString(), AppStrings.posts(lang)),
                    _stat(favoritesCount.toString(), AppStrings.likes(lang)),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              children: [
                _tile(Icons.person, AppStrings.editProfile(lang), () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const EditProfilePage()),
                  );
                }),

                _tile(Icons.favorite, AppStrings.favorites(lang), () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const FavoritesPage()),
                  );
                }),

                _tile(Icons.article_outlined, "My Posts", () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const MyPostsPage()),
                  );
                }),

                const SizedBox(height: 10),

                // BIO CARD
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 15,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.orange.shade800),
                          const SizedBox(width: 10),
                          const Text(
                            "About Me",
                            style: TextStyle(
                                fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 15),
                      infoRow(Icons.phone_outlined, "Phone",
                          userData?["phone"] ?? ""),
                      const SizedBox(height: 12),
                      infoRow(Icons.location_city_outlined, "City",
                          userData?["city"] ?? ""),
                      const SizedBox(height: 12),
                      infoRow(Icons.person_outline, "Gender",
                          userData?["gender"] ?? ""),
                      const SizedBox(height: 12),
                      infoRow(Icons.flag_outlined, "Nationality",
                          userData?["nationality"] ?? ""),
                      const SizedBox(height: 12),
                      infoRow(Icons.mosque_outlined, "Religion",
                          userData?["religion"] ?? ""),
                      const SizedBox(height: 12),
                      infoRow(Icons.work_outline, "Status",
                          userData?["status"] ?? ""),
                      const SizedBox(height: 18),
                      Text(
                        userData?["bio"] ?? "",
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          height: 1.6,
                          fontSize: 15,
                        ),
                      ),

                      // ── Lifestyle chips ───────────────────────────────
                      if ((userData?["lifestyle"] as List?)?.isNotEmpty == true) ...[
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            Icon(Icons.self_improvement,
                                color: Colors.orange.shade700, size: 20),
                            const SizedBox(width: 8),
                            const Text(
                              "Lifestyle",
                              style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: List<String>.from(
                              userData!["lifestyle"])
                              .map((item) => _profileChip(item))
                              .toList(),
                        ),
                      ],

                      // ── Hobbies chips ────────────────────────────────
                      if ((userData?["hobbies"] as List?)?.isNotEmpty == true) ...[
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            Icon(Icons.sports_esports_outlined,
                                color: Colors.orange.shade700, size: 20),
                            const SizedBox(width: 8),
                            const Text(
                              "Hobbies",
                              style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: List<String>.from(
                              userData!["hobbies"])
                              .map((item) => _profileChip(item))
                              .toList(),
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 18),

                _tile(Icons.settings, AppStrings.settings(lang), () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const SettingsPage()),
                  );
                }),

                const SizedBox(height: 20),

                // FIX: logout now signs out from FirebaseAuth before navigating
                ListTile(
                  leading: const Icon(Icons.logout, color: Colors.red),
                  title: Text(
                    AppStrings.logout(lang),
                    style: const TextStyle(color: Colors.red),
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
        selectedItemColor: Colors.orange.shade900,
        unselectedItemColor: textGrey,
        type: BottomNavigationBarType.fixed,
        onTap: (index) {
          if (index == currentIndex) return;

          if (index == 0) {
            Navigator.pushReplacementNamed(context, '/');
          } else if (index == 1) {
            Navigator.pushReplacementNamed(context, '/post');
          } else if (index == 2) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ChatsPage()),
            );
          }
        },
        items: [
          BottomNavigationBarItem(
              icon: const Icon(Icons.home), label: AppStrings.home(lang)),
          BottomNavigationBarItem(
              icon: const Icon(Icons.add_circle_outline),
              label: AppStrings.post(lang)),
          BottomNavigationBarItem(
              icon: const Icon(Icons.chat_bubble_outline),
              label: AppStrings.chat(lang)),
          BottomNavigationBarItem(
              icon: const Icon(Icons.person_outline),
              label: AppStrings.profile(lang)),
        ],
      ),
    );
  }
}

Widget _stat(String number, String title) {
  return Column(
    children: [
      Text(number,
          style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold)),
      const SizedBox(height: 5),
      Text(title,
          style: const TextStyle(color: Colors.white70, fontSize: 12)),
    ],
  );
}

Widget _tile(IconData icon, String title, VoidCallback onTap) {
  return Container(
    margin: const EdgeInsets.only(bottom: 12),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(15),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.08),
          blurRadius: 10,
          offset: const Offset(0, 5),
        ),
      ],
    ),
    child: ListTile(
      leading: Icon(icon, color: const Color(0xFFE65100)),
      title: Text(title),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
    ),
  );
}

Widget _profileChip(String label) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
    decoration: BoxDecoration(
      color: Colors.orange.shade50,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: Colors.orange.shade200),
    ),
    child: Text(
      label,
      style: TextStyle(
          color: Colors.orange.shade800, fontWeight: FontWeight.w500),
    ),
  );
}

Widget infoRow(IconData icon, String title, String value) {
  return Row(
    children: [
      Icon(icon, color: Colors.orange.shade700, size: 22),
      const SizedBox(width: 12),
      Text(
        "$title: ",
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
      ),
      Expanded(
        child: Text(value, style: TextStyle(color: Colors.grey.shade700)),
      ),
    ],
  );
}
