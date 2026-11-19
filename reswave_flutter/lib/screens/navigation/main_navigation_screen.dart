import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../models/user_model.dart';
import '../home/home_dashboard_screen.dart';
import '../discover/discover_screen.dart';
import '../research_hub/domain_finder_screen.dart';
import '../projects/projects_screen.dart';
import '../wellbeing/wellbeing_screen.dart';
import '../learning_hub/learning_hub_screen.dart';
import '../papers/paper_library_screen.dart';
import '../community/feed_screen.dart';
import '../messages/chat_screen.dart';
import '../profile/profile_screen.dart';
import '../profile/interests_manager_screen.dart';
import '../admin/admin_dashboard_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  final UserModel currentUser;

  const MainNavigationScreen({super.key, required this.currentUser});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;
  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      HomeDashboardScreen(user: widget.currentUser),
      const DiscoverScreen(),
      const DomainFinderScreen(),
      const ProjectsScreen(),
      WellbeingScreen(user: widget.currentUser),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = widget.currentUser.isAdmin || widget.currentUser.role.contains('Admin');

    return Scaffold(
      drawer: Drawer(
        backgroundColor: AppColors.darkSurface,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            UserAccountsDrawerHeader(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.deepTeal, AppColors.primaryTeal],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              accountName: Text(widget.currentUser.displayName, style: const TextStyle(fontWeight: FontWeight.bold)),
              accountEmail: Text(widget.currentUser.role, style: const TextStyle(color: AppColors.brightTeal, fontSize: 12)),
              currentAccountPicture: CircleAvatar(
                backgroundColor: AppColors.darkBackground,
                child: Text(
                  widget.currentUser.displayName.isNotEmpty ? widget.currentUser.displayName[0] : 'U',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 22, color: AppColors.brightTeal),
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.school_rounded, color: AppColors.brightTeal),
              title: const Text('Research Learning Hub'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const LearningHubScreen()));
              },
            ),
            ListTile(
              leading: const Icon(Icons.menu_book_rounded, color: AppColors.brightTeal),
              title: const Text('Personal Paper Library'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const PaperLibraryScreen()));
              },
            ),
            ListTile(
              leading: const Icon(Icons.forum_rounded, color: AppColors.brightTeal),
              title: const Text('Academic Community Feed'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const FeedScreen()));
              },
            ),
            ListTile(
              leading: const Icon(Icons.chat_bubble_outline_rounded, color: AppColors.brightTeal),
              title: const Text('Academic Messages'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ChatScreen(
                      conversationTitle: 'Prof. Elena Rostova',
                      participantRole: 'Mentorship Collaboration',
                    ),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.psychology_rounded, color: AppColors.brightTeal),
              title: const Text('Manage Research Interests'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const InterestsManagerScreen()));
              },
            ),
            ListTile(
              leading: const Icon(Icons.person_outline_rounded, color: AppColors.brightTeal),
              title: const Text('Profile & Settings'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => ProfileScreen(user: widget.currentUser)));
              },
            ),
            if (isAdmin) ...[
              const Divider(color: AppColors.darkBorder),
              ListTile(
                leading: const Icon(Icons.admin_panel_settings_rounded, color: AppColors.warning),
                title: const Text('Admin & Governance Console', style: TextStyle(color: AppColors.warning, fontWeight: FontWeight.bold)),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminDashboardScreen()));
                },
              ),
            ],
          ],
        ),
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard_rounded), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.explore_rounded), label: 'Discover'),
          BottomNavigationBarItem(icon: Icon(Icons.compass_calibration_rounded), label: 'Finder'),
          BottomNavigationBarItem(icon: Icon(Icons.group_work_rounded), label: 'Teams'),
          BottomNavigationBarItem(icon: Icon(Icons.spa_rounded), label: 'Well-being'),
        ],
      ),
    );
  }
}
