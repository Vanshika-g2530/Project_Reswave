import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../models/team_request.dart';
import '../../services/api_client.dart';

class ProjectsScreen extends StatefulWidget {
  const ProjectsScreen({super.key});

  @override
  State<ProjectsScreen> createState() => _ProjectsScreenState();
}

class _ProjectsScreenState extends State<ProjectsScreen> {
  final ResWaveApiService _apiService = ResWaveApiService();
  List<TeamRequestModel> _teamCalls = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRequests();
  }

  Future<void> _loadRequests() async {
    setState(() => _isLoading = true);
    try {
      final list = await _apiService.getTeamRequests();
      if (mounted) setState(() => _teamCalls = list);
    } catch (_) {
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showApplyModal(TeamRequestModel call) {
    final expController = TextEditingController();
    final hoursController = TextEditingController();

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
              Text('Apply: ${call.title}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              Text(call.description, style: const TextStyle(fontSize: 12, color: AppColors.darkTextSecondary)),
              const Divider(height: 24),
              const Text('1. Relevant skills & contributions:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 6),
              TextField(
                controller: expController,
                maxLines: 3,
                decoration: const InputDecoration(hintText: 'e.g. 2 years Python and machine learning data analysis...'),
              ),
              const SizedBox(height: 14),
              const Text('2. Weekly availability commitment:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 6),
              TextField(
                controller: hoursController,
                decoration: const InputDecoration(hintText: 'e.g. 8-10 hours / week'),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryTeal),
                  onPressed: () async {
                    if (expController.text.trim().isEmpty) return;
                    Navigator.pop(ctx);
                    try {
                      await _apiService.applyToTeam(call.id, [
                        expController.text.trim(),
                        hoursController.text.trim(),
                      ]);
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Application submitted! Project owner notified.')),
                        );
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
                      }
                    }
                  },
                  child: const Text('Submit Application'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openProjectWorkspace() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.darkSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.8,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        expand: false,
        builder: (_, scrollController) => SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Project Workspace', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text('Active', style: TextStyle(color: AppColors.success, fontWeight: FontWeight.bold, fontSize: 11)),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              const Text('Citation Accuracy in LLMs • 2 Members (Private)', style: TextStyle(color: AppColors.darkTextSecondary, fontSize: 12)),
              const Divider(height: 24),
              const Text('Active Tasks (Sprint 1)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              const SizedBox(height: 10),
              _buildTaskItem('1. Automated PDF parser pipeline', 'High', 'In progress', 'Alex Rivera'),
              _buildTaskItem('2. Statistical significance testing script', 'Medium', 'Not started', 'Elena Rostova'),
              _buildTaskItem('3. Literature review gap matrix', 'Low', 'Done', 'Alex Rivera'),
              const Divider(height: 24),
              const Text('Milestones', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              const SizedBox(height: 8),
              const Text('• Milestone 1: Benchmark dataset curated (Target: Dec 15)', style: TextStyle(fontSize: 13)),
              const Text('• Milestone 2: Evaluation script executed on 10 models (Target: Jan 10)', style: TextStyle(fontSize: 13)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTaskItem(String title, String priority, String status, String assignee) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.darkBackground,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.darkBorder),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 2),
                Text('Assignee: $assignee', style: const TextStyle(fontSize: 11, color: AppColors.darkTextMuted)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: status == 'Done' ? AppColors.success.withValues(alpha: 0.2) : AppColors.primaryTeal.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(status, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: status == 'Done' ? AppColors.success : AppColors.brightTeal)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Teams & Project Workspaces')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadRequests,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  const Text(
                    'Open Team Calls',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.darkTextPrimary),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Collaborate on peer academic projects. Must-have skills are required for eligibility.',
                    style: TextStyle(fontSize: 12, color: AppColors.darkTextSecondary),
                  ),
                  const SizedBox(height: 12),
                  if (_teamCalls.isEmpty)
                    const Card(
                      child: Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Text('No open team calls right now.', textAlign: TextAlign.center),
                      ),
                    )
                  else
                    ..._teamCalls.map((call) => Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(call.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: call.remainingCapacity > 0 ? AppColors.brightTeal.withValues(alpha: 0.15) : AppColors.error.withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        '${call.remainingCapacity} / ${call.membersNeeded} Slots',
                                        style: TextStyle(
                                          color: call.remainingCapacity > 0 ? AppColors.brightTeal : AppColors.error,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text('Domain: ${call.primaryDomain.toUpperCase()} • Mode: ${call.mode}', style: const TextStyle(fontSize: 11, color: AppColors.darkTextMuted)),
                                const SizedBox(height: 8),
                                Text(call.description, style: const TextStyle(fontSize: 13, height: 1.4)),
                                const SizedBox(height: 10),
                                Wrap(
                                  spacing: 6,
                                  runSpacing: 4,
                                  children: call.skillsNeeded.map((s) => Chip(
                                    label: Text('${s.skill} ${s.mustHave ? "(Required)" : ""}', style: const TextStyle(fontSize: 10)),
                                    backgroundColor: s.mustHave ? AppColors.warning.withValues(alpha: 0.2) : AppColors.darkBackground,
                                  )).toList(),
                                ),
                                const SizedBox(height: 12),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryTeal),
                                    onPressed: call.remainingCapacity > 0 ? () => _showApplyModal(call) : null,
                                    child: Text(call.remainingCapacity > 0 ? 'Apply to Team' : 'Team Filled'),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )),
                  const SizedBox(height: 20),
                  const Text(
                    'Active Workspace (Members Only)',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.darkTextPrimary),
                  ),
                  const SizedBox(height: 10),
                  Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: const BorderSide(color: AppColors.brightTeal, width: 1.2),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.folder_shared_rounded, color: AppColors.brightTeal, size: 20),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text('LLM Citation Accuracy Evaluation Workspace', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          const Text('Private collaboration workspace active for team members.', style: TextStyle(fontSize: 12, color: AppColors.darkTextSecondary)),
                          const SizedBox(height: 12),
                          OutlinedButton.icon(
                            icon: const Icon(Icons.arrow_forward_rounded, size: 16),
                            label: const Text('Open Project Workspace & Tasks'),
                            onPressed: _openProjectWorkspace,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
