import 'package:flutter/material.dart';
//import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'services/auth_service.dart';
import 'services/notification_service.dart';
import 'services/firestore_service.dart';
import 'services/chat_service.dart';
import 'providers/theme_provider.dart';
import 'providers/user_provider.dart';
import 'screens/splash_screen.dart';
import 'utils/theme.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
 // await Firebase.initializeApp();
  
  
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
            home: const SplashScreen(),
          );
        },
      ),
    );
  }
}