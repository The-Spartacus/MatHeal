import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/theme.dart';
import 'auth/login_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;

  // Restored the original list of page content
  final List<OnboardingPage> _pages = [
    OnboardingPage(
      title: 'Track Your Health',
      description:
          'Monitor your pregnancy journey with personalized reminders and health tracking.',
      imagePath: 'assets/onboarding/onboarding1.png',
    ),
    OnboardingPage(
      title: 'Smart Reminders',
      description:
          'Never miss medications, appointments, or important health checkups.',
      imagePath: 'assets/onboarding/onboarding2.png',
    ),
    OnboardingPage(
      title: 'AI Health Assistant',
      description:
          'Get instant answers to your health questions from our AI assistant.',
      imagePath: 'assets/onboarding/onboarding3.png',
    ),
    OnboardingPage(
        title: 'Exercise Guidance',
        description:
            'Stay active and healthy with pregnancy-safe exercise routines and tips.',
        imagePath: 'assets/onboarding/onboarding4.png'),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentIndex < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    } else {
      _completeOnboarding();
    }
  }

  void _skipOnboarding() {
    _completeOnboarding();
  }

  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hasSeenOnboarding', true);

    if (mounted) {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              const LoginScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return SlideTransition(
              position: animation.drive(
                Tween(begin: const Offset(1.0, 0.0), end: Offset.zero),
              ),
              child: child,
            );
          },
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8), // Background for the whole screen
      // The button changes position and style based on the current page
      floatingActionButtonLocation: _currentIndex < _pages.length - 1
          ? FloatingActionButtonLocation.endFloat
          : FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 20.0),
        child: _currentIndex < _pages.length - 1
            ? FloatingActionButton(
                onPressed: _nextPage,
                backgroundColor: AppColors.primary,
                shape: const CircleBorder(),
                child: const Icon(Icons.arrow_forward, color: Colors.white),
              )
            : FloatingActionButton.extended(
                onPressed: _completeOnboarding,
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                label: const Text(
                  'Get Started',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
                icon: const Icon(Icons.check_circle_outline),
              ),
      ),
      body: Stack(
        children: [
          // The PageView now builds pages with the new UI
          PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            itemCount: _pages.length,
            itemBuilder: (context, index) {
              final page = _pages[index];
              // Each page is a Column with the new design
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipPath(
                    clipper: OnboardingImageClipper(),
                    child: Container(
                      height: MediaQuery.of(context).size.height * 0.55,
                      decoration: BoxDecoration(
                        image: DecorationImage(
                          image: AssetImage(page.imagePath),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          page.title,
                          style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          page.description,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: Colors.black54,
                                height: 1.5,
                              ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
          // Positioned controls (indicators, skip, back) are overlaid on top
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Back button only shows after the first page
                    AnimatedOpacity(
                      opacity: _currentIndex > 0 ? 1.0 : 0.0,
                      duration: const Duration(milliseconds: 300),
                      child: TextButton(
                        onPressed: () => _pageController.previousPage(
                          duration: const Duration(milliseconds: 400),
                          curve: Curves.easeInOut,
                        ),
                        child: Text('Back', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    // Page indicators
                    Row(
                      children: List.generate(
                        _pages.length,
                        (index) => AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: _currentIndex == index ? 24 : 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: _currentIndex == index
                                ? AppColors.primary
                                : Colors.grey.shade400,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    ),
                    // Skip button hides on the last page
                    AnimatedOpacity(
                      opacity: _currentIndex < _pages.length - 1 ? 1.0 : 0.0,
                      duration: const Duration(milliseconds: 300),
                      child: TextButton(
                        onPressed: _skipOnboarding,
                        child: Text('Skip', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Data model for each onboarding page's content
class OnboardingPage {
  final String title;
  final String description;
  final String imagePath;

  OnboardingPage({
    required this.title,
    required this.description,
    required this.imagePath,
  });
}

// The custom clipper for the image shape

class OnboardingImageClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, size.height - 80);
    path.quadraticBezierTo(
      size.width / 2, size.height + 80,
      size.width, size.height - 80,
    );
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}


