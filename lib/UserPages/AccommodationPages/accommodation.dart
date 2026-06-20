import 'package:flutter/material.dart';
import '../../AppFunctionalities/app_strings.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'accommodation_details.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../ChatFolder/chat_screen.dart';
import '../ChatFolder/chats_page.dart';

class Accommodation extends StatefulWidget {
  const Accommodation({super.key});

  @override
  State<Accommodation> createState() => _AccommodationState();
}

class _AccommodationState extends State<Accommodation> {
  int currentIndex = 0;
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  String searchText = "";
  String selectedType = "All";
  double minPrice = 0;
  double maxPrice = 3000;

  // 🔥 Two-step Location Filter Variables
  String selectedDistrictFilter = "All";
  String selectedAreaFilter = "All";

  // 🔥 District Map defined correctly inside the state class
  final Map<String, List<String>> districts = {
    "لواء الجامعة": ["الجامعة", "صويلح", "تلاع العلي", "خلدا", "أبو نصير"],
    "لواء ماركا": ["ماركا", "النصر", "طارق", "بسمان"],
    "لواء القويسمة": ["القويسمة", "أبو علندا", "الجويدة"],
    "لواء وادي السير": ["وادي السير", "الصويفية", "دابوق", "مرج الحمام"],
    "لواء الجيزة": ["الجيزة", "أم العمد", "اليادودة"],
  };

  Set<String> _blockedUserIds = {};

  Future<void> loadBlockedUsers() async {
    final String uid = FirebaseAuth.instance.currentUser!.uid;
    final snapshot = await FirebaseFirestore.instance
        .collection("blocks")
        .where("blockerId", isEqualTo: uid)
        .get();
    setState(() {
      _blockedUserIds =
          snapshot.docs.map((d) => d["blockedId"] as String).toSet();
    });
  }

  @override
  void initState() {
    super.initState();
    loadBlockedUsers();
  }

