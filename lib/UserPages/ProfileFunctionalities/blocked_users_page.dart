import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class BlockedUsersPage extends StatelessWidget {
  const BlockedUsersPage({super.key});

  @override
  Widget build(BuildContext context) {

    String myUid =
        FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Blocked Users"),
      ),

      body: StreamBuilder(
        stream: FirebaseFirestore.instance
            .collection("blocks")
            .where(
          "blockerId",
          isEqualTo: myUid,
        )
            .snapshots(),

        builder: (context, snapshot) {

          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          var docs = snapshot.data!.docs;

          if (docs.isEmpty) {
            return const Center(
              child: Text(
                "No blocked users",
              ),
            );
          }

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {

              var block = docs[index];

              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance
                    .collection("users")
                    .doc(block["blockedId"])
                    .get(),

                builder: (context, userSnapshot) {

                  if (!userSnapshot.hasData) {
                    return const SizedBox();
                  }

                  var userData =
                  userSnapshot.data!.data()
                  as Map<String, dynamic>;

                  return ListTile(

                    leading: CircleAvatar(
                      backgroundImage:
                      userData["profileImage"] != null
                          ? NetworkImage(
                        userData["profileImage"],
                      )
                          : null,
                      child:
                      userData["profileImage"] == null
                          ? const Icon(Icons.person)
                          : null,
                    ),

                    title: Text(
                      "${userData["firstName"]} ${userData["lastName"]}",
                    ),

                    subtitle: Text(
                      userData["city"] ?? "",
                    ),

                    trailing: TextButton(
                      child: const Text(
                        "Unblock",
                        style: TextStyle(
                          color: Colors.red,
                        ),
                      ),

                      onPressed: () async {

                        await FirebaseFirestore
                            .instance
                            .collection("blocks")
                            .doc(block.id)
                            .delete();
                      },
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}