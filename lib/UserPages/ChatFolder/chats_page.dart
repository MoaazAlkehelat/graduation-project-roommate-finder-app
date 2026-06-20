import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../AppFunctionalities/app_strings.dart';
import 'chat_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// HOW ONLINE STATUS WORKS
// Each user's document in the "users" collection should have two fields:
//   isOnline : bool       → true while the app is open, false when closed
//   lastSeen : Timestamp  → set when the user goes offline
//
// You should call the helper below from your app's lifecycle (main.dart or
// whichever widget wraps your routes):
//
//   // When app comes to foreground / user logs in:
//   OnlineStatusHelper.setOnline();
//
//   // When app goes to background / user logs out:
//   OnlineStatusHelper.setOffline();
//
// ─────────────────────────────────────────────────────────────────────────────

// ─────────────────────────────────────────────────────────────────────────────
// NEW IN THIS VERSION
//  • Unread badge: each chat tile shows a red circle with the count of unseen
//    messages sent by the other user (senderId != myUid && isSeen == false)
//  • Block filter: chats where the other user is in the current user's
//    `blocks` collection are hidden from the list
// ─────────────────────────────────────────────────────────────────────────────

class OnlineStatusHelper {
  static final _auth = FirebaseAuth.instance;
  static final _firestore = FirebaseFirestore.instance;

  static Future<void> setOnline() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    await _firestore.collection("users").doc(uid).update({
      "isOnline": true,
    });
  }

  static Future<void> setOffline() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    await _firestore.collection("users").doc(uid).update({
      "isOnline": false,
      "lastSeen": Timestamp.now(),
    });
  }
}

class ChatsPage extends StatefulWidget {
  const ChatsPage({super.key});

  @override
  State<ChatsPage> createState() => _ChatsPageState();
}

class _ChatsPageState extends State<ChatsPage> with WidgetsBindingObserver {
  int currentIndex = 2;

