import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../ChatFolder/chat_screen.dart';
import 'package:flutter/services.dart';

class AccommodationDetailsPage extends StatefulWidget {
  final Map<String, dynamic> post;

  const AccommodationDetailsPage({super.key, required this.post});

  @override
  State<AccommodationDetailsPage> createState() =>
      _AccommodationDetailsPageState();
}

class _AccommodationDetailsPageState extends State<AccommodationDetailsPage> {
  final FirebaseAuth auth = FirebaseAuth.instance;
  final FirebaseFirestore firestore = FirebaseFirestore.instance;



  Future<String> createChat() async {
    String currentUserId = auth.currentUser!.uid;
    String otherUserId = widget.post["userId"];

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

    // FIX: fetch current user's real name from Firestore instead of using email
    String currentUserName = auth.currentUser!.email ?? "";
    DocumentSnapshot currentUserDoc =
    await firestore.collection("users").doc(currentUserId).get();
    if (currentUserDoc.exists) {
      var data = currentUserDoc.data() as Map<String, dynamic>;
      String first = data["firstName"] ?? "";
      String last = data["lastName"] ?? "";
      currentUserName = "$first $last".trim();
      if (currentUserName.isEmpty)
        currentUserName = auth.currentUser!.email ?? "";
    }

    // FIX: fetch the listing owner's real name from Firestore
    // widget.post["name"] doesn't exist in roomListings schema — look up by userId
    String otherUserName = "User";
    DocumentSnapshot otherUserDoc =
    await firestore.collection("users").doc(otherUserId).get();
    if (otherUserDoc.exists) {
      var data = otherUserDoc.data() as Map<String, dynamic>;
      String first = data["firstName"] ?? "";
      String last = data["lastName"] ?? "";
      otherUserName = "$first $last".trim();
      if (otherUserName.isEmpty) otherUserName = "User";
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
                child: StreamBuilder<QuerySnapshot>(
                  stream: firestore
                      .collection("favoritesAccommodation")
                      .where("userId", isEqualTo: auth.currentUser!.uid)
                      .where("postId", isEqualTo: widget.post["postId"])
                      .snapshots(),
                  builder: (context, snapshot) {
                    final bool isFav = snapshot.hasData &&
                        snapshot.data!.docs.isNotEmpty;
                    return CircleAvatar(
                      backgroundColor: Colors.white,
                      child: IconButton(
                        icon: Icon(
                          isFav ? Icons.favorite : Icons.favorite_border,
                          color: isFav ? Colors.red : Colors.black,
                        ),
                        onPressed: () async {
                          if (isFav) {
                            // Remove from favourites
                            final docId =
                                snapshot.data!.docs.first.id;
                            await firestore
                                .collection("favoritesAccommodation")
                                .doc(docId)
                                .delete();
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text("Removed from Favorites")),
                              );
                            }
                          } else {
                            // Add to favourites
                            await firestore
                                .collection("favoritesAccommodation")
                                .add({
                              "userId": auth.currentUser!.uid,
                              "postId": widget.post["postId"],
                              "createdAt": Timestamp.now(),
                            });
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text("Added to Favorites")),
                              );
                            }
                          }
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: (widget.post["image"] ?? "") != ""
                  ? Image.network(
                widget.post["image"],
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.orange.shade100,
                    child: const Center(
                      child:
                      Icon(Icons.broken_image_outlined, size: 70),
                    ),
                  );
                },
              )
                  : Container(
                color: Colors.orange.shade100,
                child: const Center(
                  child: Icon(Icons.home_work_outlined, size: 80),
                ),
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
                  topRight: Radius.circular(30),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // TYPE badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 7),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade100,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      widget.post["type"] ?? "",
                      style: TextStyle(
                          color: Colors.orange.shade800,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 18),

                  // CITY
                  Text(
                    widget.post["city"] ?? "",
                    style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Color(0xff1B1F3B)),
                  ),
                  const SizedBox(height: 10),

                  // STREET
                  Row(
                    children: [
                      Icon(Icons.location_on_outlined,
                          color: Colors.grey.shade700),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          widget.post["street"] ?? "",
                          style: TextStyle(
                              color: Colors.grey.shade700, fontSize: 16),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 25),

                  // PRICE + ACTION BUTTONS
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "${widget.post["priceMin"]} - ${widget.post["priceMax"]} JD",
                              style: TextStyle(
                                  fontSize: 30,
                                  color: Colors.orange.shade700,
                                  fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 5),
                            Text("per month",
                                style:
                                TextStyle(color: Colors.grey.shade700)),
                          ],
                        ),
                      ),



                      const SizedBox(width: 12),

                      // Call button (Fetches phone number from user's document)
                      buildActionButton(Icons.call_outlined, () async {
                        String otherUserId = widget.post["userId"] ?? "";

                        if (otherUserId.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("User ID not found for this listing")),
                          );
                          return;
                        }

                        try {
                          // Fetch the owner's user document from Firestore
                          DocumentSnapshot userDoc =
                          await firestore.collection("users").doc(otherUserId).get();

                          if (userDoc.exists && userDoc.data() != null) {
                            var data = userDoc.data() as Map<String, dynamic>;
                            String phone = (data["phone"] ?? "").toString().trim();

                            if (!mounted) return;

                            if (phone.isNotEmpty) {
                              // Show Popup Dialog with Copy Action
                              showDialog(
                                context: context,
                                builder: (BuildContext context) {
                                  return AlertDialog(
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    title: const Text(
                                      "Contact Number",
                                      style: TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                    content: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            phone,
                                            style: const TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.w500,
                                              color: Color(0xff1B1F3B),
                                            ),
                                          ),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.copy, color: Colors.orange),
                                          tooltip: "Copy to clipboard",
                                          onPressed: () {
                                            Clipboard.setData(ClipboardData(text: phone));
                                            Navigator.pop(context); // Close the dialog
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              const SnackBar(
                                                content: Text("Phone number copied to clipboard!"),
                                                duration: Duration(seconds: 2),
                                              ),
                                            );
                                          },
                                        ),
                                      ],
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(context),
                                        child: const Text(
                                          "Close",
                                          style: TextStyle(color: Colors.orange, fontSize: 16),
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              );
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text("Phone number not shared by user")),
                              );
                            }
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("User profile not found")),
                            );
                          }
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text("Error fetching phone number: $e")),
                          );
                        }
                      }),
                    ],
                  ),
                  const SizedBox(height: 30),

                  // INFO CARDS
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
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        buildInfoItem(Icons.meeting_room_outlined,
                            widget.post["rooms"] ?? "-", "Rooms"),
                        buildInfoItem(Icons.bathtub_outlined,
                            widget.post["baths"] ?? "-", "Baths"),
                        buildInfoItem(Icons.square_foot_outlined,
                            widget.post["space"] ?? "-", "m²"),
                        buildInfoItem(Icons.calendar_month_outlined,
                            widget.post["date"] ?? "-", "Added"),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),

                  // CLOSE TO
                  buildSectionTitle(
                      Icons.location_city_outlined, "Close To"),
                  const SizedBox(height: 10),
                  Text(
                    widget.post["closeTo"] ?? "",
                    style: const TextStyle(fontSize: 16, height: 1.5),
                  ),
                  const SizedBox(height: 30),

                  // DESCRIPTION
                  buildSectionTitle(
                      Icons.description_outlined, "Description"),
                  const SizedBox(height: 10),
                  Text(
                    widget.post["description"] ?? "",
                    style: const TextStyle(fontSize: 16, height: 1.7),
                  ),
                  const SizedBox(height: 40),

                  // MAIN BUTTONS
                  Row(
                    children: [

                      const SizedBox(width: 15),
                      Expanded(
                        child: buildMainButton(
                          title: "Chat Now",
                          icon: Icons.chat_bubble_outline,
                          color: Colors.orange,
                          textColor: Colors.white,
                          onTap: () async {
                            String chatId = await createChat();
                            String otherUserId = widget.post["userId"];
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

  Widget buildActionButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 55,
        height: 55,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 15,
                offset: const Offset(0, 8))
          ],
        ),
        child: Icon(icon, size: 26),
      ),
    );
  }

  Widget buildInfoItem(IconData icon, String value, String title) {
    return Column(
      children: [
        Icon(icon, color: Colors.orange, size: 28),
        const SizedBox(height: 10),
        Text(value,
            style: const TextStyle(
                fontWeight: FontWeight.bold, fontSize: 18)),
        const SizedBox(height: 5),
        Text(title, style: TextStyle(color: Colors.grey.shade700)),
      ],
    );
  }

  Widget buildSectionTitle(IconData icon, String title) {
    return Row(
      children: [
        Icon(icon, color: Colors.orange),
        const SizedBox(width: 10),
        Text(title,
            style:
            const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
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
