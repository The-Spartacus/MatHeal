// ignore_for_file: deprecated_member_use
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:matheal/models/appointment_model.dart';
import 'package:matheal/models/user_model.dart';
import 'package:matheal/screens/auth/login_screen.dart';
import 'package:matheal/screens/features/book_appointment_screen.dart';
import 'package:matheal/screens/features/community_screen.dart';
import 'package:matheal/screens/features/doctor/doctor_detail_screen.dart';
import 'package:matheal/screens/features/tracker_dashboard_page.dart';
import 'package:matheal/screens/features/user_appointments_screen.dart';
import 'package:matheal/services/appointment_service.dart';
import 'package:matheal/services/auth_service.dart';
import 'package:matheal/services/firestore_service.dart';
import 'package:matheal/widgets/fetal_size_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import '../providers/theme_provider.dart';
import '../utils/theme.dart';
import 'features/medicine_reminders_screen.dart';
import 'features/diet_suggestions_screen.dart';
import 'features/exercise_suggestions_screen.dart';
import 'features/chat_screen.dart';
import 'profile/profile_screen.dart';
import 'features/article_list_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  bool _notificationsEnabled = true;
  final AppointmentService _appointmentService = AppointmentService();

  late final List<Widget> _screens = [
    _buildHomeTab(),
    const MedicineRemindersScreen(),
    const ChatScreen(),
    const ArticleListScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _notificationsEnabled = prefs.getBool('notificationsEnabled') ?? true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _selectedIndex == 0
          ? AppBar(
        backgroundColor: Color.fromARGB(255, 255, 255, 255),
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Image.asset("assets/images/logo.png"),
        ),
        centerTitle: true,
        title: RichText(
          text: TextSpan(
            children: [
TextSpan(
  text: "mat",
  style: GoogleFonts.niconne(
    color: const Color.fromRGBO(59, 170, 243, 1),
    fontWeight: FontWeight.w100,
    fontSize: 32
  ),
),

              TextSpan(
                text: "Heal",
                style: GoogleFonts.niconne(
                      color: Colors.black,
                      fontWeight: FontWeight.w100,
                      fontSize: 32
                    ),
              ),
            ],
          ),
        ),
        actions: [
          Builder(
            builder: (context) {
              return IconButton(
                icon: const Icon(Icons.menu),
                onPressed: () => Scaffold.of(context).openEndDrawer(),
              );
            },
          ),
        ],
          ):null,
      endDrawer: _buildDrawer(context),
      body: _screens[_selectedIndex],
