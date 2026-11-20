import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../models/opportunity.dart';
import '../../services/api_client.dart';

class DiscoverScreen extends StatefulWidget {
  const DiscoverScreen({super.key});

  @override
  State<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends State<DiscoverScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ResWaveApiService _apiService = ResWaveApiService();

  List<dynamic> _researchers = [];
  List<dynamic> _mentors = [];
  List<OpportunityModel> _opportunities = [];

  bool _loadingResearchers = true;
  bool _loadingMentors = true;
  bool _loadingOpportunities = true;

  String? _errorResearchers;
  String? _errorMentors;
  String? _errorOpportunities;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadAllDiscoverData();
  }

  void _loadAllDiscoverData() {
    _fetchResearchers();
    _fetchMentors();
    _fetchOpportunities();
  }

  Future<void> _fetchResearchers() async {
    setState(() {
      _loadingResearchers = true;
      _errorResearchers = null;
    });
    try {
      final res = await _apiService.getResearcherMatches();
      if (mounted) setState(() => _researchers = res);
    } catch (e) {
      if (mounted) setState(() => _errorResearchers = e.toString());
    } finally {
      if (mounted) setState(() => _loadingResearchers = false);
    }
  }

  Future<void> _fetchMentors() async {
    setState(() {
      _loadingMentors = true;
      _errorMentors = null;
    });
    try {
      final res = await _apiService.getMentorMatches();
      if (mounted) setState(() => _mentors = res);
    } catch (e) {
      if (mounted) setState(() => _errorMentors = e.toString());
    } finally {
      if (mounted) setState(() => _loadingMentors = false);
    }
  }

  Future<void> _fetchOpportunities() async {
    setState(() {
      _loadingOpportunities = true;
      _errorOpportunities = null;
    });
    try {
      final res = await _apiService.getOpportunities();
      if (mounted) setState(() => _opportunities = res);
    } catch (e) {
      if (mounted) setState(() => _errorOpportunities = e.toString());
    } finally {
      if (mounted) setState(() => _loadingOpportunities = false);
    }
  }

  void _showConnectDialog(Map<String, dynamic> researcher) {
    final noteController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Connect with ${researcher['displayName']}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${researcher['role']} • ${researcher['institution'] ?? ""}', style: const TextStyle(fontSize: 12, color: AppColors.darkTextSecondary)),
            const SizedBox(height: 14),
            TextField(
              controller: noteController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Personalized Note (Optional)',
                hintText: 'e.g. I noticed our shared research interests in HCI and usability metrics...',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryTeal),
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await _apiService.sendConnectionRequest(researcher['userId'], note: noteController.text.trim());
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Connection request sent to ${researcher['displayName']}!'), backgroundColor: AppColors.success),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                }
              }
            },
            child: const Text('Send Request'),
          ),
        ],
      ),
    );
  }

  void _showMentorRequestDialog(Map<String, dynamic> mentor) {
    String selectedHelp = (mentor['helpTypes'] as List).isNotEmpty ? mentor['helpTypes'][0] : 'Methodology & Topic Selection';
    final contextController = TextEditingController();
    String selectedFormat = 'Remote';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.darkSurface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
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
              Text('Request Mentorship: ${mentor['displayName']}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text('${mentor['institution'] ?? ""} • ${mentor['remainingCapacity']} slot(s) open', style: const TextStyle(fontSize: 12, color: AppColors.brightTeal)),
              const Divider(height: 24),
              const Text('1. What help do you need? *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                value: selectedHelp,
                items: [
                  'Methodology & Topic Selection',
                  'Literature review and gap analysis',
                  'Experiment design and data analysis',
                  'Paper writing and publication feedback',
                  'Career guidance and PhD advice',
                ].map((h) => DropdownMenuItem(value: h, child: Text(h, style: const TextStyle(fontSize: 12)))).toList(),
                onChanged: (v) => selectedHelp = v ?? selectedHelp,
              ),
              const SizedBox(height: 14),
              const Text('2. Research context & specific question * (min 20 chars)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 6),
              TextField(
                controller: contextController,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: 'Briefly describe your current research question, challenges, and what guidance you are seeking...',
                ),
              ),
              const SizedBox(height: 14),
              const Text('3. Preferred Mentoring Format:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                value: selectedFormat,
                items: ['Remote', 'Online video call', 'Asynchronous feedback', 'Hybrid'].map((f) => DropdownMenuItem(value: f, child: Text(f))).toList(),
                onChanged: (v) => selectedFormat = v ?? selectedFormat,
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryTeal),
                  onPressed: () async {
                    final ctxText = contextController.text.trim();
                    if (ctxText.length < 20) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please provide at least 20 characters of context.')));
                      return;
                    }
                    Navigator.pop(ctx);
                    try {
                      await _apiService.sendMentorRequest(
                        mentorId: mentor['mentorId'],
                        interestId: 'int-general',
                        helpType: selectedHelp,
                        context: ctxText,
                        format: selectedFormat,
                      );
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Mentorship request sent to ${mentor['displayName']}!'), backgroundColor: AppColors.success),
                        );
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                      }
                    }
                  },
                  child: const Text('Submit Mentorship Request'),
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
        title: const Text('Discover & Smart Match'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.brightTeal,
          labelColor: AppColors.brightTeal,
          unselectedLabelColor: AppColors.darkTextMuted,
          tabs: const [
            Tab(text: 'Researchers'),
            Tab(text: 'Mentors'),
            Tab(text: 'Opportunities'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildResearchersTab(),
          _buildMentorsTab(),
          _buildOpportunitiesTab(),
        ],
      ),
    );
  }

  Widget _buildResearchersTab() {
    if (_loadingResearchers) return const Center(child: CircularProgressIndicator());
    if (_errorResearchers != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.wifi_off_rounded, size: 48, color: AppColors.darkTextMuted),
            const SizedBox(height: 12),
            const Text('Could not fetch matches', style: TextStyle(color: AppColors.darkTextSecondary)),
            const SizedBox(height: 12),
            ElevatedButton(onPressed: _fetchResearchers, child: const Text('Retry')),
          ],
        ),
      );
    }
    if (_researchers.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: Text(
            'No matching discoverable researchers found for your saved interests yet.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.darkTextSecondary),
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchResearchers,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _researchers.length,
        itemBuilder: (context, index) {
          final m = _researchers[index];
          final score = (m['score'] as num?)?.toDouble() ?? 0.0;
          final reasons = List<String>.from(m['reasons'] ?? []);
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
                      Text(m['displayName'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.primaryTeal.withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: AppColors.brightTeal),
                        ),
                        child: Text('${m['fitBand']} (${score.toInt()}%)', style: const TextStyle(color: AppColors.brightTeal, fontSize: 11, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text('${m['role']} • ${m['institution'] ?? m['country']}', style: const TextStyle(fontSize: 12, color: AppColors.darkTextSecondary)),
                  if (m['headline'] != null && (m['headline'] as String).isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(m['headline'], style: const TextStyle(fontSize: 13, height: 1.3)),
                  ],
                  if (reasons.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    const Text('Why this match:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: AppColors.darkTextMuted)),
                    ...reasons.map((r) => Text('• $r', style: const TextStyle(fontSize: 11, color: AppColors.darkTextSecondary))),
                  ],
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.person_add_outlined, size: 16),
                      label: const Text('Connect'),
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryTeal),
                      onPressed: () => _showConnectDialog(m),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMentorsTab() {
    if (_loadingMentors) return const Center(child: CircularProgressIndicator());
    if (_errorMentors != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.wifi_off_rounded, size: 48, color: AppColors.darkTextMuted),
            const SizedBox(height: 12),
            const Text('Could not fetch mentors', style: TextStyle(color: AppColors.darkTextSecondary)),
            const SizedBox(height: 12),
            ElevatedButton(onPressed: _fetchMentors, child: const Text('Retry')),
          ],
        ),
      );
    }
    if (_mentors.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: Text(
            'No opted-in mentors with open slots currently. Check back soon.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.darkTextSecondary),
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchMentors,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _mentors.length,
        itemBuilder: (context, index) {
          final mentor = _mentors[index];
          final expertise = List<String>.from(mentor['expertise'] ?? []);
          final reasons = List<String>.from(mentor['reasons'] ?? []);
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
                      Text(mentor['displayName'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.brightTeal.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text('${mentor['remainingCapacity']} Slots Open', style: const TextStyle(color: AppColors.brightTeal, fontSize: 11, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text('${mentor['institution'] ?? ""}', style: const TextStyle(fontSize: 12, color: AppColors.darkTextSecondary)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: expertise
                        .map((e) => Chip(
                              label: Text(e, style: const TextStyle(fontSize: 10)),
                              backgroundColor: AppColors.darkBackground,
                            ))
                        .toList(),
                  ),
                  if (reasons.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    ...reasons.map((r) => Text('• $r', style: const TextStyle(fontSize: 11, color: AppColors.darkTextSecondary))),
                  ],
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryTeal),
                      onPressed: () => _showMentorRequestDialog(mentor),
                      child: const Text('Request Mentorship'),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildOpportunitiesTab() {
    if (_loadingOpportunities) return const Center(child: CircularProgressIndicator());
    if (_errorOpportunities != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.wifi_off_rounded, size: 48, color: AppColors.darkTextMuted),
            const SizedBox(height: 12),
            const Text('Could not fetch academic listings', style: TextStyle(color: AppColors.darkTextSecondary)),
            const SizedBox(height: 12),
            ElevatedButton(onPressed: _fetchOpportunities, child: const Text('Retry')),
          ],
        ),
      );
    }
    if (_opportunities.isEmpty) {
      return const Center(child: Text('No verified listings available.'));
    }

    return RefreshIndicator(
      onRefresh: _fetchOpportunities,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _opportunities.length,
        itemBuilder: (context, index) {
          final opp = _opportunities[index];
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
                      Expanded(child: Text(opp.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15))),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(color: AppColors.warning.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(4)),
                        child: Text(opp.type, style: const TextStyle(color: AppColors.warning, fontSize: 10, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text('${opp.organiser} • ${opp.mode}', style: const TextStyle(fontSize: 12, color: AppColors.darkTextSecondary)),
                  const SizedBox(height: 6),
                  Text(opp.description, style: const TextStyle(fontSize: 13, height: 1.4)),
                  const SizedBox(height: 8),
                  Text('Admin Verified: ${opp.lastVerifiedDate}', style: const TextStyle(fontSize: 10, color: AppColors.darkTextMuted)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
