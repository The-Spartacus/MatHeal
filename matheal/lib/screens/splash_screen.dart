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
      duration: const Duration(seconds: 2),
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
    await Future.delayed(const Duration(seconds: 3));
    
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
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: AppColors.splashGradient,
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
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 20,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.health_and_safety,
                          size: 60,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'MatHeal',
                        style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Maternal Health Care',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: AppColors.textSecondary,
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

