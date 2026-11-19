import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../models/user_model.dart';
import '../../models/research_interest.dart';
import '../../services/api_client.dart';
import '../navigation/main_navigation_screen.dart';

class OnboardingScreen extends StatefulWidget {
  final UserModel user;

  const OnboardingScreen({super.key, required this.user});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  int _currentStep = 0;
  final int _totalSteps = 10;
  final ResWaveApiService _apiService = ResWaveApiService();

  // Step 2: Basic Academic Profile
  final _institutionController = TextEditingController();
  final _departmentController = TextEditingController();
  final _cityController = TextEditingController();
  final _bioController = TextEditingController();

  // Step 3: Multi-Domain Research Interests (Repeatable)
  final List<ResearchInterest> _stagedInterests = [];
  String _selectedDomain = 'hci';
  final _subdomainController = TextEditingController(text: 'Cognitive Ergonomics');
  final _topicsController = TextEditingController(text: 'cognitive load, accessibility');
  String _interestStatus = 'Exploring';
  String _interestProficiency = 'Beginner';

  // Step 4: Goals
  final List<String> _selectedGoals = ['explore', 'learn'];

  // Step 5: Collaboration Preferences
  String _collabMode = 'Remote';
  String _availabilityHours = '5-10 hours/week';
  String _commitment = 'Flexible';

  // Step 6: Skills & Methods
  final List<String> _selectedSkills = ['programming', 'writing'];
  final List<String> _selectedMethods = ['Literature-based'];

  // Step 7: Mentorship
  bool _wantsMentor = true;
  String _mentorshipHelpType = 'Methodology & Topic Selection';

  // Step 8: Privacy
  String _profileVisibility = 'Public to members';
  bool _discoverable = true;

