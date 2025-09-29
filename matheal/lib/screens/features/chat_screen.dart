import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../../services/chat_service.dart';
import '../../utils/theme.dart';
import '../../models/chat_model.dart';
import '../../services/firestore_service.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<ChatMessageModel> _messages = [];
  bool _isTyping = false;
  late final String _userId;
  late final FirestoreService _firestoreService;

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      Navigator.of(context).pop();
      return;
    }
    _userId = user.uid;
    _firestoreService = context.read<FirestoreService>();
    _loadInitialMessages();
  }

  void _loadInitialMessages() {
    _firestoreService.getChatHistory(_userId).listen((messages) {
      if (mounted) {
        setState(() => _messages = messages);
        if (_messages.isEmpty) _addInitialGreeting();
        _scrollToBottom();
      }
    }, onError: (error) {
      print("Error loading chat history: $error");
      if (mounted) _addInitialGreeting();
    });
  }

  void _addInitialGreeting() {
    final greeting = ChatMessageModel(
      userId: _userId,
      text: "Hello! I'm your maternal health assistant. How can I help you today?",
      isUser: false,
      timestamp: DateTime.now(),
    );
    if (mounted) setState(() => _messages.add(greeting));
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _addMessage(ChatMessageModel message, {bool saveToDb = true}) {
    if (mounted) setState(() => _messages.add(message));
    if (saveToDb) _firestoreService.addChatMessage(message);
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
    final messageText = _messageController.text.trim();
    if (messageText.isEmpty) return;

    final userMessage = ChatMessageModel(
        userId: _userId, text: messageText, isUser: true, timestamp: DateTime.now());
    _addMessage(userMessage);

    _messageController.clear();
    setState(() => _isTyping = true);

    try {
      final responseText = await context.read<ChatService>().sendMessage(messageText);
      final botMessage = ChatMessageModel(
          userId: _userId, text: responseText, isUser: false, timestamp: DateTime.now());
      _addMessage(botMessage);
    } catch (e) {
      final errorMessage = ChatMessageModel(
          userId: _userId,
          text: "Sorry, an error occurred. Please try again.",
          isUser: false,
          timestamp: DateTime.now(),
          isError: true);
      _addMessage(errorMessage);
    } finally {
      if (mounted) setState(() => _isTyping = false);
    }
  }

  void _copyMessage(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Message copied to clipboard"),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              child: Image.asset('assets/images/bot.png')),
            const SizedBox(width: 12),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('AI Health Assistant', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                Text('Online', style: TextStyle(fontSize: 12, color: Colors.green)),
              ],
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            color: AppColors.primary.withOpacity(0.05),
            child: const Row(
              children: [
                Icon(Icons.info_outline, color: AppColors.primary, size: 20),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'This AI provides general health information. Always consult your doctor for medical advice.',
                    style: TextStyle(fontSize: 12),
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

  Widget _buildMessageBubble(ChatMessageModel message) {
    return GestureDetector(
      onLongPress: () => _copyMessage(message.text),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          mainAxisAlignment: message.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (!message.isUser)
              CircleAvatar(child: Image.asset('assets/images/bot.png')),
            const SizedBox(width: 8),
            Flexible(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: message.isUser
                      ? AppColors.primary
                      : (message.isError ? AppColors.error.withOpacity(0.1) : Colors.grey.shade200),
                  borderRadius: BorderRadius.circular(18).copyWith(
                    bottomRight: message.isUser ? const Radius.circular(4) : const Radius.circular(18),
                    bottomLeft: !message.isUser ? const Radius.circular(4) : const Radius.circular(18),
                  ),
                ),
                child: MarkdownBody(
                  data: message.text,
                  selectable: false, // Use onLongPress for copying
                  styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
                    p: TextStyle(
                      color: message.isUser ? Colors.white : (message.isError ? AppColors.error : Colors.black87),
                      fontSize: 15,
                    ),
                  ),
                ),
              ),
            ),
            if (message.isUser)
              const SizedBox(width: 8),
            if (message.isUser)
              const CircleAvatar(child: Icon(Icons.person)),
          ],
        ),
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          const CircleAvatar(child: Icon(Icons.psychology)),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(18).copyWith(bottomLeft: const Radius.circular(4)),
            ),
            child: const Text("Typing..."),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          )
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: InputDecoration(
                hintText: 'Ask a question...',
                filled: true,
                fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 20),
              ),
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          const SizedBox(width: 8),
          FloatingActionButton(
            mini: true,
            onPressed: _isTyping ? null : _sendMessage,
            elevation: 1,
            child: const Icon(Icons.send),
          ),
        ],
      ),
    );
  }
}
