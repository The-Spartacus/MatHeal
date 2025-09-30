import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:matheal/services/tracking_service.dart';
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
import 'services/image_upload_service.dart'; // ✅ ADDED IMPORT
import 'providers/theme_provider.dart';
import 'providers/user_provider.dart';
import 'screens/splash_screen.dart';
import 'screens/alarm_screen.dart'; // <-- add this import
import 'utils/theme.dart';
import 'package:firebase_auth/firebase_auth.dart'; // <-- add this import



final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();


void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await dotenv.load();
    print("✅ .env loaded successfully");
  } catch (e) {
    print("❌ Failed to load .env: $e");
  }

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
  await NotificationService.init(
  timeZoneName: 'Asia/Kolkata',
  onDidReceiveNotificationResponse: onDidReceiveNotificationResponse,
);

  

  runApp(const MatHealApp());
  
}
void onDidReceiveNotificationResponse(NotificationResponse notificationResponse) {
  if (notificationResponse.payload != null) {
    navigatorKey.currentState?.pushNamed(
      '/alarm',
      arguments: notificationResponse.payload, // ✅ pass medicine name
    );
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
        Provider<TrackingService>(
          create: (_) => TrackingService()
        ),

        Provider<ImageUploadService>(
          create: (_) => ImageUploadService(),
        ), // ✅ ADDED PROVIDER
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
  '/alarm': (context) {
    final medicineName = ModalRoute.of(context)!.settings.arguments as String?;
    return AlarmScreen(medicineName: medicineName ?? "Medicine", alarmId: -1);
  },
},

          );
        },
      ),
    );
  }
}
