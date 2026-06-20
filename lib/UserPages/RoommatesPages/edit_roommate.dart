import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import '../../AppFunctionalities/app_strings.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../AccommodationPages/post_accommodation.dart'; // Redirects user if they haven't posted housing yet

class EditRoommatePage extends StatefulWidget {
  final Map<String, dynamic>? postData;
  final int? postIndex;
  // FIX: added postDocId for Firestore document updates (edit mode)
  final String? postDocId;

  const EditRoommatePage({super.key, this.postData, this.postIndex, this.postDocId});

  @override
  State<EditRoommatePage> createState() => _PostRoommatePageState();
}

class _PostRoommatePageState extends State<EditRoommatePage> {
  final _formKey = GlobalKey<FormState>();

  String? status;
  String? religion;
  String? gender;
  String? _selectedListingId;

  bool _isLoadingCheck = true;
  List<DocumentSnapshot> _myAccommodations = [];

  Uint8List? selectedImage;

  // DATE CONTROLLERS
  final TextEditingController startDateController = TextEditingController();
  final TextEditingController endDateController = TextEditingController();

  // AGE CONTROLLERS
  final TextEditingController ageMinController = TextEditingController();
  final TextEditingController ageMaxController = TextEditingController();


  Map<String, bool> lifestyleValues = {
    "Clean": false,
    "Smoker": false,
    "Gamer": false,
    "Night Person": false,
    "Quiet": false,
    "Social": false,
    "Early Sleeper": false,
    "Pet Lover": false,
  };
  List<String> selectedHobbies = [];

  final List<String> hobbiesOptions = [
    "Gym",
    "Gaming",
    "Movies",
    "Football",
    "Cooking",
    "Reading",
    "Traveling",
    "Music",
  ];




  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final FirebaseStorage storage = FirebaseStorage.instance;

  @override
  void initState() {
    super.initState();
    _checkAndFetchAccommodations();

    if (widget.postData != null) {
      status = widget.postData!["status"];
      gender = widget.postData!["gender"];
      religion = widget.postData!["religion"];
      startDateController.text = widget.postData!["startDate"] ?? "";
      endDateController.text = widget.postData!["endDate"] ?? "";
      ageMinController.text = widget.postData!["ageMin"] ?? "";
      ageMaxController.text = widget.postData!["ageMax"] ?? "";
      _selectedListingId = widget.postData!["listingId"];

      if (widget.postData!["lifestyle"] != null) {
        List savedLifestyle = widget.postData!["lifestyle"];
        for (var key in savedLifestyle) {
          // FIX: keys are always English, so this lookup is correct
          if (lifestyleValues.containsKey(key)) {
            lifestyleValues[key] = true;
          }
        }
      }
    }
  }

  // Verifies if the current user has uploaded any accommodations in Firestore
  Future<void> _checkAndFetchAccommodations() async {
    String uid = FirebaseAuth.instance.currentUser!.uid;
    try {
      final querySnapshot = await firestore
          .collection("roomListings")
          .where("userId", isEqualTo: uid)
          .get();

      setState(() {
        _myAccommodations = querySnapshot.docs;
        _isLoadingCheck = false;

        if (widget.postData != null && _myAccommodations.any((doc) => doc.id == _selectedListingId)) {
          _selectedListingId = widget.postData!["listingId"];
        }
      });
    } catch (e) {
      debugPrint("Error fetching accommodations: $e");
      setState(() {
        _isLoadingCheck = false;
      });
    }
  }

