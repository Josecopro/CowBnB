import 'dart:async';
import 'package:flutter/material.dart';
import '../design_tokens.dart';
import '../services/chat_service.dart';

class ChatPage extends StatefulWidget {
  final String conversationId;
  final String conversationTitle;

  const ChatPage({
    super.key,
    required this.conversationId,
    required this.conversationTitle,
  });

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final ChatService _chatService = ChatService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  StreamSubscription? _messagesSubscription;

  List<ChatMessage> _messages = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _chatService.markAsRead(widget.conversationId);
    _messagesSubscription = _chatService
        .messagesStream(widget.conversationId)
        .listen((messages) {
      setState(() {
        _messages = messages;
        _loading = false;
      });
      _scrollToBottom();
    });
  }

  @override
  void dispose() {
    _messagesSubscription?.cancel();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    _chatService.sendMessage(
      conversationId: widget.conversationId,
      text: text,
    );
    _messageController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.darkBg,
        title: Text(
          widget.conversationTitle,
          style: AppTextStyles.headlineSmall.copyWith(
            color: Colors.white,
            fontSize: 18,
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _messages.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(AppSpacing.lg),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 64,
                                height: 64,
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceContainer,
                                  borderRadius: BorderRadius.circular(AppRadius.lg),
                                ),
                                child: const Icon(
                                  Icons.forum_outlined,
                                  size: 28,
                                  color: AppColors.inkMuted,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.md),
                              Text(
                                'Aun no hay mensajes',
                                style: AppTextStyles.label,
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: AppSpacing.xs),
                              Text(
                                'Envia el primer mensaje para iniciar la conversacion.',
                                textAlign: TextAlign.center,
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: AppColors.inkMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(AppSpacing.md),
                        itemCount: _messages.length,
                        itemBuilder: (context, index) {
                          return _MessageBubble(
                            message: _messages[index],
                            isMine: _messages[index].senderId ==
                                _chatService.currentUserId,
                          );
                        },
                      ),
          ),
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.sm,
        AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(
          top: BorderSide(color: AppColors.borderSoft),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _messageController,
                decoration: InputDecoration(
                  hintText: 'Escribe un mensaje...',
                  hintStyle: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.inkMuted,
                  ),
                  filled: true,
                  fillColor: AppColors.surfaceContainer,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: 12,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                    borderSide: const BorderSide(
                      color: AppColors.primary,
                      width: 2,
                    ),
                  ),
                ),
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Material(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(AppRadius.pill),
              child: InkWell(
                borderRadius: BorderRadius.circular(AppRadius.pill),
                onTap: _sendMessage,
                child: const Padding(
                  padding: EdgeInsets.all(12),
                  child: Icon(Icons.send, color: Colors.white, size: 20),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final ChatMessage message;
  final bool isMine;

  const _MessageBubble({
    required this.message,
    required this.isMine,
  });

  String _formatTime(int timestamp) {
    final dt = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final now = DateTime.now();
    final diff = now.difference(dt);

    if (diff.inMinutes < 1) return 'Ahora';
    if (diff.inHours < 1) return '${diff.inMinutes}m';
    if (diff.inDays < 1) {
      return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    }
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Column(
        crossAxisAlignment:
            isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          if (!isMine)
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 2),
              child: Text(
                message.senderName,
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.primary,
                ),
              ),
            ),
          Row(
            mainAxisAlignment:
                isMine ? MainAxisAlignment.end : MainAxisAlignment.start,
            children: [
              if (!isMine) const SizedBox(width: 48),
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: isMine ? AppColors.primary : AppColors.surface,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(AppRadius.md),
                      topRight: const Radius.circular(AppRadius.md),
                      bottomLeft: Radius.circular(
                        isMine ? AppRadius.md : 4,
                      ),
                      bottomRight: Radius.circular(
                        isMine ? 4 : AppRadius.md,
                      ),
                    ),
                    border: isMine
                        ? null
                        : Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        message.text,
                        style: AppTextStyles.bodySmall.copyWith(
                          color:
                              isMine ? Colors.white : AppColors.ink,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _formatTime(message.timestamp),
                        style: TextStyle(
                          fontSize: 11,
                          color: isMine
                              ? Colors.white.withValues(alpha: 0.7)
                              : AppColors.inkMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (isMine) const SizedBox(width: 48),
            ],
          ),
        ],
      ),
    );
  }
}
