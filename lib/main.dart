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
import 'prayer_times_repository.dart';
import 'splash_screen.dart';
import 'theme.dart';
import 'theme_provider.dart';



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
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: const MyApp(),
    ),
  );
}



class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    //final themeP = context.watch<ThemeProvider>();
    return MaterialApp(
      title: 'Al Fajr',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      //darkTheme: AppTheme.darkTheme,           // ← add this
      themeMode: ThemeMode.light,               // ← replace ThemeMode.light
          //? ThemeMode.dark
          //: ThemeMode.light,
      home: const VideoSplashScreen(nextScreen: AuthWrapper()),
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  String? _scheduledForUserId;

  void _scheduleFor(User user, AdminProfileProvider profile) {
    if (_scheduledForUserId == user.uid) return;
    _scheduledForUserId = user.uid;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await profile.fetchProfile();
      try {
        final timings = await PrayerTimesRepository.fetchKualaLumpur();
        await NotificationService().scheduleAllPrayers(timings);
      } catch (error) {
        debugPrint('Unable to refresh prayer notifications: $error');
        _scheduledForUserId = null;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator.adaptive()),
          );
        }

        // If the user is authenticated, handle scheduling and send them to the Dashboard
        if (snapshot.hasData) {
          _scheduleFor(snapshot.data!, context.read<AdminProfileProvider>());
          return const MainDashboard();
        }

        _scheduledForUserId = null;

        // Otherwise, show the Login Screen
        return const LoginScreen();
      },
    );
  }
}
