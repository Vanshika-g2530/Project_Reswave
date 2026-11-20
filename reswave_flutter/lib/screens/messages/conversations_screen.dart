import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../models/message_models.dart';
import '../../services/api_client.dart';
import 'chat_screen.dart';

class ConversationsScreen extends StatefulWidget {
  const ConversationsScreen({super.key});

  @override
  State<ConversationsScreen> createState() => _ConversationsScreenState();
}

class _ConversationsScreenState extends State<ConversationsScreen> {
  final ResWaveApiService _apiService = ResWaveApiService();
  List<ConversationModel> _conversations = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadConversations();
  }

  Future<void> _loadConversations() async {
    setState(() => _isLoading = true);
    try {
      final list = await _apiService.getConversations();
      if (mounted) setState(() => _conversations = list);
    } catch (_) {
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Academic Messages'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadConversations,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadConversations,
              child: _conversations.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.chat_bubble_outline_rounded, size: 56, color: AppColors.darkTextMuted),
                            const SizedBox(height: 14),
                            const Text('No conversations yet', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 6),
                            const Text(
                              'Connect with researchers or accept incoming connection requests to start direct academic messaging.',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 12, color: AppColors.darkTextSecondary),
                            ),
                          ],
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: _conversations.length,
                      itemBuilder: (context, index) {
                        final conv = _conversations[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 10),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: AppColors.primaryTeal,
                              child: Text(
                                conv.otherUserName.isNotEmpty ? conv.otherUserName[0] : 'U',
                                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                              ),
                            ),
                            title: Text(conv.otherUserName, style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text(
                              conv.lastMessage,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 12, color: AppColors.darkTextSecondary),
                            ),
                            trailing: conv.unreadCount > 0
                                ? Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(color: AppColors.brightTeal, borderRadius: BorderRadius.circular(10)),
                                    child: Text(
                                      '${conv.unreadCount}',
                                      style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 11),
                                    ),
                                  )
                                : const Icon(Icons.chevron_right_rounded, color: AppColors.darkTextMuted),
                            onTap: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ChatScreen(
                                    conversationTitle: conv.otherUserName,
                                    participantRole: conv.otherUserRole ?? 'Researcher',
                                    conversationId: conv.id,
                                  ),
                                ),
                              );
                              _loadConversations();
                            },
                          ),
                        );
                      },
                    ),
            ),
    );
  }
}
