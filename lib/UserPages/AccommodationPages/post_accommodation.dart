import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../AppFunctionalities/app_strings.dart';
import '../posts_data.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'dart:typed_data';
import 'package:flutter/services.dart';

class PostAccommodationPage extends StatefulWidget {
  final Map<String, dynamic>? postData;
  final String? postId; // Explicit document reference tracker
  final int? postIndex;

  const PostAccommodationPage({super.key, this.postData, this.postId, this.postIndex});

  @override
  State<PostAccommodationPage> createState() => _PostAccommodationPageState();
}

class _PostAccommodationPageState extends State<PostAccommodationPage> {
  final _formKey = GlobalKey<FormState>();

  /// 🔥 Controllers
  final streetController = TextEditingController();
  final priceMinController = TextEditingController();
  final priceMaxController = TextEditingController();
  final descriptionController = TextEditingController();
  final closeToController = TextEditingController();

  final spaceController = TextEditingController();
  final roomsController = TextEditingController();
  final bathsController = TextEditingController();

  String? type;
  String? showNum;
  final FirebaseStorage storage = FirebaseStorage.instance;

  /// 🔥 IMAGE
  Uint8List? selectedImage;
  final FirebaseAuth auth = FirebaseAuth.instance;
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  String? selectedDistrict;
  String? selectedArea;

  final Map<String, List<String>> districts = {
    "لواء الجامعة": ["الجامعة", "صويلح", "تلاع العلي", "خلدا", "أبو نصير"],
    "لواء ماركا": ["ماركا", "النصر", "طارق", "بسمان"],
    "لواء القويسمة": ["القويسمة", "أبو علندا", "الجويدة"],
    "لواء وادي السير": ["وادي السير", "الصويفية", "دابوق", "مرج الحمام"],
    "لواء الجيزة": ["الجيزة", "أم العمد", "اليادودة"],
  };

  @override
  void initState() {
    super.initState();

    // Map every single layout attribute cleanly when editing an existing listing
    if (widget.postData != null) {
      selectedDistrict = widget.postData!["city"];
      selectedArea = widget.postData!["area"];
      streetController.text = widget.postData!["street"] ?? "";
      type = widget.postData!["type"];
      priceMinController.text = widget.postData!["priceMin"] ?? "";
      priceMaxController.text = widget.postData!["priceMax"] ?? "";
      descriptionController.text = widget.postData!["description"] ?? "";
      closeToController.text = widget.postData!["closeTo"] ?? "";
      spaceController.text = widget.postData!["space"] ?? "";
      roomsController.text = widget.postData!["rooms"] ?? "";
      bathsController.text = widget.postData!["baths"] ?? "";
      showNum = widget.postData!["showNum"];
    }
  }

  /// 🔥 PICK IMAGE
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

  Future<String> uploadImage() async {
    try {
      if (selectedImage == null) {
        // Fallback to the current database image link if no new image was uploaded
        return widget.postData != null ? (widget.postData!["image"] ?? "") : "";
      }

      String fileName = DateTime.now().millisecondsSinceEpoch.toString();
      Reference ref = storage.ref().child("accommodation_images").child(fileName);
      UploadTask uploadTask = ref.putData(selectedImage!);
      TaskSnapshot snapshot = await uploadTask;
      String downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      print(e.toString());
      return "";
    }
  }

  /// 🔥 SAVE / UPDATE POST
  Future savePost() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    String uid = auth.currentUser!.uid;
    String imageUrl = await uploadImage();

    Map<String, dynamic> data = {
      "userId": uid,
      "city": selectedDistrict,
      "area": selectedArea,
      "street": streetController.text,
      "type": type,
      "priceMin": priceMinController.text,
      "priceMax": priceMaxController.text,
      "date": "${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}",
      "description": descriptionController.text,
      "closeTo": closeToController.text,
      "space": spaceController.text,
      "rooms": roomsController.text,
      "baths": bathsController.text,
      "showNum": showNum,
      "image": imageUrl,
    };

