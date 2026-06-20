import 'package:flutter/material.dart';

import 'package:cloud_firestore/cloud_firestore.dart';

class EditAccommodationPage
    extends StatefulWidget {

  final String postId;

  final Map<String, dynamic>
  postData;

  const EditAccommodationPage({

    super.key,

    required this.postId,

    required this.postData,
  });

  @override
  State<EditAccommodationPage>
  createState() =>

      _EditAccommodationPageState();
}

class _EditAccommodationPageState
    extends State<EditAccommodationPage> {

  final FirebaseFirestore
  firestore =
      FirebaseFirestore.instance;

  late TextEditingController
  cityController;

  late TextEditingController
  streetController;

  late TextEditingController
  priceMinController;

  late TextEditingController
  priceMaxController;

  late TextEditingController
  descriptionController;

  @override
  void initState() {

    super.initState();

    cityController =
        TextEditingController(

          text:
          widget.postData["city"],
        );

    streetController =
        TextEditingController(

          text:
          widget.postData["street"],
        );

    priceMinController =
        TextEditingController(

          text:
          widget.postData["priceMin"],
        );

    priceMaxController =
        TextEditingController(

          text:
          widget.postData["priceMax"],
        );

    descriptionController =
        TextEditingController(

          text:
          widget.postData[
          "description"],
        );
  }

  Future updatePost() async {
    try {
      print("*updating*");

      print("POST ID: ${widget.postId}");
      print("CITY: ${cityController.text}");

      await firestore
          .collection("roomListings")
          .doc(widget.postId)
          .update({
        "city": cityController.text,
        "street": streetController.text,
        "priceMin": priceMinController.text,
        "priceMax": priceMaxController.text,
        "description": descriptionController.text,
      });

      print("UPDATE SUCCESS");

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Post Updated")),
      );

      Navigator.pop(context);

    } catch (e) {
      print("UPDATE ERROR: $e");

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      backgroundColor:
      const Color(0xfff7f4f2),

      appBar: AppBar(

        backgroundColor:
        Colors.orange.shade900,

        title: const Text(

          "Edit Accommodation",

          style: TextStyle(
              color: Colors.white),
        ),
      ),

      body: SingleChildScrollView(

        padding:
        const EdgeInsets.all(20),

        child: Column(

          children: [

            buildField(

              controller:
              cityController,

              hint:
              "City",
            ),

            buildField(

              controller:
              streetController,

              hint:
              "Street",
            ),

            buildField(

              controller:
              priceMinController,

              hint:
              "Min Price",
            ),

            buildField(

              controller:
              priceMaxController,

              hint:
              "Max Price",
            ),

            buildField(

              controller:
              descriptionController,

              hint:
              "Description",

              maxLines: 5,
            ),

            const SizedBox(
                height: 25),

            GestureDetector(

              onTap: updatePost,

              child: Container(

                width:
                double.infinity,

                padding:
                const EdgeInsets
                    .symmetric(
                    vertical: 16),

                decoration:
                BoxDecoration(

                  color:
                  Colors.orange
                      .shade900,

                  borderRadius:
                  BorderRadius
                      .circular(
                      18),
                ),

                child: const Center(

                  child: Text(

                    "Update Post",

                    style: TextStyle(

                      color:
                      Colors.white,

                      fontWeight:
                      FontWeight.bold,

                      fontSize: 16,
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

  Widget buildField({

    required
    TextEditingController
    controller,

    required String hint,

    int maxLines = 1,
  }) {

    return Container(

      margin:
      const EdgeInsets.only(
          bottom: 18),

      child: TextField(

        controller:
        controller,

        maxLines:
        maxLines,

        decoration:
        InputDecoration(

          hintText: hint,

          filled: true,

          fillColor:
          Colors.white,

          border:
          OutlineInputBorder(

            borderRadius:
            BorderRadius.circular(
                16),

            borderSide:
            BorderSide.none,
          ),
        ),
      ),
    );
  }
}