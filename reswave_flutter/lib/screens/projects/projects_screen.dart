import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../models/team_request.dart' hide ProjectModel;
import '../../models/project_models.dart';
import '../../models/group_model.dart';
import '../../services/api_client.dart';

class ProjectsScreen extends StatefulWidget {
  final int initialTabIndex;

  const ProjectsScreen({
    super.key,
    this.initialTabIndex = 0,
  });

  @override
  State<ProjectsScreen> createState() => _ProjectsScreenState();
}

class _ProjectsScreenState extends State<ProjectsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ResWaveApiService _apiService = ResWaveApiService();

  List<TeamRequestModel> _teamCalls = [];
  List<ProjectModel> _myProjects = [];
  List<GroupModel> _groups = [];

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 3,
      initialIndex: widget.initialTabIndex.clamp(0, 2).toInt(),
      vsync: this,
    );
    _loadAllData();
  }

  Future<void> _loadAllData() async {
    setState(() => _isLoading = true);
    try {
      final teamCallsFuture = _apiService.getTeamRequests();
      final myProjectsFuture = _apiService.getMyProjects();
      final groupsFuture = _apiService.getGroups();

      final results = await Future.wait([
        teamCallsFuture,
        myProjectsFuture,
        groupsFuture,
      ]);

      if (mounted) {
        setState(() {
          _teamCalls = results[0] as List<TeamRequestModel>;
          _myProjects = results[1] as List<ProjectModel>;
          _groups = results[2] as List<GroupModel>;
        });
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showCreateTeamCallModal() {
    final titleController = TextEditingController();
    final descController = TextEditingController();
    final domainController = TextEditingController(text: 'ai-nlp');
    final topicsController =
        TextEditingController(text: 'evaluation, benchmarks');
    final membersController = TextEditingController(text: '2');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.darkSurface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
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
              const Text('Create Team Request / Call',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              TextField(
                controller: titleController,
                decoration:
                    const InputDecoration(labelText: 'Project / Paper Title *'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descController,
                maxLines: 3,
                decoration: const InputDecoration(
                    labelText: 'Research Objective & Requirements *'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: topicsController,
                decoration: const InputDecoration(
                    labelText: 'Topics (comma-separated)',
                    hintText: 'e.g. NLP, evaluation'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: membersController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                    labelText: 'Members Needed (Opening Capacity)',
                    hintText: 'e.g. 2'),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryTeal),
                  onPressed: () async {
                    if (titleController.text.trim().isEmpty) return;
                    Navigator.pop(ctx);
                    final numMembers =
                        int.tryParse(membersController.text.trim()) ?? 1;
                    final topics = topicsController.text
                        .split(',')
                        .map((e) => e.trim())
                        .where((e) => e.isNotEmpty)
                        .toList();
                    try {
                      await _apiService.createTeamRequest({
                        'title': titleController.text.trim(),
                        'description': descController.text.trim(),
                        'primaryDomain': domainController.text.trim(),
                        'topics': topics,
                        'skillsNeeded': [
                          {'skill': 'research methodology', 'mustHave': true}
                        ],
                        'rolesNeeded': ['Collaborator'],
                        'membersNeeded': numMembers,
                        'visibility': 'Discoverable',
                      });
                      _loadAllData();
                    } catch (e) {
                      if (mounted)
                        ScaffoldMessenger.of(context)
                            .showSnackBar(SnackBar(content: Text('Error: $e')));
                    }
                  },
                  child: const Text('Publish Team Call'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showApplyModal(TeamRequestModel call) {
    final expController = TextEditingController();
    final hoursController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.darkSurface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
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
              Text('Apply: ${call.title}',
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              Text(call.description,
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.darkTextSecondary)),
              const Divider(height: 24),
              const Text('1. Relevant skills & contributions:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 6),
              TextField(
                controller: expController,
                maxLines: 3,
                decoration: const InputDecoration(
                    hintText:
                        'e.g. 2 years Python and machine learning data analysis...'),
              ),
              const SizedBox(height: 14),
              const Text('2. Weekly availability commitment:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 6),
              TextField(
                controller: hoursController,
                decoration:
                    const InputDecoration(hintText: 'e.g. 8-10 hours / week'),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryTeal),
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
                          const SnackBar(
                              content: Text(
                                  'Application submitted! Project owner notified.'),
                              backgroundColor: AppColors.success),
                        );
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context)
                            .showSnackBar(SnackBar(content: Text('Error: $e')));
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

  void _showCreateGroupModal() {
    final titleController = TextEditingController();
    final descController = TextEditingController();
    final domainController = TextEditingController(text: 'hci');
    final topicsController =
        TextEditingController(text: 'user study, accessibility');
    String membershipMode = 'Open';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.darkSurface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
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
              const Text('Create Research Group',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              TextField(
                controller: titleController,
                decoration: const InputDecoration(labelText: 'Group Name *'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descController,
                maxLines: 3,
                decoration:
                    const InputDecoration(labelText: 'Purpose & Description *'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: topicsController,
                decoration: const InputDecoration(
                    labelText: 'Topic Tags (comma-separated)'),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: membershipMode,
                decoration: const InputDecoration(labelText: 'Membership Mode'),
                items: ['Open', 'Request to join']
                    .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                    .toList(),
                onChanged: (v) => membershipMode = v ?? membershipMode,
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryTeal),
                  onPressed: () async {
                    if (titleController.text.trim().isEmpty) return;
                    Navigator.pop(ctx);
                    final topics = topicsController.text
                        .split(',')
                        .map((e) => e.trim())
                        .where((e) => e.isNotEmpty)
                        .toList();
                    try {
                      await _apiService.createGroup({
                        'title': titleController.text.trim(),
                        'description': descController.text.trim(),
                        'primaryDomain': domainController.text.trim(),
                        'topics': topics,
                        'purpose':
                            'Collaborative academic inquiry and paper reading',
                        'membershipMode': membershipMode,
                        'visibility': 'Discoverable',
                        'rules':
                            'Respect academic integrity, foster constructive discussions.',
                      });
                      _loadAllData();
                    } catch (e) {
                      if (mounted)
                        ScaffoldMessenger.of(context)
                            .showSnackBar(SnackBar(content: Text('Error: $e')));
                    }
                  },
                  child: const Text('Create Group'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openProjectWorkspace(ProjectModel project) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.darkSurface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) =>
          _ProjectWorkspaceSheet(project: project, apiService: _apiService),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Collaborate: Teams & Groups'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.brightTeal,
          labelColor: AppColors.brightTeal,
          unselectedLabelColor: AppColors.darkTextMuted,
          tabs: [
            Tab(text: 'Team Calls (${_teamCalls.length})'),
            Tab(text: 'Workspaces (${_myProjects.length})'),
            Tab(text: 'Groups (${_groups.length})'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildTeamCallsTab(),
                _buildWorkspacesTab(),
                _buildGroupsTab(),
              ],
            ),
    );
  }

  Widget _buildTeamCallsTab() {
    return RefreshIndicator(
      onRefresh: _loadAllData,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Open Research Positions',
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                ElevatedButton.icon(
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Post Call'),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryTeal),
                  onPressed: _showCreateTeamCallModal,
                ),
              ],
            ),
          ),
          Expanded(
            child: _teamCalls.isEmpty
                ? const Center(child: Text('No active team requests.'))
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _teamCalls.length,
                    itemBuilder: (context, index) {
                      final call = _teamCalls[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                      child: Text(call.title,
                                          style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16))),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                        color: AppColors.primaryTeal
                                            .withValues(alpha: 0.2),
                                        borderRadius: BorderRadius.circular(4)),
                                    child: Text(
                                        '${call.remainingCapacity} Opening(s)',
                                        style: const TextStyle(
                                            color: AppColors.brightTeal,
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold)),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(call.description,
                                  style: const TextStyle(
                                      fontSize: 13,
                                      height: 1.3,
                                      color: AppColors.darkTextSecondary)),
                              const SizedBox(height: 10),
                              Wrap(
                                spacing: 6,
                                children: call.skillsNeeded.map((s) {
                                  final must = s.mustHave;
                                  return Chip(
                                    label: Text('${s.skill}${must ? " *" : ""}',
                                        style: TextStyle(
                                            fontSize: 10,
                                            color: must
                                                ? AppColors.warning
                                                : Colors.white)),
                                    backgroundColor: AppColors.darkBackground,
                                  );
                                }).toList(),
                              ),
                              const SizedBox(height: 12),
                              Align(
                                alignment: Alignment.centerRight,
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.primaryTeal),
                                  onPressed: () => _showApplyModal(call),
                                  child: const Text('Apply for Role'),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildWorkspacesTab() {
    return RefreshIndicator(
      onRefresh: _loadAllData,
      child: _myProjects.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.group_work_outlined,
                        size: 56, color: AppColors.darkTextMuted),
                    const SizedBox(height: 14),
                    const Text('No Active Workspaces',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    const Text(
                      'When you accept a team application or your application is accepted, a private workspace with tasks and milestones unlocks here.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 12, color: AppColors.darkTextSecondary),
                    ),
                  ],
                ),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _myProjects.length,
              itemBuilder: (context, index) {
                final proj = _myProjects[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: const CircleAvatar(
                        backgroundColor: AppColors.primaryTeal,
                        child: Icon(Icons.folder_shared_rounded,
                            color: Colors.white)),
                    title: Text(proj.title,
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(
                        '${proj.memberIds.length} Members • ${proj.status}',
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.darkTextSecondary)),
                    trailing: const Icon(Icons.arrow_forward_ios_rounded,
                        size: 16, color: AppColors.brightTeal),
                    onTap: () => _openProjectWorkspace(proj),
                  ),
                );
              },
            ),
    );
  }

  Widget _buildGroupsTab() {
    return RefreshIndicator(
      onRefresh: _loadAllData,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Research Communities',
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                ElevatedButton.icon(
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('New Group'),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryTeal),
                  onPressed: _showCreateGroupModal,
                ),
              ],
            ),
          ),
          Expanded(
            child: _groups.isEmpty
                ? const Center(child: Text('No research groups created yet.'))
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _groups.length,
                    itemBuilder: (context, index) {
                      final g = _groups[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(g.title,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16)),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                        color: AppColors.darkBackground,
                                        borderRadius: BorderRadius.circular(4)),
                                    child: Text('${g.memberCount} Members',
                                        style: const TextStyle(
                                            fontSize: 11,
                                            color: AppColors.brightTeal)),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(g.description,
                                  style: const TextStyle(
                                      fontSize: 13,
                                      color: AppColors.darkTextSecondary)),
                              const SizedBox(height: 12),
                              Align(
                                alignment: Alignment.centerRight,
                                child: ElevatedButton.icon(
                                  icon: const Icon(Icons.group_add_rounded,
                                      size: 16),
                                  label: Text(g.membershipMode == 'Open'
                                      ? 'Join Group'
                                      : 'Request to Join'),
                                  style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.primaryTeal),
                                  onPressed: () async {
                                    try {
                                      await _apiService.joinGroup(g.id);
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                            content: Text('Joined ${g.title}!'),
                                            backgroundColor: AppColors.success),
                                      );
                                      _loadAllData();
                                    } catch (e) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(SnackBar(
                                              content: Text('Error: $e')));
                                    }
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _ProjectWorkspaceSheet extends StatefulWidget {
  final ProjectModel project;
  final ResWaveApiService apiService;

  const _ProjectWorkspaceSheet(
      {required this.project, required this.apiService});

  @override
  State<_ProjectWorkspaceSheet> createState() => _ProjectWorkspaceSheetState();
}

class _ProjectWorkspaceSheetState extends State<_ProjectWorkspaceSheet> {
  List<ProjectTaskModel> _tasks = [];
  List<ProjectMilestoneModel> _milestones = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadWorkspaceData();
  }

  Future<void> _loadWorkspaceData() async {
    setState(() => _isLoading = true);
    try {
      final t = await widget.apiService.getProjectTasks(widget.project.id);
      final m = await widget.apiService.getProjectMilestones(widget.project.id);
      if (mounted) {
        setState(() {
          _tasks = t;
          _milestones = m;
        });
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showAddTaskDialog() {
    final titleController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Workspace Task'),
        content: TextField(
          controller: titleController,
          decoration: const InputDecoration(
              labelText: 'Task Title',
              hintText: 'e.g. Run data collection pipeline'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryTeal),
            onPressed: () async {
              if (titleController.text.trim().isEmpty) return;
              Navigator.pop(ctx);
              await widget.apiService.addProjectTask(
                  widget.project.id, titleController.text.trim());
              _loadWorkspaceData();
            },
            child: const Text('Add Task'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
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
                Expanded(
                    child: Text(widget.project.title,
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold))),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(4)),
                  child: Text(widget.project.status,
                      style: const TextStyle(
                          color: AppColors.success,
                          fontWeight: FontWeight.bold,
                          fontSize: 11)),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
                '${widget.project.memberIds.length} Members (Private Workspace)',
                style: const TextStyle(
                    color: AppColors.darkTextSecondary, fontSize: 12)),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Active Tasks',
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                TextButton.icon(
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Add Task'),
                  onPressed: _showAddTaskDialog,
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else if (_tasks.isEmpty)
              const Text('No tasks created yet.',
                  style:
                      TextStyle(color: AppColors.darkTextMuted, fontSize: 12))
            else
              ..._tasks.map((task) => Container(
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
                              Text(task.title,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13)),
                              Text(
                                  'Assignee: ${task.assigneeName ?? "Member"} • Priority: ${task.priority}',
                                  style: const TextStyle(
                                      fontSize: 11,
                                      color: AppColors.darkTextMuted)),
                            ],
                          ),
                        ),
                        InkWell(
                          onTap: () async {
                            final newStatus =
                                task.status == 'Done' ? 'In progress' : 'Done';
                            await widget.apiService.updateProjectTask(
                                widget.project.id,
                                task.id,
                                {'status': newStatus});
                            _loadWorkspaceData();
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: task.status == 'Done'
                                  ? AppColors.success.withValues(alpha: 0.2)
                                  : AppColors.primaryTeal
                                      .withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(task.status,
                                style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: task.status == 'Done'
                                        ? AppColors.success
                                        : AppColors.brightTeal)),
                          ),
                        ),
                      ],
                    ),
                  )),
            const Divider(height: 24),
            const Text('Milestones',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(height: 8),
            if (_milestones.isEmpty)
              const Text('• Initial Project Setup & Planning',
                  style: TextStyle(
                      fontSize: 13, color: AppColors.darkTextSecondary))
            else
              ..._milestones.map((m) => Text('• ${m.title} (${m.status})',
                  style: const TextStyle(fontSize: 13))),
          ],
        ),
      ),
    );
  }
}
