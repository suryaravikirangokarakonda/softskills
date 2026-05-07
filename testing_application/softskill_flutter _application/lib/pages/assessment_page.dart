import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:record/record.dart';
import 'package:audioplayers/audioplayers.dart';
import '../theme/app_colors.dart';
import '../widgets/navbar.dart';
import '../api_service.dart';

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final bool isRead;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.isRead = true,
  });
}

class AssessmentPage extends StatefulWidget {
  const AssessmentPage({super.key});

  @override
  State<AssessmentPage> createState() => _AssessmentPageState();
}

class _AssessmentPageState extends State<AssessmentPage> {
  final List<ChatMessage> _messages = [
    ChatMessage(
      text:
          "Hello! 👋\nI'm your AI communication coach. Ask me anything related to communication, soft skills, confidence, or any other topic. I'm here to help you grow!",
      isUser: false,
      timestamp: DateTime.now(),
    ),
  ];

  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final AudioRecorder _audioRecorder = AudioRecorder();
  final AudioPlayer _audioPlayer = AudioPlayer();

  final String _activeTab = 'AI Interaction';
  bool _isRecording = false;
  bool _isProcessing = false;

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _audioRecorder.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  void _sendMessage() {
    if (_messageController.text.trim().isEmpty) return;

    final userMessage = _messageController.text;
    setState(() {
      _messages.add(
        ChatMessage(text: userMessage, isUser: true, timestamp: DateTime.now()),
      );
      _messageController.clear();
      _isProcessing = true;
    });
    _scrollToBottom();

    // In a real app, you'd call a text-based AI API here.
    // For this demo, we'll simulate a response or you can hook it to your backend.
    Timer(const Duration(milliseconds: 1500), () {
      if (!mounted) return;
      setState(() {
        _isProcessing = false;
        _messages.add(
          ChatMessage(
            text:
                "That's a great point! Let's continue. How would you like to proceed?",
            isUser: false,
            timestamp: DateTime.now(),
          ),
        );
      });
      _scrollToBottom();
    });
  }

  Future<void> _toggleVoiceRecording() async {
    if (_isProcessing) return;

    if (_isRecording) {
      // Stop recording
      setState(() => _isRecording = false);
      final path = await _audioRecorder.stop();
      if (path != null) {
        _processAudio(path);
      }
    } else {
      // Start recording
      final hasPermission = await _audioRecorder.hasPermission();
      if (hasPermission) {
        setState(() => _isRecording = true);
        await _audioRecorder.start(
          const RecordConfig(encoder: AudioEncoder.opus),
          path: '', // Blob URL for web
        );
      }
    }
  }

