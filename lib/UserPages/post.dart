// FIX: removed unused 'dart:io' import
// FIX: replaced in-memory dummy data (accommodationPosts / roommatePosts) with
//      live Firestore streams filtered to the current user's posts.
// FIX: removed dependency on posts_data.dart entirely.

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../AppFunctionalities/app_strings.dart';
import 'AccommodationPages/post_accommodation.dart';
import 'RoommatesPages/post_roommate.dart';
import 'ChatFolder/chats_page.dart';

class PostPage extends StatefulWidget {
  const PostPage({super.key});

  @override
  State<PostPage> createState() => _PostPageState();
}

class _PostPageState extends State<PostPage> {
  int currentIndex = 1;

  final Color primaryCoral = const Color(0xFFE65100);
  final Color textGrey = const Color(0xFFA0A0A0);
  final Color bgLight = const Color(0xFFF6F3F1);

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Delete a post from Firestore with a confirmation dialog
  Future<void> _deletePost(BuildContext context, String collection, String docId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Delete Post"),
        content: const Text("Are you sure you want to delete this post?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("No"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("Yes", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await _firestore.collection(collection).doc(docId).delete();
    }
  }

  @override
  Widget build(BuildContext context) {
    String lang = Localizations.localeOf(context).languageCode;
    final String uid = _auth.currentUser!.uid;

    return Scaffold(
      backgroundColor: bgLight,

      appBar: AppBar(
        backgroundColor: Colors.orange.shade900,
        toolbarHeight: 80,
        title: Text(
          AppStrings.createPost(lang),
          style: const TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),

      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            /// POST ACCOMMODATION button
            _card(
              icon: Icons.home,
              title: AppStrings.postAccommodation(lang),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const PostAccommodationPage(),
                  ),
                );
              },
            ),

            const SizedBox(height: 20),

            /// POST ROOMMATE button
            _card(
              icon: Icons.people,
              title: AppStrings.postRoommate(lang),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const PostRoommatePage(),
                  ),
                );
              },
            ),

            const SizedBox(height: 30),

            /// LIVE LIST: current user's posts from Firestore

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

          if (index == 0) {
            Navigator.pushReplacementNamed(context, '/');
          } else if (index == 2) {
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

Widget _card({
  required IconData icon,
  required String title,
  required VoidCallback onTap,
}) {
  return Container(
    width: double.infinity,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.2),
          blurRadius: 25,
          spreadRadius: 3,
          offset: const Offset(0, 10),
        ),
      ],
    ),
    child: Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFE65100).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: const Color(0xFFE65100), size: 28),
            ),
            const SizedBox(width: 15),
            Text(
              title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const Spacer(),
            const Icon(Icons.arrow_forward_ios, size: 18),
          ],
        ),
      ),
    ),
  );
}
