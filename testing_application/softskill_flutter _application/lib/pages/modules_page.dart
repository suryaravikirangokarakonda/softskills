import 'dart:math';
import 'package:flutter/material.dart';
import 'package:record/record.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../api_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/navbar.dart';
import 'package:google_fonts/google_fonts.dart';

class ModulesPage extends StatefulWidget {
  const ModulesPage({super.key});

  @override
  State<ModulesPage> createState() => _ModulesPageState();
}

class _ModulesPageState extends State<ModulesPage> {
  // 5 narration images with prompts using local assets
  static const List<Map<String, String>> _descriptionImages = [
    {
      'url': 'assets/images/scene1.png',
      'scene': 'A Village Fair',
      'label': 'FAIR_SCENE_01',
      'prompt': 'Tell a story about this village fair. What rides, animals, and activities can you see? How do the people feel?',
      'duration': '60 - 90 Seconds',
      'keywords': 'Fun, Celebration, Joy',
      'tips': 'Name the animals and rides you can see.|Talk about the sounds and smells you imagine.|Describe the mood and feelings of the people.',
    },
    {
      'url': 'assets/images/scene2.png',
      'scene': 'A Day at the Beach',
      'label': 'BEACH_SCENE_02',
      'prompt': 'Describe this beach scene. What are the people doing? How does the weather look? Tell us about the sights and sounds.',
      'duration': '60 - 90 Seconds',
      'keywords': 'Family, Ocean, Relaxation',
      'tips': 'Describe what the family is doing together.|Talk about the weather, water, and sand.|Use describing words like warm, bright, happy.',
    },
    {
      'url': 'assets/images/scene3.png',
      'scene': 'A Village Candy Shop',
      'label': 'SHOP_SCENE_03',
      'prompt': 'Describe what you see at this small candy shop. Who are the people? What are they doing?',
      'duration': '60 - 90 Seconds',
      'keywords': 'Children, Sweets, Happiness',
      'tips': 'Describe the colourful sweets and items you see.|Talk about the expressions on the children\'s faces.|Use simple action words like buying, sharing, smiling.',
    },
    {
      'url': 'assets/images/scene4.png',
      'scene': 'An Ice Cream Vendor',
      'label': 'VENDOR_SCENE_04',
      'prompt': 'Look at this ice cream vendor scene. Who are the people? What are they doing? What makes this moment special?',
      'duration': '60 - 90 Seconds',
      'keywords': 'Community, Treat, Joy',
      'tips': 'Describe the vendor and his bicycle cart.|Talk about the children and what they are holding.|Share how this image makes you feel.',
    },
    {
      'url': 'assets/images/scene5.png',
      'scene': 'Family Movie Time',
      'label': 'FAMILY_TV_05',
      'prompt': 'Describe this family watching TV together. What are they watching? What is the atmosphere in the room?',
      'duration': '60 - 90 Seconds',
      'keywords': 'Family, Home, Togetherness',
      'tips': 'Describe the room and the objects around the family.|Talk about the family members and their expressions.|Imagine what show or movie they are enjoying.',
    },
  ];

  final AudioRecorder _audioRecorder = AudioRecorder();
  final AudioPlayer _audioPlayer = AudioPlayer();
  final _supabase = Supabase.instance.client;

  bool _isRecording = false;
  bool _isProcessing = false;
  String _statusText = 'Click the microphone to start your story...';
  String _userInput = '';
  String _aiOutput = '';

  late List<int> _shuffledOrder;
  int _currentIndex = 0;
  bool _isCompleted = false;

  @override
  void initState() {
    super.initState();
    _shuffleImages();
  }

