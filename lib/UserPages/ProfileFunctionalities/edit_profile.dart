import 'package:flutter/material.dart';
import '../../AppFunctionalities/app_strings.dart';
// FIX: removed duplicate imports (cloud_firestore and firebase_auth were each imported twice)
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final Color primaryCoral = const Color(0xFFE65100);

  final Color bgLight = const Color(0xFFF6F3F1);

  final TextEditingController neighborhood = TextEditingController();




  final TextEditingController bio = TextEditingController();
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  final FirebaseAuth auth = FirebaseAuth.instance;
  Uint8List? selectedImage;

  final FirebaseStorage storage = FirebaseStorage.instance;

  String pets = "No";
  String looking = "Accommodation";
  String smoking = "No";
  String nationality = "Saudi";
  String religion = "Christian";
  String status = "Employee";

  List<String> lifestyle = [];
  List<String> hobbies = [];
  String profileImageUrl = "";

  String? selectedDistrict;
  String? selectedArea;

  final Map<String, List<String>> districts = {
    "لواء الجامعة": [
      "الجبيهة",
      "صويلح",
      "تلاع العلي",
      "خلدا",
      "أم السماق",
      "شفا بدران",
    ],

    "لواء وادي السير": [
      "الصويفية",
      "دابوق",
      "مرج الحمام",
      "البنيات",
      "وادي السير",
    ],

    "لواء ماركا": ["ماركا الشمالية", "ماركا الجنوبية", "النصر", "طارق"],

    "لواء القويسمة": ["القويسمة", "أبو علندا", "الجويدة", "خريبة السوق"],

    "لواء الجيزة": ["الجيزة", "أم الرصاص", "الطيبة"],

    "لواء ناعور": ["ناعور", "حسبان", "أم البساتين"],

    "لواء سحاب": ["سحاب", "اليادودة", "الرقيم"],
  };

  /// Lifestyle Options (always stored in English in Firestore)
  final List<String> lifestyleOptions = [
    "Clean",
    "Smoker",
    "Gamer",
    "Night Person",
    "Quiet",
    "Social",
    "Early Sleeper",
    "Pet Lover",
  ];

  /// Hobbies Options (always stored in English in Firestore)
  final List<String> hobbiesOptions = [
    "Gym",
    "Music",
    "Travel",
    "Cooking",
    "Football",
    "Gaming",
    "Reading",
    "Movies",
  ];

  Future saveProfile() async {
    String uid = auth.currentUser!.uid;
    String imageUrl = await uploadProfileImage();
    await firestore.collection("users").doc(uid).set({
      "neighborhood": neighborhood.text,



      "bio": bio.text,

      "pets": pets,

      "looking": looking,

      "smoking": smoking,

      "nationality": nationality,

      "religion": religion,

      "status": status,

      "lifestyle": lifestyle,

      "hobbies": hobbies,
      "profileImage": imageUrl,

      "district": selectedDistrict,
      "area": selectedArea,

      "updatedAt": Timestamp.now(),
    }, SetOptions(merge: true));

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("Profile Updated")));
  }

  Future loadProfile() async {
    String uid = auth.currentUser!.uid;

    DocumentSnapshot doc = await firestore.collection("users").doc(uid).get();

    if (!doc.exists) return;

    var data = doc.data() as Map<String, dynamic>;

    setState(() {
      selectedDistrict = data["district"];
      selectedArea = data["area"];

      neighborhood.text = data["neighborhood"] ?? "";


      bio.text = data["bio"] ?? "";

      pets = data["pets"] ?? "No";

      looking = data["looking"] ?? "Accommodation";

      smoking = data["smoking"] ?? "No";

      nationality = data["nationality"] ?? "Saudi";

      religion = data["religion"] ?? "Christian";

      status = data["status"] ?? "Employee";

      lifestyle = List<String>.from(data["lifestyle"] ?? []);

      hobbies = List<String>.from(data["hobbies"] ?? []);
      profileImageUrl = data["profileImage"] ?? "";
    });
  }

  Future pickImage() async {
    final ImagePicker picker = ImagePicker();

    final XFile? file = await picker.pickImage(source: ImageSource.gallery);

    if (file != null) {
      selectedImage = await file.readAsBytes();

      setState(() {});
    }
  }

  Future<String> uploadProfileImage() async {
    if (selectedImage == null) {
      return profileImageUrl; // keep existing image URL if no new image selected
    }

    String uid = auth.currentUser!.uid;

    Reference ref = storage.ref().child("profile_images").child(uid);

    await ref.putData(selectedImage!);

    return await ref.getDownloadURL();
  }

  @override
  void initState() {
    super.initState();

    loadProfile();
  }

  @override
  Widget build(BuildContext context) {
    String lang = Localizations.localeOf(context).languageCode;

    return Scaffold(
      backgroundColor: bgLight,

      appBar: AppBar(
        backgroundColor: Colors.orange.shade900,

        title: Text(
          AppStrings.editProfile(lang),

          style: const TextStyle(color: Colors.white),
        ),

        iconTheme: const IconThemeData(color: Colors.white),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,

          children: [
            Center(
              child: Column(
                children: [
                  GestureDetector(
                    onTap: pickImage,

                    child: CircleAvatar(
                      radius: 50,

                      backgroundImage:
                          selectedImage != null
                              ? MemoryImage(selectedImage!)
                              : profileImageUrl.isNotEmpty
                              ? NetworkImage(profileImageUrl) as ImageProvider
                              : null,
                      child:
                          selectedImage == null && profileImageUrl.isEmpty
                              ? const Icon(Icons.camera_alt, size: 35)
                              : null,
                    ),
                  ),

                  const SizedBox(height: 12),

                  Text(
                    "Edit Your Profile",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange.shade900,
                    ),
                  ),

                  const SizedBox(height: 5),

                  Text(
                    "Keep your profile updated",
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            /// Lifestyle
            Text(
              AppStrings.lifestyle(lang),

              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 15),

            Wrap(
              spacing: 10,
              runSpacing: 10,

              children:
                  lifestyleOptions.map((item) {
                    bool selected = lifestyle.contains(item);

                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          if (selected) {
                            lifestyle.remove(item);
                          } else {
                            lifestyle.add(item);
                          }
                        });
                      },

                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,

                          vertical: 12,
                        ),

                        decoration: BoxDecoration(
                          color: selected ? primaryCoral : Colors.white,

                          borderRadius: BorderRadius.circular(30),

                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.08),

                              blurRadius: 10,

                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),

                        child: Text(
                          item == "Clean"
                              ? AppStrings.clean(lang)
                              : item == "Smoker"
                              ? AppStrings.smoker(lang)
                              : item == "Gamer"
                              ? AppStrings.gamer(lang)
                              : item == "Night Person"
                              ? AppStrings.nightPerson(lang)
                              : item == "Quiet"
                              ? AppStrings.quiet(lang)
                              : item == "Social"
                              ? AppStrings.social(lang)
                              : item == "Early Sleeper"
                              ? AppStrings.earlySleeper(lang)
                              : item == "Pet Lover"
                              ? AppStrings.petLover(lang)
                              : item,

                          style: TextStyle(
                            color: selected ? Colors.white : Colors.black,

                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
            ),

            const SizedBox(height: 30),

            /// Hobbies
            Text(
              AppStrings.hobbies(lang),

              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 15),

            Wrap(
              spacing: 10,
              runSpacing: 10,

              children:
                  hobbiesOptions.map((item) {
                    bool selected = hobbies.contains(item);

                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          if (selected) {
                            hobbies.remove(item);
                          } else {
                            hobbies.add(item);
                          }
                        });
                      },

                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,

                          vertical: 12,
                        ),

                        decoration: BoxDecoration(
                          color: selected ? primaryCoral : Colors.white,

                          borderRadius: BorderRadius.circular(30),

                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.08),

                              blurRadius: 10,

                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),

                        child: Text(
                          item == "Gym"
                              ? AppStrings.gym(lang)
                              : item == "Music"
                              ? AppStrings.music(lang)
                              : item == "Travel"
                              ? AppStrings.travel(lang)
                              : item == "Cooking"
                              ? AppStrings.cooking(lang)
                              : item == "Football"
                              ? AppStrings.football(lang)
                              : item == "Gaming"
                              ? AppStrings.gaming(lang)
                              : item == "Reading"
                              ? AppStrings.reading(lang)
                              : item == "Movies"
                              ? AppStrings.movies(lang)
                              : item,

                          style: TextStyle(
                            color: selected ? Colors.white : Colors.black,

                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
            ),

            const SizedBox(height: 30),

            Text(
              "Location",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 15),

            /// DISTRICT
            _dropdown(
              icon: Icons.location_city,
              value: selectedDistrict,
              items: districts.keys.toList(),
              onChanged: (value) {
                setState(() {
                  selectedDistrict = value;
                  selectedArea = null;
                });
              },
            ),

            /// AREA
            if (selectedDistrict != null)
              _dropdown(
                icon: Icons.map_outlined,
                value: selectedArea,
                items: districts[selectedDistrict]!,
                onChanged: (value) {
                  setState(() {
                    selectedArea = value;
                  });
                },
              ),

            const SizedBox(height: 20),

            /// Bio
            _textField(
              controller: bio,
              hint: AppStrings.writeBio(lang),
              icon: Icons.info_outline,
              maxLines: 3,
            ),
            const SizedBox(height: 20),

            Text(
              "Personal Information",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 15),

            /// Nationality
            _dropdown(
              icon: Icons.flag_outlined,
              value: nationality,
              items: ["Jordanian", "Saudi", "Egyptian"],
              onChanged: (value) {
                setState(() {
                  nationality = value!;
                });
              },
            ),

            _dropdown(
              icon: Icons.mosque_outlined,
              value: religion,
              items: ["Muslim", "Christian"],
              onChanged: (value) {
                setState(() {
                  religion = value!;
                });
              },
            ),

            _dropdown(
              icon: Icons.work_outline,
              value: status,
              items: ["Student", "Employee"],
              onChanged: (value) {
                setState(() {
                  status = value!;
                });
              },
            ),

            const SizedBox(height: 30),

            SizedBox(
              width: double.infinity,

              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryCoral,

                  padding: const EdgeInsets.symmetric(vertical: 16),

                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),

                onPressed: () async {
                  await saveProfile();
                  Navigator.pop(context);
                },

                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,

                  children: [
                    const Icon(Icons.save_outlined, color: Colors.white),

                    const SizedBox(width: 10),

                    Text(
                      AppStrings.saveChanges(lang),

                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _textField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),

      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,

          borderRadius: BorderRadius.circular(16),

          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),

              blurRadius: 10,

              offset: const Offset(0, 5),
            ),
          ],
        ),

        child: TextField(
          controller: controller,

          maxLines: maxLines,

          decoration: InputDecoration(
            hintText: hint,

            prefixIcon: Icon(icon, color: primaryCoral),

            border: InputBorder.none,

            contentPadding: const EdgeInsets.all(18),
          ),
        ),
      ),
    );
  }

  Widget _dropdown({
    required IconData icon,
    required String? value,
    required List<String> items,
    required Function(String?) onChanged,
  }) {
    String lang = Localizations.localeOf(context).languageCode;

    return Padding(
      padding: const EdgeInsets.only(bottom: 18),

      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18),

        decoration: BoxDecoration(
          color: Colors.white,

          borderRadius: BorderRadius.circular(16),

          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),

              blurRadius: 10,

              offset: const Offset(0, 5),
            ),
          ],
        ),

        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            hint: const Text("Select"),

            value: items.contains(value) ? value : null,

            isExpanded: true,

            items:
                items.map((item) {
                  return DropdownMenuItem(
                    value: item,

                    child: Row(
                      children: [
                        Icon(icon, color: primaryCoral),

                        const SizedBox(width: 10),

                        Text(
                          item == "Yes"
                              ? AppStrings.yes(lang)
                              : item == "No"
                              ? AppStrings.no(lang)
                              : item == "Student"
                              ? AppStrings.student(lang)
                              : item == "Employee"
                              ? AppStrings.employee(lang)
                              : item == "Muslim"
                              ? AppStrings.muslim(lang)
                              : item == "Christian"
                              ? AppStrings.christian(lang)
                              : item == "Jordanian"
                              ? AppStrings.jordanian(lang)
                              : item == "Saudi"
                              ? AppStrings.saudi(lang)
                              : item == "Egyptian"
                              ? AppStrings.egyptian(lang)
                              : item == "Roommate"
                              ? AppStrings.postRoommate(lang)
                              : item == "Accommodation"
                              ? AppStrings.accommodation(lang)
                              : item,
                        ),
                      ],
                    ),
                  );
                }).toList(),

            onChanged: onChanged,
          ),
        ),
      ),
    );
  }
}