    if (widget.postId != null) {
      // Direct field update using the valid Document snapshot path identifier
      await firestore
          .collection("roomListings")
          .doc(widget.postId)
          .update(data);
    } else {
      data["postId"] = DateTime.now().millisecondsSinceEpoch.toString();
      data["createdAt"] = FieldValue.serverTimestamp();
      await firestore.collection("roomListings").add(data);
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(widget.postId != null ? "Post Updated" : "Post Added"),
      ),
    );

    Navigator.pop(context);
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
          icon: const Icon(Icons.arrow_back, color: Colors.orange),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        centerTitle: true,
        title: Text(
          widget.postId != null
              ? "Update Accommodation"
              : AppStrings.postAccommodation(lang),
          style: const TextStyle(
            color: Color(0xff1B1F3B),
            fontWeight: FontWeight.bold,
            fontSize: 28,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Container(
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    /// IMAGE CONTAINER
                    buildLabel(AppStrings.accommodationImage(lang), Icons.image_outlined, required: false),
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
                            ? ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: Image.memory(selectedImage!, fit: BoxFit.cover, width: double.infinity, height: 130),
                        )
                            : widget.postData != null && widget.postData!["image"] != ""
                            ? ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: Image.network(widget.postData!["image"], fit: BoxFit.cover, width: double.infinity, height: 130),
                        )
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

                    /// DISTRICT
                    buildLabel("District", Icons.location_on_outlined),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      value: selectedDistrict,
                      decoration: inputDecoration(),
                      hint: const Text("Select District"),
                      items: districts.keys.map((district) {
                        return DropdownMenuItem(value: district, child: Text(district));
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          selectedDistrict = value;
                          selectedArea = null;
                        });
                      },
                    ),

                    if (selectedDistrict != null) ...[
                      const SizedBox(height: 25),

                      /// AREA
                      buildLabel("Area", Icons.map_outlined),
                      const SizedBox(height: 10),
                      DropdownButtonFormField<String>(
                        value: selectedArea,
                        decoration: inputDecoration(),
                        hint: const Text("Select Area"),
                        items: districts[selectedDistrict]!.map((area) {
                          return DropdownMenuItem<String>(value: area, child: Text(area));
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            selectedArea = value;
                          });
                        },
                        validator: (value) => value == null ? "Please select area" : null,
                      ),
                    ],
                    const SizedBox(height: 25),

                    /// STREET
                    buildLabel(AppStrings.street(lang), Icons.route_outlined),
                    const SizedBox(height: 10),
                    buildTextField(AppStrings.enterStreet(lang), streetController),
                    const SizedBox(height: 25),

                    /// PRICE RANGE
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              buildLabel(AppStrings.priceMin(lang), Icons.attach_money),
                              const SizedBox(height: 10),
                              buildTextField("10", priceMinController, isNumber: true),
                            ],
                          ),
                        ),
                        const SizedBox(width: 15),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              buildLabel(AppStrings.priceMax(lang), Icons.attach_money),
                              const SizedBox(height: 10),
                              buildTextField("100", priceMaxController, isNumber: true),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 25),

                    /// TYPE
                    buildLabel(AppStrings.type(lang), Icons.category_outlined),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      value: type,
                      decoration: inputDecoration(),
                      hint: Text(AppStrings.selectType(lang)),
                      items: [
                        DropdownMenuItem(value: "Apartment", child: Text(AppStrings.apartment(lang))),
                        DropdownMenuItem(value: "Studio", child: Text(AppStrings.studio(lang))),
                        DropdownMenuItem(value: "Shared Room", child: Text(AppStrings.sharedRoom(lang))),
                      ],
                      onChanged: (value) => setState(() => type = value),
                    ),
                    const SizedBox(height: 25),

                    /// SPACE / ROOMS / BATHS
                    Row(
                      children: [
                        Expanded(child: buildSmallField(AppStrings.space(lang), "120", Icons.square_foot_outlined, spaceController)),
                        const SizedBox(width: 10),
                        Expanded(child: buildSmallField(AppStrings.rooms(lang), "3", Icons.meeting_room_outlined, roomsController)),
                        const SizedBox(width: 10),
                        Expanded(child: buildSmallField(AppStrings.baths(lang), "2", Icons.bathtub_outlined, bathsController)),
                      ],
                    ),
                    const SizedBox(height: 25),

                    /// CLOSE TO
                    buildLabel(AppStrings.closeTo(lang), Icons.location_city_outlined),
                    const SizedBox(height: 10),
                    buildTextField(AppStrings.nearbyPlaces(lang), closeToController),
                    const SizedBox(height: 25),

                    /// DESCRIPTION
                    buildLabel(AppStrings.description(lang), Icons.description_outlined, required: false),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: descriptionController,
                      maxLines: 4,
                      decoration: inputDecoration().copyWith(
                        hintText: AppStrings.describeAccommodation(lang),
                        hintStyle: TextStyle(color: Colors.grey[500]),
                      ),
                    ),
                    const SizedBox(height: 25),

                    /// SHOW NUMBER
                    buildDropdownField(AppStrings.showNum(lang), Icons.remove_red_eye_outlined),
                    const SizedBox(height: 35),

                    /// SAVE SUBMIT ACTION BUTTON
                    GestureDetector(
                      onTap: savePost,
                      child: Container(
                        width: double.infinity,
                        height: 55,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(18),
                          color: Colors.orange.shade800,
                          boxShadow: [
                            BoxShadow(color: Colors.orange.withOpacity(0.35), blurRadius: 12, offset: const Offset(0, 6)),
                          ],
                        ),
                        child: Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.send_outlined, color: Colors.white),
                              const SizedBox(width: 10),
                              Text(
                                widget.postId != null ? "Update Accommodation" : AppStrings.postAccommodation(lang),
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration inputDecoration() {
    return InputDecoration(
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide(color: Colors.grey.shade300)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide(color: Colors.orange.shade700, width: 1.5)),
    );
  }

  Widget buildLabel(String text, IconData icon, {bool required = true}) {
    return Wrap(
      children: [
        Icon(icon, color: Colors.orange.shade700, size: 22),
        const SizedBox(width: 10),
        Text(text, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 20, color: Color(0xff1B1F3B))),
        if (required) const Text(" *", style: TextStyle(color: Colors.red, fontSize: 20, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget buildTextField(String hint, TextEditingController controller, {bool isNumber = false}) {
    return TextFormField(
      controller: controller,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      inputFormatters: isNumber ? <TextInputFormatter>[FilteringTextInputFormatter.allow(RegExp(r'[0-9]'))] : [],
      validator: (value) => (value == null || value.isEmpty) ? "Required" : null,
      decoration: inputDecoration().copyWith(hintText: hint, hintStyle: TextStyle(color: Colors.grey[500])),
    );
  }

  Widget buildSmallField(String title, String hint, IconData icon, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        buildLabel(title, icon),
        const SizedBox(height: 10),
        buildTextField(hint, controller, isNumber: true),
      ],
    );
  }

  Widget buildDropdownField(String hint, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        buildLabel(hint, icon, required: false),
        const SizedBox(height: 10),
        DropdownButtonFormField<String>(
          value: showNum,
          decoration: inputDecoration(),
          hint: Text(hint),
          items: [
            DropdownMenuItem(value: "Yes", child: Text(Localizations.localeOf(context).languageCode == 'ar' ? "نعم" : "Yes")),
            DropdownMenuItem(value: "No", child: Text(Localizations.localeOf(context).languageCode == 'ar' ? "لا" : "No")),
          ],
          onChanged: (value) => setState(() => showNum = value),
        ),
      ],
    );
  }
}