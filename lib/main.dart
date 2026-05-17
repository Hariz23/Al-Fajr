import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'language_provider.dart';
import 'admin_profile_provider.dart';
import 'home_screen.dart';
import 'login_screen.dart';
import 'firebase_options.dart';
import 'notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  
  // Initialize notification plugins and permissions hooks
  await NotificationService().init();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => LanguageProvider()),
        ChangeNotifierProvider(create: (_) => AdminProfileProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.green, useMaterial3: true),
      home: const AuthWrapper(),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        
        // If the user is authenticated, handle scheduling and send them to the Dashboard
        if (snapshot.hasData) {
          // AUTOMATION FIX: Trigger the scheduling engine as soon as the user is authenticated.
          // Replace this hardcoded map with your actual prayer calculation database/API output map.
          WidgetsBinding.instance.addPostFrameCallback((_) async {
            Map<String, String> currentPrayerTimes = {
              'Fajr': '05:46',
              'Dhuhr': '13:05',
              'Asr': '16:29',
              'Maghrib': '19:15',
              'Isha': '20:28',
            };

            debugPrint("AuthWrapper: User detected. Automating background prayer registration queue...");
            await NotificationService().scheduleAllPrayers(currentPrayerTimes);
          });

          return const MainDashboard(); 
        }
        
        // Otherwise, show the Login Screen
        return const LoginScreen();
      },
    );
  }
}