// lib/screens/splash_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/theme.dart';
import 'onboarding_screen.dart';
import 'home_screen.dart';

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
    await Future.delayed(const Duration(seconds: 5));
    
    final user = FirebaseAuth.instance.currentUser;
    final prefs = await SharedPreferences.getInstance();
    final hasSeenOnboarding = prefs.getBool('hasSeenOnboarding') ?? false;

    if (!mounted) return;

    if (user != null) {
      Navigator.of(context).pushReplacement(
        _createRoute(const HomeScreen()),
      );
    } else if (hasSeenOnboarding) {
      Navigator.of(context).pushReplacement(
        _createRoute(const OnboardingScreen()),
      );
    } else {
      Navigator.of(context).pushReplacement(
        _createRoute(const OnboardingScreen()),
      );
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

