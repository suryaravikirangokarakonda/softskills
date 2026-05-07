import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:record/record.dart';
import 'package:audioplayers/audioplayers.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../api_service.dart';

class VoiceInteractionWidget extends StatefulWidget {
  final String endpoint;
  final String initialPrompt;
  final Map<String, String>? extraParams;

  final String? tableName;

  const VoiceInteractionWidget({
    super.key,
    required this.endpoint,
    this.initialPrompt = 'Click the microphone to begin voice interaction.',
    this.extraParams,
    this.tableName,
  });

  @override
  State<VoiceInteractionWidget> createState() => _VoiceInteractionWidgetState();
}

class _VoiceInteractionWidgetState extends State<VoiceInteractionWidget> {
  final AudioRecorder _audioRecorder = AudioRecorder();
  final AudioPlayer _audioPlayer = AudioPlayer();
  final _supabase = Supabase.instance.client;
  
  bool _isRecording = false;
  bool _isProcessing = false;
  String _statusText = '';
  String _assistantText = '';

  @override
  void initState() {
    super.initState();
    _statusText = widget.initialPrompt;
  }

  @override
  void dispose() {
    _audioRecorder.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _toggleRecording() async {
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
      bool hasPermission = await _audioRecorder.hasPermission();
      if (hasPermission) {
        setState(() {
          _isRecording = true;
          _statusText = 'Recording... Tap again to stop.';
        });
        // Using Opus encoder (WebM wrapper on chrome) avoids the WAV AudioWorklet 
        // buffering bugs that cut off recording during brief silences.
        await _audioRecorder.start(
          const RecordConfig(encoder: AudioEncoder.opus),
          path: '', // empty path for web creates a blob URL
        );
      } else {
        setState(() => _statusText = 'Microphone permission denied.');
      }
    }
  }

  Future<void> _processAudio(String audioPath) async {
    setState(() {
      _isProcessing = true;
      _statusText = 'Processing with AI...';
    });

    try {
      // 1. Send to Backend for AI processing
      final response = await ApiService.sendAudioToBackend(
        widget.endpoint,
        audioPath,
        'test_user_1',
        widget.extraParams,
      );

      final fullText = (response['fullText'] as String?) ?? '';
      final aiAudioBytes = response['audioBytes'];

      // Parse the text (Format: "Transcribed: [User] Polished: [AI] ...")
      // Parse the text
      String userMessage = (response['userText'] as String?) ?? '';
      String aiMessage = fullText;

      // Fallback parsing if userText is empty or placeholder but fullText has "Transcribed:"
      final isPlaceholder = userMessage.isEmpty || 
                            userMessage.toUpperCase() == 'EMPTY' || 
                            userMessage == 'Success' || 
                            userMessage == 'Speech not detected';

      if (isPlaceholder && fullText.contains('Transcribed:')) {
        if (fullText.contains('Polished:')) {
          final transcribedIdx = fullText.indexOf('Transcribed:') + 'Transcribed:'.length;
          final polishedIdx = fullText.indexOf('Polished:');
          userMessage = fullText.substring(transcribedIdx, polishedIdx).trim();
          aiMessage = fullText.substring(polishedIdx).trim();
        } else {
          userMessage = fullText.replaceFirst(RegExp(r'.*Transcribed:'), '').trim();
        }
      }

      // If userMessage is still empty or placeholder, use fallback
      if (userMessage.isEmpty || userMessage.toUpperCase() == 'EMPTY' || userMessage == 'Speech not detected') {
        userMessage = 'Voice Interaction (No speech detected)';
      }

      // Clean up quotes if present
      if (userMessage.startsWith('"') && userMessage.endsWith('"')) {
        userMessage = userMessage.substring(1, userMessage.length - 1);
      }

      setState(() {
        _assistantText = fullText;
        _statusText = 'Response generated. Saving to Supabase...';
      });

      // 2. Save to Database
      try {
        final targetTable = widget.tableName ?? 'conversation_logs';
        await _supabase.from(targetTable).insert({
          'user_id': 'test_user_1',
          'user_message': userMessage,
          'ai_message': aiMessage,
          'module_name': widget.endpoint,
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Progress saved to history.'), duration: Duration(seconds: 1)),
          );
        }
      } catch (e) {
        print('DEBUG: Supabase save error: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Database error: $e')),
          );
        }
      }

      setState(() {
        _statusText = 'Success! Data saved.';
        _isProcessing = false;
      });

      // Play audio response
      if (aiAudioBytes != null) {
        await _audioPlayer.play(BytesSource(aiAudioBytes));
      }
      
    } catch (e) {
      setState(() {
        _isProcessing = false;
        _statusText = 'Error: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_assistantText.isNotEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.only(bottom: 24),
            decoration: BoxDecoration(
              color: AppColors.groqOrange.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(6),
              border: const Border(left: BorderSide(color: AppColors.groqOrange, width: 3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.smart_toy, color: AppColors.groqOrange, size: 14),
                    const SizedBox(width: 6),
                    Text('AI RESPONSE', style: AppTextStyles.label.copyWith(color: AppColors.groqOrange, fontSize: 10)),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  _assistantText,
                  style: AppTextStyles.bodyText.copyWith(fontSize: 14),
                ),
              ],
            ),
          ),

        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(color: _isRecording ? AppColors.groqOrange : AppColors.borderGray),
            borderRadius: BorderRadius.circular(12),
            color: _isRecording ? AppColors.groqOrange.withValues(alpha: 0.05) : Colors.transparent,
          ),
          child: Row(
            children: [
              GestureDetector(
                onTap: _toggleRecording,
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: _isProcessing 
                        ? Colors.grey 
                        : (_isRecording ? AppColors.black : AppColors.groqOrange),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: _isProcessing 
                      ? const Padding(
                          padding: EdgeInsets.all(12.0),
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : Icon(
                          _isRecording ? Icons.stop : Icons.mic,
                          color: AppColors.white,
                          size: 22,
                        ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _isRecording ? 'Listening...' : 'Voice Input',
                      style: AppTextStyles.cardTitle.copyWith(fontSize: 14),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _statusText,
                      style: AppTextStyles.bodySmall.copyWith(
                        fontSize: 12,
                        color: _isRecording ? AppColors.groqOrange : AppColors.bodyGray,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
