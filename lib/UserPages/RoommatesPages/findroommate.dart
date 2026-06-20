import 'package:flutter/material.dart';
import '../../AppFunctionalities/app_strings.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'roommate_details.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../ChatFolder/chat_screen.dart';
import '../ChatFolder/chats_page.dart';

class FindRoommate extends StatefulWidget {
  const FindRoommate({super.key});

  @override
  State<FindRoommate> createState() => _FindRoommateState();
}

class _FindRoommateState extends State<FindRoommate> {
  int currentIndex = 0;
  String searchText = "";
  String selectedGender = "All";
  double minAge = 18;
  double maxAge = 70;
  String selectedStatus = "All";
  String selectedReligion = "All";

  String selectedDistrictFilter = "All";
  String selectedAreaFilter = "All";

  final Map<String, List<String>> districts = {
    "لواء الجامعة": ["الجامعة", "صويلح", "تلاع العلي", "خلدا", "أبو نصير"],
    "لواء ماركا": ["ماركا", "النصر", "طارق", "بسمان"],
    "لواء القويسمة": ["القويسمة", "أبو علندا", "الجويدة"],
    "لواء وادي السير": ["وادي السير", "الصويفية", "دابوق", "مرج الحمام"],
    "لواء الجيزة": ["الجيزة", "أم العمد", "اليادودة"],
  };

  List<String> selectedLifestyle = [];
  Map<String, dynamic>? currentUserData;

  String _myGender = "";
  Set<String> _blockedUserIds = {};
  Set<String> _femaleOnlyUserIds = {};

  Future<void> loadCurrentUser() async {
    String? uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    var doc = await FirebaseFirestore.instance.collection("users").doc(uid).get();
    if (doc.exists) {
      setState(() {
        currentUserData = doc.data() as Map<String, dynamic>;
        _myGender = (currentUserData?["gender"] ?? "").toString().toLowerCase();
      });
    }
  }

  Future<double> calculateMatchScore(
      Map<String, dynamic> user,
      Map<String, dynamic> request,
      ) async {
    double score = 0;

    final String? posterId = request["userId"]?.toString();
    if (posterId != null && posterId.isNotEmpty) {
      try {
        final posterDoc = await FirebaseFirestore.instance.collection("users").doc(posterId).get();
        if (posterDoc.exists) {
          // 🔥 Safe map casting to prevent field errors
          final posterData = posterDoc.data() as Map<String, dynamic>? ?? {};

          final String myArea = (user["area"]?.toString() ?? "").trim().toLowerCase();
          final String posterArea = (posterData["area"]?.toString() ?? "").trim().toLowerCase();
          if (myArea.isNotEmpty && posterArea.isNotEmpty && myArea == posterArea) {
            score += 35;
          }

          final String myCity = (user["city"]?.toString() ?? "").trim().toLowerCase();
          final String posterCity = (posterData["city"]?.toString() ?? "").trim().toLowerCase();
          if (myCity.isNotEmpty && posterCity.isNotEmpty && myCity == posterCity) {
            score += 10;
          }
        }
      } catch (_) {}
    }

    final List userLifestyle = user["lifestyle"] is List ? user["lifestyle"] : [];
    final List requestLifestyle = request["lifestyle"] is List ? request["lifestyle"] : [];
    if (userLifestyle.isNotEmpty) {
      final int common = userLifestyle.where((item) => requestLifestyle.contains(item)).length;
      score += (common / userLifestyle.length) * 25;
    }

    final List userHobbies = user["hobbies"] is List ? user["hobbies"] : [];
    final List requestHobbies = request["hobbies"] is List ? request["hobbies"] : [];
    if (userHobbies.isNotEmpty) {
      final int common = userHobbies.where((item) => requestHobbies.contains(item)).length;
      score += (common / userHobbies.length) * 20;
    }

    if ((user["religion"]?.toString() ?? "").isNotEmpty && user["religion"] == request["religion"]) {
      score += 5;
    }

    if ((user["status"]?.toString() ?? "").isNotEmpty && user["status"] == request["status"]) {
      score += 5;
    }

    return score;
  }

  final List<String> lifestyleOptions = [
    "Clean",
    "Gamer",
    "Quiet",
    "Social",
    "Early Sleeper",
    "Night Person",
    "Pet Lover",
  ];

  Future<void> loadBlockedUsers() async {
    String? uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    try {
      final snapshot = await FirebaseFirestore.instance.collection("blocks").where("blockerId", isEqualTo: uid).get();
      setState(() {
        // 🔥 Safe map casting for block documents
        _blockedUserIds = snapshot.docs.map((d) {
          final data = d.data() as Map<String, dynamic>?;
          return data?["blockedId"]?.toString() ?? "";
        }).where((id) => id.isNotEmpty).toSet();
      });
    } catch (e) {
      print("Error loading blocked users: $e");
    }
  }