  // Step 9: Notifications & Well-being
  bool _enableWellbeing = true;
  final Map<String, bool> _notifPrefs = {
    'connections': true,
    'teamRequests': true,
    'mentorship': true,
    'learningReminders': true,
  };

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _institutionController.text = widget.user.institution ?? '';
    _cityController.text = widget.user.city ?? '';
    _bioController.text = widget.user.bio ?? '';
  }

  void _addStagedInterest() {
    if (_subdomainController.text.trim().isEmpty) return;
    setState(() {
      _stagedInterests.add(ResearchInterest(
        id: 'int-stage-${DateTime.now().millisecondsSinceEpoch}',
        userId: widget.user.uid,
        domainId: _selectedDomain,
        subdomainId: _subdomainController.text.trim(),
        topicTags: _topicsController.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList(),
        proficiency: _interestProficiency,
        status: _interestStatus,
        goals: _selectedGoals,
      ));
      _subdomainController.clear();
      _topicsController.clear();
    });
  }

  Future<void> _completeOnboarding() async {
    setState(() => _isSaving = true);
    try {
      // 1. Save user profile updates
      // 2. Persist all staged interests
      for (final interest in _stagedInterests) {
        await _apiService.addInterest(interest);
      }
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => MainNavigationScreen(currentUser: widget.user)),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error saving profile: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _nextStep() {
    if (_currentStep == 2 && _stagedInterests.isEmpty) {
      _addStagedInterest();
    }
    if (_currentStep < _totalSteps - 1) {
      setState(() => _currentStep++);
    } else {
      _completeOnboarding();
    }
  }

  void _prevStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Step ${_currentStep + 1} of $_totalSteps'),
        leading: _currentStep > 0
            ? IconButton(icon: const Icon(Icons.arrow_back), onPressed: _prevStep)
            : null,
        actions: [
          if (_currentStep < _totalSteps - 1)
            TextButton(
              onPressed: _nextStep,
              child: const Text('Skip', style: TextStyle(color: AppColors.brightTeal)),
            ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Progress Bar
            LinearProgressIndicator(
              value: (_currentStep + 1) / _totalSteps,
              backgroundColor: AppColors.darkBorder,
              color: AppColors.brightTeal,
              minHeight: 4,
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20.0),
                child: _buildCurrentStep(),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryTeal),
                  onPressed: _isSaving ? null : _nextStep,
                  child: _isSaving
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                          _currentStep == _totalSteps - 1 ? 'Finish & Launch Hub' : 'Continue',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentStep() {
    switch (_currentStep) {
      case 0:
        return _buildStepAccount();
      case 1:
        return _buildStepProfile();
      case 2:
        return _buildStepInterests();
      case 3:
        return _buildStepGoals();
      case 4:
        return _buildStepCollaboration();
      case 5:
        return _buildStepSkills();
      case 6:
        return _buildStepMentorship();
      case 7:
        return _buildStepPrivacy();
      case 8:
        return _buildStepNotifications();
      case 9:
        return _buildStepSummary();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildStepAccount() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Account Setup', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        Text('Signed in as ${widget.user.email} (${widget.user.role})', style: const TextStyle(color: AppColors.darkTextSecondary)),
        const SizedBox(height: 20),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Role Verified', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.brightTeal)),
                const SizedBox(height: 4),
                Text(widget.user.role, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                const Text('Your declared role guides collaboration recommendations and eligibility.', style: TextStyle(fontSize: 12, color: AppColors.darkTextMuted)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStepProfile() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Academic Profile', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        const Text('Help fellow scholars discover you across academic institutions.', style: TextStyle(color: AppColors.darkTextSecondary)),
        const SizedBox(height: 20),
        TextField(
          controller: _institutionController,
          decoration: const InputDecoration(labelText: 'Institution / University', hintText: 'e.g. Carnegie Mellon University'),
        ),
        const SizedBox(height: 14),
        TextField(
          controller: _departmentController,
          decoration: const InputDecoration(labelText: 'Department / Faculty', hintText: 'e.g. Computer Science'),
        ),
        const SizedBox(height: 14),
        TextField(
          controller: _cityController,
          decoration: const InputDecoration(labelText: 'City (Optional)', hintText: 'e.g. Pittsburgh'),
        ),
        const SizedBox(height: 14),
        TextField(
          controller: _bioController,
          maxLines: 3,
          decoration: const InputDecoration(labelText: 'Short Bio (Optional)', hintText: 'Research background, interests...'),
        ),
      ],
    );
  }

  Widget _buildStepInterests() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Research Interests', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        const Text(
          'Multi-Domain Support: You may add multiple independent interests across different domains (e.g. HCI, AI, and Psychology).',
          style: TextStyle(color: AppColors.darkTextSecondary, fontSize: 13),
        ),
        const SizedBox(height: 16),

        if (_stagedInterests.isNotEmpty) ...[
          const Text('Your Staged Research Areas:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.brightTeal)),
          const SizedBox(height: 8),
          ..._stagedInterests.map((i) => Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  title: Text('${i.domainId.toUpperCase()} • ${i.subdomainId}', style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('Topics: ${i.topicTags.join(", ")} | Status: ${i.status}'),
                  trailing: IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    onPressed: () => setState(() => _stagedInterests.remove(i)),
                  ),
                ),
              )),
          const Divider(height: 24),
        ],

        const Text('Add Research Focus:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          initialValue: _selectedDomain,
          decoration: const InputDecoration(labelText: 'Broad Domain'),
          items: const [
            DropdownMenuItem(value: 'hci', child: Text('Human-Computer Interaction (HCI)')),
            DropdownMenuItem(value: 'ai-nlp', child: Text('Artificial Intelligence & NLP')),
            DropdownMenuItem(value: 'cog-psych', child: Text('Cognitive Psychology & Neuroscience')),
            DropdownMenuItem(value: 'env-science', child: Text('Environmental Science & Climate')),
            DropdownMenuItem(value: 'bio-info', child: Text('Bio-Informatics & Health')),
          ],
          onChanged: (val) => setState(() => _selectedDomain = val ?? _selectedDomain),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _subdomainController,
          decoration: const InputDecoration(labelText: 'Subdomain / Sub-field', hintText: 'e.g. Explainable AI (XAI)'),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _topicsController,
          decoration: const InputDecoration(labelText: 'Topics / Keywords (comma-separated)', hintText: 'e.g. user study, cognitive load'),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                initialValue: _interestStatus,
                decoration: const InputDecoration(labelText: 'Status'),
                items: ['Exploring', 'Learning', 'Active research', 'Completed', 'Published work']
                    .map((s) => DropdownMenuItem(value: s, child: Text(s, style: const TextStyle(fontSize: 12))))
                    .toList(),
                onChanged: (val) => setState(() => _interestStatus = val ?? _interestStatus),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: DropdownButtonFormField<String>(
                initialValue: _interestProficiency,
                decoration: const InputDecoration(labelText: 'Proficiency'),
                items: ['Beginner', 'Intermediate', 'Advanced', 'Expert']
                    .map((p) => DropdownMenuItem(value: p, child: Text(p, style: const TextStyle(fontSize: 12))))
                    .toList(),
                onChanged: (val) => setState(() => _interestProficiency = val ?? _interestProficiency),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        OutlinedButton.icon(
          icon: const Icon(Icons.add),
          label: const Text('+ Add This Research Interest'),
          onPressed: _addStagedInterest,
        ),
      ],
    );
  }

  Widget _buildStepGoals() {
    final goals = [
      {'id': 'explore', 'label': 'Explore new domains'},
      {'id': 'learn', 'label': 'Learn research fundamentals & ethics'},
      {'id': 'mentor', 'label': 'Find an academic mentor'},
      {'id': 'teammates', 'label': 'Find project teammates'},
      {'id': 'publish', 'label': 'Publish or prepare manuscripts'},
      {'id': 'peer-support', 'label': 'Connect for peer well-being support'},
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Research Goals', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        const Text('What do you want to accomplish on ResWave? (Select all that apply)', style: TextStyle(color: AppColors.darkTextSecondary)),
        const SizedBox(height: 16),
        ...goals.map((g) {
          final isChecked = _selectedGoals.contains(g['id']);
          return CheckboxListTile(
            title: Text(g['label']!),
            value: isChecked,
            activeColor: AppColors.primaryTeal,
            onChanged: (val) {
              setState(() {
                if (val == true) {
                  _selectedGoals.add(g['id']!);
                } else {
                  _selectedGoals.remove(g['id']!);
                }
              });
            },
          );
        }),
      ],
    );
  }

  Widget _buildStepCollaboration() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Collaboration Preferences', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        const Text('How do you prefer to collaborate on academic projects?', style: TextStyle(color: AppColors.darkTextSecondary)),
        const SizedBox(height: 20),
        DropdownButtonFormField<String>(
          initialValue: _collabMode,
          decoration: const InputDecoration(labelText: 'Preferred Mode'),
          items: ['Remote', 'In-person', 'Hybrid', 'No preference']
              .map((m) => DropdownMenuItem(value: m, child: Text(m)))
              .toList(),
          onChanged: (v) => setState(() => _collabMode = v ?? _collabMode),
        ),
        const SizedBox(height: 14),
        DropdownButtonFormField<String>(
          initialValue: _availabilityHours,
          decoration: const InputDecoration(labelText: 'Weekly Availability'),
          items: ['1-4 hours/week', '5-10 hours/week', '10-20 hours/week', '20+ hours/week']
              .map((a) => DropdownMenuItem(value: a, child: Text(a)))
              .toList(),
          onChanged: (v) => setState(() => _availabilityHours = v ?? _availabilityHours),
        ),
        const SizedBox(height: 14),
        DropdownButtonFormField<String>(
          initialValue: _commitment,
          decoration: const InputDecoration(labelText: 'Preferred Commitment'),
          items: ['One-time', 'Short-term (1-4 weeks)', 'Semester (1-3 months)', 'Long-term (3+ months)', 'Flexible']
              .map((c) => DropdownMenuItem(value: c, child: Text(c)))
              .toList(),
          onChanged: (v) => setState(() => _commitment = v ?? _commitment),
        ),
      ],
    );
  }

  Widget _buildStepSkills() {
    final skillOptions = ['programming', 'statistics', 'ui/ux design', 'data analysis', 'scientific writing', 'lab work', 'interviewing'];
    final methodOptions = ['Literature-based', 'Qualitative', 'Quantitative', 'Experimental', 'Computational', 'Mixed'];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Skills & Methodologies', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        const Text('Select your competencies and primary research methodologies.', style: TextStyle(color: AppColors.darkTextSecondary)),
        const SizedBox(height: 16),
        const Text('Skills You Have:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.brightTeal)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: skillOptions.map((s) {
            final checked = _selectedSkills.contains(s);
            return FilterChip(
              label: Text(s),
              selected: checked,
              selectedColor: AppColors.primaryTeal.withValues(alpha: 0.3),
              onSelected: (val) {
                setState(() => val ? _selectedSkills.add(s) : _selectedSkills.remove(s));
              },
            );
          }).toList(),
        ),
        const SizedBox(height: 20),
        const Text('Research Methodologies:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.brightTeal)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: methodOptions.map((m) {
            final checked = _selectedMethods.contains(m);
            return FilterChip(
              label: Text(m),
              selected: checked,
              selectedColor: AppColors.primaryTeal.withValues(alpha: 0.3),
              onSelected: (val) {
                setState(() => val ? _selectedMethods.add(m) : _selectedMethods.remove(m));
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildStepMentorship() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Mentorship Preferences', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        const Text('Connect with experienced professors or opt in to mentor emerging researchers.', style: TextStyle(color: AppColors.darkTextSecondary)),
        const SizedBox(height: 20),
        SwitchListTile(
          title: const Text('Would you like an academic mentor?'),
          subtitle: const Text('Matches you with opted-in faculty and senior scholars.'),
          value: _wantsMentor,
          activeThumbColor: AppColors.brightTeal,
          onChanged: (v) => setState(() => _wantsMentor = v),
        ),
        if (_wantsMentor) ...[
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _mentorshipHelpType,
            decoration: const InputDecoration(labelText: 'Primary Guidance Desired'),
            items: [
              'Methodology & Topic Selection',
              'Paper Feedback & Rebuttals',
              'PhD / Grad School Advice',
              'Research Process & Ethics',
            ].map((h) => DropdownMenuItem(value: h, child: Text(h, style: const TextStyle(fontSize: 13)))).toList(),
            onChanged: (v) => setState(() => _mentorshipHelpType = v ?? _mentorshipHelpType),
          ),
        ],
      ],
    );
  }

  Widget _buildStepPrivacy() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Visibility & Privacy', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        const Text('You control how your profile appears to other members.', style: TextStyle(color: AppColors.darkTextSecondary)),
        const SizedBox(height: 20),
        DropdownButtonFormField<String>(
          initialValue: _profileVisibility,
          decoration: const InputDecoration(labelText: 'Profile Visibility'),
          items: ['Public to members', 'Connections only', 'Private']
              .map((v) => DropdownMenuItem(value: v, child: Text(v)))
              .toList(),
          onChanged: (v) => setState(() => _profileVisibility = v ?? _profileVisibility),
        ),
        const SizedBox(height: 14),
        SwitchListTile(
          title: const Text('Appear in Researcher Matching'),
          subtitle: const Text('Allow peers to find you based on topic and skill overlap.'),
          value: _discoverable,
          activeThumbColor: AppColors.brightTeal,
          onChanged: (v) => setState(() => _discoverable = v),
        ),
      ],
    );
  }

  Widget _buildStepNotifications() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Well-Being & Notifications', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        const Text('Configure notifications and well-being access. (Mood entries are strictly private).', style: TextStyle(color: AppColors.darkTextSecondary)),
        const SizedBox(height: 16),
        SwitchListTile(
          title: const Text('Enable Well-Being Area'),
          subtitle: const Text('Access private mood reflection, peer support, and crisis resources.'),
          value: _enableWellbeing,
          activeThumbColor: AppColors.brightTeal,
          onChanged: (v) => setState(() => _enableWellbeing = v),
        ),
        const Divider(height: 20),
        const Text('Notification Categories:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.brightTeal)),
        const SizedBox(height: 6),
        CheckboxListTile(
          title: const Text('Connection Requests'),
          value: _notifPrefs['connections'],
          activeColor: AppColors.primaryTeal,
          onChanged: (v) => setState(() => _notifPrefs['connections'] = v ?? true),
        ),
        CheckboxListTile(
          title: const Text('Team Applications & Project Updates'),
          value: _notifPrefs['teamRequests'],
          activeColor: AppColors.primaryTeal,
          onChanged: (v) => setState(() => _notifPrefs['teamRequests'] = v ?? true),
        ),
        CheckboxListTile(
          title: const Text('Mentorship Messages'),
          value: _notifPrefs['mentorship'],
          activeColor: AppColors.primaryTeal,
          onChanged: (v) => setState(() => _notifPrefs['mentorship'] = v ?? true),
        ),
      ],
    );
  }

  Widget _buildStepSummary() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Onboarding Complete!', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.brightTeal)),
        const SizedBox(height: 6),
        const Text('Your academic research profile is ready.', style: TextStyle(color: AppColors.darkTextSecondary)),
        const SizedBox(height: 20),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.user.displayName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Text('${widget.user.role} • ${_institutionController.text.isNotEmpty ? _institutionController.text : widget.user.country}', style: const TextStyle(fontSize: 12, color: AppColors.darkTextSecondary)),
                const Divider(height: 20),
                Text('Active Domains: ${_stagedInterests.length}', style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                ..._stagedInterests.map((i) => Text('• ${i.domainId.toUpperCase()} &rarr; ${i.subdomainId}', style: const TextStyle(fontSize: 12, color: AppColors.darkTextSecondary))),
                const SizedBox(height: 12),
                Text('Mode: $_collabMode | Visibility: $_profileVisibility', style: const TextStyle(fontSize: 11, color: AppColors.darkTextMuted)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
