import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'blocked_users_page.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _notificationsEnabled = true;
  bool _profileVisible = true;
  bool _femaleOnly = false;   // only shown to female users
  String _gender = "";        // loaded from Firestore
  bool _loadingPrefs = true;

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    final doc = await _firestore.collection("users").doc(uid).get();
    if (!doc.exists) return;

    final Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    if (mounted) {
      setState(() {
        _notificationsEnabled = data.containsKey("notificationsEnabled")
            ? data["notificationsEnabled"] as bool
            : true;
        _profileVisible = data.containsKey("isProfileVisible")
            ? data["isProfileVisible"] as bool
            : true;
        _femaleOnly = data.containsKey("femaleOnly")
            ? data["femaleOnly"] as bool
            : false;
        _gender = (data["gender"] ?? "").toString().toLowerCase();
        _loadingPrefs = false;
      });
    }
  }

  Future<void> _updatePref(String field, dynamic value) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    await _firestore.collection("users").doc(uid).update({field: value});
  }

  // ── 1. Change password ───────────────────────────────────────────────────

  Future<void> _changePassword() async {
    final email = _auth.currentUser?.email;
    if (email == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Change Password"),
        content: Text(
            "A password reset link will be sent to\n$email"),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text("Cancel")),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text("Send",
                  style: TextStyle(
                      color: Colors.orange.shade800,
                      fontWeight: FontWeight.bold))),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await _auth.sendPasswordResetEmail(email: email);
      if (!mounted) return;
      _showSnack("Reset email sent. Check your inbox.", Colors.green);
    } catch (e) {
      if (!mounted) return;
      _showSnack("Failed to send reset email.", Colors.red);
    }
  }

  // ── 2. Delete account ────────────────────────────────────────────────────

  Future<void> _deleteAccount() async {
    // Step 1 — first confirmation
    final step1 = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Delete Account"),
        content: const Text(
            "This will permanently delete your account and all your data. This cannot be undone."),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text("Cancel")),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text("Continue",
                  style: TextStyle(
                      color: Colors.red, fontWeight: FontWeight.bold))),
        ],
      ),
    );

    if (step1 != true) return;

    // Step 2 — type DELETE to confirm
    final controller = TextEditingController();
    final step2 = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Are you sure?"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
                "Type DELETE below to confirm you want to permanently delete your account."),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              decoration: InputDecoration(
                hintText: "DELETE",
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text("Cancel")),
          TextButton(
              onPressed: () =>
                  Navigator.pop(ctx, controller.text.trim() == "DELETE"),
              child: const Text("Delete",
                  style: TextStyle(
                      color: Colors.red, fontWeight: FontWeight.bold))),
        ],
      ),
    );

    if (step2 != true) {
      if (!mounted) return;
      _showSnack(
          "Account not deleted. You must type DELETE exactly.", Colors.orange);
      return;
    }

    try {
      final uid = _auth.currentUser?.uid;
      if (uid != null) {
        await _firestore.collection("users").doc(uid).delete();
      }
      await _auth.currentUser?.delete();

      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(
          context, '/login', (route) => false);
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      if (e.code == 'requires-recent-login') {
        _showSnack(
            "Please log out and log back in, then try again.", Colors.red);
      } else {
        _showSnack("Failed to delete account: ${e.message}", Colors.red);
      }
    } catch (e) {
      if (!mounted) return;
      _showSnack("Something went wrong. Please try again.", Colors.red);
    }
  }

  // ── About dialog ─────────────────────────────────────────────────────────

  void _showAbout() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.apartment_rounded, color: Colors.orange.shade800),
            const SizedBox(width: 10),
            const Text("Roommate Finder"),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _aboutRow("Version", "1.0.0"),
            const SizedBox(height: 8),
            _aboutRow("Built with", "Flutter + Firebase"),
            const SizedBox(height: 8),
            _aboutRow("Contact", "support@roommatefinder.app"),
            const SizedBox(height: 8),
            _aboutRow("Purpose", "Graduation Project 2"),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text("Close",
                  style: TextStyle(color: Colors.orange.shade800))),
        ],
      ),
    );
  }

  Widget _aboutRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("$label: ",
            style: const TextStyle(fontWeight: FontWeight.bold)),
        Expanded(
            child: Text(value,
                style: TextStyle(color: Colors.grey.shade700))),
      ],
    );
  }

  void _showSnack(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff7f4f2),
      appBar: AppBar(
        backgroundColor: Colors.orange.shade900,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text("Settings",
            style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: _loadingPrefs
          ? const Center(child: CircularProgressIndicator())
          : ListView(
        padding: const EdgeInsets.all(20),
        children: [

          // ── Account section ──────────────────────────────────────
          _sectionHeader("Account"),
          _settingsTile(
            icon: Icons.lock_reset_outlined,
            iconColor: Colors.blue.shade700,
            title: "Change Password",
            subtitle: "Send a reset link to your email",
            onTap: _changePassword,
          ),

          const SizedBox(height: 20),

          // ── Privacy section — females only ────────────────────────
          if (_gender == "female") ...[
            _sectionHeader("Privacy"),
            _switchTile(
              icon: Icons.female,
              iconColor: Colors.pink.shade400,
              title: "Hide profile from males",
              subtitle:
              "Your profile won't appear in searches by male users",
              value: _femaleOnly,
              onChanged: (val) {
                setState(() => _femaleOnly = val);
                _updatePref("femaleOnly", val);
                _showSnack(
                  val
                      ? "Your profile is now hidden from male users."
                      : "Your profile is now visible to everyone.",
                  val ? Colors.pink.shade400 : Colors.green,
                );
              },
            ),
            const SizedBox(height: 20),
          ],

          // ── Preferences section ──────────────────────────────────
          _sectionHeader("Preferences"),
          _switchTile(
            icon: Icons.notifications_outlined,
            iconColor: Colors.orange.shade700,
            title: "Push Notifications",
            subtitle: "Receive message and activity alerts",
            value: _notificationsEnabled,
            onChanged: (val) {
              setState(() => _notificationsEnabled = val);
              _updatePref("notificationsEnabled", val);
            },
          ),
          const SizedBox(height: 12),
          _switchTile(
            icon: Icons.visibility_outlined,
            iconColor: Colors.green.shade700,
            title: "Profile Visibility",
            subtitle: "Allow others to find and view your profile",
            value: _profileVisible,
            onChanged: (val) {
              setState(() => _profileVisible = val);
              _updatePref("isProfileVisible", val);
            },
          ),
          const SizedBox(height: 12),
          _settingsTile(
            icon: Icons.language_outlined,
            iconColor: Colors.purple.shade600,
            title: "Language",
            subtitle: "English / Arabic",
            trailing: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Text(
                Localizations.localeOf(context).languageCode == "ar"
                    ? "العربية"
                    : "English",
                style: TextStyle(
                    color: Colors.orange.shade800,
                    fontWeight: FontWeight.w600,
                    fontSize: 13),
              ),
            ),
            onTap: () {
              _showSnack(
                  "Change the language from your device settings or ask your developer to add a locale provider.",
                  Colors.orange);
            },
          ),

          const SizedBox(height: 20),

          // ── About section ────────────────────────────────────────
          _sectionHeader("About"),
          _settingsTile(
            icon: Icons.info_outline,
            iconColor: Colors.teal.shade600,
            title: "About App",
            subtitle: "Version, contact & project info",
            onTap: _showAbout,
          ),
          const SizedBox(height: 12),
          _settingsTile(
            icon: Icons.block,
            iconColor: Colors.red.shade700,
            title: "Blocked Users",
            subtitle: "Manage blocked accounts",
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const BlockedUsersPage(),
                ),
              );
            },
          ),

          const SizedBox(height: 20),

          // ── Danger zone ──────────────────────────────────────────
          _sectionHeader("Danger Zone"),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.red.shade100),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.delete_forever_outlined,
                    color: Colors.red.shade700, size: 22),
              ),
              title: const Text("Delete Account",
                  style: TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold)),
              subtitle: const Text(
                  "Permanently delete your account and data"),
              onTap: _deleteAccount,
            ),
          ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  // ── Helper widgets ────────────────────────────────────────────────────────

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.grey.shade500,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _settingsTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Widget? trailing,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: iconColor, size: 22),
        ),
        title: Text(title,
            style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle,
            style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
        trailing: trailing ??
            Icon(Icons.arrow_forward_ios,
                size: 14, color: Colors.grey.shade400),
        onTap: onTap,
      ),
    );
  }

  Widget _switchTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: iconColor, size: 22),
        ),
        title: Text(title,
            style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle,
            style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
        trailing: Switch(
          value: value,
          onChanged: onChanged,
          activeColor: Colors.orange.shade700,
        ),
      ),
    );
  }
}