  Future<void> loadFemaleOnlyUsers() async {
    try {
      final snapshot = await FirebaseFirestore.instance.collection("users").where("femaleOnly", isEqualTo: true).get();
      setState(() {
        _femaleOnlyUserIds = snapshot.docs.map((d) => d.id).toSet();
      });
    } catch (e) {
      print("Error loading female users: $e");
    }
  }

  @override
  void initState() {
    super.initState();
    loadCurrentUser();
    loadBlockedUsers();
    loadFemaleOnlyUsers();
  }

  @override
  Widget build(BuildContext context) {
    String lang = Localizations.localeOf(context).languageCode;

    if (currentUserData == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: Colors.orange)),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xfff7f4f2),
      appBar: AppBar(
        backgroundColor: Colors.orange.shade900,
        toolbarHeight: 80,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white, size: 30),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: IconButton(
          onPressed: () => Navigator.pushNamed(context, '/post'),
          icon: const Icon(Icons.add_circle_outline, color: Colors.white, size: 32),
        ),
        actions: [
          Row(
            children: [
              IconButton(
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    builder: (context) {
                      return StatefulBuilder(
                        builder: (context, setSheetState) {
                          return SingleChildScrollView(
                            padding: const EdgeInsets.all(20),
                            child: AnimatedPadding(
                              padding: MediaQuery.of(context).viewInsets,
                              duration: const Duration(milliseconds: 100),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Text(
                                    "Filters",
                                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 25),

                                  DropdownButtonFormField(
                                    value: selectedGender,
                                    items: ["All", "Male", "Female"]
                                        .map((gender) => DropdownMenuItem(value: gender, child: Text(gender)))
                                        .toList(),
                                    onChanged: (value) {
                                      setSheetState(() => selectedGender = value!);
                                      setState(() {});
                                    },
                                    decoration: const InputDecoration(labelText: "Gender"),
                                  ),
                                  const SizedBox(height: 20),

                                  DropdownButtonFormField<String>(
                                    value: selectedDistrictFilter,
                                    decoration: const InputDecoration(labelText: "District (اللواء)"),
                                    items: ["All", ...districts.keys].map((district) {
                                      return DropdownMenuItem(value: district, child: Text(district));
                                    }).toList(),
                                    onChanged: (value) {
                                      setSheetState(() {
                                        selectedDistrictFilter = value!;
                                        selectedAreaFilter = "All";
                                      });
                                      setState(() {});
                                    },
                                  ),
                                  const SizedBox(height: 20),

                                  if (selectedDistrictFilter != "All") ...[
                                    DropdownButtonFormField<String>(
                                      value: selectedAreaFilter,
                                      decoration: const InputDecoration(labelText: "Area (الحي)"),
                                      items: ["All", ...districts[selectedDistrictFilter]!].map((area) {
                                        return DropdownMenuItem(value: area, child: Text(area));
                                      }).toList(),
                                      onChanged: (value) {
                                        setSheetState(() => selectedAreaFilter = value!);
                                        setState(() {});
                                      },
                                    ),
                                    const SizedBox(height: 20),
                                  ],

                                  const Text("Lifestyle", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 10),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: lifestyleOptions.map((item) {
                                      bool selected = selectedLifestyle.contains(item);
                                      return FilterChip(
                                        label: Text(item),
                                        selected: selected,
                                        onSelected: (value) {
                                          setSheetState(() {
                                            if (value) {
                                              selectedLifestyle.add(item);
                                            } else {
                                              selectedLifestyle.remove(item);
                                            }
                                          });
                                          setState(() {});
                                        },
                                      );
                                    }).toList(),
                                  ),
                                  const SizedBox(height: 20),

                                  DropdownButtonFormField(
                                    value: selectedStatus,
                                    items: ["All", "Student", "Employee"]
                                        .map((item) => DropdownMenuItem(value: item, child: Text(item)))
                                        .toList(),
                                    onChanged: (value) {
                                      setSheetState(() => selectedStatus = value!);
                                      setState(() {});
                                    },
                                    decoration: const InputDecoration(labelText: "Status"),
                                  ),
                                  const SizedBox(height: 30),

                                  Text("Min Age: ${minAge.toInt()}"),
                                  Slider(
                                    value: minAge,
                                    min: 18,
                                    max: 40,
                                    divisions: 22,
                                    activeColor: Colors.orange.shade700,
                                    onChanged: (value) {
                                      setSheetState(() => minAge = value);
                                      setState(() {});
                                    },
                                  ),
                                  const SizedBox(height: 20),
                                  Text("Max Age: ${maxAge.toInt()}"),
                                  Slider(
                                    value: maxAge,
                                    min: 18,
                                    max: 70,
                                    divisions: 32,
                                    activeColor: Colors.orange.shade700,
                                    onChanged: (value) {
                                      setSheetState(() => maxAge = value);
                                      setState(() {});
                                    },
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  );
                },
                icon: const Icon(Icons.filter_list, color: Colors.white, size: 30),
              ),
              Text(AppStrings.filter(lang), style: const TextStyle(color: Colors.white, fontSize: 16)),
              const SizedBox(width: 10),
            ],
          ),
          IconButton(
            onPressed: () => Navigator.pushNamed(context, '/notifications'),
            icon: const Icon(Icons.notifications_active, color: Colors.white, size: 30),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(15),
            child: TextField(
              onChanged: (value) => setState(() => searchText = value.toLowerCase()),
              decoration: InputDecoration(
                hintText: "Search by keyword...",
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide.none),
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder(
              stream: FirebaseFirestore.instance.collection("roommateRequests").orderBy("createdAt", descending: true).snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: Colors.orange));
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text("No Requests Yet"));
                }

                var requestsSnapshots = snapshot.data!.docs;
                String currentUserId = FirebaseAuth.instance.currentUser?.uid ?? "";

                // 🔥 Fix: Extract Map BEFORE doing any processing to prevent state errors
                var requests = requestsSnapshots.where((requestSnap) {
                  var request = requestSnap.data() as Map<String, dynamic>? ?? {};

                  if (request["userId"] == currentUserId) return false;

                  final String postUserId = request["userId"]?.toString() ?? "";
                  if (_blockedUserIds.contains(postUserId)) return false;

                  // Safely read properties using Map structure and provide fallback strings
                  String religion = (request["religion"] ?? "").toString().toLowerCase();
                  String gender = (request["gender"] ?? "").toString().toLowerCase();
                  String status = (request["status"] ?? "").toString().toLowerCase();

                  String cityField = (request["city"] ?? "").toString();
                  String areaField = (request["area"] ?? "").toString();

                  double ageMin = double.tryParse(request["ageMin"]?.toString() ?? "") ?? 0;
                  double ageMax = double.tryParse(request["ageMax"]?.toString() ?? "") ?? 0;

                  var lifestyleData = request["lifestyle"];
                  List lifestyle = lifestyleData is List ? lifestyleData : [lifestyleData];

                  String lifestyleText = "";
                  if (lifestyleData is List) {
                    lifestyleText = lifestyleData.join(" ").toLowerCase();
                  } else if (lifestyleData is String) {
                    lifestyleText = lifestyleData.toLowerCase();
                  }

                  bool matchesSearch = religion.contains(searchText) ||
                      gender.contains(searchText) ||
                      status.contains(searchText) ||
                      lifestyleText.contains(searchText) ||
                      cityField.toLowerCase().contains(searchText) ||
                      areaField.toLowerCase().contains(searchText);

                  bool matchesGender = selectedGender == "All" || gender == selectedGender.toLowerCase();
                  bool matchesStatus = selectedStatus == "All" || status == selectedStatus.toLowerCase();
                  bool matchesAge = ageMin >= minAge && ageMax <= maxAge;
                  bool matchesLifestyle = selectedLifestyle.isEmpty || selectedLifestyle.any((item) => lifestyle.contains(item));

                  bool matchesDistrict = selectedDistrictFilter == "All" || cityField == selectedDistrictFilter;
                  bool matchesArea = selectedAreaFilter == "All" || areaField == selectedAreaFilter;

                  final String posterUid = request["userId"]?.toString() ?? "";
                  final bool femaleOnly = _femaleOnlyUserIds.contains(posterUid);
                  bool passesFemaleOnly = !(femaleOnly && _myGender == "male");

                  return matchesSearch &&
                      matchesGender &&
                      matchesStatus &&
                      matchesAge &&
                      matchesLifestyle &&
                      passesFemaleOnly &&
                      matchesDistrict &&
                      matchesArea;
                }).toList();

                if (requests.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search_off_rounded, size: 80, color: Colors.orange.shade200),
                        const SizedBox(height: 15),
                        Text(
                          "No roommates found",
                          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.grey.shade700),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Try adjusting your filters or search terms.",
                          style: TextStyle(fontSize: 15, color: Colors.grey.shade500),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: requests.length,
                  itemBuilder: (context, index) {
                    var requestSnap = requests[index];
                    var request = requestSnap.data() as Map<String, dynamic>? ?? {}; // Safe extraction

                    return FutureBuilder<double>(
                      future: calculateMatchScore(currentUserData!, request),
                      builder: (context, scoreSnapshot) {
                        final double matchScore = scoreSnapshot.data ?? 0;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(30),
                            boxShadow: [
                              BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 20, offset: const Offset(0, 10)),
                            ],
                          ),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(30),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => RoommateDetailsPage(request: request)),
                              );
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(24),
                                        child: SizedBox(
                                          width: 110,
                                          height: 140,
                                          child: (request["image"] ?? "") != ""
                                              ? Image.network(
                                            request["image"],
                                            fit: BoxFit.cover,
                                            errorBuilder: (context, error, stackTrace) => Container(
                                              color: Colors.orange.shade50,
                                              child: Icon(Icons.person, size: 45, color: Colors.orange.shade700),
                                            ),
                                          )
                                              : Container(
                                            color: Colors.orange.shade50,
                                            child: Icon(Icons.person, size: 45, color: Colors.orange.shade700),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 15),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            if (request["userId"] != null && request["userId"].toString().isNotEmpty)
                                              FutureBuilder<DocumentSnapshot>(
                                                future: FirebaseFirestore.instance.collection("users").doc(request["userId"] as String).get(),
                                                builder: (context, userSnap) {
                                                  String firstName = "";
                                                  if (userSnap.hasData && userSnap.data!.exists) {
                                                    final ud = userSnap.data!.data() as Map<String, dynamic>? ?? {};
                                                    firstName = ud["firstName"]?.toString() ?? ud["name"]?.toString() ?? "";
                                                  }
                                                  return Text(
                                                    firstName.isNotEmpty ? firstName : request["gender"] ?? "User",
                                                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xff1B1F3B)),
                                                  );
                                                },
                                              ),
                                            const SizedBox(height: 2),
                                            Text(request["gender"] ?? "", style: TextStyle(fontSize: 13, color: Colors.grey.shade500)),
                                            const SizedBox(height: 6),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                              decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(10)),
                                              child: Text(
                                                "${matchScore.toInt()}% Match",
                                                style: TextStyle(color: Colors.green.shade800, fontWeight: FontWeight.bold),
                                              ),
                                            ),
                                            const SizedBox(height: 10),
                                            Row(
                                              children: [
                                                Icon(Icons.cake, color: Colors.orange.shade700, size: 18),
                                                const SizedBox(width: 6),
                                                Text("Age: ${request["ageMin"] ?? "18"}-${request["ageMax"] ?? "70"}", style: const TextStyle(fontSize: 14)),
                                              ],
                                            ),
                                            const SizedBox(height: 6),
                                            Row(
                                              children: [
                                                Icon(Icons.work, color: Colors.grey.shade700, size: 18),
                                                const SizedBox(width: 6),
                                                Text(request["status"] ?? "Student", style: const TextStyle(fontSize: 14)),
                                              ],
                                            ),
                                            const SizedBox(height: 12),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                              decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(10)),
                                              child: Text(
                                                request["date"]?.toString() ?? "",
                                                style: TextStyle(color: Colors.orange.shade900, fontWeight: FontWeight.bold, fontSize: 13),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 15),
                                    child: Divider(color: Colors.grey.shade200, height: 1),
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
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        selectedItemColor: Colors.orange.shade900,
        unselectedItemColor: const Color(0xFFA0A0A0),
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        onTap: (index) {
          if (index == currentIndex) return;
          setState(() => currentIndex = index);
          if (index == 0) {
            Navigator.pushReplacementNamed(context, '/');
          } else if (index == 1) {
            Navigator.pushReplacementNamed(context, '/post');
          } else if (index == 2) {
            Navigator.push(context, MaterialPageRoute(builder: (context) => const ChatsPage()));
          } else if (index == 3) {
            Navigator.pushReplacementNamed(context, '/profile');
          }
        },
        items: [
          BottomNavigationBarItem(icon: const Icon(Icons.home), label: AppStrings.home(lang)),
          BottomNavigationBarItem(icon: const Icon(Icons.add_circle_outline), label: AppStrings.post(lang)),
          BottomNavigationBarItem(icon: const Icon(Icons.chat_bubble_outline), label: AppStrings.chat(lang)),
          BottomNavigationBarItem(icon: const Icon(Icons.person_outline), label: AppStrings.profile(lang)),
        ],
      ),
    );
  }
}