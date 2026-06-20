import 'package:flutter/material.dart';
import '../../AppFunctionalities/app_strings.dart';
import '../../AppFunctionalities/FadeAnimation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final TextEditingController firstName = TextEditingController();
  final TextEditingController lastName = TextEditingController();
  final TextEditingController dob = TextEditingController();
  final TextEditingController email = TextEditingController();
  final TextEditingController phone = TextEditingController();
  final TextEditingController password = TextEditingController();
  final TextEditingController confirmPassword = TextEditingController();

  String gender = "Male";

  final FirebaseAuth auth = FirebaseAuth.instance;
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  // Form key for validation
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;

  // ── VALIDATORS ──────────────────────────────────────────────

  String? _validateFirstName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return "First name is required";
    }
    if (value.trim().length < 2) {
      return "First name must be at least 2 characters";
    }
    final nameRegex = RegExp(r"^[a-zA-Z\u0600-\u06FF\s]+$");
    if (!nameRegex.hasMatch(value.trim())) {
      return "First name must contain letters only";
    }
    return null;
  }

  String? _validateLastName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return "Last name is required";
    }
    if (value.trim().length < 2) {
      return "Last name must be at least 2 characters";
    }
    final nameRegex = RegExp(r"^[a-zA-Z\u0600-\u06FF\s]+$");
    if (!nameRegex.hasMatch(value.trim())) {
      return "Last name must contain letters only";
    }
    return null;
  }

  String? _validateDob(String? value) {
    if (value == null || value.trim().isEmpty) {
      return "Date of birth is required"; //
    }

    try {
      // Split the "dd/mm/yyyy" formatted text string
      List<String> parts = value.split('/');
      if (parts.length != 3) {
        return "Enter a valid date format (DD/MM/YYYY)";
      }

      int day = int.parse(parts[0]);
      int month = int.parse(parts[1]);
      int year = int.parse(parts[2]);

      DateTime birthDate = DateTime(year, month, day);
      DateTime today = DateTime.now();

      // 1. Check if the date is in the future
      if (birthDate.isAfter(today)) {
        return "Birth date cannot be a future date";
      }

      // 2. Check if the user is at least 18 years old
      DateTime eighteenYearsAgo = DateTime(today.year - 18, today.month, today.day);
      if (birthDate.isAfter(eighteenYearsAgo)) {
        return "You must be at least 18 years old to sign up";
      }
    } catch (e) {
      return "Enter a valid date";
    }

    return null;
  }

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

  String? _validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return "Phone number is required";
    }
    final phoneRegex = RegExp(r'^\+?[0-9]{7,15}$');
    if (!phoneRegex.hasMatch(value.trim())) {
      return "Enter a valid phone number (digits only, 7–15 chars)";
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.trim().isEmpty) {
      return "Password is required";
    }
    if (value.trim().length < 8) {
      return "Password must be at least 8 characters";
    }
    if (!RegExp(r'[A-Z]').hasMatch(value)) {
      return "Password must contain at least one uppercase letter";
    }
    if (!RegExp(r'[a-z]').hasMatch(value)) {
      return "Password must contain at least one lowercase letter";
    }
    if (!RegExp(r'[0-9]').hasMatch(value)) {
      return "Password must contain at least one number";
    }
    if (!RegExp(r'[!@#\$%^&*(),.?":{}|<>]').hasMatch(value)) {
      return "Password must contain at least one special character";
    }
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (value == null || value.trim().isEmpty) {
      return "Please confirm your password";
    }
    if (value != password.text) {
      return "Passwords do not match";
    }
    return null;
  }

  // ── SIGN UP LOGIC ────────────────────────────────────────────

  Future signUp() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      UserCredential userCredential = await auth.createUserWithEmailAndPassword(
        email: email.text.trim(),
        password: password.text.trim(),
      );

      String uid = userCredential.user!.uid;

      await firestore.collection("users").doc(uid).set({
        "userId": uid,
        "firstName": firstName.text.trim(),
        "lastName": lastName.text.trim(),
        "email": email.text.trim(),
        "phone": phone.text.trim(),
        "gender": gender,
        "dob": dob.text.trim(),
        "profileImage": "",
        "bio": "",
        "city": "",
        "neighborhood": "",
        "nationality": "",
        "religion": "",
        "status": "",
        "Posts": 0,
        "likes": 0,
        "smoking": false,
        "pets": false,
        "looking": true,
        "lifeStyle": 0,
      });

      await userCredential.user!.sendEmailVerification();
      await auth.signOut();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Account created! Please check your email to verify your account.",
          ),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 4),
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      String errorMessage = _getFriendlyError(e.toString());
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _getFriendlyError(String error) {
    if (error.contains("email-already-in-use")) {
      return "An account already exists with this email.";
    }
    if (error.contains("invalid-email"))
      return "The email address is not valid.";
    if (error.contains("weak-password")) {
      return "Password is too weak. Please choose a stronger one.";
    }
    if (error.contains("network-request-failed")) {
      return "No internet connection. Please check your network.";
    }
    return "Sign up failed. Please try again.";
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
                      AppStrings.signUp(lang),
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
                      AppStrings.welcome(lang),
                      style: const TextStyle(color: Colors.white, fontSize: 18),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: const BorderRadius.only(
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

                        /// FIRST + LAST NAME
                        FadeAnimation(
                          1.4,
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Theme.of(context).cardColor,
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.withOpacity(0.4),
                                  blurRadius: 25,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: firstName,
                                    validator: _validateFirstName,
                                    autovalidateMode:
                                        AutovalidateMode.onUserInteraction,
                                    decoration: InputDecoration(
                                      hintText: AppStrings.firstName(lang),
                                      border: InputBorder.none,
                                      errorStyle: const TextStyle(fontSize: 11),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: TextFormField(
                                    controller: lastName,
                                    validator: _validateLastName,
                                    autovalidateMode:
                                        AutovalidateMode.onUserInteraction,
                                    decoration: InputDecoration(
                                      hintText: AppStrings.lastName(lang),
                                      border: InputBorder.none,
                                      errorStyle: const TextStyle(fontSize: 11),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        /// DATE OF BIRTH
                        FadeAnimation(
                          1.5,
                          _inputField(
                            context,
                            AppStrings.dob(lang),
                            dob,
                            isDate: true,
                            validator: _validateDob,
                          ),
                        ),

                        const SizedBox(height: 20),

                        /// EMAIL
                        FadeAnimation(
                          1.6,
                          _inputField(
                            context,
                            AppStrings.email(lang),
                            email,
                            keyboardType: TextInputType.emailAddress,
                            validator: _validateEmail,
                          ),
                        ),

                        const SizedBox(height: 20),

                        /// PHONE
                        FadeAnimation(
                          1.65,
                          _inputField(
                            context,
                            "Phone Number",
                            phone,
                            keyboardType: TextInputType.phone,
                            validator: _validatePhone,
                          ),
                        ),

                        const SizedBox(height: 20),

                        /// PASSWORD
                        FadeAnimation(
                          1.7,
                          _passwordField(
                            context,
                            AppStrings.password(lang),
                            password,
                            obscure: _obscurePassword,
                            onToggle:
                                () => setState(
                                  () => _obscurePassword = !_obscurePassword,
                                ),
                            validator: _validatePassword,
                          ),
                        ),

                        // Password strength hint
                        const Padding(
                          padding: EdgeInsets.only(top: 6, left: 4),
                          child: Text(
                            "Min 8 chars · uppercase · lowercase · number · special character",
                            style: TextStyle(color: Colors.grey, fontSize: 11),
                          ),
                        ),

                        const SizedBox(height: 20),

                        /// CONFIRM PASSWORD
                        FadeAnimation(
                          1.8,
                          _passwordField(
                            context,
                            AppStrings.confirmPassword(lang),
                            confirmPassword,
                            obscure: _obscureConfirmPassword,
                            onToggle:
                                () => setState(
                                  () =>
                                      _obscureConfirmPassword =
                                          !_obscureConfirmPassword,
                                ),
                            validator: _validateConfirmPassword,
                          ),
                        ),

                        const SizedBox(height: 30),

                        /// GENDER
                        Row(
                          children: [
                            Radio<String>(
                              value: "Male",
                              groupValue: gender,
                              activeColor: Colors.orange.shade900,
                              onChanged:
                                  (value) => setState(() => gender = value!),
                            ),
                            Text(AppStrings.male(lang)),
                            Radio<String>(
                              value: "Female",
                              groupValue: gender,
                              activeColor: Colors.orange.shade900,
                              onChanged:
                                  (value) => setState(() => gender = value!),
                            ),
                            Text(AppStrings.female(lang)),
                          ],
                        ),

                        const SizedBox(height: 40),

                        /// BUTTONS
                        FadeAnimation(
                          1.9,
                          Row(
                            children: [
                              Expanded(
                                child: GestureDetector(
                                  onTap: () {
                                    Navigator.pop(context);
                                  },
                                  child: Container(
                                    height: 50,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(50),
                                      color: Colors.grey.shade400,
                                    ),
                                    child: Center(
                                      child: Text(
                                        AppStrings.back(lang),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 15),
                              Expanded(
                                child: Container(
                                  height: 50,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(50),
                                    color: Colors.orange.shade900,
                                  ),
                                  child: GestureDetector(
                                    onTap: _isLoading ? null : signUp,
                                    child: Center(
                                      child:
                                          _isLoading
                                              ? const SizedBox(
                                                width: 24,
                                                height: 24,
                                                child:
                                                    CircularProgressIndicator(
                                                      color: Colors.white,
                                                      strokeWidth: 2.5,
                                                    ),
                                              )
                                              : Text(
                                                AppStrings.next(lang),
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 30),
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

  // ── PLAIN INPUT FIELD ────────────────────────────────────────

  Widget _inputField(
    BuildContext context,
    String hint,
    TextEditingController controller, {
    bool isDate = false,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.4),
            blurRadius: 25,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        readOnly: isDate,
        keyboardType: keyboardType,
        validator: validator,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        decoration: InputDecoration(
          hintText: hint,
          border: InputBorder.none,
          errorStyle: const TextStyle(fontSize: 11),
        ),
        onTap:
            isDate
                ? () async {
                  DateTime? picked = await showDatePicker(
                    context: context,
                    initialDate: DateTime(2000),
                    firstDate: DateTime(1950),
                    // Must be at least 18 years old
                    lastDate: DateTime(
                      DateTime.now().year - 18,
                      DateTime.now().month,
                      DateTime.now().day,
                    ),
                  );
                  if (picked != null) {
                    controller.text =
                        "${picked.day}/${picked.month}/${picked.year}";
                  }
                }
                : null,
      ),
    );
  }

  // ── PASSWORD FIELD WITH SHOW/HIDE TOGGLE ────────────────────

  Widget _passwordField(
    BuildContext context,
    String hint,
    TextEditingController controller, {
    required bool obscure,
    required VoidCallback onToggle,
    String? Function(String?)? validator,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.4),
            blurRadius: 25,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        obscureText: obscure,
        validator: validator,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        decoration: InputDecoration(
          hintText: hint,
          border: InputBorder.none,
          errorStyle: const TextStyle(fontSize: 11),
          suffixIcon: IconButton(
            icon: Icon(
              obscure ? Icons.visibility_off : Icons.visibility,
              color: Colors.grey,
            ),
            onPressed: onToggle,
          ),
        ),
      ),
    );
  }
}
