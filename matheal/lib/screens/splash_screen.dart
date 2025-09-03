// lib/screens/splash_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:matheal/screens/auth/login_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/theme.dart';
import 'onboarding_screen.dart';
import 'home_screen.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../providers/user_provider.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.5,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));

    _animationController.forward();
    _checkAuthAndNavigate();
  }


Future<void> _checkAuthAndNavigate() async {
  // A shorter delay is better for user experience
  await Future.delayed(const Duration(seconds: 3)); 

  if (!mounted) return;

  final firebaseUser = FirebaseAuth.instance.currentUser;
  final prefs = await SharedPreferences.getInstance();
  final hasSeenOnboarding = prefs.getBool('hasSeenOnboarding') ?? false;

  if (firebaseUser != null) {
    // ✅ USER IS LOGGED IN - FETCH THEIR DATA
    try {
      final firestoreService = context.read<FirestoreService>();
      final userProvider = context.read<UserProvider>();

      // Fetch the user model and profile from Firestore
      final userModel = await firestoreService.getUser(firebaseUser.uid);
      final userProfile = await firestoreService.getProfile(firebaseUser.uid);

      // Populate the provider with the fetched data
      userProvider.setUser(userModel);
      userProvider.setProfile(userProfile);
      
      if (mounted) {
        // Now navigate to the home screen
        Navigator.of(context).pushReplacement(
          _createRoute(const HomeScreen()),
        );
      }
    } catch (e) {
      // If there's an error (e.g., user deleted in Firestore), sign out and go to login
      if (mounted) {
        await context.read<AuthService>().signOut();
        Navigator.of(context).pushReplacement(
          _createRoute(const LoginScreen()),
        );
      }
    }
  } else {
    // ❌ USER IS NOT LOGGED IN
    if (hasSeenOnboarding) {
      Navigator.of(context).pushReplacement(
        _createRoute(const LoginScreen()),
      );
    } else {
      Navigator.of(context).pushReplacement(
        _createRoute(const OnboardingScreen()),
      );
    }
  }
}

  PageRouteBuilder _createRoute(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(opacity: animation, child: child);
      },
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration (
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors:  [
              Color.fromARGB(255, 255, 255, 255),
              Color.fromRGBO(255, 255, 255, 1),
              Color.fromARGB(255, 255, 255, 255),
            ],
          ),
        ),
        child: Center(
          child: AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              return FadeTransition(
                opacity: _fadeAnimation,
                child: ScaleTransition(
                  scale: _scaleAnimation,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start, // push content to top
                    children: [
                      SizedBox(height: MediaQuery.of(context).size.height * 0.12), // 12% from top
                      Container(
                        width: 225,
                        height: 225,
                        decoration: BoxDecoration  (
                          color: const Color.fromARGB(0, 245, 243, 243),
                          borderRadius: BorderRadius.circular(30),),
                        child: Image.asset(
                            "assets/images/logo.png",  // your splash logo
                            width: 225,
                            height: 225,
                            fit: BoxFit.contain,
                            ),   
                      ),
                      const SizedBox(height: 1),
                        RichText(
                            text: TextSpan(
                              children: [
                                TextSpan(
                                  text: "Mat",
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                        color: const Color.fromRGBO(59, 170, 243, 1), // pinkish color
                                        fontWeight: FontWeight.bold,
                                        fontSize: 30,
                                      ),
                                ),
                                TextSpan(
                                  text: "Heal",
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                        color: Colors.black, // black for Heal
                                        fontWeight: FontWeight.bold,
                                        fontSize: 30,
                                      ),
                                ),
                              ],
                            ),
                          )
                          ,
                    
                      const SizedBox(height: 50),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 100),
                        child: Text(
                          'Your journey begins here \n         care for both \n    mothers and babies',
                         style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: AppColors.textSecondary,
                            height: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

