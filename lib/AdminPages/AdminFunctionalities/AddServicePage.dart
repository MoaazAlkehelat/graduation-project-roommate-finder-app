import 'package:flutter/material.dart';
import '../ServicesPages/HomeFoodAdminPage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AddServicePage extends StatefulWidget {
  const AddServicePage({super.key});

  @override
  State<AddServicePage> createState() => _AddServicePageState();
}

class _AddServicePageState extends State<AddServicePage> {
  /// 1. each field should not be Empty/// 2. it has the right info that match the database
  /// 3. i need a Message that confirm the info is right or not

  final _formKey = GlobalKey<FormState>();

  /// a FormKey a Validation

  final serviceNameController = TextEditingController();

  final socialLinkController = TextEditingController();

  final descriptionController = TextEditingController();

  final whatsappController = TextEditingController();

  final instagramController = TextEditingController();

  final facebookController = TextEditingController();

  String? selectedServiceType;
  Uint8List? selectedImage;

  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  final FirebaseStorage storage = FirebaseStorage.instance;

  final FirebaseAuth auth = FirebaseAuth.instance;

  bool isLoading = false;

  Future pickImage() async {
    //Image Adding

    final ImagePicker picker = ImagePicker();

    final XFile? pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
    );

    if (pickedFile != null) {
      print("IMAGE PICKED");
      Uint8List imageBytes = await pickedFile.readAsBytes();

      setState(() {
        selectedImage = imageBytes;
      });
    }
  }

  Future<String> uploadImage() async {
    try {
      print("UPLOAD STARTED");
      if (selectedImage == null) {
        return "";
      }

      String fileName = DateTime.now().millisecondsSinceEpoch.toString();

      Reference ref = storage.ref().child("service_images").child(fileName);

      UploadTask uploadTask = ref.putData(selectedImage!);

      TaskSnapshot snapshot = await uploadTask;

      String downloadUrl = await snapshot.ref.getDownloadURL();

      print(downloadUrl);
      return downloadUrl;
    } catch (e) {
      print(e.toString());

      return "";
    }
  }

  Future saveService() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      String imageUrl = await uploadImage();

      await firestore.collection("services").add({
        "title": serviceNameController.text,

        "subtitle": descriptionController.text,

        "whatsapp": whatsappController.text,

        "instagram": instagramController.text,

        "facebook": facebookController.text,

        "type": selectedServiceType,

        "image": imageUrl,

        "createdAt": FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Service Added")));

      Navigator.pop(context);
    } catch (e) {
      print(e);
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F8FC),

      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.blue),

          onPressed: () {
            Navigator.pop(context);
          },
        ),
        centerTitle: true,
        title: const Text(
          "Add Service",
          style: TextStyle(
            color: Color(0xff1B1F3B),
            fontWeight: FontWeight.bold,
            fontSize: 30,
          ),
        ),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),

        child: Container(
          padding: const EdgeInsets.all(20),

          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(30),

            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.15),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),

          child: Form(
            /// The Start of the Form
            key: _formKey,

            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                /// IMAGE
                buildLabel("Service Image", Icons.image_outlined),

                const SizedBox(height: 15),

                GestureDetector(
                  onTap: pickImage,

                  child: Container(
                    height: 130,
                    width: double.infinity,

                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),

                      border: Border.all(color: Colors.blue.shade200),

                      color: Colors.blue.shade50,
                    ),

                    child: selectedImage != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(20),

                            child: Image.memory(
                              selectedImage!,
                              fit: BoxFit.cover,
                              width: double.infinity,
                              height: 130,
                            ),
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,

                            children: [
                              Icon(
                                Icons.add_a_photo_outlined,
                                size: 45,
                                color: Colors.blue.shade700,
                              ),

                              const SizedBox(height: 10),

                              Text(
                                "Upload Service Image",

                                style: TextStyle(
                                  color: Colors.blue.shade700,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),

                const SizedBox(height: 25),

                /// SERVICE NAME
                buildLabel("Service Name", Icons.miscellaneous_services),

                const SizedBox(height: 10),

                buildTextField("Enter service name", serviceNameController),

                const SizedBox(height: 25),

                /// the TYPE selection
                buildLabel("Service Type", Icons.category_outlined),

                const SizedBox(height: 10),

                ///
                DropdownButtonFormField<String>(
                  value: selectedServiceType,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white,

                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 15,
                    ),

                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),

                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                      borderSide: BorderSide(color: Colors.blue.shade700),
                    ),
                  ),

                  hint: const Text("Select service type"),

                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return "Please select service type";
                    }

                    return null;
                  },

                  items: const [
                    DropdownMenuItem(
                      value: "Home Food",
                      child: Text("Home Food"),
                    ),

                    DropdownMenuItem(
                      value: "Dry Clean",
                      child: Text("Dry Clean"),
                    ),

                    DropdownMenuItem(
                      value: "Clean Up",
                      child: Text("Clean Up"),
                    ),

                    DropdownMenuItem(value: "Other", child: Text("Other")),
                  ],

                  onChanged: (value) {
                    setState(() {
                      selectedServiceType = value;
                    });
                  },
                ),

                const SizedBox(height: 25),

                /// DESCRIPTION
                buildLabel("Description", Icons.description_outlined),

                const SizedBox(height: 10),

                TextFormField(
                  controller: descriptionController,

                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return "Description is required";
                    }

                    return null;
                  },
                  maxLines: 4,

                  decoration: InputDecoration(
                    hintText: "Describe your service...",
                    filled: true,
                    fillColor: Colors.white,

                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 15,
                    ),

                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),

                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                      borderSide: BorderSide(color: Colors.blue.shade700),
                    ),
                  ),
                ),

                const SizedBox(height: 25),

                /// CONTACT LINK
                /// SOCIAL LINKS
                buildLabel("Social Links", Icons.link, required: false),

                const SizedBox(height: 18),

                /// WHATSAPP
                buildRequiredField("WhatsApp", Icons.phone, whatsappController),

                const SizedBox(height: 18),

                /// INSTAGRAM
                buildOptionalField(
                  "Instagram",

                  Icons.camera_alt_outlined,

                  instagramController,
                ),

                const SizedBox(height: 18),

                /// FACEBOOK
                buildOptionalField(
                  "Facebook",

                  Icons.facebook,

                  facebookController,
                ),

                const SizedBox(height: 25),

                /// BUTTON
                GestureDetector(
                  onTap: isLoading
                      ? null
                      : () async {
                          await saveService();
                        },

                  child: Container(
                    width: double.infinity,
                    height: 55,

                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      color: Colors.blue.shade800,

                      boxShadow: [
                        BoxShadow(
                          color: Colors.blue.withOpacity(0.35),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),

                    child: Center(
                      child: isLoading
                          ? const SizedBox(
                              width: 28,
                              height: 28,

                              child: CircularProgressIndicator(
                                color: Colors.white,

                                strokeWidth: 3,
                              ),
                            )
                          : const Row(
                              mainAxisAlignment: MainAxisAlignment.center,

                              children: [
                                Icon(Icons.add_business, color: Colors.white),

                                SizedBox(width: 10),

                                Text(
                                  "Add Service",

                                  style: TextStyle(
                                    color: Colors.white,

                                    fontWeight: FontWeight.bold,

                                    fontSize: 18,
                                  ),
                                ),
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

  /// LABEL
  /// LABEL
  Widget buildLabel(String text, IconData icon, {bool required = true}) {
    return Row(
      children: [
        Icon(icon, color: Colors.blue.shade700, size: 22),

        const SizedBox(width: 10),

        Text(
          text,

          style: const TextStyle(
            fontWeight: FontWeight.w600,

            fontSize: 20,

            color: Color(0xff1B1F3B),
          ),
        ),

        if (required)
          const Text(
            " *",

            style: TextStyle(
              color: Colors.red,

              fontWeight: FontWeight.bold,

              fontSize: 20,
            ),
          ),
      ],
    );
  }

  /// TEXT FIELD
  Widget buildTextField(String hint, TextEditingController controller) {
    return TextFormField(
      controller: controller,

      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return "Service name is required";
        }

        if (value.trim().length < 5) {
          return "Minimum 5 characters";
        }

        if (value.trim().length > 80) {
          return "Maximum 80 characters";
        }

        return null;
      },
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: Colors.white,

        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 15,
        ),

        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),

        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: Colors.blue.shade700, width: 1.5),
        ),
      ),
    );
  }

  /// SMALL FIELD
  Widget buildSmallField(String title, String hint, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        buildLabel(title, icon),

        const SizedBox(height: 10),

        buildTextField(hint, TextEditingController()),
      ],
    );
  }

  /// REQUIRED OPTIONAL FIELD
  Widget buildRequiredField(
    String hint,

    IconData icon,

    TextEditingController controller,
  ) {
    return TextFormField(
      controller: controller,

      validator: (value) {

        if (value == null ||
            value.trim().isEmpty) {

          return
            "WhatsApp is required";
        }

        String phone =
        value.trim();

        final jordanPhoneRegex =
        RegExp(

          r'^(?:\+962|962|0)?7[789]\d{7}$',
        );

        if (!jordanPhoneRegex
            .hasMatch(phone)) {

          return
            "Invalid Jordan phone number";
        }

        return null;
      },

      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: Colors.blue.shade700),

        hintText: hint,

        filled: true,

        fillColor: Colors.white,

        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,

          vertical: 15,
        ),

        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),

          borderSide: BorderSide(color: Colors.grey.shade300),
        ),

        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),

          borderSide: BorderSide(color: Colors.blue.shade700, width: 1.5),
        ),
      ),
    );
  }

  Widget buildOptionalField(
    String hint,

    IconData icon,

    TextEditingController controller,
  ) {
    return TextFormField(
      controller: controller,

      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: Colors.blue.shade700),

        hintText: hint,

        filled: true,

        fillColor: Colors.white,

        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,

          vertical: 15,
        ),

        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),

          borderSide: BorderSide(color: Colors.grey.shade300),
        ),

        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),

          borderSide: BorderSide(color: Colors.blue.shade700, width: 1.5),
        ),
      ),
    );
  }

  /// DROPDOWN
  Widget buildDropdown() {
    return DropdownButtonFormField<String>(
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white,

        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 15,
        ),

        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),

        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: Colors.blue.shade700),
        ),
      ),

      hint: const Text("Select type"),

      items: const [
        DropdownMenuItem(value: "Apartment", child: Text("Apartment")),
        DropdownMenuItem(value: "Studio", child: Text("Studio")),
      ],

      onChanged: (value) {},
    );
  }
}