  final Color textGrey = const Color(0xFFA0A0A0);
  final FirebaseAuth auth = FirebaseAuth.instance;
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  // Cache of blocked user IDs so we don't re-fetch on every rebuild
  Set<String> _blockedIds = {};
  bool _blocksLoaded = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _setOnline(); // mark current user online when chats page opens
    _loadBlockedUsers();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _setOnline();
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.detached) {
      _setOffline();
    }
  }

  Future<void> _setOnline() async {
    final uid = auth.currentUser?.uid;
    if (uid == null) return;
    await firestore.collection("users").doc(uid).update({"isOnline": true});
  }

  Future<void> _setOffline() async {
    final uid = auth.currentUser?.uid;
    if (uid == null) return;
    await firestore.collection("users").doc(uid).update({
      "isOnline": false,
      "lastSeen": Timestamp.now(),
    });
  }

  /// Fetch the list of UIDs that the current user has blocked.
  Future<void> _loadBlockedUsers() async {
    final myUid = auth.currentUser?.uid;
    if (myUid == null) return;

    final snap = await firestore
        .collection("blocks")
        .where("blockerId", isEqualTo: myUid)
        .get();

    final ids = snap.docs
        .map((d) => (d.data()["blockedId"] as String?) ?? "")
        .where((id) => id.isNotEmpty)
        .toSet();

    if (mounted) {
      setState(() {
        _blockedIds = ids;
        _blocksLoaded = true;
      });
    }
  }

  // Format lastMessageTime timestamp
  String _formatTime(dynamic ts) {
    if (ts == null) return '';
    final dt = (ts as Timestamp).toDate();
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'Now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) {
      final h = dt.hour.toString().padLeft(2, '0');
      final m = dt.minute.toString().padLeft(2, '0');
      return '$h:$m';
    }
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  // Format lastSeen timestamp for offline users
  String _formatLastSeen(dynamic ts) {
    if (ts == null) return 'Offline';
    final dt = (ts as Timestamp).toDate();
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'Last seen just now';
    if (diff.inMinutes < 60) return 'Last seen ${diff.inMinutes}m ago';
    if (diff.inHours < 24) {
      final h = dt.hour.toString().padLeft(2, '0');
      final m = dt.minute.toString().padLeft(2, '0');
      return 'Last seen at $h:$m';
    }
    return 'Last seen ${dt.day}/${dt.month}/${dt.year}';
  }

  // Delete an entire chat (the chat doc + all its messages subcollection)
  Future<void> _deleteChat(BuildContext context, String chatDocId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Delete Chat"),
        content: const Text(
            "This will permanently delete the entire conversation. Are you sure?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("Delete",
                style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    // Delete all messages in the subcollection first
    final messages = await firestore
        .collection("chats")
        .doc(chatDocId)
        .collection("messages")
        .get();
    for (final msg in messages.docs) {
      await msg.reference.delete();
    }

    // Then delete the chat document itself
    await firestore.collection("chats").doc(chatDocId).delete();
  }

  // ── Unread badge widget ──────────────────────────────────────────────────

  /// Streams ALL unseen messages in a chat, then filters in Dart to count
  /// only those sent by the OTHER user. This avoids needing a composite
  /// Firestore index (isNotEqualTo + isEqualTo together requires one).
  Widget _buildUnreadBadge(String chatId, String myUid) {
    return StreamBuilder<QuerySnapshot>(
      stream: firestore
          .collection("chats")
          .doc(chatId)
          .collection("messages")
          .where("isSeen", isEqualTo: false)
          .snapshots(),
      builder: (context, snap) {
        if (!snap.hasData) return const SizedBox.shrink();

        // Filter in Dart: only count messages NOT sent by me
        final count = snap.data!.docs
            .where((d) =>
        (d.data() as Map<String, dynamic>)["senderId"] != myUid)
            .length;

        if (count == 0) return const SizedBox.shrink();

        return Container(
          constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.red,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            count > 99 ? "99+" : "$count",
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final String myUid = auth.currentUser!.uid;
    String lang = Localizations.localeOf(context).languageCode;

    return Scaffold(
      backgroundColor: const Color(0xfff7f4f2),

      appBar: AppBar(
        backgroundColor: Colors.orange.shade900,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Text(
          AppStrings.chat(lang),
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      body: !_blocksLoaded
          ? const Center(child: CircularProgressIndicator())
          : StreamBuilder<QuerySnapshot>(
        stream: firestore
            .collection("chats")
            .where("users", arrayContains: myUid)
            .orderBy("lastMessageTime", descending: true)
            .snapshots(),

        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text(snapshot.error.toString()));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          // Filter out chats where the other user is blocked
          final allChats = snapshot.data!.docs;
          final chats = allChats.where((chat) {
            final List users = (chat["users"] ?? [])
                .where((e) => e != null)
                .toList();
            final String otherId = users.isNotEmpty
                ? users.firstWhere(
                  (u) => u != myUid,
              orElse: () => "",
            )
                : "";
            return !_blockedIds.contains(otherId);
          }).toList();

          if (chats.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.chat_bubble_outline,
                      size: 80, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  Text("No chats yet",
                      style: TextStyle(
                          fontSize: 18, color: Colors.grey.shade500)),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(15),
            itemCount: chats.length,
            itemBuilder: (context, index) {
              final chat = chats[index];

              final List users = (chat["users"] ?? [])
                  .where((e) => e != null)
                  .toList();

              final String otherUserId = users.isNotEmpty
                  ? users.firstWhere(
                    (u) => u != myUid,
                orElse: () => "",
              )
                  : "";

              return StreamBuilder<DocumentSnapshot>(
                // Stream the other user's doc to get live online status
                stream: firestore
                    .collection("users")
                    .doc(otherUserId)
                    .snapshots(),
                builder: (context, userSnap) {
                  if (!userSnap.hasData) return const SizedBox();

                  final userData =
                      userSnap.data!.data() as Map<String, dynamic>? ?? {};

                  final String fullName =
                  "${userData["firstName"] ?? ""} ${userData["lastName"] ?? ""}"
                      .trim();
                  final String image =
                      userData["profileImage"]?.toString() ?? "";
                  final bool isOnline = userData["isOnline"] == true;
                  final dynamic lastSeen = userData["lastSeen"];

                  // Swipe-to-delete
                  return Dismissible(
                    key: Key(chat.id),
                    direction: DismissDirection.endToStart,
                    confirmDismiss: (_) async {
                      await _deleteChat(context, chat.id);
                      return false; // we handle deletion manually above
                    },
                    background: Container(
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 20),
                      margin: const EdgeInsets.only(bottom: 15),
                      decoration: BoxDecoration(
                        color: Colors.red.shade400,
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: const Icon(Icons.delete_outline,
                          color: Colors.white, size: 30),
                    ),
                    child: GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ChatScreen(
                              chatId: chat.id,
                              otherUserId: otherUserId,
                            ),
                          ),
                        );
                      },
                      child: Container(
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
                        child: Row(
                          children: [
                            /// AVATAR + online dot
                            Stack(
                              children: [
                                CircleAvatar(
                                  radius: 30,
                                  backgroundColor: Colors.orange.shade100,
                                  backgroundImage: image != ""
                                      ? NetworkImage(image)
                                      : null,
                                  child: image == ""
                                      ? Text(
                                    fullName.isNotEmpty
                                        ? fullName[0].toUpperCase()
                                        : "?",
                                    style: TextStyle(
                                      color: Colors.orange.shade900,
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  )
                                      : null,
                                ),
                                // Online / offline indicator dot
                                Positioned(
                                  bottom: 0,
                                  right: 0,
                                  child: Container(
                                    width: 15,
                                    height: 15,
                                    decoration: BoxDecoration(
                                      color: isOnline
                                          ? Colors.green
                                          : Colors.grey.shade400,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                          color: Colors.white, width: 2),
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(width: 15),

                            /// Name + last message + online/last-seen label
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    fullName.isEmpty ? "User" : fullName,
                                    style: const TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  // Online status text
                                  Text(
                                    isOnline
                                        ? "Online"
                                        : _formatLastSeen(lastSeen),
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: isOnline
                                          ? Colors.green
                                          : Colors.grey.shade500,
                                      fontWeight: isOnline
                                          ? FontWeight.w600
                                          : FontWeight.normal,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    chat["lastMessage"]?.toString() ?? "",
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                        color: Colors.grey.shade700,
                                        fontSize: 13),
                                  ),
                                ],
                              ),
                            ),

                            /// Last message timestamp + unread badge + delete button
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  _formatTime(chat["lastMessageTime"]),
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                // ── Unread badge ──────────────
                                _buildUnreadBadge(chat.id, myUid),
                                const SizedBox(height: 6),
                                // Delete button
                                GestureDetector(
                                  onTap: () =>
                                      _deleteChat(context, chat.id),
                                  child: Icon(Icons.delete_outline,
                                      size: 20,
                                      color: Colors.red.shade300),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
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
          } else if (index == 3) {
            Navigator.pushReplacementNamed(context, '/profile');
          }
        },
        items: [
          BottomNavigationBarItem(
              icon: const Icon(Icons.home), label: AppStrings.home(lang)),
          BottomNavigationBarItem(
              icon: const Icon(Icons.add_circle_outline),
              label: AppStrings.post(lang)),
          BottomNavigationBarItem(
              icon: const Icon(Icons.chat), label: AppStrings.chat(lang)),
          BottomNavigationBarItem(
              icon: const Icon(Icons.person_outline),
              label: AppStrings.profile(lang)),
        ],
      ),
    );
  }
}