  Future pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      Uint8List imageBytes = await pickedFile.readAsBytes();
      setState(() {
        selectedImage = imageBytes;
      });
    }
  }

  // SAVE POST
  Future savePost() async {
    if (_selectedListingId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("Please select the accommodation you want a roommate for"),
            backgroundColor: Colors.red
        ),
      );
      return;
    }

    String imageUrl = await uploadImage();


    List selectedLifestyle = lifestyleValues.entries
        .where((e) => e.value)
        .map((e) => e.key)
        .toList();


    bool femaleOnly = false;
    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;
      final userDoc = await firestore.collection("users").doc(uid).get();
      if (userDoc.exists) {
        final userData = userDoc.data() as Map<String, dynamic>;
        femaleOnly = userData.containsKey("femaleOnly")
            ? userData["femaleOnly"] as bool
            : false;
      }
    } catch (_) {}

    Map<String, dynamic> data = {
      "postId": widget.postData?["postId"] ?? DateTime.now().millisecondsSinceEpoch.toString(),
      "userId": FirebaseAuth.instance.currentUser!.uid,
      "listingId": _selectedListingId,
      "image": imageUrl,
      "status": status,
      "gender": gender,
      "religion": religion,
      "startDate": startDateController.text,
      "endDate": endDateController.text,
      "ageMin": ageMinController.text,
      "ageMax": ageMaxController.text,
      "lifestyle": selectedLifestyle,
      "hobbies": selectedHobbies,
      "date": "${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}",
      "createdAt": Timestamp.now(),
      "femaleOnly": femaleOnly,
    };

    if (widget.postData != null) {
      // Use postDocId if available, else fall back to postId field
      final docId = widget.postDocId ?? widget.postData!["postId"];
      await firestore
          .collection("roommateRequests")
          .doc(docId)
          .update(data);
    } else {
      await firestore
          .collection("roommateRequests")
          .doc(data["postId"])
          .set(data);
    }

    Navigator.pop(context);
  }

  Future<String> uploadImage() async {
    try {
      if (selectedImage == null) {
        return widget.postData != null ? (widget.postData!["image"] ?? "") : "";
      }
      String fileName = DateTime.now().millisecondsSinceEpoch.toString();
      Reference ref = storage.ref().child("roommate_images").child(fileName);
      UploadTask uploadTask = ref.putData(selectedImage!);
      TaskSnapshot snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      debugPrint(e.toString());
      return "";
    }
  }

  @override
  Widget build(BuildContext context) {
    String lang = Localizations.localeOf(context).languageCode;
    return Scaffold(
      backgroundColor: const Color(0xfff7f4f2),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
          color: Colors.orange,
        ),
        centerTitle: true,
        title: Text(
          "Update Roommate",
          style: const TextStyle(color: Color(0xff1B1F3B), fontWeight: FontWeight.bold, fontSize: 30),
        ),
      ),
      body: _isLoadingCheck
          ? const Center(child: CircularProgressIndicator(color: Colors.orange))
          : _myAccommodations.isEmpty
          ? _buildNoAccommodationWidget(lang)
          : SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(color: Colors.grey.withOpacity(0.15), blurRadius: 20, offset: const Offset(0, 10)),
            ],
          ),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                buildLabel(AppStrings.accommodation(lang), Icons.home_work_outlined),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: _selectedListingId,
                  validator: (value) => value == null ? "Please select an accommodation" : null,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.home_work_outlined, color: Colors.orange),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide(color: Colors.grey.shade300)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: const BorderSide(color: Colors.orange, width: 1.5)),
                  ),
                  hint: const Text("Select the accommodation "),
                  items: _myAccommodations.map((doc) {
                    final resData = doc.data() as Map<String, dynamic>;
                    return DropdownMenuItem<String>(
                      value: doc.id,
                      child: Text("${resData['type'] ?? 'Housing'} - ${resData['city'] ?? ''}"),
                    );
                  }).toList(),
                  onChanged: (value) => setState(() => _selectedListingId = value),
                ),
                const SizedBox(height: 25),

                // IMAGE CONTAINER
                buildLabel(AppStrings.roommateImage(lang), Icons.image_outlined, required: false),
                const SizedBox(height: 15),
                GestureDetector(
                  onTap: pickImage,
                  child: Container(
                    height: 130,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.orange.shade200),
                      color: Colors.orange.shade50,
                    ),
                    child: selectedImage != null
                        ? ClipRRect(borderRadius: BorderRadius.circular(20), child: Image.memory(selectedImage!, fit: BoxFit.cover, width: double.infinity, height: 130))
                        : widget.postData != null && (widget.postData!["image"] ?? "") != ""
                        ? ClipRRect(borderRadius: BorderRadius.circular(20), child: Image.network(widget.postData!["image"], fit: BoxFit.cover, width: double.infinity, height: 130))
                        : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_a_photo_outlined, size: 45, color: Colors.orange.shade700),
                        const SizedBox(height: 10),
                        Text(AppStrings.uploadImage(lang), style: TextStyle(color: Colors.orange.shade700, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 25),

                // STATUS
                buildLabel(AppStrings.status(lang), Icons.info_outline),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                  decoration: BoxDecoration(borderRadius: BorderRadius.circular(18), border: Border.all(color: Colors.grey.shade300)),
                  child: Row(
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Radio<String>(value: "Student", groupValue: status, activeColor: Colors.orange.shade700, onChanged: (value) => setState(() => status = value)),
                            Text(AppStrings.student(lang)),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Row(
                          children: [
                            Radio<String>(value: "Employee", groupValue: status, activeColor: Colors.orange.shade700, onChanged: (value) => setState(() => status = value)),
                            Text(AppStrings.employee(lang)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 25),

                // DATE
                Row(
                  children: [
                    Expanded(child: buildDateField(AppStrings.selectStartDate(lang), Icons.calendar_month_outlined, startDateController)),
                    const SizedBox(width: 15),
                    Expanded(child: buildDateField(AppStrings.selectEndDate(lang), Icons.calendar_month_outlined, endDateController)),
                  ],
                ),
                const SizedBox(height: 25),

                // LIFESTYLE
                buildLabel(AppStrings.lifestyle(lang), Icons.person_outline),
                const SizedBox(height: 15),

                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    buildLifestyleChip("Clean",        AppStrings.clean(lang)),
                    buildLifestyleChip("Smoker",       AppStrings.smoker(lang)),
                    buildLifestyleChip("Gamer",        AppStrings.gamer(lang)),
                    buildLifestyleChip("Night Person", AppStrings.nightPerson(lang)),
                    buildLifestyleChip("Quiet",        AppStrings.quiet(lang)),
                    buildLifestyleChip("Social",       AppStrings.social(lang)),
                    buildLifestyleChip("Early Sleeper",AppStrings.earlySleeper(lang)),
                    buildLifestyleChip("Pet Lover",    AppStrings.petLover(lang)),
                  ],

                ),


                const SizedBox(height: 25),

                Text(
                  "Hobbies",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 12),

                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    buildHobbyChip("Gym"),
                    buildHobbyChip("Gaming"),
                    buildHobbyChip("Movies"),
                    buildHobbyChip("Football"),
                    buildHobbyChip("Cooking"),
                    buildHobbyChip("Reading"),
                    buildHobbyChip("Traveling"),
                    buildHobbyChip("Music"),
                  ],
                ),

                // RELIGION
                buildLabel(AppStrings.religion(lang), Icons.public),
                const SizedBox(height: 10),
                _dropdown(
                  icon: Icons.public,
                  hint: AppStrings.selectReligion(lang),
                  value: religion,

                  items: ["Muslim", "Christian", "Other"],
                  displayLabels: [AppStrings.muslim(lang), AppStrings.christian(lang), AppStrings.other(lang)],
                  onChanged: (value) => setState(() => religion = value),
                ),
                const SizedBox(height: 25),

                // GENDER
                buildLabel(AppStrings.gender(lang), Icons.male_outlined),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                  decoration: BoxDecoration(borderRadius: BorderRadius.circular(18), border: Border.all(color: Colors.grey.shade300)),
                  child: Row(
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Radio<String>(value: "Male", groupValue: gender, activeColor: Colors.orange.shade700, onChanged: (value) => setState(() => gender = value)),
                            Text(AppStrings.male(lang)),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Row(
                          children: [
                            Radio<String>(value: "Female", groupValue: gender, activeColor: Colors.orange.shade700, onChanged: (value) => setState(() => gender = value)),
                            Text(AppStrings.female(lang)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 25),

                // AGE
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        validator: (value) => value == null || value.isEmpty ? "Required" : null,
                        controller: ageMinController,
                        keyboardType: TextInputType.number,
                        decoration: _inputFieldDecoration(AppStrings.minAge(lang)),
                      ),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: TextFormField(
                        validator: (value) => value == null || value.isEmpty ? "Required" : null,
                        controller: ageMaxController,
                        keyboardType: TextInputType.number,
                        decoration: _inputFieldDecoration(AppStrings.maxAge(lang)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 35),

                // BUTTON
                GestureDetector(
                  onTap: () async {
                    if (_formKey.currentState!.validate()) {
                      savePost();
                    }
                  },
                  child: Container(
                    width: double.infinity,
                    height: 60,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      color: Colors.orange.shade700,
                      boxShadow: [BoxShadow(color: Colors.orange.withOpacity(0.35), blurRadius: 12, offset: const Offset(0, 6))],
                    ),
                    child: Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.send_outlined, color: Colors.white),
                          const SizedBox(width: 10),
                          Text("Update Roommate", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20)),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNoAccommodationWidget(String lang) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(25.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.home_work_outlined, size: 80, color: Colors.grey),
            const SizedBox(height: 20),
            const Text("Accommodation Required", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xff1B1F3B))),
            const SizedBox(height: 12),
            const Text(
              "To ensure transparency and maintain high quality listings, you cannot post a roommate request until you upload your available accommodation details first.",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 15, color: Colors.black87, height: 1.5),
            ),
            const SizedBox(height: 30),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => const PostAccommodationPage())).then((_) => _checkAndFetchAccommodations());
              },
              icon: const Icon(Icons.add_home, color: Colors.white),
              label: Text("Update Roommate", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange.shade700,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              ),
            )
          ],
        ),
      ),
    );
  }

  InputDecoration _inputFieldDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      suffixIcon: Icon(Icons.calendar_today_outlined, color: Colors.grey.shade600),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide(color: Colors.grey.shade300)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide(color: Colors.orange.shade700, width: 1.5)),
    );
  }

  Widget buildLabel(String text, IconData icon, {bool required = true}) {
    return Row(
      children: [
        Icon(icon, color: Colors.orange.shade700, size: 22),
        const SizedBox(width: 10),
        Text(text, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 20, color: Color(0xff1B1F3B))),
        if (required) const Text(" *", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 20)),
      ],
    );
  }

  Widget buildDateField(String hint, IconData icon, TextEditingController controller) {
    DateTime now = DateTime.now();
    DateTime today = DateTime(now.year, now.month, now.day);

    return TextFormField(
      controller: controller,
      readOnly: true,
      autovalidateMode: AutovalidateMode.onUserInteraction, // Instantly validates fields
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return "Required";
        }
        try {
          List<String> parts = value.split('/');
          if (parts.length != 3) return "Invalid format (DD/MM/YYYY)";

          int day = int.parse(parts[0]);
          int month = int.parse(parts[1]);
          int year = int.parse(parts[2]);
          DateTime picked = DateTime(year, month, day);

          // 1. Validation for the Start Date field
          if (controller == startDateController) {
            if (picked.isBefore(today)) {
              return "Start date cannot be in the past";
            }
          }

          // 2. Validation for the End Date field
          if (controller == endDateController) {
            if (startDateController.text.isNotEmpty) {
              List<String> startParts = startDateController.text.split('/');
              DateTime startDate = DateTime(
                int.parse(startParts[2]),
                int.parse(startParts[1]),
                int.parse(startParts[0]),
              );
              // End date must strictly come AFTER the start date
              if (picked.isBefore(startDate) || picked.isAtSameMomentAs(startDate)) {
                return "End date must be after start date";
              }
            } else if (picked.isBefore(today)) {
              return "End date cannot be in the past";
            }
          }
        } catch (_) {
          return "Invalid date selection";
        }
        return null;
      },
      onTap: () async {
        // Default earliest selection boundary is today
        DateTime dynamicFirstDate = today;

        // If configuring the End Date, look at what was picked for the Start Date
        if (controller == endDateController && startDateController.text.isNotEmpty) {
          try {
            List<String> startParts = startDateController.text.split('/');
            DateTime startDate = DateTime(
              int.parse(startParts[2]),
              int.parse(startParts[1]),
              int.parse(startParts[0]),
            );
            // Sets the minimum selectable day in the calendar to 1 day AFTER the start date
            dynamicFirstDate = startDate.add(const Duration(days: 1));
          } catch (_) {}
        }

        // Handle initial calendar focus point cleanly
        DateTime initialDate = dynamicFirstDate;
        if (controller.text.isNotEmpty) {
          try {
            List<String> parts = controller.text.split('/');
            DateTime parsedTextDate = DateTime(int.parse(parts[2]), int.parse(parts[1]), int.parse(parts[0]));
            if (!parsedTextDate.isBefore(dynamicFirstDate)) {
              initialDate = parsedTextDate;
            }
          } catch (_) {}
        }

        DateTime? pickedDate = await showDatePicker(
          context: context,
          initialDate: initialDate,
          firstDate: dynamicFirstDate, // Blocks out unselectable historical days completely
          lastDate: DateTime(today.year + 20),
        );

        if (pickedDate != null) {
          setState(() {
            controller.text = "${pickedDate.day}/${pickedDate.month}/${pickedDate.year}";

            // UX Improvement: If they change the Start Date to a date after the current End Date,
            // automatically wipe out the invalid End Date field so they have to pick a new one.
            if (controller == startDateController && endDateController.text.isNotEmpty) {
              try {
                List<String> endParts = endDateController.text.split('/');
                DateTime endDate = DateTime(
                  int.parse(endParts[2]),
                  int.parse(endParts[1]),
                  int.parse(endParts[0]),
                );
                if (pickedDate.isAfter(endDate) || pickedDate.isAtSameMomentAs(endDate)) {
                  endDateController.clear();
                }
              } catch (_) {}
            }
          });
        }
      },
      decoration: InputDecoration(
        hintText: hint,
        suffixIcon: Icon(icon, color: Colors.grey.shade600),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: Colors.orange.shade700, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: Colors.red, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: Colors.red, width: 1.5),
        ),
      ),
    );
  }

  Widget buildLifestyleChip(String englishKey, String displayLabel) {
    bool isSelected = lifestyleValues[englishKey] ?? false;
    return GestureDetector(
      onTap: () => setState(() => lifestyleValues[englishKey] = !isSelected),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? Colors.orange.shade100 : Colors.white,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 10, offset: const Offset(0, 5))],
          border: Border.all(color: isSelected ? Colors.orange.shade700 : Colors.transparent, width: 1.5),
        ),

        child: Text(displayLabel, style: TextStyle(fontWeight: FontWeight.w600, color: isSelected ? Colors.orange.shade800 : Colors.black87)),
      ),
    );
  }
  Widget buildHobbyChip(String hobby) {
    bool isSelected = selectedHobbies.contains(hobby);

    return GestureDetector(
      onTap: () {
        setState(() {
          if (isSelected) {
            selectedHobbies.remove(hobby);
          } else {
            selectedHobbies.add(hobby);
          }
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(
          horizontal: 22,
          vertical: 16,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.orange.shade100
              : Colors.white,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
          border: Border.all(
            color: isSelected
                ? Colors.orange.shade700
                : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Text(
          hobby,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: isSelected
                ? Colors.orange.shade800
                : Colors.black87,
          ),
        ),
      ),
    );
  }


  Widget _dropdown({
    required IconData icon,
    required String hint,
    required String? value,
    required List<String> items,
    required List<String> displayLabels,
    required Function(String?) onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      validator: (value) => value == null ? "Required" : null,
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: Colors.orange.shade700),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide(color: Colors.grey.shade300)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide(color: Colors.orange.shade700, width: 1.5)),
      ),
      hint: Text(hint),
      // value is the English key; child shows the translated label
      items: List.generate(items.length, (i) =>
          DropdownMenuItem<String>(
            value: items[i],
            child: Text(displayLabels[i]),
          )).toList(),
      onChanged: onChanged,
    );
  }
}
