import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:matheal/screens/auth/login_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
  late AnimationController _controller;
  late Animation<double> _fadeLogo;
  late Animation<double> _fadeText;
  late Animation<Offset> _logoSlide;
  late Animation<Offset> _textSlide;
  late Animation<Offset> _screenSlide;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    );

    // Logo fades in & slides from top
    _fadeLogo = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.0, 0.5, curve: Curves.easeIn)),
    );
    _logoSlide = Tween<Offset>(
      begin: const Offset(0, -1), // from top
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.0, 0.5, curve: Curves.easeOut)),
    );

    // Text fades in & slides from bottom
    _fadeText = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.3, 0.7, curve: Curves.easeIn)),
    );
    _textSlide = Tween<Offset>(
      begin: const Offset(0, 1), // from bottom
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.3, 0.7, curve: Curves.easeOut)),
    );

    // Whole screen slides upward at the end
    _screenSlide = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(0, -1), // slide screen up
    ).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.7, 1.0, curve: Curves.easeInOut)),
    );

    _controller.forward();
    _checkAuthAndNavigate();
  }

  Future<void> _checkAuthAndNavigate() async {
    await Future.delayed(const Duration(seconds: 4)); // match animation duration

    if (!mounted) return;

    final firebaseUser = FirebaseAuth.instance.currentUser;
    final prefs = await SharedPreferences.getInstance();
    final hasSeenOnboarding = prefs.getBool('hasSeenOnboarding') ?? false;

    if (firebaseUser != null) {
      try {
        final firestoreService = context.read<FirestoreService>();
        final userProvider = context.read<UserProvider>();

        final userModel = await firestoreService.getUser(firebaseUser.uid);
        final userProfile = await firestoreService.getProfile(firebaseUser.uid);

        userProvider.setUser(userModel);
        userProvider.setProfile(userProfile);

        if (mounted) {
          Navigator.of(context).pushReplacement(
            _createRoute(const HomeScreen()),
          );
        }
      } catch (e) {
        if (mounted) {
          await context.read<AuthService>().signOut();
          Navigator.of(context).pushReplacement(
            _createRoute(const LoginScreen()),
          );
        }
      }
    } else {
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
        return FadeTransition(
          opacity: animation,
          child: child,
        );
      },
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SlideTransition(
        position: _screenSlide, // whole screen slides up
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white,
                Colors.white,
                Colors.white,
              ],
            ),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FadeTransition(
                  opacity: _fadeLogo,
                  child: SlideTransition(
                    position: _logoSlide,
                    child: Container(
                      width: 225,
                      height: 225,
                      child: Image.asset(
                        "assets/images/logo.png",
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                FadeTransition(
                  opacity: _fadeText,
                  child: SlideTransition(
                    position: _textSlide,
                    child: RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: "Mat",
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  color:
                                      const Color.fromRGBO(59, 170, 243, 1),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 30,
                                ),
                          ),
                          TextSpan(
                            text: "Heal",
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 30,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
