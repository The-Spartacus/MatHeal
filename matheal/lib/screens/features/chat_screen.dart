// ignore_for_file: deprecated_member_use, prefer_const_constructors, prefer_const_literals_to_create_immutables

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/chat_service.dart';
import '../../utils/theme.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  bool _isTyping = false;

  @override
  void initState() {
    super.initState();
    _addMessage(
      ChatMessage(
        text: "Hello! I'm your maternal health assistant. I'm here to provide safe, conservative health tips. How can I help you today?",
        isUser: false,
        timestamp: DateTime.now(),
      ),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _addMessage(ChatMessage message) {
    setState(() {
      _messages.add(message);
    });
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty) return;

    // Add user message
    _addMessage(
      ChatMessage(
        text: message,
        isUser: true,
        timestamp: DateTime.now(),
      ),
    );

    _messageController.clear();
    setState(() => _isTyping = true);

    try {
      final response = await context.read<ChatService>().sendMessage(message);
      
      setState(() => _isTyping = false);
      
      _addMessage(
        ChatMessage(
          text: response,
          isUser: false,
          timestamp: DateTime.now(),
        ),
      );
    } catch (e) {
      setState(() => _isTyping = false);
      
      _addMessage(
        ChatMessage(
          text: "I'm sorry, I'm having trouble connecting right now. Please check your internet connection and try again. For urgent health concerns, please contact your healthcare provider directly.",
          isUser: false,
          timestamp: DateTime.now(),
          isError: true,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.psychology,
                color: AppColors.primary,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AI Health Assistant',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                Text(
                  'Online',
                  style: TextStyle(fontSize: 12, color: AppColors.success),
                ),
              ],
            ),
          ],
        ),
        backgroundColor: AppColors.background,
        elevation: 1,
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: AppColors.accent.withOpacity(0.1),
            child: Row(
              children: [
                const Icon(
                  Icons.info_outline,
                  color: AppColors.accent,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'This AI provides general health information. Always consult your doctor for medical advice.',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                return _buildMessageBubble(_messages[index]);
              },
            ),
          ),
          if (_isTyping) _buildTypingIndicator(),
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: message.isUser 
            ? MainAxisAlignment.end 
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!message.isUser) ...[
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: message.isError 
                    ? AppColors.error.withOpacity(0.1)
                    : AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                message.isError ? Icons.error_outline : Icons.psychology,
                size: 20,
                color: message.isError ? AppColors.error : AppColors.primary,
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.75,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: message.isUser
                    ? AppColors.primary
                    : message.isError
                        ? AppColors.error.withOpacity(0.1)
                        : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(18).copyWith(
                  bottomRight: message.isUser 
                      ? const Radius.circular(4) 
                      : const Radius.circular(18),
                  bottomLeft: !message.isUser 
                      ? const Radius.circular(4) 
                      : const Radius.circular(18),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.text,
                    style: TextStyle(
                      color: message.isUser 
                          ? Colors.white 
                          : message.isError
                              ? AppColors.error
                              : AppColors.textPrimary,
                      fontSize: 14,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatTime(message.timestamp),
                    style: TextStyle(
                      color: message.isUser 
                          ? Colors.white.withOpacity(0.7)
                          : AppColors.textHint,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (message.isUser) ...[
            const SizedBox(width: 8),
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.person,
                size: 20,
                color: AppColors.primary,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.psychology,
              size: 20,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(18),
                topRight: Radius.circular(18),
                bottomRight: Radius.circular(18),
                bottomLeft: Radius.circular(4),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildTypingDot(0),
                const SizedBox(width: 4),
                _buildTypingDot(1),
                const SizedBox(width: 4),
                _buildTypingDot(2),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypingDot(int index) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.4, end: 1.0),
      duration: const Duration(milliseconds: 600),
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: AppColors.textSecondary.withOpacity(value),
              borderRadius: BorderRadius.circular(3),
            ),
          ),
        );
      },
      onEnd: () {
        if (mounted) {
          Future.delayed(Duration(milliseconds: index * 200), () {
            if (mounted) setState(() {});
          });
        }
      },
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: InputDecoration(
                hintText: 'Ask about your health...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                  borderSide: const BorderSide(color: AppColors.primary),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.attach_file),
                  onPressed: () {
                    // TODO: Add file attachment
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('File attachment coming soon'),
                      ),
                    );
                  },
                ),
              ),
              maxLines: null,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          const SizedBox(width: 12),
          FloatingActionButton(
            mini: true,
            onPressed: _isTyping ? null : _sendMessage,
            backgroundColor: _isTyping 
                ? Colors.grey.shade300 
                : AppColors.primary,
            child: Icon(
              Icons.send,
              color: _isTyping ? Colors.grey.shade600 : Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }
}

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final bool isError;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.isError = false,
  });
}