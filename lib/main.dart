import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'UserPages/ProfileFunctionalities/login.dart';
import 'UserPages/homepage.dart';
import 'UserPages/RoommatesPages/findroommate.dart';
import 'UserPages/RoommatesPages/edit_roommate.dart';
import 'UserPages/AccommodationPages/accommodation.dart';
import 'UserPages/ProfileServicesPages/services.dart';
import 'UserPages/ProfileFunctionalities/profile.dart';
import 'UserPages/post.dart';
import 'UserPages/ProfileFunctionalities/edit_profile.dart';
import 'AdminPages/AdminHomePage.dart';
import 'AdminPages/AdminFunctionalities/ManageServicesPage.dart';
import 'AdminPages/AdminFunctionalities/AddServicePage.dart';
import 'AdminPages/ReportsPage.dart';
import 'AdminPages/AdminProfile.dart';

//import 'notifications_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  static void setLocale(BuildContext context, Locale locale) {
    _MyAppState? state = context.findAncestorStateOfType<_MyAppState>();

    state?.changeLanguage(locale);
  }

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  Locale _locale = const Locale('en');

  void changeLanguage(Locale locale) {
    setState(() {
      _locale = locale;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,

      locale: _locale,

      supportedLocales: const [Locale('en'), Locale('ar')],

      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,

        GlobalWidgetsLocalizations.delegate,

        GlobalCupertinoLocalizations.delegate,
      ],

      theme: ThemeData(
        brightness: Brightness.light,

        primaryColor: Colors.orange,

        colorScheme: const ColorScheme.light(primary: Colors.orange),
      ),

      initialRoute: '/login',

      routes: {
        '/login': (context) => const LogInPage(),

        '/': (context) => const homepage(),

        '/findRoommate': (context) => const FindRoommate(),

        '/accommodation': (context) => const Accommodation(),

        '/services': (context) => const Services(),

        '/profile': (context) => const ProfilePage(),

        '/post': (context) => const PostPage(),

        '/edit_profile': (context) => const EditProfilePage(),

        '/AdminHomePage': (context) => const AdminHomePage(),

        '/ManageServicesPage': (context) => const ManageServicesPage(),

        '/AddServicePage': (context) => const AddServicePage(),

        '/ReportsPage': (context) => const ReportsPage(),

        '/AdminProfile': (context) => const AdminProfile(),
        // '/notifications':
        //   (context) => NotificationsPage(),
      },
    );
  }
}
