import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../ChatFolder/chat_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../AccommodationPages/accommodation_details.dart';

class RoommateDetailsPage extends StatefulWidget {
  final Map<String, dynamic> request;

  const RoommateDetailsPage({super.key, required this.request});

  @override
  State<RoommateDetailsPage> createState() => _RoommateDetailsPageState();
}

class _RoommateDetailsPageState extends State<RoommateDetailsPage> {
  final FirebaseAuth auth = FirebaseAuth.instance;
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  Future addToFavorites() async {
    await firestore.collection("favoritesRoommates").add({
      "userId": auth.currentUser!.uid,
      "postId": widget.request["postId"],
      "createdAt": Timestamp.now(),
      // FIX: removed "typing: false" — that field belongs in chats, not favorites
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Added To Favorites")),
    );
  }

  Future<String> createChat() async {
    String currentUserId = auth.currentUser!.uid;
    String otherUserId = widget.request["userId"];

    // Check if chat already exists
    var existingChats = await firestore
        .collection("chats")
        .where("users", arrayContains: currentUserId)
        .get();

    for (var chat in existingChats.docs) {
      List users = chat["users"];
      if (users.contains(otherUserId)) {
        return chat.id;
      }
    }

    // FIX: fetch the current user's real name from Firestore instead of using email
    String currentUserName = auth.currentUser!.email ?? "";
    DocumentSnapshot currentUserDoc =
        await firestore.collection("users").doc(currentUserId).get();
    if (currentUserDoc.exists) {
      var data = currentUserDoc.data() as Map<String, dynamic>;
      String first = data["firstName"] ?? "";
      String last = data["lastName"] ?? "";
      currentUserName = "$first $last".trim();
      if (currentUserName.isEmpty) currentUserName = auth.currentUser!.email ?? "";
    }

    // FIX: fetch the other user's real name from Firestore
    String otherUserName = "Roommate";
    DocumentSnapshot otherUserDoc =
        await firestore.collection("users").doc(otherUserId).get();
    if (otherUserDoc.exists) {
      var data = otherUserDoc.data() as Map<String, dynamic>;
      String first = data["firstName"] ?? "";
      String last = data["lastName"] ?? "";
      otherUserName = "$first $last".trim();
      if (otherUserName.isEmpty) otherUserName = "Roommate";
    }

    var newChat = await firestore.collection("chats").add({
      "users": [currentUserId, otherUserId],
      "userNames": [currentUserName, otherUserName],
      "lastMessage": "",
      "lastMessageTime": Timestamp.now(),
      "typing": {currentUserId: false, otherUserId: false},
    });

    return newChat.id;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff7f4f2),
      body: CustomScrollView(
        slivers: [
          // HERO IMAGE
          SliverAppBar(
            expandedHeight: 320,
            pinned: true,
            backgroundColor: Colors.white,
            elevation: 0,
            leading: Padding(
              padding: const EdgeInsets.all(8),
              child: CircleAvatar(
                backgroundColor: Colors.black.withOpacity(0.35),
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.all(8),
                child: CircleAvatar(
                  backgroundColor: Colors.white,
                  child: IconButton(
                    icon: const Icon(Icons.favorite_border, color: Colors.black),
                    onPressed: () async => await addToFavorites(),
                  ),
                ),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background:
                  widget.request["image"] != "" && widget.request["image"] != null
                      ? Image.network(
                          widget.request["image"],
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: Colors.orange.shade100,
                              child: const Center(
                                  child: Icon(Icons.broken_image_outlined,
                                      size: 70)),
                            );
                          },
                        )
                      : Container(
                          color: Colors.orange.shade100,
                          child: const Center(
                              child: Icon(Icons.person_outline, size: 90)),
                        ),
            ),
          ),

          // CONTENT
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Color(0xfff7f4f2),
                borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(30),
                    topRight: Radius.circular(30)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // STATUS
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 7),
                    decoration: BoxDecoration(
                        color: Colors.orange.shade100,
                        borderRadius: BorderRadius.circular(20)),
                    child: Text(
                      widget.request["status"] ?? "Student",
                      style: TextStyle(
                          color: Colors.orange.shade800,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 18),

                  // GENDER + RELIGION
                  Text(
                    "${widget.request["gender"]} * ${widget.request["religion"]}",
                    style: const TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                        color: Color(0xff1B1F3B)),
                  ),
                  const SizedBox(height: 12),

                  // AGE
                  Row(
                    children: [
                      Icon(Icons.cake_outlined, color: Colors.grey.shade700),
                      const SizedBox(width: 8),
                      Text(
                        "Age ${widget.request["ageMin"]} - ${widget.request["ageMax"]}",
                        style: TextStyle(
                            fontSize: 16, color: Colors.grey.shade700),
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),

                  // INFO CARD
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 20,
                            offset: const Offset(0, 10))
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        buildSectionTitle(Icons.auto_awesome, "Lifestyle"),
                        const SizedBox(height: 15),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          // FIX: null-safe cast — older posts may not have lifestyle field
                          children:
                              (widget.request["lifestyle"] as List? ?? [])
                                  .map((item) {
                            return Chip(
                              label: Text(item.toString()),
                              backgroundColor: Colors.orange.shade50,
                              side: BorderSide.none,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10)),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 20),

                        const Text(
                          "Hobbies",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 10),

                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children:
                          (widget.request["hobbies"] as List? ?? [])
                              .map((item) {
                            return Chip(
                              label: Text(item.toString()),
                              backgroundColor: Colors.blue.shade50,
                              side: BorderSide.none,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 25),
                        buildInfoRow(Icons.calendar_month_outlined, "Posted",
                            widget.request["date"] ?? ""),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),

                  // ABOUT
                  buildSectionTitle(Icons.description_outlined, "About"),
                  const SizedBox(height: 12),
                  Text(
                    widget.request["bio"] ??
                        "Looking for a respectful and clean roommate with similar lifestyle preferences.",
                    style: const TextStyle(fontSize: 16, height: 1.7),
                  ),
                  const SizedBox(height: 45),

                  // DYNAMIC ACCOMMODATION BUTTON
                  if (widget.request["listingId"] != null &&
                      widget.request["listingId"] != "") ...[
                    FutureBuilder<DocumentSnapshot>(
                      future: firestore
                          .collection("roomListings")
                          .doc(widget.request["listingId"])
                          .get(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData || !snapshot.data!.exists) {
                          return const SizedBox.shrink();
                        }
                        var accomData =
                            snapshot.data!.data() as Map<String, dynamic>;

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 15),
                          child: buildMainButton(
                            title: "See Accommodation",
                            icon: Icons.home_work_outlined,
                            color: Colors.white,
                            textColor: Colors.orange.shade900,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      AccommodationDetailsPage(
                                          post: accomData),
                                ),
                              );
                            },
                          ),
                        );
                      },
                    ),
                  ],

                  // INTERACTION BUTTONS
                  Row(
                    children: [
                      // FIX: Match button — shows a dialog instead of doing nothing
                      Expanded(
                        child: buildMainButton(
                          title: "Match",
                          icon: Icons.people_outline,
                          color: Colors.white,
                          textColor: Colors.black,
                          onTap: () {
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text("Send Match Request"),
                                content: const Text(
                                    "Would you like to send a match request to this person?"),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(context),
                                    child: const Text("Cancel"),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      Navigator.pop(context);
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(const SnackBar(
                                              content: Text(
                                                  "Match request sent!")));
                                    },
                                    child: const Text("Send"),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: buildMainButton(
                          title: "Chat Now",
                          icon: Icons.chat_bubble_outline,
                          color: Colors.orange,
                          textColor: Colors.white,
                          onTap: () async {
                            String chatId = await createChat();
                            String otherUserId = widget.request["userId"];
                            if (!mounted) return;
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ChatScreen(
                                    chatId: chatId,
                                    otherUserId: otherUserId),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildSectionTitle(IconData icon, String title) {
    return Row(
      children: [
        Icon(icon, color: Colors.orange),
        const SizedBox(width: 10),
        Text(title,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget buildInfoRow(IconData icon, String title, String value) {
    return Row(
      children: [
        Icon(icon, color: Colors.orange),
        const SizedBox(width: 12),
        Text("$title: ",
            style: const TextStyle(
                fontWeight: FontWeight.bold, fontSize: 16)),
        Expanded(child: Text(value, style: const TextStyle(fontSize: 16))),
      ],
    );
  }

  Widget buildMainButton({
    required String title,
    required IconData icon,
    required Color color,
    required Color textColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 58,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(20),
          border: color == Colors.white
              ? Border.all(color: textColor.withOpacity(0.5), width: 1)
              : null,
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 18,
                offset: const Offset(0, 10))
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: textColor),
            const SizedBox(width: 10),
            Text(title,
                style: TextStyle(
                    color: textColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 17)),
          ],
        ),
      ),
    );
  }
}
