import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class NotificationCenterScreen extends StatefulWidget {
  const NotificationCenterScreen({super.key});

  @override
  State<NotificationCenterScreen> createState() => _NotificationCenterScreenState();
}

class _NotificationCenterScreenState extends State<NotificationCenterScreen> {
  final List<Map<String, dynamic>> _notifications = [
    {
      'id': 'notif-1',
      'title': 'New Team Application',
      'body': 'Elena Rostova applied to join "LLM Citation Accuracy Evaluation".',
      'time': '15m ago',
      'read': false,
      'type': 'Team',
    },
    {
      'id': 'notif-2',
      'title': 'Mentorship Request Update',
      'body': 'Your mentorship request for Methodology & Topic Selection was accepted.',
      'time': '2h ago',
      'read': false,
      'type': 'Mentorship',
    },
    {
      'id': 'notif-3',
      'title': 'Relevant Opportunity Match',
      'body': 'ACM CHI 2027 submission deadline is approaching (Dec 15). Matches your saved HCI interests.',
      'time': '1d ago',
      'read': true,
      'type': 'Opportunity',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                for (var n in _notifications) {
                  n['read'] = true;
                }
              });
            },
            child: const Text('Mark all read', style: TextStyle(color: AppColors.brightTeal)),
          ),
        ],
      ),
      body: _notifications.isEmpty
          ? const Center(child: Text('No notifications yet.'))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _notifications.length,
              itemBuilder: (context, index) {
                final n = _notifications[index];
                final isRead = n['read'] as bool;
                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  color: isRead ? AppColors.darkSurface : AppColors.darkSurfaceVariant,
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: isRead ? AppColors.darkBackground : AppColors.primaryTeal,
                      child: Icon(
                        n['type'] == 'Team'
                            ? Icons.group_add_rounded
                            : n['type'] == 'Mentorship'
                                ? Icons.school_rounded
                                : Icons.event_note_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                    title: Text(n['title'], style: TextStyle(fontWeight: isRead ? FontWeight.normal : FontWeight.bold, fontSize: 14)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 2),
                        Text(n['body'], style: const TextStyle(fontSize: 12, color: AppColors.darkTextSecondary)),
                        const SizedBox(height: 4),
                        Text(n['time'], style: const TextStyle(fontSize: 10, color: AppColors.darkTextMuted)),
                      ],
                    ),
                    trailing: isRead
                        ? null
                        : Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(color: AppColors.brightTeal, shape: BoxShape.circle),
                          ),
                    onTap: () {
                      setState(() => n['read'] = true);
                    },
                  ),
                );
              },
            ),
    );
  }
}
