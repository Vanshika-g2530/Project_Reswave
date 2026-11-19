import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../models/user_model.dart';
import '../../models/mood_entry.dart';
import '../../services/api_client.dart';

class WellbeingScreen extends StatefulWidget {
  final UserModel user;

  const WellbeingScreen({super.key, required this.user});

  @override
  State<WellbeingScreen> createState() => _WellbeingScreenState();
}

class _WellbeingScreenState extends State<WellbeingScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ResWaveApiService _apiService = ResWaveApiService();
  List<MoodEntry> _moods = [];
  bool _isLoading = true;

  final List<Map<String, dynamic>> _peerPosts = [
    {
      'id': 'sp-01',
      'authorName': 'Anonymous Scholar',
      'category': 'Publication rejection',
      'text': 'Received a rejection on our CHI paper today after 4 months of review. Reviewer 2 made valid points on participant sample diversity. Taking the weekend off before revising.',
      'time': '3h ago',
      'replies': 8,
    },
    {
      'id': 'sp-02',
      'authorName': 'PhD Candidate',
      'category': 'PhD life',
      'text': 'Reminder to fellow doctoral students: progress is rarely linear. If you read two papers today and thought deeply about a limitation, that was a productive day.',
      'time': 'Yesterday',
      'replies': 15,
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadMoods();
  }

  Future<void> _loadMoods() async {
    setState(() => _isLoading = true);
    try {
      final list = await _apiService.getMyMoods();
      if (mounted) setState(() => _moods = list);
    } catch (_) {
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _openMoodDialog() {
    String selectedMood = 'Calm';
    int intensity = 3;
    final factors = <String>[];
    final noteController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: AppColors.darkSurface,
          title: const Text('Private Mood Check-in', style: TextStyle(fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '100% Confidential: Your mood reflections are strictly owner-only and never shared with mentors, matching algorithms, or platform analytics.',
                  style: TextStyle(fontSize: 11, color: AppColors.brightTeal),
                ),
                const SizedBox(height: 14),
                const Text('How are you feeling?', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                DropdownButton<String>(
                  isExpanded: true,
                  value: selectedMood,
                  dropdownColor: AppColors.darkSurface,
                  items: ['Calm', 'Good', 'Motivated', 'Okay', 'Stressed', 'Overwhelmed', 'Low', 'Anxious']
                      .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                      .toList(),
                  onChanged: (val) => setDialogState(() => selectedMood = val ?? selectedMood),
                ),
                const SizedBox(height: 12),
                Text('Self-Rated Intensity: $intensity / 5 (Non-clinical)', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                Slider(
                  value: intensity.toDouble(),
                  min: 1,
                  max: 5,
                  divisions: 4,
                  activeColor: AppColors.brightTeal,
                  onChanged: (val) => setDialogState(() => intensity = val.toInt()),
                ),
                const SizedBox(height: 10),
                const Text('Private Reflection Note (User-only):', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 6),
                TextField(
                  controller: noteController,
                  maxLines: 3,
                  decoration: const InputDecoration(hintText: 'Record thoughts for yourself...'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryTeal),
              onPressed: () async {
                final entry = MoodEntry(
                  id: 'mood-${DateTime.now().millisecondsSinceEpoch}',
                  userId: widget.user.uid,
                  mood: selectedMood,
                  intensity: intensity,
                  factors: factors,
                  privateNote: noteController.text.trim().isNotEmpty ? noteController.text.trim() : null,
                  createdAt: DateTime.now().toIso8601String(),
                );
                Navigator.pop(ctx);
                await _apiService.saveMood(entry);
                _loadMoods();
              },
              child: const Text('Save Reflection'),
            ),
          ],
        ),
      ),
    );
  }

  void _showCreateSupportPostModal() {
    final textController = TextEditingController();
    String category = 'Research stress';
    bool hideIdentity = true;
    bool safetyAcknowledged = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.darkSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
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
                const Text('Share in Peer Support Haven', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                const Text('A safe space to discuss research workload, setbacks, and doctoral resilience.', style: TextStyle(fontSize: 12, color: AppColors.darkTextSecondary)),
                const SizedBox(height: 14),
                DropdownButtonFormField<String>(
                  initialValue: category,
                  decoration: const InputDecoration(labelText: 'Category'),
                  items: [
                    'Research stress',
                    'Publication rejection',
                    'Motivation',
                    'PhD life',
                    'First-time researcher',
                    'Work-life balance',
                  ].map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                  onChanged: (v) => setModalState(() => category = v ?? category),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: textController,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Your Reflection / Discussion (max 2000 chars)',
                    hintText: 'Share your experience (avoid posting private personal/medical information)...',
                  ),
                ),
                const SizedBox(height: 10),
                SwitchListTile(
                  title: const Text('Post Anonymously to Members', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                  subtitle: const Text('Your profile name will be hidden from peers.', style: TextStyle(fontSize: 11, color: AppColors.darkTextSecondary)),
                  value: hideIdentity,
                  activeThumbColor: AppColors.brightTeal,
                  onChanged: (v) => setModalState(() => hideIdentity = v),
                ),
                CheckboxListTile(
                  title: const Text(
                    'I acknowledge that peer support is for mutual encouragement and is NOT professional clinical therapy or crisis medical care.',
                    style: TextStyle(fontSize: 11, color: AppColors.darkTextSecondary),
                  ),
                  value: safetyAcknowledged,
                  activeColor: AppColors.primaryTeal,
                  onChanged: (v) => setModalState(() => safetyAcknowledged = v ?? false),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryTeal),
                    onPressed: safetyAcknowledged
                        ? () {
                            if (textController.text.trim().isEmpty) return;
                            setState(() {
                              _peerPosts.insert(0, {
                                'id': 'sp-${DateTime.now().millisecondsSinceEpoch}',
                                'authorName': hideIdentity ? 'Anonymous Scholar' : widget.user.displayName,
                                'category': category,
                                'text': textController.text.trim(),
                                'time': 'Just now',
                                'replies': 0,
                              });
                            });
                            Navigator.pop(ctx);
                          }
                        : null,
                    child: const Text('Share with Peers'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Well-Being & Peer Support'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.brightTeal,
          labelColor: AppColors.brightTeal,
          unselectedLabelColor: AppColors.darkTextMuted,
          tabs: const [
            Tab(text: 'My Mood (Private)'),
            Tab(text: 'Peer Support'),
            Tab(text: 'Emergency Hotlines'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildMoodTab(),
          _buildPeerSupportTab(),
          _buildHotlinesTab(),
        ],
      ),
    );
  }

  Widget _buildMoodTab() {
    return Column(
      children: [
        Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.darkSurfaceVariant,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.brightTeal.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              const Icon(Icons.lock_rounded, color: AppColors.brightTeal, size: 24),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Owner-Only Privacy: Your mood history is strictly encrypted to your account. It is never queried for matching or visible to mentors/admins.',
                  style: TextStyle(fontSize: 12, color: AppColors.darkTextSecondary),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryTeal),
                onPressed: _openMoodDialog,
                child: const Text('Check-in'),
              ),
            ],
          ),
        ),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _moods.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.spa_outlined, size: 54, color: AppColors.darkTextMuted),
                          const SizedBox(height: 12),
                          const Text('No reflections recorded yet.', style: TextStyle(color: AppColors.darkTextSecondary)),
                          const SizedBox(height: 12),
                          ElevatedButton(onPressed: _openMoodDialog, child: const Text('Log Today\'s Mood')),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _moods.length,
                      itemBuilder: (context, index) {
                        final m = _moods[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 10),
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(m.mood, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: AppColors.brightTeal.withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text('Intensity ${m.intensity ?? 3}/5', style: const TextStyle(color: AppColors.brightTeal, fontSize: 10, fontWeight: FontWeight.bold)),
                                    ),
                                  ],
                                ),
                                if (m.privateNote != null && m.privateNote!.isNotEmpty) ...[
                                  const SizedBox(height: 6),
                                  Text('"${m.privateNote}"', style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: AppColors.darkTextSecondary)),
                                ],
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(m.createdAt.split('T')[0], style: const TextStyle(fontSize: 10, color: AppColors.darkTextMuted)),
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline, size: 16, color: AppColors.error),
                                      onPressed: () async {
                                        await _apiService.deleteMood(m.id);
                                        _loadMoods();
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
        ),
      ],
    );
  }

  Widget _buildPeerSupportTab() {
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primaryTeal,
        icon: const Icon(Icons.post_add_rounded),
        label: const Text('Share Reflection'),
        onPressed: _showCreateSupportPostModal,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _peerPosts.length,
        itemBuilder: (context, index) {
          final p = _peerPosts[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(p['authorName'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.brightTeal)),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(color: AppColors.darkSurfaceVariant, borderRadius: BorderRadius.circular(4)),
                        child: Text(p['category'], style: const TextStyle(fontSize: 10, color: AppColors.darkTextMuted)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(p['text'], style: const TextStyle(fontSize: 13, height: 1.4)),
                  const SizedBox(height: 10),
                  Text('${p['time']} • 💬 ${p['replies']} peer responses', style: const TextStyle(fontSize: 11, color: AppColors.darkTextMuted)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHotlinesTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.error.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.error),
          ),
          child: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: AppColors.error, size: 28),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Emergency & Crisis Support: If you are experiencing acute emotional crisis, please contact local professional emergency services immediately.',
                  style: TextStyle(fontSize: 12, color: AppColors.darkTextPrimary),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _buildHotlineCard('United States & Canada', '988 Suicide & Crisis Lifeline', 'Call or Text 988', 'Free, confidential, available 24/7 in English & Spanish.'),
        _buildHotlineCard('United Kingdom', 'Samaritans UK', 'Call 116 123', 'Free confidential emotional support 24/7 across the UK & ROI.'),
        _buildHotlineCard('India', 'Tele-MANAS (Govt of India)', 'Call 14416 or 1800-891-4416', 'Toll-free 24/7 multi-lingual mental health counseling.'),
        _buildHotlineCard('International & Worldwide', 'Befrienders Worldwide Directory', 'befrienders.org', 'Global network of 349 emotional support centers in 32 countries.'),
      ],
    );
  }

  Widget _buildHotlineCard(String country, String service, String number, String description) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(country, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.brightTeal)),
            const SizedBox(height: 2),
            Text(service, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(number, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.error)),
            const SizedBox(height: 4),
            Text(description, style: const TextStyle(fontSize: 11, color: AppColors.darkTextSecondary)),
          ],
        ),
      ),
    );
  }
}
