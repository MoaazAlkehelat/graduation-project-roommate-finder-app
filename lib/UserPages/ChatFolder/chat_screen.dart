import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';

class ChatScreen extends StatefulWidget {
  final String chatId;
  final String otherUserId;

  const ChatScreen({
    super.key,
    required this.chatId,
    required this.otherUserId,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with WidgetsBindingObserver {
  final FirebaseAuth auth = FirebaseAuth.instance;
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final FirebaseStorage storage = FirebaseStorage.instance;

  String get chatId => widget.chatId;
  String get myUid => auth.currentUser!.uid;

  final TextEditingController messageController = TextEditingController();
  final ScrollController scrollController = ScrollController();

  bool _isSendingImage = false;

  // ── Lifecycle / online status ─────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _setOnline();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    messageController.dispose();
    scrollController.dispose();
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

  // ── Reply state ───────────────────────────────────────────────────────────
  String? _replyToId;
  String? _replyToText;
  String? _replyToSenderId;
  String? _replyToSenderName; // display name for the reply preview

  // ── Helpers ──────────────────────────────────────────────────────────────

  String _formatMessageTime(dynamic ts) {
    if (ts == null) return '';
    final dt = (ts as Timestamp).toDate();
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  static const List<String> _reactionEmojis = [
    '👍',
    '❤️',
    '😂',
    '😮',
    '😢',
    '😡',
  ];

  // ── Firestore actions ─────────────────────────────────────────────────────

  Future<void> sendMessage() async {
    final text = messageController.text.trim();
    if (text.isEmpty) return;

    messageController.clear();
    await updateTyping(false);

    final Map<String, dynamic> data = {
      "senderId": myUid,
      "message": text,
      "type": "text",
      "timestamp": Timestamp.now(),
      "isSeen": false,
      "reactions": {},
    };

    if (_replyToId != null) {
      data["replyToId"] = _replyToId;
      data["replyToText"] = _replyToText ?? "";
      data["replyToSenderId"] = _replyToSenderId ?? "";
    }

    _clearReply();

    await firestore
        .collection("chats")
        .doc(chatId)
        .collection("messages")
        .add(data);

    await firestore.collection("chats").doc(chatId).update({
      "lastMessage": text,
      "lastMessageTime": Timestamp.now(),
    });

    scrollToBottom();
  }

  Future<void> sendImage() async {
    final picker = ImagePicker();
    final XFile? file = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );
    if (file == null) return;

    setState(() => _isSendingImage = true);

    try {
      final bytes = await file.readAsBytes();
      final fileName = "${myUid}_${DateTime.now().millisecondsSinceEpoch}.jpg";
      final ref = storage
          .ref()
          .child("chat_images")
          .child(chatId)
          .child(fileName);

      await ref.putData(bytes);
      final imageUrl = await ref.getDownloadURL();

      final Map<String, dynamic> data = {
        "senderId": myUid,
        "message": "",
        "imageUrl": imageUrl,
        "type": "image",
        "timestamp": Timestamp.now(),
        "isSeen": false,
        "reactions": {},
      };

      if (_replyToId != null) {
        data["replyToId"] = _replyToId;
        data["replyToText"] = _replyToText ?? "";
        data["replyToSenderId"] = _replyToSenderId ?? "";
      }

      _clearReply();

      await firestore
          .collection("chats")
          .doc(chatId)
          .collection("messages")
          .add(data);

      await firestore.collection("chats").doc(chatId).update({
        "lastMessage": "📷 Photo",
        "lastMessageTime": Timestamp.now(),
      });

      scrollToBottom();
    } catch (e) {
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),

              title: const Row(
                children: [
                  Icon(Icons.verified_outlined, color: Colors.orange),

                  SizedBox(width: 10),

                  Text("Thank You"),
                ],
              ),

              content: const Text(
                "Thank you for helping keep our community safe. "
                    "Your report has been submitted successfully.",
              ),

              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },

                  child: const Text(
                    "OK",
                    style: TextStyle(
                      color: Colors.orange,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      }
    } finally {
      if (mounted) setState(() => _isSendingImage = false);
    }
  }

  Future<void> _showReportDialog(String messageId) async {
    final reasons = [
      "Spam",
      "Harassment",
      "Inappropriate Content",
      "Scam",
      "Other",
    ];

    String selectedReason = reasons[0];

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Report Message"),

          content: StatefulBuilder(
            builder: (context, setState) {
              return DropdownButton<String>(
                value: selectedReason,
                isExpanded: true,

                items:
                reasons.map((reason) {
                  return DropdownMenuItem(
                    value: reason,
                    child: Text(reason),
                  );
                }).toList(),

                onChanged: (value) {
                  setState(() {
                    selectedReason = value!;
                  });
                },
              );
            },
          ),

          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),

            TextButton(
              onPressed: () async {
                final userDoc =
                await firestore
                    .collection("users")
                    .doc(widget.otherUserId)
                    .get();

                final userData = userDoc.data() ?? {};

                final String fullName =
                "${userData["firstName"] ?? ""} ${userData["lastName"] ?? ""}"
                    .trim();

                final messageDoc = await firestore
                    .collection("chats")
                    .doc(chatId)
                    .collection("messages")
                    .doc(messageId)
                    .get();

                final messageData = messageDoc.data() ?? {};

                await firestore.collection("reports").add({

                  "reporterId": myUid,

                  "reportedUserId": widget.otherUserId,

                  "reportedUserName": fullName,

                  "messageId": messageId,

                  "messageText": messageData["message"] ?? "",

                  "imageUrl": messageData["imageUrl"] ?? "",

                  "messageType": messageData["type"] ?? "text",

                  "chatId": chatId,

                  "reason": selectedReason,

                  "createdAt": Timestamp.now(),

                  "status": "Pending",
                });

                Navigator.pop(context);
                showDialog(
                  context: context,
                  builder: (context) {
                    return AlertDialog(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),

                      title: const Row(
                        children: [
                          Icon(
                            Icons.verified_outlined,
                            color: Colors.orange,
                          ),

                          SizedBox(width: 10),

                          Text("Thank You"),
                        ],
                      ),

                      content: const Text(
                        "Thank you for helping keep our community safe.\n\n"
                            "Your report has been submitted successfully.",
                      ),

                      actions: [
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },

                          child: const Text(
                            "OK",
                            style: TextStyle(
                              color: Colors.orange,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                );
              },

              child: const Text("Submit", style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  Future<void> deleteMessage(String messageId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text("Delete Message"),
        content: const Text("Delete this message for everyone?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              "Delete",
              style: TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    await firestore
        .collection("chats")
        .doc(chatId)
        .collection("messages")
        .doc(messageId)
        .delete();
  }


  Future<void> _toggleReaction(String messageId, String emoji) async {
    final msgRef = firestore
        .collection("chats")
        .doc(chatId)
        .collection("messages")
        .doc(messageId);

    final snap = await msgRef.get();
    if (!snap.exists) return;

    final data = snap.data() as Map<String, dynamic>;
    final Map<String, dynamic> rawReactions = Map<String, dynamic>.from(
      data["reactions"] ?? {},
    );

    // Each key in reactions is an emoji string; value is a list of uids
    final List<String> uids =
    rawReactions[emoji] != null
        ? List<String>.from(rawReactions[emoji])
        : [];

    if (uids.contains(myUid)) {
      uids.remove(myUid);
    } else {
      uids.add(myUid);
    }

    if (uids.isEmpty) {
      rawReactions.remove(emoji);
    } else {
      rawReactions[emoji] = uids;
    }

    await msgRef.update({"reactions": rawReactions});
  }

  /// Show a bottom sheet with 6 emoji options to react to a message.
  void _showReactionPicker(
      String messageId,
      bool isMe,
      Map<String, dynamic> currentReactions,
      ) {
    // Trigger haptic feedback so the user knows long-press registered
    HapticFeedback.mediumImpact();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder:
          (_) => Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.12),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // drag handle
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const Text(
              "React to message",
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children:
              _reactionEmojis.map((emoji) {
                final List uids = currentReactions[emoji] ?? [];
                final bool iReacted = uids.contains(myUid);
                return GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                    _toggleReaction(messageId, emoji);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color:
                      iReacted
                          ? Colors.orange.shade100
                          : Colors.grey.shade100,
                      shape: BoxShape.circle,
                      border:
                      iReacted
                          ? Border.all(
                        color: Colors.orange.shade400,
                        width: 2,
                      )
                          : null,
                    ),
                    child: Text(
                      emoji,
                      style: const TextStyle(fontSize: 26),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            // show delete/copy options for own messages
            if (!isMe) ...[
              const Divider(),

              ListTile(
                leading: const Icon(
                  Icons.flag_outlined,
                  color: Colors.orange,
                ),

                title: const Text("Report Message"),

                onTap: () {
                  Navigator.pop(context);

                  _showReportDialog(messageId);
                },
              ),
            ],
            if (isMe) ...[
              const Divider(),
              ListTile(
                leading: const Icon(
                  Icons.delete_outline,
                  color: Colors.red,
                ),
                title: const Text(
                  "Delete message",
                  style: TextStyle(color: Colors.red),
                ),
                onTap: () {
                  Navigator.pop(context);
                  deleteMessage(messageId);
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Set reply state for the given message.
  void _setReply({
    required String msgId,
    required String text,
    required String senderId,
    required String senderName,
  }) {
    setState(() {
      _replyToId = msgId;
      _replyToText = text;
      _replyToSenderId = senderId;
      _replyToSenderName = senderName;
    });
    // Focus the text field
    FocusScope.of(context).requestFocus(FocusNode());
  }

  void _clearReply() {
    setState(() {
      _replyToId = null;
      _replyToText = null;
      _replyToSenderId = null;
      _replyToSenderName = null;
    });
  }

  Future<void> updateTyping(bool value) async {
    await firestore.collection("chats").doc(chatId).update({
      "typing.$myUid": value,
    });
  }

  /// Mark all messages sent by the OTHER user as seen.
  /// Filters in Dart to avoid needing a composite Firestore index.
  Future<void> markMessagesAsSeen() async {
    final snap =
    await firestore
        .collection("chats")
        .doc(chatId)
        .collection("messages")
        .where("isSeen", isEqualTo: false)
        .get();

    for (final doc in snap.docs) {
      // Only mark messages that were sent BY the other user
      if (doc.data()["senderId"] != myUid) {
        await doc.reference.update({"isSeen": true});
      }
    }
  }

  /// Block the other user — writes to blocks collection then pops back.
  Future<void> _blockUser() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text("Block User"),
        content: const Text(
          "Are you sure you want to block this user? You won't see their messages anymore.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              "Block",
              style: TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    await firestore.collection("blocks").add({
      "blockerId": myUid,
      "blockedId": widget.otherUserId,
      "createdAt": Timestamp.now(),
    });

    if (!mounted) return;
    // The profile sheet is already closed before _blockUser() is called.
    // Just pop the chat screen itself to go back to ChatsPage.
    Navigator.of(context).pop();
  }

  void scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 300), () {
      if (scrollController.hasClients) {
        scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // ── Profile bottom sheet ──────────────────────────────────────────────────

  void _showUserProfile(Map<String, dynamic> userData) {
    final String fullName =
    "${userData["firstName"] ?? ""} ${userData["lastName"] ?? ""}".trim();
    final String image = userData["profileImage"] ?? "";
    final String bio = userData["bio"] ?? "";
    final String city = userData["city"] ?? "";
    final String status = userData["status"] ?? "";
    final String religion = userData["religion"] ?? "";
    final String nationality = userData["nationality"] ?? "";
    final bool isOnline = userData["isOnline"] == true;
    final List lifestyle = List<String>.from(userData["lifestyle"] ?? []);
    final List hobbies = List<String>.from(userData["hobbies"] ?? []);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (_) => DraggableScrollableSheet(
        initialChildSize: 0.65,
        minChildSize: 0.4,
        maxChildSize: 0.92,
        builder:
            (_, controller) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(30),
            ),
          ),
          child: ListView(
            controller: controller,
            padding: const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 16,
            ),
            children: [
              // drag handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),

              // Avatar + name + online
              Center(
                child: Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.orange.shade100,
                      backgroundImage:
                      image != "" ? NetworkImage(image) : null,
                      child:
                      image == ""
                          ? Text(
                        fullName.isNotEmpty
                            ? fullName[0].toUpperCase()
                            : "?",
                        style: TextStyle(
                          fontSize: 36,
                          color: Colors.orange.shade900,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                          : null,
                    ),
                    Container(
                      width: 18,
                      height: 18,
                      decoration: BoxDecoration(
                        color:
                        isOnline
                            ? Colors.green
                            : Colors.grey.shade400,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white,
                          width: 2,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Center(
                child: Text(
                  fullName.isEmpty ? "User" : fullName,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Center(
                child: Text(
                  isOnline ? "Online" : "Offline",
                  style: TextStyle(
                    color: isOnline ? Colors.green : Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),

              const SizedBox(height: 20),
              const Divider(),

              // Info rows
              if (bio.isNotEmpty)
                _infoRow(Icons.info_outline, "Bio", bio),
              if (city.isNotEmpty)
                _infoRow(Icons.location_on_outlined, "City", city),
              if (status.isNotEmpty)
                _infoRow(Icons.work_outline, "Status", status),
              if (religion.isNotEmpty)
                _infoRow(Icons.mosque_outlined, "Religion", religion),
              if (nationality.isNotEmpty)
                _infoRow(
                  Icons.flag_outlined,
                  "Nationality",
                  nationality,
                ),

              // Lifestyle chips
              if (lifestyle.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Text(
                  "Lifestyle",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children:
                  lifestyle
                      .map((item) => _chip(item.toString()))
                      .toList(),
                ),
              ],

              // Hobbies chips
              if (hobbies.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Text(
                  "Hobbies",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children:
                  hobbies
                      .map((item) => _chip(item.toString()))
                      .toList(),
                ),
              ],

              const SizedBox(height: 24),

              // ── Block user button ──────────────────────────────────────
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade50,
                  foregroundColor: Colors.red.shade700,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                icon: const Icon(Icons.block),
                label: const Text(
                  "Block User",
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                onPressed: () {
                  Navigator.pop(context); // close profile sheet first
                  _blockUser();
                },
              ),

              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: Colors.orange.shade700, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip(String label) {
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
          color: Colors.orange.shade800,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  // ── Reply preview bar (shown above input when replying) ───────────────────

  Widget _buildReplyPreview() {
    if (_replyToId == null) return const SizedBox.shrink();
    final isMyReply = _replyToSenderId == myUid;
    return Container(
      margin: const EdgeInsets.fromLTRB(10, 0, 10, 0),
      padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
        border: Border(
          left: BorderSide(color: Colors.orange.shade700, width: 3),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  isMyReply ? "You" : (_replyToSenderName ?? "User"),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.orange.shade700,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _replyToText ?? "",
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 18),
            color: Colors.grey.shade500,
            onPressed: _clearReply,
          ),
        ],
      ),
    );
  }

  // ── Reaction row shown below a bubble ─────────────────────────────────────

  Widget _buildReactionRow(Map<String, dynamic> reactions, String msgId) {
    if (reactions.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Wrap(
        spacing: 4,
        runSpacing: 4,
        children:
        reactions.entries.map((entry) {
          final emoji = entry.key;
          final List uids = entry.value ?? [];
          if (uids.isEmpty) return const SizedBox.shrink();
          final bool iReacted = uids.contains(myUid);
          return GestureDetector(
            onTap: () => _toggleReaction(msgId, emoji),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 6,
                vertical: 3,
              ),
              decoration: BoxDecoration(
                color:
                iReacted
                    ? Colors.orange.shade100
                    : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
                border:
                iReacted
                    ? Border.all(
                  color: Colors.orange.shade300,
                  width: 1.5,
                )
                    : Border.all(color: Colors.grey.shade300),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(emoji, style: const TextStyle(fontSize: 14)),
                  if (uids.length > 1) ...[
                    const SizedBox(width: 3),
                    Text(
                      "${uids.length}",
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── Quoted reply preview inside a bubble ─────────────────────────────────

  Widget _buildInBubbleReply(Map<String, dynamic> msgData, bool isMe) {
    final String replyToId = msgData["replyToId"] ?? "";
    if (replyToId.isEmpty) return const SizedBox.shrink();
    final String replyText = msgData["replyToText"] ?? "";
    final String replySenderId = msgData["replyToSenderId"] ?? "";
    final bool isMyOriginal = replySenderId == myUid;

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.fromLTRB(10, 6, 10, 6),
      decoration: BoxDecoration(
        color:
        isMe
            ? Colors.orange.shade800.withOpacity(0.35)
            : Colors.grey.shade200,
        borderRadius: BorderRadius.circular(10),
        border: Border(
          left: BorderSide(
            color: isMe ? Colors.white54 : Colors.orange.shade400,
            width: 3,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isMyOriginal ? "You" : "User",
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: isMe ? Colors.white70 : Colors.orange.shade700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            replyText,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12,
              color: isMe ? Colors.white70 : Colors.grey.shade700,
            ),
          ),
        ],
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff7f4f2),

      appBar: AppBar(
        backgroundColor: Colors.orange.shade900,
        elevation: 0,
        titleSpacing: 0,
        title: FutureBuilder<DocumentSnapshot>(
          future: firestore.collection("users").doc(widget.otherUserId).get(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const SizedBox();

            final userData =
                snapshot.data!.data() as Map<String, dynamic>? ?? {};
            final String fullName =
            "${userData["firstName"] ?? ""} ${userData["lastName"] ?? ""}"
                .trim();
            final String image = userData["profileImage"] ?? "";

            return Row(
              children: [
                // Tappable avatar → opens profile sheet
                GestureDetector(
                  onTap: () => _showUserProfile(userData),
                  child: CircleAvatar(
                    radius: 20,
                    backgroundColor: Colors.orange.shade200,
                    backgroundImage: image != "" ? NetworkImage(image) : null,
                    child:
                    image == ""
                        ? Text(
                      fullName.isNotEmpty
                          ? fullName[0].toUpperCase()
                          : "?",
                      style: TextStyle(
                        color: Colors.orange.shade900,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                        : null,
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      fullName.isEmpty ? "User" : fullName,
                      style: const TextStyle(
                        fontSize: 17,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    // Live typing / online indicator
                    StreamBuilder<DocumentSnapshot>(
                      stream:
                      firestore.collection("chats").doc(chatId).snapshots(),
                      builder: (context, chatSnap) {
                        if (!chatSnap.hasData) return const SizedBox();
                        final data =
                        chatSnap.data!.data() as Map<String, dynamic>?;
                        bool otherTyping = false;
                        if (data != null && data["typing"] is Map) {
                          final typingMap =
                          data["typing"] as Map<String, dynamic>;
                          otherTyping = typingMap[widget.otherUserId] == true;
                        }
                        return Text(
                          otherTyping ? "Typing..." : "Online",
                          style: TextStyle(
                            fontSize: 13,
                            color:
                            otherTyping
                                ? Colors.greenAccent
                                : Colors.white.withOpacity(0.8),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ),

      body: Column(
        children: [
          // ── Messages list ──────────────────────────────────────────────
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream:
              firestore
                  .collection("chats")
                  .doc(chatId)
                  .collection("messages")
                  .orderBy("timestamp", descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final messages = snapshot.data!.docs;
                markMessagesAsSeen();

                if (messages.isEmpty) {
                  return Center(
                    child: Text(
                      "Say hello 👋",
                      style: TextStyle(
                        color: Colors.grey.shade400,
                        fontSize: 16,
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  reverse: true,
                  controller: scrollController,
                  padding: const EdgeInsets.all(15),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final msgData = message.data() as Map<String, dynamic>;
                    final bool isMe = msgData["senderId"] == myUid;
                    final String msgType = msgData["type"] ?? "text";
                    final dynamic ts = msgData["timestamp"];
                    final Map<String, dynamic> reactions =
                    Map<String, dynamic>.from(msgData["reactions"] ?? {});

                    // ── Swipe-to-reply wrapper ──────────────────────────
                    return Dismissible(
                      key: ValueKey("${message.id}_$index"),
                      direction: DismissDirection.startToEnd,
                      confirmDismiss: (_) async {
                        // Determine sender name for the reply preview
                        String senderName = "User";
                        if (isMe) {
                          senderName = "You";
                        } else {
                          // Try to get from Firestore — fire-and-forget
                          firestore
                              .collection("users")
                              .doc(msgData["senderId"])
                              .get()
                              .then((doc) {
                            if (doc.exists) {
                              final d = doc.data() as Map<String, dynamic>;
                              final n =
                              "${d["firstName"] ?? ""} ${d["lastName"] ?? ""}"
                                  .trim();
                              if (n.isNotEmpty) senderName = n;
                            }
                          });
                        }

                        final String textPreview =
                        msgType == "image"
                            ? "📷 Photo"
                            : (msgData["message"] ?? "");

                        _setReply(
                          msgId: message.id,
                          text: textPreview,
                          senderId: msgData["senderId"] ?? "",
                          senderName: senderName,
                        );
                        return false; // don't actually dismiss
                      },
                      background: Container(
                        alignment: Alignment.centerLeft,
                        padding: const EdgeInsets.only(left: 16),
                        child: const Icon(
                          Icons.reply,
                          color: Colors.orange,
                          size: 28,
                        ),
                      ),
                      child: GestureDetector(
                        // Long-press → reaction picker + delete option
                        onLongPress:
                            () => _showReactionPicker(
                          message.id,
                          isMe,
                          reactions,
                        ),
                        child: Align(
                          alignment:
                          isMe
                              ? Alignment.centerRight
                              : Alignment.centerLeft,
                          child: Column(
                            crossAxisAlignment:
                            isMe
                                ? CrossAxisAlignment.end
                                : CrossAxisAlignment.start,
                            children: [
                              Container(
                                margin: const EdgeInsets.only(bottom: 4),
                                constraints: const BoxConstraints(
                                  maxWidth: 280,
                                ),
                                decoration: BoxDecoration(
                                  color: isMe ? Colors.orange : Colors.white,
                                  borderRadius: BorderRadius.only(
                                    topLeft: const Radius.circular(18),
                                    topRight: const Radius.circular(18),
                                    bottomLeft: Radius.circular(isMe ? 18 : 4),
                                    bottomRight: Radius.circular(isMe ? 4 : 18),
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.05),
                                      blurRadius: 10,
                                      offset: const Offset(0, 5),
                                    ),
                                  ],
                                ),
                                child: Padding(
                                  padding:
                                  msgType == "image"
                                      ? const EdgeInsets.all(4)
                                      : const EdgeInsets.fromLTRB(
                                    14,
                                    10,
                                    14,
                                    8,
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      // ── In-bubble reply quote ───
                                      _buildInBubbleReply(msgData, isMe),

                                      // ── Image message ───────────
                                      if (msgType == "image")
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(
                                            14,
                                          ),
                                          child: Image.network(
                                            msgData["imageUrl"] ?? "",
                                            width: 240,
                                            fit: BoxFit.cover,
                                            loadingBuilder: (
                                                ctx,
                                                child,
                                                progress,
                                                ) {
                                              if (progress == null) {
                                                return child;
                                              }
                                              return Container(
                                                width: 240,
                                                height: 160,
                                                alignment: Alignment.center,
                                                child: CircularProgressIndicator(
                                                  value:
                                                  progress.expectedTotalBytes !=
                                                      null
                                                      ? progress
                                                      .cumulativeBytesLoaded /
                                                      progress
                                                          .expectedTotalBytes!
                                                      : null,
                                                  color: Colors.orange,
                                                ),
                                              );
                                            },
                                          ),
                                        ),

                                      // ── Text message ────────────
                                      if (msgType == "text")
                                        Text(
                                          msgData["message"] ?? "",
                                          style: TextStyle(
                                            fontSize: 15,
                                            color:
                                            isMe
                                                ? Colors.white
                                                : Colors.black,
                                          ),
                                        ),

                                      // ── Timestamp + seen icon ───
                                      const SizedBox(height: 4),
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            _formatMessageTime(ts),
                                            style: TextStyle(
                                              fontSize: 11,
                                              color:
                                              isMe
                                                  ? Colors.white70
                                                  : Colors.grey.shade500,
                                            ),
                                          ),
                                          if (isMe) ...[
                                            const SizedBox(width: 4),
                                            Icon(
                                              (msgData["isSeen"] == true)
                                                  ? Icons.done_all
                                                  : Icons.done,
                                              size: 16,
                                              color:
                                              (msgData["isSeen"] == true)
                                                  ? Colors.blue.shade200
                                                  : Colors.white70,
                                            ),
                                          ],
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              // ── Reaction row below bubble ──────────
                              _buildReactionRow(reactions, message.id),
                              const SizedBox(height: 8),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),

          // ── Reply preview strip (above input bar) ────────────────────
          _buildReplyPreview(),

          // ── Input bar ─────────────────────────────────────────────────
          SafeArea(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 10,
                    offset: const Offset(0, -3),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Image picker button
                  _isSendingImage
                      ? const Padding(
                    padding: EdgeInsets.all(10),
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.orange,
                      ),
                    ),
                  )
                      : IconButton(
                    icon: Icon(
                      Icons.image_outlined,
                      color: Colors.orange.shade700,
                      size: 28,
                    ),
                    onPressed: sendImage,
                  ),

                  // Text field
                  Expanded(
                    child: TextField(
                      controller: messageController,
                      onChanged: (value) async {
                        await updateTyping(value.isNotEmpty);
                      },
                      textCapitalization: TextCapitalization.sentences,
                      decoration: InputDecoration(
                        hintText: "Type a message...",
                        filled: true,
                        fillColor: Colors.grey.shade100,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 8),

                  // Send button
                  CircleAvatar(
                    radius: 25,
                    backgroundColor: Colors.orange.shade700,
                    child: IconButton(
                      onPressed: sendMessage,
                      icon: const Icon(
                        Icons.send,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
