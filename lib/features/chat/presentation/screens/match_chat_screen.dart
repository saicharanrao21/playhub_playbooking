import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:playhub_playbooking/app/bootstrap/bootstrap.dart';
import 'package:playhub_playbooking/core/security/auth_provider.dart';
import 'package:playhub_playbooking/features/chat/presentation/providers/chat_providers.dart';

class MatchChatScreen extends ConsumerStatefulWidget {
  final String matchId;
  const MatchChatScreen({super.key, required this.matchId});

  @override
  ConsumerState<MatchChatScreen> createState() => _MatchChatScreenState();
}

class _MatchChatScreenState extends ConsumerState<MatchChatScreen> {
  final _textController = TextEditingController();
  final _scrollController = ScrollController();
  final List<Map<String, dynamic>> _liveMessages = [];
  StreamSubscription? _msgSub;
  StreamSubscription? _arrivalSub;
  bool _isArriving = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      final tokenStorage = ref.read(tokenStorageProvider);
      final token = await tokenStorage.readAccessToken();

      if (token != null && mounted) {
        final chatService = ref.read(chatServiceProvider);
        chatService.connect('http://localhost:3000', token);
        chatService.joinMatchRoom(widget.matchId);

        _msgSub = chatService.onNewMessage.listen((data) {
          if (data['matchId'] == widget.matchId && data['message'] != null && mounted) {
            setState(() {
              _liveMessages.add(Map<String, dynamic>.from(data['message']));
            });
            _scrollToBottom();
          }
        });

        _arrivalSub = chatService.onCourtArrival.listen((data) {
          if (data['matchId'] == widget.matchId && mounted) {
            final messenger = ScaffoldMessenger.of(context);
            messenger.showSnackBar(
              SnackBar(
                content: Text('📍 ${data['senderName']} has arrived at the court!'),
                backgroundColor: Colors.green,
              ),
            );
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _msgSub?.cancel();
    _arrivalSub?.cancel();
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent + 80,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    }
  }

  void _sendMessage() {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    final chatService = ref.read(chatServiceProvider);
    chatService.sendMessage(
      widget.matchId,
      text,
      clientMessageId: 'client_msg_${DateTime.now().millisecondsSinceEpoch}',
    );

    _textController.clear();
  }

  Future<void> _handleCourtArrival() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Court Arrival'),
        content: const Text('Notify all match participants that you have arrived on ground?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(context, true),
            icon: const Icon(Icons.my_location),
            label: const Text("I've Arrived"),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final messenger = ScaffoldMessenger.of(context);
      setState(() => _isArriving = true);
      try {
        final chatService = ref.read(chatServiceProvider);
        chatService.registerCourtArrival(widget.matchId, notes: 'At Court Gate');
        messenger.showSnackBar(
          const SnackBar(content: Text('📍 Court arrival registered & broadcasted!'), backgroundColor: Colors.green),
        );
      } finally {
        if (mounted) setState(() => _isArriving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    final currentUserId = authState.identity?.id;
    final historyAsync = ref.watch(chatHistoryProvider(widget.matchId));
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Match Group Chat', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: _isArriving
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.my_location, color: Colors.green),
            tooltip: "I've Arrived at Court",
            onPressed: _handleCourtArrival,
          ),
        ],
      ),
      body: Column(
        children: [
          // Real-time Chat Banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: colorScheme.primaryContainer.withValues(alpha: 0.3),
            child: const Row(
              children: [
                Icon(Icons.circle, color: Colors.green, size: 10),
                SizedBox(width: 8),
                Text('Real-Time Match Room Active', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
              ],
            ),
          ),

          // Message List
          Expanded(
            child: historyAsync.when(
              data: (history) {
                final historyItems = (history?['items'] as List?)?.map((e) => Map<String, dynamic>.from(e)).toList() ?? [];

                // Combine history + live messages
                final allMessages = [...historyItems];
                for (final live in _liveMessages) {
                  if (!allMessages.any((m) => m['id'] == live['id'] || (m['clientMessageId'] != null && m['clientMessageId'] == live['clientMessageId']))) {
                    allMessages.add(live);
                  }
                }

                if (allMessages.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24.0),
                      child: Text('No messages in match chat yet. Say hi to your team!'),
                    ),
                  );
                }

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: allMessages.length,
                  itemBuilder: (context, index) {
                    final msg = allMessages[index];
                    final isMe = msg['senderId'] == currentUserId;
                    final isArrival = msg['messageType'] == 'ARRIVAL_ALERT';
                    final senderName = msg['sender']?['fullName'] ?? msg['sender']?['email'] ?? 'Player';
                    final timeStr = DateFormat('h:mm a').format(DateTime.tryParse(msg['createdAt']?.toString() ?? '') ?? DateTime.now());

                    if (isArrival) {
                      return Container(
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.green.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.green.withValues(alpha: 0.4)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.my_location, color: Colors.green, size: 20),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                msg['body'] ?? 'Player has arrived at court!',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.green),
                              ),
                            ),
                            Text(timeStr, style: const TextStyle(fontSize: 10, color: Colors.grey)),
                          ],
                        ),
                      );
                    }

                    return Align(
                      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: isMe ? colorScheme.primary : colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.only(
                            topLeft: const Radius.circular(16),
                            topRight: const Radius.circular(16),
                            bottomLeft: Radius.circular(isMe ? 16 : 4),
                            bottomRight: Radius.circular(isMe ? 4 : 16),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (!isMe)
                              Text(
                                senderName,
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: colorScheme.primary),
                              ),
                            Text(
                              msg['body'] ?? '',
                              style: TextStyle(color: isMe ? colorScheme.onPrimary : colorScheme.onSurface, fontSize: 13),
                            ),
                            const SizedBox(height: 2),
                            Align(
                              alignment: Alignment.bottomRight,
                              child: Text(
                                timeStr,
                                style: TextStyle(fontSize: 9, color: isMe ? Colors.white70 : Colors.grey),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(child: Text('Error: $err')),
            ),
          ),

          // Message Composer
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4, offset: const Offset(0, -2)),
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _textController,
                      decoration: InputDecoration(
                        hintText: 'Type a message...',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(24)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      ),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  CircleAvatar(
                    backgroundColor: colorScheme.primary,
                    child: IconButton(
                      icon: const Icon(Icons.send, color: Colors.white, size: 18),
                      onPressed: _sendMessage,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
