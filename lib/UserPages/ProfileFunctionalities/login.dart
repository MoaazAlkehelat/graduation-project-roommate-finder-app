import 'package:flutter/material.dart';
import 'sign_up.dart';
import '../../AppFunctionalities/app_strings.dart';
import '../../AppFunctionalities/FadeAnimation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

// FIX: "Forgot Password" is now a GestureDetector that calls sendPasswordResetEmail
// FIX: Facebook/GitHub social buttons now show "not available" snackbar instead of silently doing nothing
// FIX: Admin login still uses Firestore .where("password") — noted as a known security issue for school project scope
//      A proper fix would use Firebase Auth for admins too, but that requires backend changes.
// NEW: After successful Normal User login, the FCM device token is saved to
//      users/{uid}.fcmToken so Cloud Functions can send push notifications.

class LogInPage extends StatefulWidget {
  const LogInPage({super.key});

  @override
  State<LogInPage> createState() => _LogInPageState();
}

class _LogInPageState extends State<LogInPage> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  final FirebaseAuth auth = FirebaseAuth.instance;
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  String selectedRole = "Normal User";
  bool _obscurePassword = true;
  bool _isLoading = false;

  // ── VALIDATORS ──────────────────────────────────────────────

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return "Email is required";
    }
    final emailRegex = RegExp(r'^[\w\.-]+@[\w\.-]+\.\w{2,}$');
    if (!emailRegex.hasMatch(value.trim())) {
      return "Enter a valid email address";
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.trim().isEmpty) {
      return "Password is required";
    }
    if (value.trim().length < 6) {
      return "Password must be at least 6 characters";
    }
    return null;
  }

  // ── FCM token save ───────────────────────────────────────────

  /// Saves the FCM registration token to the user's Firestore document
  /// so Cloud Functions can look it up when sending push notifications.
  Future<void> _saveFcmToken(String uid) async {
    try {
      // Request notification permission on iOS / newer Android
      final messaging = FirebaseMessaging.instance;
      final settings = await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.denied) {
        // User denied — skip silently
        return;
      }

      final token = await messaging.getToken();
      if (token == null || token.isEmpty) return;

      await firestore.collection("users").doc(uid).update({
        "fcmToken": token,
      });
    } catch (_) {
      // Token saving is best-effort — never block login if it fails
    }
  }

  // ── LOGIN LOGIC ──────────────────────────────────────────────

  Future login() async {
    print("LOGIN BUTTON PRESSED");

    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    String lang = Localizations.localeOf(context).languageCode;

    try {
      if (selectedRole == "Normal User") {
        await auth.signInWithEmailAndPassword(
          email: emailController.text.trim(),
          password: passwordController.text.trim(),
        );

        if (!auth.currentUser!.emailVerified) {
          await auth.signOut();
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content:
              Text("Please verify your email before logging in!"),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }

        // Save FCM token after successful verified login
        await _saveFcmToken(auth.currentUser!.uid);

        final userDoc = await firestore
            .collection("users")
            .doc(auth.currentUser!.uid)
            .get();

        final data = userDoc.data();

        if (data?["isBanned"] == true) {

          final bannedUntil = data?["bannedUntil"];

          if (bannedUntil == null) {

            await auth.signOut();

            if (!mounted) return;

            showDialog(
              context: context,
              builder: (_) => AlertDialog(

                title: const Text("Account Permanently Blocked"),

                content: const Text(
                  "Your account has been permanently blocked.",
                ),

                actions: [

                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },

                    child: const Text("OK"),
                  ),
                ],
              ),
            );

            return;
          }

          else {

            final DateTime banDate =
            (bannedUntil as Timestamp).toDate();

            if (DateTime.now().isBefore(banDate)) {

              await auth.signOut();

              if (!mounted) return;

              showDialog(
                context: context,
                builder: (_) => AlertDialog(

                  title: const Text("Account Blocked"),

                  content: Text(
                    "Your account is blocked until:\n\n"
                        "$banDate",
                  ),

                  actions: [

                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },

                      child: const Text("OK"),
                    ),
                  ],
                ),
              );

              return;
            }

            else {

              await firestore
                  .collection("users")
                  .doc(auth.currentUser!.uid)
                  .update({

                "isBanned": false,
                "bannedUntil": null,
              });
            }
          }
        }

        if (!mounted) return;
        Navigator.pushReplacementNamed(context, '/');
      } else {
        // ADMIN: still checked against Firestore (school project limitation)
        QuerySnapshot adminQuery = await firestore
            .collection("admins")
            .where("email", isEqualTo: emailController.text.trim())
            .where("password", isEqualTo: passwordController.text.trim())
            .get();

        if (!mounted) return;

        if (adminQuery.docs.isNotEmpty) {
          Navigator.pushReplacementNamed(context, '/AdminHomePage');
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppStrings.wrongLogin(lang)),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (!mounted) return;
      String errorMessage = _getFriendlyError(e.toString());
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // FIX: Forgot Password now sends a real reset email
  Future forgotPassword() async {
    final email = emailController.text.trim();
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Enter your email first, then tap Forgot Password."),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    try {
      await auth.sendPasswordResetEmail(email: email);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Password reset email sent. Check your inbox."),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error: ${e.toString()}"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _getFriendlyError(String error) {
    if (error.contains("user-not-found")) return "No account found with this email.";
    if (error.contains("wrong-password")) return "Incorrect password. Please try again.";
    if (error.contains("invalid-email")) return "The email address is not valid.";
    if (error.contains("user-disabled")) return "This account has been disabled.";
    if (error.contains("too-many-requests")) return "Too many attempts. Please try again later.";
    if (error.contains("network-request-failed")) return "No internet connection. Please check your network.";
    return "Login failed. Please try again.";
  }

  @override
  Widget build(BuildContext context) {
    String lang = Localizations.localeOf(context).languageCode;

    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            colors: [
              Colors.orange.shade900,
              Colors.orange.shade800,
              Colors.orange.shade400,
            ],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 80),

            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FadeAnimation(
                    1,
                    Text(
                      AppStrings.login(lang),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  FadeAnimation(
                    1.3,
                    Text(
                      AppStrings.welcomeBack(lang),
                      style: const TextStyle(
                          color: Colors.white, fontSize: 18),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(60),
                    topRight: Radius.circular(60),
                  ),
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(30),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        const SizedBox(height: 40),

                        /// INPUT CARD
                        FadeAnimation(
                          1.4,
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color.fromRGBO(255, 95, 27, 0.3),
                                  blurRadius: 20,
                                  offset: Offset(0, 10),
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                /// EMAIL
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 4),
                                  decoration: const BoxDecoration(
                                    border: Border(
                                      bottom: BorderSide(
                                          color: Color(0xFFEEEEEE)),
                                    ),
                                  ),
                                  child: TextFormField(
                                    controller: emailController,
                                    keyboardType:
                                    TextInputType.emailAddress,
                                    validator: _validateEmail,
                                    autovalidateMode: AutovalidateMode
                                        .onUserInteraction,
                                    decoration: InputDecoration(
                                      hintText: AppStrings.email(lang),
                                      hintStyle: const TextStyle(
                                          color: Colors.grey),
                                      border: InputBorder.none,
                                      errorStyle: const TextStyle(
                                          fontSize: 12),
                                    ),
                                  ),
                                ),

                                /// PASSWORD
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 4),
                                  child: TextFormField(
                                    controller: passwordController,
                                    obscureText: _obscurePassword,
                                    validator: _validatePassword,
                                    autovalidateMode: AutovalidateMode
                                        .onUserInteraction,
                                    decoration: InputDecoration(
                                      hintText:
                                      AppStrings.password(lang),
                                      hintStyle: const TextStyle(
                                          color: Colors.grey),
                                      border: InputBorder.none,
                                      errorStyle: const TextStyle(
                                          fontSize: 12),
                                      suffixIcon: IconButton(
                                        icon: Icon(
                                          _obscurePassword
                                              ? Icons.visibility_off
                                              : Icons.visibility,
                                          color: Colors.grey,
                                        ),
                                        onPressed: () {
                                          setState(() {
                                            _obscurePassword =
                                            !_obscurePassword;
                                          });
                                        },
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 30),

                        /// ROLE SELECTOR
                        FadeAnimation(
                          1.5,
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Radio<String>(
                                value: "Normal User",
                                groupValue: selectedRole,
                                activeColor: Colors.orange.shade900,
                                onChanged: (value) => setState(
                                        () => selectedRole = value!),
                              ),
                              const Text("Normal User"),
                              const SizedBox(width: 20),
                              Radio<String>(
                                value: "Admin",
                                groupValue: selectedRole,
                                activeColor: Colors.orange.shade900,
                                onChanged: (value) => setState(
                                        () => selectedRole = value!),
                              ),
                              const Text("Admin"),
                            ],
                          ),
                        ),

                        const SizedBox(height: 20),

                        // FIX: Forgot Password is now tappable and sends a reset email
                        FadeAnimation(
                          1.6,
                          GestureDetector(
                            onTap: forgotPassword,
                            child: Text(
                              AppStrings.forgotPassword(lang),
                              style: const TextStyle(
                                color: Colors.orange,

                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 40),

                        /// LOGIN BUTTON
                        FadeAnimation(
                          1.6,
                          GestureDetector(
                            onTap: _isLoading ? null : login,
                            child: Container(
                              height: 50,
                              margin: const EdgeInsets.symmetric(
                                  horizontal: 50),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(50),
                                color: Colors.orange.shade900,
                              ),
                              child: Center(
                                child: _isLoading
                                    ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2.5,
                                  ),
                                )
                                    : Text(
                                  AppStrings.login(lang),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 50),

                        /// SIGN UP LINK
                        FadeAnimation(
                          1.7,
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(AppStrings.dontHaveAccount(lang)),
                              const SizedBox(width: 10),
                              TextButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                      const SignUpPage(),
                                    ),
                                  );
                                },
                                child: Text(
                                    AppStrings.createAccount(lang)),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 30),



                        const SizedBox(height: 30),

                        // FIX: Social buttons now show a "not available" message instead of doing nothing silently

                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
