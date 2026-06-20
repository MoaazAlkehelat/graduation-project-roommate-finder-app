import 'package:flutter/material.dart';
import '../main.dart';
import '../AppFunctionalities/app_strings.dart';
import 'ProfileFunctionalities/favorites.dart';
import 'ChatFolder/chats_page.dart';
import 'notifications_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'RoommatesPages/roommate_details.dart';

class homepage extends StatefulWidget {
  const homepage({super.key});

  @override
  State<homepage> createState() => _homepageState();
}

class _homepageState extends State<homepage> {

  int currentIndex = 0;

  final Color primaryCoral = const Color(0xFFE65100);
  final Color bgLight = const Color(0xFFF8F9FA);
  final Color textDark = const Color(0xFF5A5A5A);
  final Color textGrey = const Color(0xFFA0A0A0);
  final Color iconTeal = const Color(0xFF67C2A6);
  final Color textNude = const Color(0xFFD0AB99);

  Map<String, dynamic>? currentUserData;

  Future<void> loadCurrentUser() async {
    String uid = FirebaseAuth.instance.currentUser!.uid;
    var doc = await FirebaseFirestore.instance
        .collection("users")
        .doc(uid)
        .get();
    if (doc.exists) {
      setState(() {
        currentUserData = doc.data() as Map<String, dynamic>;
      });
    }
  }

  // -------------------------------------------------------------------
  // Matching algorithm
  // Weights:  Area 35%  |  City 10%  |  Lifestyle 25%  |  Hobbies 20%
  //           Religion  5%  |  Status  5%
  // -------------------------------------------------------------------
  // Area and city are stored on the users doc, not on the post.
  // We fetch the poster's area and city from Firestore to compare.
  Future<double> calculateMatchScore(
      Map<String, dynamic> user,
      Map<String, dynamic> request,
      ) async {
    double score = 0;

    // ── Area (35 pts) + City (10 pts) ───────────────────────────────
    final String? posterId = request["userId"] as String?;
    if (posterId != null) {
      try {
        final posterDoc = await FirebaseFirestore.instance
            .collection("users")
            .doc(posterId)
            .get();
        if (posterDoc.exists) {
          final posterData = posterDoc.data() as Map<String, dynamic>;

          final String myArea =
          (user["area"] as String? ?? "").trim().toLowerCase();
          final String posterArea =
          (posterData["area"] as String? ?? "").trim().toLowerCase();
          if (myArea.isNotEmpty && posterArea.isNotEmpty && myArea == posterArea) {
            score += 35;
          }

          final String myCity =
          (user["city"] as String? ?? "").trim().toLowerCase();
          final String posterCity =
          (posterData["city"] as String? ?? "").trim().toLowerCase();
          if (myCity.isNotEmpty && posterCity.isNotEmpty && myCity == posterCity) {
            score += 10;
          }
        }
      } catch (_) {
        // If fetch fails, skip location scores — don't crash
      }
    }

    // ── Lifestyle (25 pts) ──────────────────────────────────────────
    // Proportional: (common items / user's items) × 25
    final List userLifestyle = user["lifestyle"] ?? [];
    final List requestLifestyle = request["lifestyle"] ?? [];
    if (userLifestyle.isNotEmpty) {
      final int common = userLifestyle
          .where((item) => requestLifestyle.contains(item))
          .length;
      score += (common / userLifestyle.length) * 25;
    }

    // ── Hobbies (20 pts) ────────────────────────────────────────────
    // Proportional: (common items / user's items) × 20
    final List userHobbies = user["hobbies"] ?? [];
    final List requestHobbies = request["hobbies"] ?? [];
    if (userHobbies.isNotEmpty) {
      final int common = userHobbies
          .where((item) => requestHobbies.contains(item))
          .length;
      score += (common / userHobbies.length) * 20;
    }

    // ── Religion (5 pts) ────────────────────────────────────────────
    if ((user["religion"] as String? ?? "").isNotEmpty &&
        user["religion"] == request["religion"]) {
      score += 5;
    }

    // ── Status (5 pts) ──────────────────────────────────────────────
    if ((user["status"] as String? ?? "").isNotEmpty &&
        user["status"] == request["status"]) {
      score += 5;
    }

    return score;
  }

  // Fetch all roommate requests, score them, and return top 3.
  // Always returns up to 3 results — sorted by score descending.
  // Posts with score 0 are excluded so only relevant matches show.
  Future<List<Map<String, dynamic>>> _loadTopMatches() async {
    final String currentUserId = FirebaseAuth.instance.currentUser!.uid;
    final snapshot = await FirebaseFirestore.instance
        .collection("roommateRequests")
        .get();

    final List<Map<String, dynamic>> scored = [];

    for (final doc in snapshot.docs) {
      final request = doc.data();
      // Skip own posts
      if (request["userId"] == currentUserId) continue;

      final double score =
      await calculateMatchScore(currentUserData!, request);

      // Only include posts with at least some match (score > 0)
      if (score > 0) {
        scored.add({"request": request, "score": score});
      }
    }

    // Sort highest score first, always return top 3
    scored.sort((a, b) =>
        (b["score"] as double).compareTo(a["score"] as double));
    return scored.take(3).toList();
  }

