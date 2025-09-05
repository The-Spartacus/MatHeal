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
import 'screens/alarm_screen.dart'; // <-- add this import
import 'utils/theme.dart';
import 'package:firebase_auth/firebase_auth.dart'; // <-- add this



final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();


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
  await NotificationService.init('Asia/Kolkata', timeZoneName: 'Asia/Kolkata',
   onDidReceiveNotificationResponse: onDidReceiveNotificationResponse,
  );

  

  runApp(const MatHealApp());
}
void onDidReceiveNotificationResponse(NotificationResponse notificationResponse) {
  if (notificationResponse.payload == 'alarm') {
    // Use the navigatorKey to push the AlarmScreen
    navigatorKey.currentState?.pushNamed('/alarm');
  }
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
            navigatorKey: navigatorKey,
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
                  return const SplashScreen(); // user logged out
                }
              },
            ),
                  routes: {
        '/alarm': (context) => const AlarmScreen(),
      },
          );
        },
      ),
    );
  }
}