bottomNavigationBar: BottomNavigationBar(
  type: BottomNavigationBarType.fixed,
  currentIndex: _selectedIndex,
  onTap: _onItemTapped,
  backgroundColor: const Color.fromARGB(255, 32, 159, 223),
  
  // --- CHANGES START HERE ---

  // 1. Create a clear contrast for the active tab
  selectedItemColor: Colors.white,
  
  // 2. Use a semi-transparent white for inactive items
  unselectedItemColor: Colors.white.withOpacity(0.6),

  // 3. Make the active icon slightly larger for a subtle "pop"
  selectedIconTheme: const IconThemeData(size: 30),
  
  // showSelectedLabels: false,

  // showUnselectedLabels: true,

  // --- CHANGES END HERE ---

  items: const [
    BottomNavigationBarItem(
        icon: Icon(Icons.home_rounded), label: "Home"),
    BottomNavigationBarItem(icon: Icon(Icons.alarm), label: "Reminders"),
    BottomNavigationBarItem(
        icon: Icon(Icons.smart_toy_outlined), label: "AI"),
    BottomNavigationBarItem(icon: Icon(Icons.article), label: "Articles"),
  ],
),
    );
  }
  // ✅ --- NOTIFICATION BELL WIDGET UPDATED ---
  Widget _buildNotificationBell(BuildContext context) {
    final user = context.watch<UserProvider>().user;
    if (user == null) return const SizedBox.shrink();

    return StreamBuilder<QuerySnapshot>(
      stream: _appointmentService.getConfirmedAppointmentsStream(user.uid),
      builder: (context, snapshot) {
        // Map QuerySnapshot to a list of Appointment models
        final notifications = snapshot.data?.docs
                .map((doc) => Appointment.fromFirestore(
                    doc.data() as Map<String, dynamic>, doc.id))
                .toList() ??
            [];
        final hasNotifications = notifications.isNotEmpty;

        return Badge(
          label: Text(notifications.length.toString()),
          isLabelVisible: hasNotifications,
          child: IconButton(
            icon: Icon(hasNotifications
                ? Icons.notifications_active
                : Icons.notifications_none_outlined),
            onPressed: () {
              if (hasNotifications) {
                _showNotificationsDialog(context, notifications);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text("You have no new notifications.")));
              }
            },
          ),
        );
      },
    );
  }

  // ✅ --- NOTIFICATIONS DIALOG UPDATED ---
  void _showNotificationsDialog(
      BuildContext context, List<Appointment> appointments) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text("Appointment Confirmations"),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: appointments.length,
              separatorBuilder: (_, __) => const Divider(),
              itemBuilder: (context, index) {
                final appointment = appointments[index];
                // Fetch doctor details for each notification
                return FutureBuilder<UserModel?>(
                  future: context
                      .read<FirestoreService>()
                      .getUser(appointment.doctorId),
                  builder: (context, userSnap) {
                    final doctorName = userSnap.data?.name ?? 'Dr. ...';
                    final date = DateFormat('dd MMM yyyy, hh:mm a')
                        .format(appointment.dateTime);
                    return ListTile(
                      leading:
                          const Icon(Icons.check_circle, color: Colors.green),
                      title: Text(
                        "Confirmed: Dr. $doctorName",
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text("On $date"),
                    );
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () async {
                final userId = context.read<UserProvider>().user?.uid;
                if (userId != null) {
                  await _appointmentService.markAppointmentsAsRead(userId);
                }
                if (mounted) Navigator.of(context).pop();
              },
              child: const Text("Clear All"),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("Close"),
            ),
          ],
        );
      },
    );
  }

  // --- Other widgets remain the same ---
  Widget _buildHomeTab() {
    return RefreshIndicator(
      onRefresh: () async {
        final userProvider = context.read<UserProvider>();
        if (userProvider.user != null) {
          await context
              .read<FirestoreService>()
              .getProfile(userProvider.user!.uid);
        }
        await Future.delayed(const Duration(seconds: 1));
      },
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildWelcomeCard(),
                _buildDisplayView() ,
                Text(
                  'Health Hub',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w100,
                        color: AppColors.textPrimary,
                      ),
                ),
                          _buildFeatureGrid(context),
            _buildDoctorSection(),
          ],
        ),
      ),
    );
  }

  Future<void> _saveNotificationPreference(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notificationsEnabled', value);
  }
  // ... inside the _buildDisplayView method

Widget _buildDisplayView() {
  return Consumer<UserProvider>(
    builder: (context, userProvider, child) {
      final user = userProvider.user;
      final profile = userProvider.profile;

      if (user == null) {
        return const Center(child: CircularProgressIndicator());
      }

      return SingleChildScrollView(
        padding: const EdgeInsets.all(0.0),
        child: Column(
          children: [

            // +++ ADD THE NEW WIDGET HERE +++
            if (profile != null && profile.currentWeeksPregnant != null) ...[
              const SizedBox(height: 14),
              FetalSizeWelcomeCard(week: profile.currentWeeksPregnant!),
              const SizedBox(height: 10),
            ],
            
          ],
        ),
      );
    },
  );
}

  Widget _buildWelcomeCard() {
    return Consumer<UserProvider>(
      builder: (context, userProvider, child) {
        final user = userProvider.user;
        final profile = userProvider.profile;

        return Row(
          children: [
            CircleAvatar(
              radius: 20, // Smaller radius for a more compact look
              backgroundColor: Colors.white.withOpacity(0.9),
              backgroundImage: profile?.avatarUrl != null
                  ? NetworkImage(profile!.avatarUrl!)
                  : null,
              child: profile?.avatarUrl == null
                  ? const Icon(Icons.person, color: Colors.grey, size: 22)
                  : null,
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Hi, ${user?.name ?? 'User'}',
                  style: GoogleFonts.lobsterTwo(
                    color: const Color.fromARGB(255, 10, 10, 10),
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  'Welcome back!',
                  style: GoogleFonts.poppins(
                    color: const Color.fromARGB(255, 0, 0, 0).withOpacity(0.9),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const Spacer(),
          _buildNotificationBell(context),

          ],
        );
      },
    );
  }

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 30.0),
            child: Container(
              height: kToolbarHeight,
              width: double.infinity,
              color: const Color.fromARGB(255, 253, 254, 255),
              alignment: Alignment.center,
              child: const Text('Settings',
                  style: TextStyle(
                      color: Colors.black,
                      fontSize: 18,
                      fontWeight: FontWeight.bold)),
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(8),
              children: [
                _buildSettingsSection('Profile', [_buildProfileTile(context)]),
                _buildSettingsSection('Preferences',
                    [_buildThemeToggle(), _buildNotificationToggle()]),
                const SizedBox(height: 16),
                _buildSettingsSection('Account', [_buildLogoutTile(context)]),
              ],
            ),
          ),
        ],
      ),
    );
  }

