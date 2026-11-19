import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../models/paper_item.dart';
import '../../services/api_client.dart';

class PaperLibraryScreen extends StatefulWidget {
  const PaperLibraryScreen({super.key});

  @override
  State<PaperLibraryScreen> createState() => _PaperLibraryScreenState();
}

class _PaperLibraryScreenState extends State<PaperLibraryScreen> {
  final ResWaveApiService _apiService = ResWaveApiService();
  List<PaperItem> _papers = [];
  bool _isLoading = true;
  String _statusFilter = 'All';

  @override
  void initState() {
    super.initState();
    _loadPapers();
  }

  Future<void> _loadPapers() async {
    setState(() => _isLoading = true);
    try {
      final list = await _apiService.getMyPapers();
      if (mounted) setState(() => _papers = list);
    } catch (_) {
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showAddPaperDialog() {
    final titleController = TextEditingController();
    final authorsController = TextEditingController();
    final doiController = TextEditingController();
    final yearController = TextEditingController();
    final urlController = TextEditingController();
    final notesController = TextEditingController();
    String readingStatus = 'Want to read';

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
              const Text('Add Paper to Library', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 14),
              TextField(
                controller: titleController,
                decoration: const InputDecoration(labelText: 'Paper Title *', hintText: 'e.g. Attention Is All You Need'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: authorsController,
                decoration: const InputDecoration(labelText: 'Authors (comma-separated)', hintText: 'e.g. Vaswani, Shazeer, Parmar'),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: doiController,
                      decoration: const InputDecoration(labelText: 'DOI (Optional)', hintText: '10.1145/...'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: yearController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Year', hintText: '2023'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: urlController,
                decoration: const InputDecoration(labelText: 'URL (HTTPS)', hintText: 'https://arxiv.org/abs/...'),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: readingStatus,
                decoration: const InputDecoration(labelText: 'Reading Status'),
                items: ['Want to read', 'Reading', 'Read']
                    .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                    .toList(),
                onChanged: (v) => readingStatus = v ?? readingStatus,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: notesController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Private Notes (Strictly Confidential)',
                  hintText: 'Critical takeaways, research gaps identified...',
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryTeal),
                  onPressed: () async {
                    if (titleController.text.trim().isEmpty) return;
                    final paper = PaperItem(
                      id: 'paper-${DateTime.now().millisecondsSinceEpoch}',
                      userId: _apiService.currentUser?.uid ?? 'usr-local',
                      title: titleController.text.trim(),
                      authors: authorsController.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList(),
                      doi: doiController.text.trim().isNotEmpty ? doiController.text.trim() : null,
                      year: int.tryParse(yearController.text),
                      url: urlController.text.trim().isNotEmpty ? urlController.text.trim() : null,
                      readingStatus: readingStatus,
                      privateNotes: notesController.text.trim().isNotEmpty ? notesController.text.trim() : null,
                    );
                    Navigator.pop(ctx);
                    await _apiService.addPaper(paper);
                    _loadPapers();
                  },
                  child: const Text('Save to Library'),
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
    final filteredPapers = _statusFilter == 'All'
        ? _papers
        : _papers.where((p) => p.readingStatus == _statusFilter).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Personal Paper Library'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            onPressed: _showAddPaperDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter Tabs
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: AppColors.darkSurface,
            child: Row(
              children: ['All', 'Want to read', 'Reading', 'Read'].map((s) {
                final selected = _statusFilter == s;
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: ChoiceChip(
                    label: Text(s, style: const TextStyle(fontSize: 11)),
                    selected: selected,
                    selectedColor: AppColors.primaryTeal,
                    onSelected: (_) => setState(() => _statusFilter = s),
                  ),
                );
              }).toList(),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : filteredPapers.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.menu_book_rounded, size: 54, color: AppColors.darkTextMuted),
                            const SizedBox(height: 12),
                            const Text('No papers in this shelf yet.', style: TextStyle(color: AppColors.darkTextSecondary)),
                            const SizedBox(height: 14),
                            ElevatedButton(
                              onPressed: _showAddPaperDialog,
                              child: const Text('+ Add First Paper'),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: filteredPapers.length,
                        itemBuilder: (context, index) {
                          final p = filteredPapers[index];
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
                                      Expanded(
                                        child: Text(
                                          p.title,
                                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: AppColors.primaryTeal.withValues(alpha: 0.2),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          p.readingStatus,
                                          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.brightTeal),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${(p.authors).join(", ")} ${p.year != null ? "(${p.year})" : ""}',
                                    style: const TextStyle(fontSize: 12, color: AppColors.darkTextSecondary),
                                  ),
                                  if (p.doi != null) ...[
                                    const SizedBox(height: 2),
                                    Text('DOI: ${p.doi}', style: const TextStyle(fontSize: 11, color: AppColors.brightTeal)),
                                  ],
                                  if (p.privateNotes != null && p.privateNotes!.isNotEmpty) ...[
                                    const SizedBox(height: 10),
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: AppColors.darkBackground,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: AppColors.privateBadge.withValues(alpha: 0.4)),
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text('🔒 Private Notes (Confidential):', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.privateBadge)),
                                          const SizedBox(height: 4),
                                          Text(p.privateNotes!, style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic)),
                                        ],
                                      ),
                                    ),
                                  ],
                                  const SizedBox(height: 10),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.error),
                                        onPressed: () async {
                                          await _apiService.deletePaper(p.id);
                                          _loadPapers();
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
      ),
    );
  }
}