  @override
  void initState() {
    super.initState();
    loadCurrentUser();
  }

  @override
  Widget build(BuildContext context) {
    String lang = Localizations.localeOf(context).languageCode;

    if (currentUserData == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: bgLight,
      body: Column(
        children: [

          // ── Header ─────────────────────────────────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.only(
                top: 50, bottom: 40, left: 20, right: 20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.orange.shade900,
                  Colors.orange.shade800,
                  Colors.orange.shade400,
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
                    const SizedBox(),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.favorite, color: Colors.white70),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const FavoritesPage(),
                              ),
                            );
                          },
                        ),
                        const SizedBox(width: 10),
                        IconButton(
                          icon: const Icon(Icons.notifications_active,
                              color: Colors.white70),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => NotificationsPage(),
                              ),
                            );
                          },
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
                  ],
                ),
                const SizedBox(height: 20),
                Image.asset('assets/Logo2.png', width: 100, height: 100),
                const SizedBox(height: 10),
                Text(AppStrings.findYourPerfect(lang),
                    style: const TextStyle(color: Colors.white)),
                Text(
                  AppStrings.roommate(lang),
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),

          // ── Nav Cards ──────────────────────────────────────────────
          Flexible(
            child: GridView.count(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              crossAxisCount: 2,
              crossAxisSpacing: 20,
              mainAxisSpacing: 20,
              childAspectRatio: 1.1,
              shrinkWrap: true,
              children: [
                _card(
                  AppStrings.accommodation(lang),
                  Icons.home,
                  primaryCoral,
                  textDark,
                      () => Navigator.pushNamed(context, '/accommodation'),
                ),
                _card(
                  AppStrings.roommates(lang),
                  Icons.people,
                  iconTeal,
                  textDark,
                      () => Navigator.pushNamed(context, '/findRoommate'),
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // ── Services Button ────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.orange.shade900,
                borderRadius: BorderRadius.circular(20),
              ),
              child: TextButton(
                onPressed: () => Navigator.pushNamed(context, '/services'),
                child: Text(
                  AppStrings.services(lang),
                  style: const TextStyle(fontSize: 18, color: Colors.white),
                ),
              ),
            ),
          ),

          // ── Top Matches Section ────────────────────────────────────
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(20),
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "🔥 Top Roommate Matches",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 15),
                  Expanded(
                    // FutureBuilder: scores are async (location fetch per post)
                    child: FutureBuilder<List<Map<String, dynamic>>>(
                      future: _loadTopMatches(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(
                              child: CircularProgressIndicator());
                        }
                        if (!snapshot.hasData || snapshot.data!.isEmpty) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.people_outline,
                                    size: 48, color: Colors.grey.shade300),
                                const SizedBox(height: 12),
                                Text(
                                  "No matches found yet.",
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  "Fill in your area, city, lifestyle\nand hobbies to find matches.",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                      color: Colors.grey.shade400,
                                      fontSize: 12),
                                ),
                              ],
                            ),
                          );
                        }

                        final matches = snapshot.data!;
                        return ListView.builder(
                          itemCount: matches.length,
                          itemBuilder: (context, index) {
                            final match = matches[index];
                            final request =
                            match["request"] as Map<String, dynamic>;
                            final score = match["score"] as double;

                            return InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        RoommateDetailsPage(request: request),
                                  ),
                                );
                              },
                              child: Card(
                                margin: const EdgeInsets.only(bottom: 10),
                                child: ListTile(
                                  leading: CircleAvatar(
                                    radius: 24,
                                    backgroundImage:
                                    request["image"] != null &&
                                        request["image"] != ""
                                        ? NetworkImage(request["image"])
                                        : null,
                                    child: request["image"] == null ||
                                        request["image"] == ""
                                        ? const Icon(Icons.person)
                                        : null,
                                  ),
                                  title: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 5,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.green.shade50,
                                          borderRadius:
                                          BorderRadius.circular(10),
                                        ),
                                        child: Text(
                                          "${score.toInt()}% Match",
                                          style: TextStyle(
                                            color: Colors.green.shade800,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  subtitle: Padding(
                                    padding: const EdgeInsets.only(top: 8),
                                    child: Text(
                                      "${request["religion"] ?? ""}",
                                      style: TextStyle(
                                        color: Colors.grey.shade600,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                  trailing: const Icon(Icons.arrow_forward_ios,
                                      size: 16),
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
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
          if (index == 0) return;
          if (index == 1) {
            Navigator.pushNamed(context, '/post');
          } else if (index == 2) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ChatsPage()),
            );
          } else if (index == 3) {
            Navigator.pushNamed(context, '/profile');
          }
        },
        items: [
          BottomNavigationBarItem(
              icon: const Icon(Icons.home), label: AppStrings.home(lang)),
          BottomNavigationBarItem(
              icon: const Icon(Icons.add), label: AppStrings.post(lang)),
          BottomNavigationBarItem(
              icon: const Icon(Icons.chat), label: AppStrings.chat(lang)),
          BottomNavigationBarItem(
              icon: const Icon(Icons.person), label: AppStrings.profile(lang)),
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