Widget _buildDoctorSection() {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Padding(
        padding: EdgeInsets.zero,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Find a Doctor',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w400,
                    color: AppColors.textPrimary,
                  ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).push(MaterialPageRoute(
                  builder: (context) => const BookAppointmentScreen(),
                ));
              },
              child: const Text('View all'),
            ),
          ],
        ),
      ),
      const SizedBox(height: 16),

      /// Cards + Swipe Arrow
      SizedBox(
        height: 180, // Fixed height for horizontal list
        child: FutureBuilder<List<UserModel>>(
          future: context.read<FirestoreService>().getAllDoctors(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError ||
                !snapshot.hasData ||
                snapshot.data!.isEmpty) {
              return const Center(child: Text('No doctors available.'));
            }

            final doctors = snapshot.data!;

            return Stack(
              children: [
                // Horizontal Doctor List
                ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: EdgeInsets.zero,
                  itemCount: doctors.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(width: 12),
                  itemBuilder: (context, index) {
                    return _buildDoctorCard(doctors[index]);
                  },
                ),

                // Right-side Swipe Arrow
                // Positioned(
                //   right: 0,
                //   top: 0,
                //   bottom: 0,
                //   child: IgnorePointer(
                //     ignoring: true, // don't block swipe
                //     child: Container(
                //       width: 3,
                //       decoration: BoxDecoration(
                //         gradient: LinearGradient(
                //           colors: [
                //             const Color.fromARGB(0, 247, 245, 245),
                //             const Color.fromARGB(0, 255, 255, 255).withOpacity(0.9),
                //           ],
                //           begin: Alignment.centerLeft,
                //           end: Alignment.centerRight,
                //         ),
                //       ),
                //       child: const Center(
                //         child: Icon(
                //           Icons.arrow_forward_ios,
                //           size: 18,
                //           color: Colors.grey,
                //         ),
                //       ),
                //     ),
                //   ),
                // ),
              ],
            );
          },
        ),
      ),
    ],
  );
}

