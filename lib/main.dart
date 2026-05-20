import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_training/controllers/auth_controller.dart';
import 'package:firebase_training/controllers/request_controller.dart';
import 'package:firebase_training/controllers/home_controller.dart'; // <-- ADD
import 'package:firebase_training/views/add_request_view.dart';
import 'package:firebase_training/views/fixer_offers_view.dart';
import 'package:firebase_training/views/home_view.dart'; // <-- UPDATE IMPORT
import 'package:firebase_training/views/login_view.dart';
import 'package:firebase_training/views/signup_view.dart';
import 'package:firebase_training/views/user_requests_view.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:get/get.dart';
import 'firebase_options.dart';
import 'package:firebase_training/views/bids_list_view.dart';
import 'package:firebase_training/views/chat_view.dart';
import 'package:firebase_training/views/forgot_password_view.dart';
import 'package:firebase_training/views/profile_view.dart';
import 'package:firebase_training/views/earnings_view.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Register controllers
  Get.put(AuthController());
  Get.put(RequestController());
  Get.put(HomeController());

  // Check initial auth state once before starting
  final initialRoute =
      FirebaseAuth.instance.currentUser == null ? '/login' : '/home';

  runApp(MyApp(initialRoute: initialRoute));
}

class MyApp extends StatelessWidget {
  final String initialRoute;
  const MyApp({super.key, required this.initialRoute});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'FixIt - Maintenance',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6366F1), // Modern Indigo
          primary: const Color(0xFF6366F1),
          secondary: const Color(0xFF9333EA), // Purple accent
          surface: Colors.white,
          background: const Color(0xFFF8FAFC), // Slate 50
        ),
        textTheme: const TextTheme(
          displayLarge: TextStyle(fontWeight: FontWeight.bold, fontSize: 32),
          titleLarge: TextStyle(fontWeight: FontWeight.w600, fontSize: 20),
        ),
        cardTheme: CardTheme(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          color: Colors.white,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Colors.grey.shade200),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Colors.grey.shade200),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFF6366F1), width: 2),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF6366F1),
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 56),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 0,
          ),
        ),
      ),
      defaultTransition: Transition.cupertino,
      initialRoute: initialRoute,
      getPages: [
        GetPage(name: '/login', page: () => LoginView()),
        GetPage(name: '/signup', page: () => SignupView()),
        GetPage(name: '/add_request', page: () => AddRequestView()),
        GetPage(name: '/home', page: () => HomeView()),
        GetPage(name: '/forgot_password', page: () => ForgotPasswordView()),
        GetPage(name: '/profile', page: () => ProfileView()),
        GetPage(
          name: '/bids',
          page: () => BidsListView(request: Get.arguments),
        ),
        GetPage(
          name: '/chat',
          page:
              () => ChatView(
                requestId: Get.arguments['requestId'],
                chatTitle: Get.arguments['chatTitle'],
              ),
        ),
        GetPage(name: '/fixer_offers', page: () => FixerOffersView()),
        GetPage(name: '/earnings', page: () => EarningsView()),
        GetPage(name: '/user_requests', page: () => const UserRequestsView()),
      ],
    );
  }
}
