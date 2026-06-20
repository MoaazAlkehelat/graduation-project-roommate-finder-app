import 'package:flutter/material.dart';

import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:firebase_auth/firebase_auth.dart';

class NotificationsPage
    extends StatelessWidget {

  NotificationsPage({super.key});

  final FirebaseFirestore firestore =
      FirebaseFirestore.instance;

  final FirebaseAuth auth =
      FirebaseAuth.instance;

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      appBar: AppBar(

        title:
        const Text("Notifications"),
      ),

      body: StreamBuilder(

        stream: firestore

            .collection("notifications")

            .where(

          "userId",

          isEqualTo:
          auth.currentUser!.uid,
        )
        // FIX: added orderBy so newest notifications appear first
            .orderBy("createdAt", descending: true)

            .snapshots(),

        builder:
            (context, snapshot) {

          if(!snapshot.hasData){

            return const Center(

              child:
              CircularProgressIndicator(),
            );
          }

          var notifications =
              snapshot.data!.docs;

          if(notifications.isEmpty){

            return const Center(

              child: Text(

                "No Notifications",
              ),
            );
          }

          return ListView.builder(

            itemCount:
            notifications.length,

            itemBuilder:
                (context, index) {

              var notification =
              notifications[index];

              return ListTile(

                leading: CircleAvatar(

                  backgroundColor:
                  Colors.orange,

                  child: Icon(

                    Icons.notifications,

                    color:
                    Colors.white,
                  ),
                ),

                title: Text(

                  notification["title"] ?? "",
                ),

                subtitle: Text(

                  notification["body"] ?? "",
                ),

                trailing:

                notification["isSeen"]
                    == false

                    ?

                const Icon(

                  Icons.circle,

                  color: Colors.red,

                  size: 12,
                )

                    :

                null,
              );
            },
          );
        },
      ),
    );
  }
}
