import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../models/research_interest.dart';
import '../../services/api_client.dart';

class InterestsManagerScreen extends StatefulWidget {
  const InterestsManagerScreen({super.key});

  @override
  State<InterestsManagerScreen> createState() => _InterestsManagerScreenState();
}

class _InterestsManagerScreenState extends State<InterestsManagerScreen> {
  final ResWaveApiService _apiService = ResWaveApiService();
  List<ResearchInterest> _interests = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadInterests();
  }

  Future<void> _loadInterests() async {
    setState(() => _isLoading = true);
    try {
      final list = await _apiService.getMyInterests();
      if (mounted) setState(() => _interests = list);
    } catch (_) {
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showAddInterestModal() {
    String selectedDomain = 'hci';
    final subdomainController = TextEditingController();
    final topicsController = TextEditingController();
    String status = 'Active research';
    String proficiency = 'Beginner';

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
              const Text('Add Research Focus Area', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              const Text('Multi-domain: Add another research topic without overwriting existing interests.', style: TextStyle(fontSize: 12, color: AppColors.darkTextSecondary)),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: selectedDomain,
                decoration: const InputDecoration(labelText: 'Domain'),
                items: const [
                  DropdownMenuItem(value: 'hci', child: Text('Human-Computer Interaction (HCI)')),
                  DropdownMenuItem(value: 'ai-nlp', child: Text('AI & NLP')),
                  DropdownMenuItem(value: 'cog-psych', child: Text('Cognitive Psychology')),
                  DropdownMenuItem(value: 'env-science', child: Text('Environmental Science')),
                  DropdownMenuItem(value: 'bio-info', child: Text('Bio-Informatics')),
                ],
                onChanged: (v) => selectedDomain = v ?? selectedDomain,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: subdomainController,
                decoration: const InputDecoration(labelText: 'Subdomain / Specialization', hintText: 'e.g. Accessibility in XAI'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: topicsController,
                decoration: const InputDecoration(labelText: 'Keywords / Topics (comma-separated)', hintText: 'e.g. user study, visual ergonomics'),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryTeal),
                  onPressed: () async {
                    if (subdomainController.text.trim().isEmpty) return;
                    final interest = ResearchInterest(
                      id: 'int-${DateTime.now().millisecondsSinceEpoch}',
                      userId: _apiService.currentUser?.uid ?? 'usr-local',
                      domainId: selectedDomain,
                      subdomainId: subdomainController.text.trim(),
                      topicTags: topicsController.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList(),
                      proficiency: proficiency,
                      status: status,
                      goals: ['Learn', 'Publish'],
                    );
                    Navigator.pop(ctx);
                    await _apiService.addInterest(interest);
                    _loadInterests();
                  },
                  child: const Text('Save Research Focus'),
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
        title: const Text('Manage Research Interests'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            onPressed: _showAddInterestModal,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _interests.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.psychology_outlined, size: 54, color: AppColors.darkTextMuted),
                      const SizedBox(height: 12),
                      const Text('No research interests saved.', style: TextStyle(color: AppColors.darkTextSecondary)),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _showAddInterestModal,
                        child: const Text('+ Add First Research Focus'),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _interests.length,
                  itemBuilder: (context, index) {
                    final item = _interests[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Padding(
                        padding: const EdgeInsets.all(14.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '${item.domainId.toUpperCase()} • ${item.subdomainId}',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: AppColors.primaryTeal.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    item.status,
                                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.brightTeal),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 6,
                              runSpacing: 4,
                              children: item.topicTags.map((t) => Chip(
                                label: Text(t, style: const TextStyle(fontSize: 11)),
                                backgroundColor: AppColors.darkBackground,
                              )).toList(),
                            ),
                            const SizedBox(height: 10),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Proficiency: ${item.proficiency}', style: const TextStyle(fontSize: 11, color: AppColors.darkTextMuted)),
                                TextButton(
                                  onPressed: () async {
                                    await _apiService.deleteInterest(item.id);
                                    _loadInterests();
                                  },
                                  child: const Text('Archive', style: TextStyle(color: AppColors.error, fontSize: 12)),
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
