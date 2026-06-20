import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:firebase_auth/firebase_auth.dart';
import '../AccommodationPages/accommodation_details.dart';

import '../RoommatesPages/roommate_details.dart';
class FavoritesPage extends StatefulWidget {
  const FavoritesPage({super.key});

  @override
  State<FavoritesPage> createState() =>
      _FavoritesPageState();
}

class _FavoritesPageState
    extends State<FavoritesPage> {

  bool showAccommodation =
  true;
  final FirebaseAuth auth =
      FirebaseAuth.instance;

  final FirebaseFirestore firestore =
      FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(

      backgroundColor:
      const Color(0xfff7f4f2),

      appBar: AppBar(

        backgroundColor:
        Colors.orange.shade900,

        elevation: 0,

        centerTitle: true,

        title: const Text(

          "Favorites",

          style: TextStyle(
            color: Colors.white,
            fontWeight:
            FontWeight.bold,
          ),
        ),
      ),

      body: Column(

        children: [

          /// TOP BUTTONS
          Container(

            padding:
            const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 15,
            ),

            child: Row(

              children: [

                Expanded(

                  child: GestureDetector(

                    onTap: () {
                      setState(() {
                        showAccommodation =
                        true;
                      });
                    },

                    child: AnimatedContainer(

                      duration:
                      const Duration(
                          milliseconds:
                          250),

                      padding:
                      const EdgeInsets
                          .symmetric(
                        vertical: 14,
                      ),

                      decoration:
                      BoxDecoration(

                        color:
                        showAccommodation

                            ? Colors.orange
                            : Colors.white,

                        borderRadius:
                        BorderRadius
                            .circular(
                            18),

                        boxShadow: [

                          BoxShadow(

                            color:
                            Colors.black
                                .withOpacity(
                                0.05),

                            blurRadius:
                            12,

                            offset:
                            const Offset(
                                0,
                                5),
                          ),
                        ],
                      ),

                      child: Center(

                        child: Text(

                          "Accommodations",

                          style: TextStyle(

                            color:
                            showAccommodation

                                ? Colors.white
                                : Colors.black,

                            fontWeight:
                            FontWeight.bold,

                            fontSize: 15,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(
                    width: 15),

                Expanded(

                  child: GestureDetector(

                    onTap: () {
                      setState(() {
                        showAccommodation =
                        false;
                      });
                    },

                    child: AnimatedContainer(

                      duration:
                      const Duration(
                          milliseconds:
                          250),

                      padding:
                      const EdgeInsets
                          .symmetric(
                        vertical: 14,
                      ),

                      decoration:
                      BoxDecoration(

                        color:
                        !showAccommodation

                            ? Colors.orange
                            : Colors.white,

                        borderRadius:
                        BorderRadius
                            .circular(
                            18),

                        boxShadow: [

                          BoxShadow(

                            color:
                            Colors.black
                                .withOpacity(
                                0.05),

                            blurRadius:
                            12,

                            offset:
                            const Offset(
                                0,
                                5),
                          ),
                        ],
                      ),

                      child: Center(

                        child: Text(

                          "Roommates",

                          style: TextStyle(

                            color:
                            !showAccommodation

                                ? Colors.white
                                : Colors.black,

                            fontWeight:
                            FontWeight.bold,

                            fontSize: 15,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          /// FAVORITES BODY
          Expanded(

            child: StreamBuilder(

              stream:

              showAccommodation

                  ? firestore
                  .collection(
                  "favoritesAccommodation")
                  .where(

                "userId",

                isEqualTo:
                auth.currentUser!.uid,
              )
                  .snapshots()

                  : firestore
                  .collection(
                  "favoritesRoommates")
                  .where(

                "userId",

                isEqualTo:
                auth.currentUser!.uid,
              )
                  .snapshots(),

              builder:
                  (context, snapshot) {
                if (snapshot.connectionState
                    ==
                    ConnectionState.waiting) {
                  return const Center(

                    child:
                    CircularProgressIndicator(),
                  );
                }

                if (!snapshot.hasData ||
                    snapshot.data!.docs
                        .isEmpty) {
                  return const Center(

                    child: Text(

                      "No Favorites Yet",
                    ),
                  );
                }

                var favorites =
                    snapshot.data!.docs;

                return ListView.builder(

                  padding:
                  const EdgeInsets.all(
                      12),

                  itemCount:
                  favorites.length,

                  itemBuilder:
                      (context, index) {
                    var favorite =
                    favorites[index];

                    return FutureBuilder(

                      future:

                      showAccommodation

                          ? firestore
                          .collection(
                          "roomListings")
                          .where(

                        "postId",

                        isEqualTo:
                        favorite["postId"],
                      )
                          .get()

                          : firestore
                          .collection(
                          "roommateRequests")
                          .where(

                        "postId",

                        isEqualTo:
                        favorite["postId"],
                      )
                          .get(),

                      builder:
                          (context,
                          postSnapshot,) {
                        if (!postSnapshot
                            .hasData) {
                          return const SizedBox();
                        }

                        var docs =
                            postSnapshot
                                .data!
                                .docs;

                        if (docs.isEmpty) {
                          return const SizedBox();
                        }

                        var post =
                            docs.first;

                        return GestureDetector(

                          onTap: () {
                            Navigator.push(

                              context,

                              MaterialPageRoute(

                                builder: (context) =>

                                showAccommodation

                                    ? AccommodationDetailsPage(

                                  post:
                                  post.data(),
                                )

                                    : RoommateDetailsPage(

                                  request:
                                  post.data(),
                                ),
                              ),
                            );
                          },

                          child: Container(

                            margin:
                            const EdgeInsets.only(
                                bottom: 15),

                            decoration:
                            BoxDecoration(

                              color:
                              Colors.white,

                              borderRadius:
                              BorderRadius
                                  .circular(
                                  22),

                              boxShadow: [

                                BoxShadow(

                                  color:
                                  Colors.black
                                      .withOpacity(
                                      0.06),

                                  blurRadius:
                                  18,

                                  offset:
                                  const Offset(
                                      0,
                                      10),
                                ),
                              ],
                            ),

                            child: Padding(

                              padding:
                              const EdgeInsets
                                  .all(12),

                              child: Row(

                                children: [

                                  /// IMAGE
                                  Container(

                                    width: 110,
                                    height: 110,

                                    decoration:
                                    BoxDecoration(

                                      borderRadius:
                                      BorderRadius
                                          .circular(
                                          18),

                                      color:
                                      Colors.orange
                                          .shade50,
                                    ),

                                    child:
                                    post["image"] != ""

                                        ? ClipRRect(

                                      borderRadius:
                                      BorderRadius
                                          .circular(
                                          18),

                                      child:
                                      Image.network(

                                        post["image"],

                                        fit:
                                        BoxFit.cover,
                                      ),
                                    )

                                        : Icon(

                                      showAccommodation

                                          ? Icons
                                          .home_work_outlined

                                          : Icons
                                          .person_outline,

                                      color:
                                      Colors.orange
                                          .shade700,

                                      size: 45,
                                    ),
                                  ),

                                  const SizedBox(
                                      width: 14),

                                  /// INFO
                                  Expanded(

                                    child: Column(

                                      crossAxisAlignment:
                                      CrossAxisAlignment
                                          .start,

                                      children: [

                                        Text(

                                          showAccommodation

                                              ? "${post["type"]} • ${post["city"]}"

                                              : "${post["gender"]} • ${post["religion"]}",

                                          style:
                                          const TextStyle(

                                            fontSize:
                                            17,

                                            fontWeight:
                                            FontWeight
                                                .bold,
                                          ),
                                        ),

                                        const SizedBox(
                                            height: 8),

                                        Text(

                                          showAccommodation

                                              ? post["street"]

                                              : "Age ${post["ageMin"]} - ${post["ageMax"]}",

                                          style:
                                          TextStyle(

                                            color:
                                            Colors
                                                .grey
                                                .shade700,

                                            fontSize:
                                            14,
                                          ),
                                        ),

                                        const SizedBox(
                                            height: 10),

                                        Container(

                                          padding:
                                          const EdgeInsets
                                              .symmetric(

                                            horizontal:
                                            10,

                                            vertical:
                                            5,
                                          ),

                                          decoration:
                                          BoxDecoration(

                                            color:
                                            Colors
                                                .orange
                                                .shade100,

                                            borderRadius:
                                            BorderRadius
                                                .circular(
                                                10),
                                          ),

                                          child: Text(

                                            showAccommodation

                                                ? "\$${post["priceMin"]} - \$${post["priceMax"]}"

                                                : post["status"],

                                            style:
                                            const TextStyle(

                                              fontWeight:
                                              FontWeight
                                                  .bold,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  /// DELETE FAVORITE
                                  IconButton(

                                    onPressed:
                                        () async {
                                      await firestore
                                          .collection(

                                          showAccommodation

                                              ? "favoritesAccommodation"

                                              : "favoritesRoommates")
                                          .doc(
                                          favorite.id)
                                          .delete();
                                    },

                                    icon:
                                    const Icon(

                                      Icons.favorite,

                                      color:
                                      Colors.red,
                                    ),
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
          ),
        ],
      ),
    );
  }
}

