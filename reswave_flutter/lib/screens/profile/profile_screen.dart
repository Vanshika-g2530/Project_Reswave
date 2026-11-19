import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../models/user_model.dart';
import '../../services/api_client.dart';
import 'interests_manager_screen.dart';
import '../auth/welcome_screen.dart';

class ProfileScreen extends StatefulWidget {
  final UserModel user;

  const ProfileScreen({super.key, required this.user});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ResWaveApiService _apiService = ResWaveApiService();
  late bool _discoverable;

  @override
  void initState() {
    super.initState();
    _discoverable = widget.user.discoverable;
  }

  void _handleLogout() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out of ResWave?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () {
              _apiService.logout();
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const WelcomeScreen()),
                (route) => false,
              );
            },
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }

  void _handleDeleteAccount() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Account', style: TextStyle(color: AppColors.error)),
        content: const Text(
          'This action is irreversible. All your private notes and mood entries will be permanently deleted. Stored projects and authored feed posts will be anonymised per data retention policy.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () {
              _apiService.logout();
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const WelcomeScreen()),
                (route) => false,
              );
            },
            child: const Text('Confirm Deletion'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Academic Profile & Settings')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Profile Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 36,
                      backgroundColor: AppColors.primaryTeal,
                      child: Text(
                        widget.user.displayName.isNotEmpty ? widget.user.displayName[0] : 'U',
                        style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      widget.user.displayName,
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.user.role,
                      style: const TextStyle(fontSize: 13, color: AppColors.brightTeal, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${widget.user.institution ?? "Independent Researcher"} • ${widget.user.country}',
                      style: const TextStyle(fontSize: 12, color: AppColors.darkTextSecondary),
                    ),
                    if (widget.user.headline != null && widget.user.headline!.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        widget.user.headline!,
                        style: const TextStyle(fontSize: 13, fontStyle: FontStyle.italic),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Quick Menu Items
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.psychology_rounded, color: AppColors.brightTeal),
                    title: const Text('Manage Research Interests'),
                    subtitle: const Text('Multi-domain focus areas across fields'),
                    trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const InterestsManagerScreen()),
                      );
                    },
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    secondary: const Icon(Icons.visibility_rounded, color: AppColors.brightTeal),
                    title: const Text('Discoverable in Matching'),
                    subtitle: const Text('Allow peers to find you by topic overlap'),
                    value: _discoverable,
                    activeThumbColor: AppColors.brightTeal,
                    onChanged: (val) => setState(() => _discoverable = val),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Account Actions
            OutlinedButton(
              onPressed: _handleLogout,
              child: const Text('Sign Out'),
            ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: _handleDeleteAccount,
              child: const Text('Delete Account', style: TextStyle(color: AppColors.error)),
            ),
          ],
        ),
      ),
    );
  }
}