  Future<void> _processAudio(String audioPath) async {
    setState(() => _isProcessing = true);

    try {
      final response = await ApiService.sendAudioToBackend(
        'ai-interaction',
        audioPath,
        'test_user_1',
      );

      final fullText = (response['fullText'] as String?) ?? '';
      String userMessage = (response['userText'] as String?) ?? '';
      final aiAudioBytes = response['audioBytes'];

      if (userMessage.isEmpty || userMessage.toUpperCase() == 'EMPTY') {
        userMessage = 'Voice message';
      }

      setState(() {
        _isProcessing = false;
        _messages.add(
          ChatMessage(
            text: userMessage,
            isUser: true,
            timestamp: DateTime.now(),
          ),
        );
        _messages.add(
          ChatMessage(text: fullText, isUser: false, timestamp: DateTime.now()),
        );
      });
      _scrollToBottom();

      if (aiAudioBytes != null) {
        await _audioPlayer.play(BytesSource(aiAudioBytes));
      }
    } catch (e) {
      setState(() => _isProcessing = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  void _showHowItWorks() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          'How AI Interaction works',
          style: GoogleFonts.sourceSans3(fontWeight: FontWeight.bold),
        ),
        content: Text(
          '1. Type or speak your message using the microphone.\n2. Our AI analyzes your communication style, tone, and vocabulary.\n3. Get instant feedback and practice real-life scenarios like role-playing conflict resolution.\n4. Track your progress in the Individual Feedback section.',
          style: GoogleFonts.sourceSans3(height: 1.6),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Got it!',
              style: TextStyle(
                color: AppColors.groqOrange,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
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

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isDesktop = width > 1024;

    return Scaffold(
      backgroundColor: const Color(0xFFFBFBFE),
      appBar: const Navbar(),
      endDrawer: const MobileDrawer(),
      body: Row(
        children: [
          if (isDesktop) _buildSidebar(),
          Expanded(
            child: Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.black.withOpacity(0.05)),
                    ),
                    child: Column(
                      children: [
                        Expanded(
                          child: ListView.builder(
                            controller: _scrollController,
                            padding: const EdgeInsets.all(24),
                            itemCount: _messages.length,
                            itemBuilder: (context, index) {
                              return _buildChatBubble(_messages[index]);
                            },
                          ),
                        ),
                        _buildInputArea(),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar() {
    return Container(
      width: 280,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          right: BorderSide(color: Colors.black.withOpacity(0.05)),
        ),
      ),
      child: Column(
        children: [
          _buildSidebarItem(
            'AI Interaction',
            Icons.chat_bubble_outline,
            '/ai-interaction',
          ),
          const SizedBox(height: 12),
          _buildSidebarItem('Role Play', Icons.people_outline, '/role-play'),
        ],
      ),
    );
  }

  Widget _buildSidebarItem(String title, IconData icon, String route) {
    final isActive = _activeTab == title;
    return GestureDetector(
      onTap: () {
        if (!isActive) Navigator.pushReplacementNamed(context, route);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: isActive ? AppColors.peach : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isActive ? AppColors.groqOrange : AppColors.mediumGray,
              size: 24,
            ),
            const SizedBox(width: 16),
            Text(
              title,
              style: GoogleFonts.sourceSans3(
                fontSize: 16,
                fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                color: isActive ? AppColors.groqOrange : AppColors.mediumGray,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'AI Interaction',
                style: GoogleFonts.sourceSans3(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: AppColors.black,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Chat with your AI assistant and improve your communication skills.',
                style: GoogleFonts.sourceSans3(
                  fontSize: 16,
                  color: AppColors.mediumGray,
                ),
              ),
            ],
          ),
          const Spacer(),
          GestureDetector(
            onTap: _showHowItWorks,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.black.withOpacity(0.05)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.02),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.lightbulb_outline,
                    size: 20,
                    color: AppColors.black,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'How it works?',
                    style: GoogleFonts.sourceSans3(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.black,
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

  Widget _buildChatBubble(ChatMessage message) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: message.isUser
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        children: [
          Container(
            constraints: const BoxConstraints(maxWidth: 600),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: message.isUser ? AppColors.peach : Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(20),
                topRight: const Radius.circular(20),
                bottomLeft: Radius.circular(message.isUser ? 20 : 0),
                bottomRight: Radius.circular(message.isUser ? 0 : 20),
              ),
              border: message.isUser
                  ? null
                  : Border.all(color: Colors.black.withOpacity(0.05)),
              boxShadow: [
                if (!message.isUser)
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildMessageContent(message.text, message.isUser),
                const SizedBox(height: 12),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      DateFormat('hh:mm a').format(message.timestamp),
                      style: GoogleFonts.sourceSans3(
                        fontSize: 12,
                        color: AppColors.mediumGray.withOpacity(0.6),
                      ),
                    ),
                    if (message.isUser) ...[
                      const SizedBox(width: 4),
                      Icon(
                        Icons.done_all,
                        size: 14,
                        color: message.isRead
                            ? AppColors.groqOrange
                            : Colors.grey,
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageContent(String text, bool isUser) {
    // Basic markdown-like parsing for bold text and bullet points
    final List<Widget> children = [];
    final lines = text.split('\n');

    for (var line in lines) {
      if (line.startsWith('•')) {
        children.add(
          Padding(
            padding: const EdgeInsets.only(left: 8, top: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '• ',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.groqOrange,
                  ),
                ),
                Expanded(
                  child: _buildRichText(line.substring(1).trim(), isUser),
                ),
              ],
            ),
          ),
        );
      } else {
        children.add(_buildRichText(line, isUser));
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children,
    );
  }

  Widget _buildRichText(String text, bool isUser) {
    final List<TextSpan> spans = [];
    final regex = RegExp(r'\*\*(.*?)\*\*');
    int lastIndex = 0;

    for (final match in regex.allMatches(text)) {
      if (match.start > lastIndex) {
        spans.add(TextSpan(text: text.substring(lastIndex, match.start)));
      }
      spans.add(
        TextSpan(
          text: match.group(1) ?? '',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      );
      lastIndex = match.end;
    }

    if (lastIndex < text.length) {
      spans.add(TextSpan(text: text.substring(lastIndex)));
    }

    return RichText(
      text: TextSpan(
        children: spans,
        style: GoogleFonts.sourceSans3(
          fontSize: 16,
          color: AppColors.black,
          height: 1.5,
        ),
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.black.withOpacity(0.05))),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.add, color: AppColors.mediumGray),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: TextField(
              controller: _messageController,
              onSubmitted: (_) => _sendMessage(),
              decoration: InputDecoration(
                hintText: 'Ask anything...',
                hintStyle: GoogleFonts.sourceSans3(
                  color: AppColors.mediumGray.withOpacity(0.5),
                  fontSize: 16,
                ),
                border: InputBorder.none,
              ),
            ),
          ),
          IconButton(
            icon: Icon(
              _isRecording ? Icons.stop_circle : Icons.mic_none,
              color: _isRecording ? Colors.red : AppColors.mediumGray,
            ),
            onPressed: _toggleVoiceRecording,
          ),
          const SizedBox(width: 16),
          GestureDetector(
            onTap: _isRecording ? _toggleVoiceRecording : _sendMessage,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _isRecording ? Colors.red : AppColors.groqOrange,
                shape: BoxShape.circle,
              ),
              child: _isProcessing
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Icon(
                      _isRecording ? Icons.stop : Icons.graphic_eq,
                      color: Colors.white,
                      size: 20,
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
