import 'package:flutter/material.dart';
import '../AccommodationPages/post_accommodation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../RoommatesPages/edit_roommate.dart';


class MyPostsPage extends StatefulWidget {
  const MyPostsPage({super.key});

  @override
  State<MyPostsPage> createState() => _MyPostsPageState();
}

class _MyPostsPageState extends State<MyPostsPage> {
  final FirebaseAuth auth = FirebaseAuth.instance;
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  bool showAccommodation = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff7f4f2),
      appBar: AppBar(
        backgroundColor: Colors.orange.shade900,
        elevation: 0,
        title: const Text(
          "My Posts",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Column(
        children: [
          /// TOP BUTTONS
          Padding(
            padding: const EdgeInsets.all(15),
            child: Row(
              children: [
                Expanded(
                  child: buildTopButton(
                    title: "Accommodation",
                    selected: showAccommodation,
                    onTap: () {
                      setState(() {
                        showAccommodation = true;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: buildTopButton(
                    title: "Roommates",
                    selected: !showAccommodation,
                    onTap: () {
                      setState(() {
                        showAccommodation = false;
                      });
                    },
                  ),
                ),
              ],
            ),
          ),

          /// POSTS
          Expanded(
            child: StreamBuilder(
              // 🔥 THE FIX: ValueKey forces Flutter to rebuild the list from scratch
              // when switching tabs, preventing the RangeError.
              key: ValueKey(showAccommodation),
              stream: showAccommodation
                  ? firestore
                  .collection("roomListings")
                  .where(
                "userId",
                isEqualTo: auth.currentUser!.uid,
              )
                  .snapshots()
                  : firestore
                  .collection("roommateRequests")
                  .where(
                "userId",
                isEqualTo: auth.currentUser!.uid,
              )
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                var posts = snapshot.data!.docs;

                if (posts.isEmpty) {
                  return const Center(
                    child: Text(
                      "No Posts Yet",
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(15),
                  itemCount: posts.length,
                  itemBuilder: (context, index) {
                    var post = posts[index];

                    // Safely cast data to Map
                    Map<String, dynamic> postData = post.data() as Map<String, dynamic>? ?? {};

                    return Container(
                      margin: const EdgeInsets.only(bottom: 15),
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(22),
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
                          /// IMAGE
                          ClipRRect(
                            borderRadius: BorderRadius.circular(18),
                            child: (postData["image"] ?? "") != ""
                                ? Image.network(
                              postData["image"],
                              height: 180,
                              width: double.infinity,
                              fit: BoxFit.cover,
                            )
                                : Container(
                              height: 180,
                              color: Colors.orange.shade100,
                              child: const Center(
                                child: Icon(
                                  Icons.image,
                                  size: 60,
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 15),

                          Text(
                            showAccommodation
                                ? "${postData["city"] ?? "Unknown"} • ${postData["type"] ?? "Property"}"
                                : "${postData["gender"] ?? "Any"} • ${postData["religion"] ?? "Any"}",
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          const SizedBox(height: 8),

                          Text(
                            showAccommodation
                                ? "${postData["priceMin"] ?? 0} - ${postData["priceMax"] ?? 0} JD"
                                : "Age ${postData["ageMin"] ?? 18} - ${postData["ageMax"] ?? 70}",
                            style: TextStyle(
                              color: Colors.grey.shade700,
                            ),
                          ),

                          const SizedBox(height: 18),

                          /// BUTTONS
                          Row(
                            children: [
                              Expanded(
                                child: buildActionButton(
                                  title: "Edit",
                                  icon: Icons.edit,
                                  color: Colors.orange,
                                  onTap: () {
                                    if (showAccommodation) {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => PostAccommodationPage(
                                            postId: post.id, // Explicitly passes the document ID string
                                            postData: postData, // Passes existing fields
                                          ),
                                        ),
                                      );
                                    } else {

                                      Navigator.push(

                                        context,

                                        MaterialPageRoute(

                                          builder: (context) => EditRoommatePage(

                                            postData: post.data(),

                                          ),

                                        ),

                                      );

                                    }
                                  },
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: buildActionButton(
                                  title: "Delete",
                                  icon: Icons.delete,
                                  color: Colors.red,
                                  onTap: () async {
                                    bool? confirm = await showDialog(
                                      context: context,
                                      builder: (context) {
                                        return AlertDialog(
                                          title: const Text("Delete Post"),
                                          content: const Text(
                                            "Are you sure you want to delete this post?",
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed: () {
                                                Navigator.pop(context, false);
                                              },
                                              child: const Text("Cancel"),
                                            ),
                                            TextButton(
                                              onPressed: () {
                                                Navigator.pop(context, true);
                                              },
                                              child: const Text(
                                                "Delete",
                                                style: TextStyle(color: Colors.red),
                                              ),
                                            ),
                                          ],
                                        );
                                      },
                                    );

                                    if (confirm == true) {
                                      await firestore
                                          .collection(
                                          showAccommodation ? "roomListings" : "roommateRequests")
                                          .doc(post.id)
                                          .delete();
                                    }
                                  },
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// TOP BUTTON
  Widget buildTopButton({
    required String title,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: selected ? Colors.orange.shade900 : Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(
          child: Text(
            title,
            style: TextStyle(
              color: selected ? Colors.white : Colors.black,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  /// ACTION BUTTON
  Widget buildActionButton({
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(15),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: Colors.white,
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}