  @override
  Widget build(BuildContext context) {
    String lang = Localizations.localeOf(context).languageCode;

    return Scaffold(
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

                                  // Property Type
                                  DropdownButtonFormField(
                                    value: selectedType,
                                    items: ["All", "Apartment", "Studio", "Shared Room"]
                                        .map((type) => DropdownMenuItem(value: type, child: Text(type)))
                                        .toList(),
                                    onChanged: (value) {
                                      setSheetState(() => selectedType = value!);
                                      setState(() {});
                                    },
                                    decoration: const InputDecoration(labelText: "Property Type"),
                                  ),
                                  const SizedBox(height: 20),

                                  // 🔥 1. District Filter Dropdown (Lewa)
                                  DropdownButtonFormField<String>(
                                    value: selectedDistrictFilter,
                                    decoration: const InputDecoration(labelText: "District (اللواء)"),
                                    items: ["All", ...districts.keys].map((district) {
                                      return DropdownMenuItem(
                                        value: district,
                                        child: Text(district),
                                      );
                                    }).toList(),
                                    onChanged: (value) {
                                      setSheetState(() {
                                        selectedDistrictFilter = value!;
                                        selectedAreaFilter = "All"; // Reset area when changing district
                                      });
                                      setState(() {});
                                    },
                                  ),
                                  const SizedBox(height: 20),

                                  // 🔥 2. Area Filter Dropdown (Only shows if a District is selected)
                                  if (selectedDistrictFilter != "All") ...[
                                    DropdownButtonFormField<String>(
                                      value: selectedAreaFilter,
                                      decoration: const InputDecoration(labelText: "Area (الحي)"),
                                      items: ["All", ...districts[selectedDistrictFilter]!].map((area) {
                                        return DropdownMenuItem(
                                          value: area,
                                          child: Text(area),
                                        );
                                      }).toList(),
                                      onChanged: (value) {
                                        setSheetState(() {
                                          selectedAreaFilter = value!;
                                        });
                                        setState(() {});
                                      },
                                    ),
                                    const SizedBox(height: 20),
                                  ],

                                  Text("Min Price: ${minPrice.toInt()}"),
                                  Slider(
                                    value: minPrice,
                                    min: 0,
                                    max: 1000,
                                    divisions: 20,
                                    onChanged: (value) {
                                      setSheetState(() => minPrice = value);
                                      setState(() {});
                                    },
                                  ),
                                  const SizedBox(height: 20),
                                  Text("Max Price: ${maxPrice.toInt()}"),
                                  Slider(
                                    value: maxPrice,
                                    min: 0,
                                    max: 3000,
                                    divisions: 30,
                                    onChanged: (value) {
                                      setSheetState(() => maxPrice = value);
                                      setState(() {});
                                    },
                                  ),
                                  const SizedBox(height: 20),
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
              Text(AppStrings.filter(lang), style: const TextStyle(color: Colors.white)),
              const SizedBox(width: 10),
            ],
          ),
          IconButton(
            onPressed: () {},
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
              stream: firestore.collection("roomListings").orderBy("createdAt", descending: true).snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text("No Posts Yet"));
                }

                var posts = snapshot.data!.docs;
                String currentUserId = FirebaseAuth.instance.currentUser!.uid;

                posts = posts.where((post) => post["userId"] != currentUserId).toList();
                posts = posts.where((post) => !_blockedUserIds.contains(post["userId"]?.toString() ?? "")).toList();

                posts = posts.where((post) {
                  String city = post["city"].toString().toLowerCase();
                  String street = post["street"].toString().toLowerCase();
                  String type = post["type"].toString().toLowerCase();
                  String rooms = post["rooms"].toString().toLowerCase();

                  // Database specific tracking fields
                  String cityField = (post["city"] ?? "").toString();
                  String areaField = (post["area"] ?? "").toString();

                  double min = double.tryParse(post["priceMin"].toString()) ?? 0;
                  double max = double.tryParse(post["priceMax"].toString()) ?? 0;

                  bool matchesSearch = city.contains(searchText) ||
                      street.contains(searchText) ||
                      type.contains(searchText) ||
                      rooms.contains(searchText);

                  bool matchesType = selectedType == "All" || type == selectedType.toLowerCase();
                  bool matchesPrice = min >= minPrice && max <= maxPrice;

                  // 🔥 Compare database fields against active dropdown variables
                  bool matchesDistrict = selectedDistrictFilter == "All" || cityField == selectedDistrictFilter;
                  bool matchesArea = selectedAreaFilter == "All" || areaField == selectedAreaFilter;

                  return matchesSearch && matchesType && matchesPrice && matchesDistrict && matchesArea;
                }).toList();

                // 🔥 EMPTY STATE TEXT
                if (posts.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search_off_rounded, size: 80, color: Colors.orange.shade200),
                        const SizedBox(height: 15),
                        Text(
                          "No accommodations found",
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
                  itemCount: posts.length,
                  itemBuilder: (context, index) {
                    var post = posts[index];

                    return Container(
                      margin: const EdgeInsets.only(bottom: 22),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 25, offset: const Offset(0, 10)),
                        ],
                      ),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(30),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => AccommodationDetailsPage(post: post.data())),
                          );
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(18),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(24),
                                child: SizedBox(
                                  width: 135,
                                  height: 170,
                                  child: post["image"] != ""
                                      ? Image.network(
                                    post["image"],
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) => Container(
                                      color: Colors.orange.shade50,
                                      child: Icon(Icons.home_work_outlined, size: 50, color: Colors.orange.shade700),
                                    ),
                                  )
                                      : Container(
                                    color: Colors.orange.shade50,
                                    child: Icon(Icons.home_work_outlined, size: 50, color: Colors.orange.shade700),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 20),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(post["type"], style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                                    const SizedBox(height: 10),
                                    Row(
                                      children: [
                                        Icon(Icons.location_on, size: 20, color: Colors.orange.shade700),
                                        const SizedBox(width: 6),
                                        Expanded(
                                          child: Text(post["city"], style: TextStyle(fontSize: 16, color: Colors.grey.shade800)),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 10),
                                    Row(
                                      children: [
                                        Icon(Icons.route, size: 18, color: Colors.grey.shade700),
                                        const SizedBox(width: 6),
                                        Expanded(
                                          child: Text(post["street"], style: TextStyle(fontSize: 15, color: Colors.grey.shade700)),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 18),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                      decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(14)),
                                      child: Text(
                                        "\$${post["priceMin"]} - \$${post["priceMax"]}",
                                        style: TextStyle(color: Colors.orange.shade900, fontWeight: FontWeight.bold, fontSize: 15),
                                      ),
                                    ),
                                    const SizedBox(height: 14),
                                    Text(post["date"], style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 15),
                              Column(
                                children: [
                                  StreamBuilder(
                                    stream: FirebaseFirestore.instance
                                        .collection("favoritesAccommodation")
                                        .where("userId", isEqualTo: FirebaseAuth.instance.currentUser!.uid)
                                        .where("postId", isEqualTo: post["postId"])
                                        .snapshots(),
                                    builder: (context, snapshot) {
                                      bool isFavorite = snapshot.hasData && snapshot.data!.docs.isNotEmpty;

                                      return GestureDetector(
                                        onTap: () async {
                                          if (isFavorite) {
                                            await FirebaseFirestore.instance
                                                .collection("favoritesAccommodation")
                                                .doc(snapshot.data!.docs.first.id)
                                                .delete();
                                          } else {
                                            await FirebaseFirestore.instance.collection("favoritesAccommodation").add({
                                              "userId": FirebaseAuth.instance.currentUser!.uid,
                                              "postId": post["postId"],
                                              "createdAt": Timestamp.now(),
                                            });
                                          }
                                        },
                                        child: CircleAvatar(
                                          radius: 24,
                                          backgroundColor: isFavorite ? Colors.red.shade50 : Colors.orange.shade50,
                                          child: Icon(
                                            isFavorite ? Icons.favorite : Icons.favorite_border,
                                            color: isFavorite ? Colors.red : Colors.orange.shade700,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                  const SizedBox(height: 18),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
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