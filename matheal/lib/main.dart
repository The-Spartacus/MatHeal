import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

//import 'package:flutter/foundation.dart' show kIsWeb;
//import 'dart:io' show Platform;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'firebase_options.dart';

import 'services/auth_service.dart';
import 'services/notification_service.dart';
import 'services/firestore_service.dart';
import 'services/chat_service.dart';
import 'providers/theme_provider.dart';
import 'providers/user_provider.dart';
import 'screens/splash_screen.dart';
import 'utils/theme.dart';
import 'screens/auth/login_screen.dart'; // ✅ your login screen
import 'package:firebase_auth/firebase_auth.dart'; // <-- add this



final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await FirebaseAppCheck.instance.activate(
    androidProvider: AndroidProvider
        .debug, // change to safetyNet/PlayIntegrity later
  );

  // Initialize timezone data
  tz.initializeTimeZones();

  // Initialize notifications
  await NotificationService.init();

  runApp(const MatHealApp());
}

class MatHealApp extends StatelessWidget {
  const MatHealApp({super.key});
  

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<AuthService>(
          create: (_) => AuthService(),
        ),
        Provider<FirestoreService>(
          create: (_) => FirestoreService(),
        ),
        Provider<NotificationService>(
          create: (_) => NotificationService(),
        ),
        Provider<ChatService>(
          create: (_) => ChatService(),
        ),
        ChangeNotifierProvider<ThemeProvider>(
          create: (_) => ThemeProvider(),
        ),
        ChangeNotifierProvider<UserProvider>(
          create: (_) => UserProvider(),
        ),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            title: 'MatHeal',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeProvider.themeMode,
            home: StreamBuilder<User?>(
              stream: FirebaseAuth.instance.authStateChanges(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SplashScreen(); // still loading
                } else if (snapshot.hasData) {
                  return const SplashScreen(); // user logged in
                } else {
                  return const LoginScreen(); // user logged out
                }
              },
            ),
          );
        },
      ),
    );
  }
}
