import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../models/domain_model.dart';
import '../../models/research_interest.dart';
import '../../services/api_client.dart';

class DomainFinderScreen extends StatefulWidget {
  const DomainFinderScreen({super.key});

  @override
  State<DomainFinderScreen> createState() => _DomainFinderScreenState();
}

class _DomainFinderScreenState extends State<DomainFinderScreen> {
  final ResWaveApiService _apiService = ResWaveApiService();

  final List<String> _selectedSubjects = [];
  final List<String> _selectedProblems = [];
  final List<String> _selectedWorkStyles = [];
  final List<String> _selectedSkills = [];
  final List<String> _selectedGoals = [];
  final TextEditingController _topicController = TextEditingController();

  List<DomainRecommendationResult> _recommendations = [];
  bool _isLoading = false;

  final List<String> _subjectOptions = [
    'computing', 'mathematics', 'psychology', 'design', 'biology', 'environment', 'social sciences', 'medicine'
  ];
  final List<String> _problemOptions = [
    'human behaviour', 'technology', 'data/patterns', 'design/experience', 'climate', 'health', 'society'
  ];
  final List<String> _workStyleOptions = [
    'building prototypes', 'analysing data', 'interviews/surveys', 'experiments', 'designing experiences', 'fieldwork'
  ];
  final List<String> _skillOptions = [
    'programming', 'statistics', 'design', 'data analysis', 'observation/interviews', 'writing'
  ];
  final List<String> _goalOptions = [
    'explore', 'solve practical problem', 'publish', 'prepare higher studies', 'build portfolio'
  ];

  Future<void> _calculateRecommendations() async {
    setState(() => _isLoading = true);
    final payload = {
      'subjects': _selectedSubjects,
      'problems': _selectedProblems,
      'workStyles': _selectedWorkStyles,
      'skills': _selectedSkills,
      'goals': _selectedGoals,
      'topicInMind': _topicController.text.trim(),
    };

    try {
      final results = await _apiService.getDomainRecommendations(payload);
      if (mounted) {
        setState(() {
          _recommendations = results;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _saveInterest(DomainRecommendationResult domain) async {
    final newInterest = ResearchInterest(
      id: 'int-${DateTime.now().millisecondsSinceEpoch}',
      userId: _apiService.currentUser?.uid ?? 'usr-local',
      domainId: domain.domainId,
      subdomainId: domain.sampleTopics.isNotEmpty ? domain.sampleTopics.first : 'General',
      topicTags: domain.sampleTopics.take(3).toList(),
      proficiency: 'Beginner',
      status: 'Exploring',
      skills: domain.requiredSkills.take(3).toList(),
      methods: ['Literature-based'],
      goals: ['Learn', 'Explore'],
    );

    try {
      await _apiService.addInterest(newInterest);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Saved ${domain.name} as an active research interest!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error saving interest: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Research Domain Finder')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Explore Research Domains',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.darkTextPrimary),
            ),
            const SizedBox(height: 4),
            const Text(
              'Answer questionnaire questions to receive explainable recommendations scored across 5 dimensions (30% subjects, 25% problems, 20% work styles, 15% skills, 10% goals).',
              style: TextStyle(fontSize: 12, color: AppColors.darkTextSecondary),
            ),
            const SizedBox(height: 20),

            _buildMultiSelectSection('1. Which subjects interest you? (30%)', _subjectOptions, _selectedSubjects),
            _buildMultiSelectSection('2. Which problem types motivate you? (25%)', _problemOptions, _selectedProblems),
            _buildMultiSelectSection('3. What kind of work would you enjoy? (20%)', _workStyleOptions, _selectedWorkStyles),
            _buildMultiSelectSection('4. Skills you have or want to develop? (15%)', _skillOptions, _selectedSkills),
            _buildMultiSelectSection('5. Your research goal (10%)', _goalOptions, _selectedGoals),

            const SizedBox(height: 12),
            TextField(
              controller: _topicController,
              decoration: const InputDecoration(
                labelText: '6. Any topic already in mind? (Optional)',
                hintText: 'e.g. Cognitive load in AI interfaces...',
              ),
            ),
            const SizedBox(height: 20),

            SizedBox(
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryTeal),
                onPressed: _isLoading ? null : _calculateRecommendations,
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Calculate Domain Recommendations'),
              ),
            ),
            const SizedBox(height: 24),

            if (_recommendations.isNotEmpty) ...[
              const Text(
                'Recommended Domains',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.darkTextPrimary),
              ),
              const SizedBox(height: 4),
              const Text(
                'Transparent fit bands and explicit reasons derived from your selections.',
                style: TextStyle(fontSize: 12, color: AppColors.darkTextMuted),
              ),
              const SizedBox(height: 12),
              ..._recommendations.map((rec) => _buildResultCard(rec)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMultiSelectSection(String title, List<String> options, List<String> selected) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.darkTextPrimary)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: options.map((opt) {
            final isChecked = selected.contains(opt);
            return FilterChip(
              label: Text(opt[0].toUpperCase() + opt.substring(1), style: const TextStyle(fontSize: 11)),
              selected: isChecked,
              selectedColor: AppColors.primaryTeal.withValues(alpha: 0.3),
              checkmarkColor: AppColors.brightTeal,
              onSelected: (val) {
                setState(() {
                  if (val) {
                    selected.add(opt);
                  } else {
                    selected.remove(opt);
                  }
                });
              },
            );
          }).toList(),
        ),
        const SizedBox(height: 14),
      ],
    );
  }

  Widget _buildResultCard(DomainRecommendationResult result) {
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
                Expanded(
                  child: Text(
                    result.name,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.darkTextPrimary),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: result.fitBand == 'Strong'
                        ? AppColors.brightTeal.withValues(alpha: 0.2)
                        : AppColors.primaryTeal.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: AppColors.brightTeal),
                  ),
                  child: Text(
                    '${result.fitBand} (${result.score.toInt()}%)',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: AppColors.brightTeal,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Sub-fields: ${result.sampleTopics.join(", ")}',
              style: const TextStyle(fontSize: 12, color: AppColors.darkTextSecondary),
            ),
            const SizedBox(height: 8),
            const Text('Why this appeared:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: AppColors.darkTextMuted)),
            ...result.reasons.map((r) => Padding(
                  padding: const EdgeInsets.only(left: 6, top: 2),
                  child: Text('• $r', style: const TextStyle(fontSize: 11, color: AppColors.darkTextSecondary)),
                )),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.bookmark_add_outlined, size: 16),
                label: const Text('Save as Interest'),
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryTeal),
                onPressed: () => _saveInterest(result),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