Widget _buildDoctorCard(UserModel doctor) {
  return SizedBox(
    width: 160,
    child: GestureDetector(
      onTap: () {
        Navigator.of(context).push(MaterialPageRoute(
          builder: (context) => DoctorDetailScreen(doctor: doctor),
        ));
      },
      child: Card(
        elevation: 3,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Doctor Image
            Image.network(
              doctor.avatarUrl ?? 'https://via.placeholder.com/150',
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) =>
                  const Icon(Icons.person, size: 80, color: Colors.grey),
            ),

            // Gradient Overlay
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color.fromARGB(0, 247, 244, 244),
                    const Color.fromARGB(111, 17, 17, 17).withOpacity(0.8),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),

            // Doctor Info
            Positioned(
              bottom: 12,
              left: 12,
              right: 12,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Dr. ${doctor.name}",
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    doctor.specialization ?? 'Specialist',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),

            // Rating Badge
            Positioned(
              top: 8,
              left: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.star, color: Colors.amber, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      doctor.averageRating.toStringAsFixed(1),
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}


  Widget _buildProfileTile(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.person, color: AppColors.primary),
      title: const Text('Profile'),
      onTap: () {
        Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => const ProfileScreen()));
      },
    );
  }

  Widget _buildSettingsSection(String title, List<Widget> children) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style:
                    const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
            const Divider(height: 16, thickness: 1),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildThemeToggle() {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return SwitchListTile(
          title: const Text('Dark Mode'),
          subtitle: const Text('Switch between light and dark theme'),
          value: themeProvider.isDarkMode,
          onChanged: (_) => themeProvider.toggleTheme(),
          secondary: Icon(
              themeProvider.isDarkMode ? Icons.dark_mode : Icons.light_mode,
              color: AppColors.primary),
        );
      },
    );
  }

  Widget _buildNotificationToggle() {
    return SwitchListTile(
      title: const Text('Notifications'),
      subtitle: const Text('Receive health reminders and updates'),
      value: _notificationsEnabled,
      onChanged: (value) {
        setState(() => _notificationsEnabled = value);
        _saveNotificationPreference(value);
      },
      secondary: const Icon(Icons.notifications, color: AppColors.primary),
    );
  }

  Widget _buildLogoutTile(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.logout, color: AppColors.error),
      title: const Text('Logout', style: TextStyle(color: AppColors.error)),
      onTap: () async {
        final shouldLogout = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Logout'),
            content: const Text('Are you sure you want to logout?'),
            actions: [
              TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Cancel')),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                style:
                    ElevatedButton.styleFrom(backgroundColor: AppColors.error),
                child: const Text('Logout'),
              ),
            ],
          ),
        );

        if (shouldLogout == true && context.mounted) {
          await context.read<AuthService>().signOut();
          context.read<UserProvider>().clear();
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const LoginScreen()),
            (route) => false,
          );
        }
      },
    );
  }

Widget _buildFeatureGrid(BuildContext context) {
    // The data for the feature cards, now with shorter titles for a cleaner look.
    final features = [
      _Feature(
        title: 'Community',
        icon: Icons.connect_without_contact_outlined,
 subtitle: 'Connect with other parents',
        backgroundColor: const Color(0xFFFFF3E0),
        iconColor: const Color(0xFFF57C00),
        onTap: () => Navigator.push(context,
            MaterialPageRoute(builder: (context) => const CommunityScreen())),
      ),
      _Feature(
        title: 'My Schedule',
        icon: Icons.calendar_month_outlined,
 subtitle: 'View your appointments',
        backgroundColor: const Color(0xFFE8F5E8),
        iconColor: const Color(0xFF388E3C),
        onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => const UserAppointmentsScreen())),
      ),
      _Feature(
        title: 'Diet Tips',
        icon: Icons.restaurant_menu_outlined,
 subtitle: 'Get healthy diet suggestions',
        backgroundColor: const Color(0xFFF1F8E9),
        iconColor: const Color(0xFF689F38),
        onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => const DietSuggestionsScreen())),
      ),
      _Feature(
        title: 'Workouts',
        icon: Icons.fitness_center_outlined,
 subtitle: 'Find pregnancy-safe exercises',
        backgroundColor: const Color(0xFFE0F2F1),
        iconColor: const Color(0xFF00695C),
        onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => const ExerciseSuggestionsScreen())),
      ),
                  _Feature(
        title: 'Log',
        icon: Icons.history,
 subtitle: 'mental health log',
        backgroundColor: const Color(0xFFEDE7F6),
        iconColor: const Color(0xFF5E35B1),
        onTap: () => Navigator.push(context,
            MaterialPageRoute(builder: (context) => TrackerDashboardPage())),
      ),
    ];

    return SizedBox(
      height: 100, 
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding:  EdgeInsets.zero,
        itemCount: features.length,
        separatorBuilder: (context, index) => const SizedBox(width: 20), // Increased spacing
        itemBuilder: (context, index) {
          final feature = features[index];
          return InkWell(
            onTap: feature.onTap,
            borderRadius: BorderRadius.circular(40), // Make the ripple effect circular
            child: SizedBox(
              width: 70, // Fixed width for each item
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: feature.backgroundColor,
                    child: Icon(feature.icon,
                        color: feature.iconColor, size: 28),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    feature.title,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _Feature {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color backgroundColor;
  final Color iconColor;
  final VoidCallback onTap;

  const _Feature({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.backgroundColor,
    required this.iconColor,
    required this.onTap,
  });
}