  @override
  void dispose() {
    _audioRecorder.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  void _shuffleImages() {
    _shuffledOrder = List<int>.generate(_descriptionImages.length, (i) => i);
    _shuffledOrder.shuffle(Random());
    _currentIndex = 0;
    _isCompleted = false;
    _resetInteraction();
  }

  void _resetInteraction() {
    _userInput = '';
    _aiOutput = '';
    _statusText = 'Click the microphone to start your story...';
    _isRecording = false;
    _isProcessing = false;
  }

  Map<String, String> get _currentImage => _descriptionImages[_shuffledOrder[_currentIndex]];

  void _onSubmitDescription() {
    setState(() {
      if (_currentIndex < _descriptionImages.length - 1) {
        _currentIndex++;
        _resetInteraction();
      } else {
        _isCompleted = true;
      }
    });
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
          _userInput = '';
          _aiOutput = '';
        });
        await _audioRecorder.start(
          RecordConfig(encoder: AudioEncoder.opus),
          path: '',
        );
      } else {
        setState(() => _statusText = 'Microphone permission denied.');
      }
    }
  }

  Future<void> _processAudio(String audioPath) async {
    setState(() {
      _isProcessing = true;
      _statusText = 'Analyzing your story...';
    });

    try {
      final response = await ApiService.sendAudioToBackend(
        'ai-interaction', // Standard endpoint for AI voice interaction
        audioPath,
        'test_user_1',
        {
          'module': 'image-narration',
          'scene': _currentImage['scene'] ?? '',
          'prompt': _currentImage['prompt'] ?? '',
          'tableName': 'image_narration_logs',
          'instructions': 'You are a professional Storytelling Coach. Analyze this user narration of "${_currentImage['scene']}". '
                          'CRITICAL: The "Polished Version" must be a charismatic, rich, and descriptive story (3-5 sentences) that fixes all errors and sounds professional. '
                          'Format your response exactly as follows: '
                          '1. Original Transcript: [user speech] '
                          '2. Polished Version: [your professional version] '
                          '3. Grammar Audit: [short list of fixes] '
                          '4. Story Flow: [feedback on logic/detail] '
                          '5. Soft Skills: [feedback on confidence/tone]'
        },
      );

      String fullText = (response['fullText'] as String?) ?? '';
      String transcribedText = (response['userText'] as String?) ?? '';
      final aiAudioBytes = response['audioBytes'];

      // Parse the 5-point structure if present
      if (fullText.contains('1. Original Transcript:')) {
        try {
          final parts = fullText.split(RegExp(r'\d\.\s+'));
          // parts[0] is usually empty or intro
          // parts[1] is Original Transcript
          // parts[2] is Polished Version...
          if (parts.length >= 3) {
            if (transcribedText.isEmpty || transcribedText.toUpperCase() == 'EMPTY') {
              transcribedText = parts[1].replaceFirst('Original Transcript:', '').trim();
            }
            // Keep the rest (from Polished Version onwards) as the AI output
            fullText = fullText.substring(fullText.indexOf('2. Polished Version:')).trim();
          }
        } catch (e) {
          // Fallback to full text
        }
      }

      setState(() {
        _userInput = transcribedText.isNotEmpty ? transcribedText : 'Voice narration processed.';
        _aiOutput = fullText;
        _statusText = 'Story analyzed!';
        _isProcessing = false;
      });

      // Save to Supabase using image_narration_logs
      await _supabase.from('image_narration_logs').insert({
        'user_id': 'test_user_1',
        'user_input': transcribedText,
        'ai_output': fullText,
      });

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
    final width = MediaQuery.of(context).size.width;
    final isDesktop = width > 900;

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: const Navbar(),
      endDrawer: const MobileDrawer(),
      body: Column(
        children: [
          Expanded(
            child: _isCompleted ? _buildCompletedScreen() : SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.all(isDesktop ? 48 : 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(isDesktop),
                    const SizedBox(height: 32),
                    _buildMainContent(isDesktop),
                    const SizedBox(height: 32),
                    _buildAudioSection(isDesktop),
                    if (_userInput.isNotEmpty || _aiOutput.isNotEmpty) ...[
                      const SizedBox(height: 32),
                      _buildCorrectionSection(isDesktop),
                    ],
                    const SizedBox(height: 48),
                    _buildPerformanceInsights(isDesktop),
                    const SizedBox(height: 48),
                    _buildFooter(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompletedScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.check_circle, color: Colors.green, size: 80),
          const SizedBox(height: 24),
          Text('Great Job!', style: AppTextStyles.sectionHeading.copyWith(fontSize: 32)),
          const SizedBox(height: 12),
          Text('You narrated all ${_descriptionImages.length} images!',
              style: AppTextStyles.bodyText.copyWith(color: AppColors.bodyGray)),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () => setState(() => _shuffleImages()),
            icon: const Icon(Icons.refresh),
            label: const Text('Practice Again'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryRed,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildHeader(bool isDesktop) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('ACTIVE MODULE: IMAGE NARRATION', style: AppTextStyles.label),
        const SizedBox(height: 12),
        Text(
          _currentImage['scene'] ?? '',
          style: isDesktop
              ? AppTextStyles.heroHeading.copyWith(fontSize: 42, color: AppColors.primaryRed)
              : AppTextStyles.heroHeading.copyWith(fontSize: 28, color: AppColors.primaryRed),
        ),
        const SizedBox(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                'Look at the image carefully and describe a short story in 3-5 sentences. Describe the people, the place, and what is happening.',
                style: AppTextStyles.bodyText,
              ),
            ),
            const SizedBox(width: 24),
            _buildBadge('IMAGE', '${_currentIndex + 1} / ${_descriptionImages.length}', AppColors.primaryRed),
            const SizedBox(width: 8),
            _buildBadge('REMAINING', '${_descriptionImages.length - _currentIndex - 1} left', AppColors.black),
          ],
        ),
      ],
    );
  }

  Widget _buildBadge(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.borderGray),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        children: [
          Text(label, style: AppTextStyles.label.copyWith(fontSize: 8, color: AppColors.bodyGray)),
          const SizedBox(height: 2),
          Text(value, style: AppTextStyles.cardTitle.copyWith(fontSize: 12, color: color)),
        ],
      ),
    );
  }

  Widget _buildMainContent(bool isDesktop) {
    if (isDesktop) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(flex: 5, child: _buildImageSection()),
          const SizedBox(width: 24),
          Expanded(flex: 4, child: _buildNarrativePromptAndTips()),
        ],
      );
    }
    return Column(
      children: [
        _buildImageSection(),
        const SizedBox(height: 24),
        _buildNarrativePromptAndTips(),
      ],
    );
  }

  Widget _buildImageSection() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Stack(
        children: [
          Container(
            height: 340,
            width: double.infinity,
            color: const Color(0xFF2A2A2A),
            child: Image.asset(
              _currentImage['url'] ?? '',
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.image_not_supported, size: 64, color: Colors.white38),
                      const SizedBox(height: 12),
                      Text(_currentImage['scene'] ?? '', style: const TextStyle(color: Colors.white54)),
                    ],
                  ),
                );
              },
            ),
          ),
          // Scene label badge
          Positioned(
            top: 12,
            left: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              color: AppColors.primaryRed.withValues(alpha: 0.9),
              child: Text(
                _currentImage['label'] ?? '',
                style: AppTextStyles.label.copyWith(color: AppColors.white, fontSize: 9),
              ),
            ),
          ),
          // Progress dots
          Positioned(
            bottom: 12,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_descriptionImages.length, (i) {
                final isDone = i < _currentIndex;
                final isCurrent = i == _currentIndex;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: isCurrent ? 24 : 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: isDone ? Colors.green : isCurrent ? AppColors.primaryRed : Colors.white38,
                    borderRadius: BorderRadius.circular(5),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNarrativePromptAndTips() {
    return Column(
      children: [
        // Narrative Prompt
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.borderGray),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.circle, size: 10, color: AppColors.primaryRed),
                  const SizedBox(width: 8),
                  Text('NARRATIVE PROMPT', style: AppTextStyles.cardTitle),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                '"${_currentImage['prompt'] ?? ''}"',
                style: AppTextStyles.bodyText.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.black,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Text('Target Duration', style: AppTextStyles.bodySmall.copyWith(fontSize: 12)),
                  const Spacer(),
                  Text(_currentImage['duration'] ?? '', style: AppTextStyles.cardTitle.copyWith(fontSize: 11)),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Text('Key Keywords', style: AppTextStyles.bodySmall.copyWith(fontSize: 12)),
                  const Spacer(),
                  Text(
                    _currentImage['keywords'] ?? '',
                    style: AppTextStyles.cardTitle.copyWith(fontSize: 11, color: AppColors.primaryRed),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Pro Tips
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.borderGray),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('PRO TIPS', style: AppTextStyles.label.copyWith(color: AppColors.bodyGray)),
              const SizedBox(height: 12),
              ...(_currentImage['tips'] ?? '').split('|').map((t) => _buildTip(t.trim())),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Buttons
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _onSubmitDescription,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryRed,
              foregroundColor: AppColors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
              elevation: 0,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _currentIndex < _descriptionImages.length - 1 ? 'Next Image →' : 'Finish Narration ✓',
                  style: AppTextStyles.buttonText.copyWith(color: AppColors.white),
                ),
                const SizedBox(width: 8),
                Icon(
                  _currentIndex < _descriptionImages.length - 1 ? Icons.arrow_forward : Icons.check_circle_outline,
                  size: 16,
                  color: AppColors.white,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: () => setState(() => _shuffleImages()),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.black,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
              side: const BorderSide(color: AppColors.black, width: 2),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Restart Practice', style: AppTextStyles.buttonText.copyWith(color: AppColors.black)),
                const SizedBox(width: 8),
                const Icon(Icons.refresh, size: 16, color: AppColors.black),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTip(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 6),
            width: 16,
            height: 2,
            color: AppColors.primaryRed,
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: AppTextStyles.bodySmall.copyWith(fontSize: 12))),
        ],
      ),
    );
  }

  Widget _buildAudioSection(bool isDesktop) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            // Mic button
            GestureDetector(
              onTap: _toggleRecording,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: _isRecording ? AppColors.black : AppColors.primaryRed,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: _isRecording ? [
                    BoxShadow(color: AppColors.primaryRed.withValues(alpha: 0.4), blurRadius: 12, spreadRadius: 2)
                  ] : [],
                ),
                child: _isProcessing
                    ? const Padding(
                        padding: EdgeInsets.all(16.0),
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
                      )
                    : Icon(_isRecording ? Icons.stop : Icons.mic, color: AppColors.white, size: 32),
              ),
            ),
            const SizedBox(width: 24),
            // Status and Waveform
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _isRecording ? 'Listening to your narration...' : 'Ready to record',
                    style: AppTextStyles.cardTitle.copyWith(fontSize: 16),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _statusText,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: _isRecording ? AppColors.primaryRed : AppColors.bodyGray,
                      fontWeight: _isRecording ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    height: 32,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: AppColors.lightGray,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: CustomPaint(
                      painter: _WaveformPainter(isAnimated: _isRecording),
                      size: const Size(double.infinity, 32),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 24),
            if (isDesktop)
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('MAX TIME', style: AppTextStyles.label.copyWith(fontSize: 10)),
                  Text('90s', style: AppTextStyles.cardTitle.copyWith(fontSize: 24, color: AppColors.primaryRed)),
                ],
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildCorrectionSection(bool isDesktop) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primaryRed.withValues(alpha: 0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome, color: AppColors.primaryRed, size: 24),
              const SizedBox(width: 12),
              Text('AI NARRATION FEEDBACK', style: AppTextStyles.cardTitle.copyWith(color: AppColors.primaryRed)),
            ],
          ),
          const SizedBox(height: 32),
          if (_userInput.isNotEmpty) ...[
            Text('YOUR NARRATION:', style: AppTextStyles.label.copyWith(letterSpacing: 1.2)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.lightGray.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _userInput,
                style: GoogleFonts.sourceSans3(
                  fontSize: 16, 
                  color: AppColors.charcoal,
                  height: 1.5,
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
          if (_aiOutput.isNotEmpty) ...[
            Text('IMPROVED STORY:', style: AppTextStyles.label.copyWith(letterSpacing: 1.2)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.primaryRed.withValues(alpha: 0.02),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.primaryRed.withValues(alpha: 0.05)),
              ),
              child: Text(
                _aiOutput,
                style: GoogleFonts.sourceSans3(
                  fontSize: 15,
                  height: 1.6,
                  color: AppColors.black,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPerformanceInsights(bool isDesktop) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('RECENT PERFORMANCE INSIGHTS', style: AppTextStyles.cardTitle),
        const SizedBox(height: 24),
        isDesktop
            ? Row(
                children: [
                  Expanded(child: _buildInsightCard('84', '%', 'VOCABULARY RICHNESS', 'Your use of professional terminology has increased by 12% since the last module.')),
                  const SizedBox(width: 16),
                  Expanded(child: _buildInsightCard('3.2', 's', 'AVG. HESITATION GAP', 'Great pacing. You are maintaining a steady flow with minimal \'um\' and \'ah\' fillers.')),
                  const SizedBox(width: 16),
                  Expanded(child: _buildInsightCard('91', '%', 'SENTIMENT ACCURACY', 'You correctly identified the \'defensive\' posture in the previous social exercise.')),
                ],
              )
            : Column(
                children: [
                  _buildInsightCard('84', '%', 'VOCABULARY RICHNESS', 'Your use of professional terminology has increased by 12% since the last module.'),
                  const SizedBox(height: 12),
                  _buildInsightCard('3.2', 's', 'AVG. HESITATION GAP', 'Great pacing. You are maintaining a steady flow with minimal \'um\' and \'ah\' fillers.'),
                  const SizedBox(height: 12),
                  _buildInsightCard('91', '%', 'SENTIMENT ACCURACY', 'You correctly identified the \'defensive\' posture in the previous social exercise.'),
                ],
              ),
      ],
    );
  }

  Widget _buildInsightCard(String value, String unit, String label, String description) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.borderGray),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                value,
                style: AppTextStyles.sectionHeading.copyWith(
                  fontSize: 36,
                  color: AppColors.primaryRed,
                ),
              ),
              Text(unit, style: AppTextStyles.bodyText.copyWith(fontSize: 20, color: AppColors.primaryRed)),
            ],
          ),
          const SizedBox(height: 4),
          Text(label, style: AppTextStyles.label.copyWith(color: AppColors.bodyGray, fontSize: 9)),
          const SizedBox(height: 12),
          Text(description, style: AppTextStyles.bodySmall.copyWith(fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.borderGray)),
      ),
      child: Row(
        children: [
          Text(
            'SoftSkill ',
            style: AppTextStyles.navLink.copyWith(color: AppColors.primaryRed, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic),
          ),
          Text('Development', style: AppTextStyles.navLink.copyWith(fontWeight: FontWeight.w900)),
          const Spacer(),
          Text('© 2023 SOFTSKILL EMPOWERMENT', style: AppTextStyles.label.copyWith(color: AppColors.bodyGray, fontSize: 9)),
          const SizedBox(width: 16),
          Text('PRIVACY POLICY', style: AppTextStyles.label.copyWith(color: AppColors.bodyGray, fontSize: 9)),
          const SizedBox(width: 16),
          Text('SECURITY PROTOCOLS', style: AppTextStyles.label.copyWith(color: AppColors.bodyGray, fontSize: 9)),
          const Spacer(),
          const Icon(Icons.share, size: 16, color: AppColors.bodyGray),
          const SizedBox(width: 12),
          const Icon(Icons.settings, size: 16, color: AppColors.bodyGray),
        ],
      ),
    );
  }
}

class _WaveformPainter extends CustomPainter {
  final bool isAnimated;
  _WaveformPainter({this.isAnimated = false});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.primaryRed
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final barWidth = 3.0;
    final gap = 3.0;
    final totalBars = (size.width / (barWidth + gap)).floor();


    for (int i = 0; i < totalBars; i++) {
      final x = i * (barWidth + gap);
      double heightFraction;
      if (isAnimated) {
        heightFraction = 0.2 + 0.8 * Random().nextDouble();
      } else {
        heightFraction = 0.3 + 0.7 * ((i * 7 + 3) % 10) / 10;
      }
      
      final barHeight = size.height * heightFraction;
      final top = (size.height - barHeight) / 2;

      canvas.drawLine(
        Offset(x, top),
        Offset(x, top + barHeight),
        paint..color = isAnimated 
            ? AppColors.primaryRed 
            : (i < totalBars * 0.3 ? AppColors.primaryRed : AppColors.borderGray),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _WaveformPainter oldDelegate) => oldDelegate.isAnimated != isAnimated || isAnimated;
}
