import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class ChatScreen extends StatefulWidget {
  final String conversationTitle;
  final String participantRole;

  const ChatScreen({
    super.key,
    required this.conversationTitle,
    required this.participantRole,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _msgController = TextEditingController();
  final List<Map<String, dynamic>> _messages = [
    {
      'id': 'm1',
      'sender': 'Prof. Elena Rostova',
      'isMe': false,
      'text': 'Hello Alex! I reviewed your proposed evaluation metric for citation consistency. The idea of isolating hallucinated DOI patterns is promising.',
      'time': '10:14 AM',
    },
    {
      'id': 'm2',
      'sender': 'Alex Rivera',
      'isMe': true,
      'text': 'Thank you Professor! We are planning to run an initial pilot on 200 synthetic prompts this Friday.',
      'time': '10:18 AM',
    },
  ];

  void _sendMessage() {
    final text = _msgController.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _messages.add({
        'id': 'm-${DateTime.now().millisecondsSinceEpoch}',
        'sender': 'Me',
        'isMe': true,
        'text': text,
        'time': 'Just now',
      });
      _msgController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.conversationTitle, style: const TextStyle(fontSize: 16)),
            Text(widget.participantRole, style: const TextStyle(fontSize: 11, color: AppColors.brightTeal)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Academic connection conversation. Strictly end-to-end access restricted.')),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final m = _messages[index];
                final isMe = m['isMe'] as bool;
                return Align(
                  alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
                    decoration: BoxDecoration(
                      color: isMe ? AppColors.primaryTeal : AppColors.darkSurface,
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(14),
                        topRight: const Radius.circular(14),
                        bottomLeft: isMe ? const Radius.circular(14) : Radius.zero,
                        bottomRight: isMe ? Radius.zero : const Radius.circular(14),
                      ),
                      border: Border.all(color: isMe ? AppColors.deepTeal : AppColors.darkBorder),
                    ),
                    child: Column(
                      crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                      children: [
                        Text(m['text'], style: const TextStyle(fontSize: 13, height: 1.4)),
                        const SizedBox(height: 4),
                        Text(m['time'], style: const TextStyle(fontSize: 10, color: AppColors.darkTextMuted)),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            color: AppColors.darkSurface,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _msgController,
                    decoration: const InputDecoration(
                      hintText: 'Type an academic discussion message...',
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send_rounded, color: AppColors.brightTeal),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
