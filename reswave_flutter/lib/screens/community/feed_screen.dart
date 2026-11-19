import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../services/api_client.dart';

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  final ResWaveApiService _apiService = ResWaveApiService();
  final List<Map<String, dynamic>> _posts = [
    {
      'id': 'post-01',
      'authorName': 'Alex Rivera',
      'authorRole': 'PhD Scholar • CMU',
      'type': 'Research update',
      'text': 'We just completed the initial pilot test of our open-source benchmark evaluating citation hallucinations across 8 model sizes! Early results show citation error rates drop by 42% when prompt grounding is introduced.',
      'tags': ['NLP', 'Evaluation', 'Benchmarks'],
      'time': '2h ago',
      'likes': 14,
    },
    {
      'id': 'post-02',
      'authorName': 'Prof. Elena Rostova',
      'authorRole': 'Associate Professor • TU Munich',
      'type': 'Question',
      'text': 'For colleagues conducting remote usability studies with neurodivergent participants: What latency compensation techniques have yielded the most reliable subjective cognitive load measurements?',
      'tags': ['HCI', 'Accessibility', 'User Study'],
      'time': '5h ago',
      'likes': 9,
    },
  ];

  void _showCreatePostModal() {
    final textController = TextEditingController();
    String selectedType = 'Research update';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.darkSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          left: 20,
          right: 20,
          top: 20,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Share with Academic Community', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: selectedType,
                decoration: const InputDecoration(labelText: 'Post Type'),
                items: [
                  'Research update',
                  'Question',
                  'Paper share',
                  'Project update',
                  'General academic discussion',
                ].map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                onChanged: (v) => selectedType = v ?? selectedType,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: textController,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Discussion Text (max 3000 chars)',
                  hintText: 'Share research findings, questions, or methodology reflections...',
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryTeal),
                  onPressed: () {
                    if (textController.text.trim().isEmpty) return;
                    setState(() {
                      _posts.insert(0, {
                        'id': 'post-${DateTime.now().millisecondsSinceEpoch}',
                        'authorName': _apiService.currentUser?.displayName ?? 'Scholar',
                        'authorRole': _apiService.currentUser?.role ?? 'Researcher',
                        'type': selectedType,
                        'text': textController.text.trim(),
                        'tags': ['Discussion'],
                        'time': 'Just now',
                        'likes': 0,
                      });
                    });
                    Navigator.pop(ctx);
                  },
                  child: const Text('Publish Post'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Academic Community Feed'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_comment_rounded),
            onPressed: _showCreatePostModal,
          ),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _posts.length,
        itemBuilder: (context, index) {
          final p = _posts[index];
          final tags = List<String>.from(p['tags'] ?? []);
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: AppColors.primaryTeal,
                        child: Text(
                          (p['authorName'] as String)[0],
                          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(p['authorName'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                            Text(p['authorRole'], style: const TextStyle(fontSize: 11, color: AppColors.darkTextSecondary)),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.primaryTeal.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(p['type'], style: const TextStyle(color: AppColors.brightTeal, fontSize: 10, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(p['text'], style: const TextStyle(fontSize: 13, height: 1.45)),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 6,
                    children: tags.map((t) => Chip(
                      label: Text('#$t', style: const TextStyle(fontSize: 10)),
                      backgroundColor: AppColors.darkBackground,
                      padding: EdgeInsets.zero,
                    )).toList(),
                  ),
                  const Divider(height: 20),
                  Row(
                    children: [
                      Text(p['time'], style: const TextStyle(fontSize: 11, color: AppColors.darkTextMuted)),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.thumb_up_alt_outlined, size: 16),
                        onPressed: () {
                          setState(() => p['likes'] = (p['likes'] as int) + 1);
                        },
                      ),
                      Text('${p['likes']}', style: const TextStyle(fontSize: 12)),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.flag_outlined, size: 16, color: AppColors.darkTextMuted),
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Report submitted to moderation queue.')),
                          );
                        },
                      ),
                    ],
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
