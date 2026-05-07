import 'dart:math';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/navbar.dart';
import '../services/supabase_service.dart';
import '../services/api_service.dart';
import 'dashboard_page.dart';

class LearningModulePage extends StatefulWidget {
  const LearningModulePage({super.key});

  @override
  State<LearningModulePage> createState() => _LearningModulePageState();
}

class _LearningModulePageState extends State<LearningModulePage> {
  int _currentStep = 1;
  int _currentQuestion = 1;
  int _selectedVocabOption = -1;
  bool _isAssessmentCompleted = false;
  bool _isCheckingStatus = true;
  bool _isSubmitting = false;

  // Track scores
  int _vocabScore = 0;
  final List<String> _userSentences = [];
  final String _imageNarrationText = "";
  final String _confidenceCheckText = "";

  // Recording state
  final AudioRecorder _recorder = AudioRecorder();
  bool _isRecording = false;
  String? _recordedFilePath;
  String? _firstRecordedFilePath;
  Timer? _timer;
  int _secondsLeft = 60;

  // Track the generated questions for the current session
  List<_VocabQuestion> _generatedVocabQuestions = [];

  late List<String> _selectedSentenceWords;
  late String _selectedConfidenceTopic;

  static const List<String> _confidenceTopics = [
    'My favorite hobby and why I love it.',
    'My best friend and what we like to do together.',
    'My favorite school subject and why it is interesting.',
    'What I want to be when I grow up.',
    'A fun day I had with my family.',
    'My favorite animal and some cool facts about it.',
    'My favorite cartoon or movie character.',
    'What I like most about my school.',
    'My favorite food and how it tastes.',
    'A place I would love to visit one day.',
  ];

  @override
  void initState() {
    super.initState();
    _checkAssessmentStatus();
    _pickRandomQuestions();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _recorder.dispose();
    super.dispose();
  }

  Future<void> _checkAssessmentStatus() async {
    final userId =
        SupabaseService.client.auth.currentUser?.id ?? 'test_user_123';
    final hasCompleted = await SupabaseService.hasCompletedAssessment(userId);
    if (mounted) {
      setState(() {
        _isAssessmentCompleted = hasCompleted;
        _isCheckingStatus = false;
      });
    }
  }

  void _pickRandomQuestions() {
    final random = Random();

    // 1. Generate 5 unique MCQ questions for Vocabulary Check (Step 1)
    final wordsWithDefs = _vocabDefinitions.keys.toList();
    wordsWithDefs.shuffle(random);

    _generatedVocabQuestions = [];
    if (wordsWithDefs.isNotEmpty) {
      final count = wordsWithDefs.length < 5 ? wordsWithDefs.length : 5;
      final selectedWords = wordsWithDefs.take(count).toList();

      for (var targetWord in selectedWords) {
        final correctDef = _vocabDefinitions[targetWord]!;

        // Pick 3 definitions of words that are alphabetically "near" to make it harder
        final targetIndex = wordsWithDefs.indexOf(targetWord);
        final startRange = (targetIndex - 10).clamp(0, wordsWithDefs.length - 1);
        final endRange = (targetIndex + 10).clamp(0, wordsWithDefs.length - 1);
        
        final nearbyWords = wordsWithDefs.sublist(startRange, endRange)
            .where((w) => w != targetWord)
            .toList();
        
        nearbyWords.shuffle(random);
        final distractors = nearbyWords.take(3).map((w) => _vocabDefinitions[w]!).toList();

        // If not enough nearby words, fill with random distractors
        if (distractors.length < 3) {
          final otherDefs = _vocabDefinitions.values
              .where((d) => d != correctDef && !distractors.contains(d))
              .toList();
          otherDefs.shuffle(random);
          distractors.addAll(otherDefs.take(3 - distractors.length));
        }

        // Create options list and shuffle
        final options = [correctDef, ...distractors];
        options.shuffle(random);

        _generatedVocabQuestions.add(
          _VocabQuestion(
            word: targetWord,
            correctDefinition: correctDef,
            options: options,
            correctIndex: options.indexOf(correctDef),
          ),
        );
      }
    }

    // 2. Pick random words for Sentence Formation
    final allWords = List<String>.from(_allVocabWords);
    allWords.shuffle(random);
    _selectedSentenceWords = allWords.take(5).toList();

    // 3. Pick a random confidence topic
    _selectedConfidenceTopic = _confidenceTopics.isNotEmpty
        ? _confidenceTopics[random.nextInt(_confidenceTopics.length)]
        : 'My future goals.';
  }

  Future<void> _startRecording() async {
    try {
      if (await _recorder.hasPermission()) {
        String? path;
        if (!kIsWeb) {
          final directory = await getApplicationDocumentsDirectory();
          path =
              '${directory.path}/recording_${DateTime.now().millisecondsSinceEpoch}.m4a';
        }

        const config = RecordConfig();
        await _recorder.start(config, path: path ?? '');

        setState(() {
          _isRecording = true;
          _recordedFilePath = path;
          _secondsLeft = 60;
        });

        _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
          setState(() {
            if (_secondsLeft > 0) {
              _secondsLeft--;
            } else {
              _onTimerComplete();
            }
          });
        });
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Microphone permission denied. Please enable it in settings.',
              ),
            ),
          );
        }
      }
    } catch (e) {
      print('Error starting record: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error starting recording: $e')));
      }
    }
  }

  Future<void> _stopRecording() async {
    try {
      _timer?.cancel();
      final path = await _recorder.stop();
      setState(() {
        _isRecording = false;
        _recordedFilePath = path;
      });
    } catch (e) {
      print('Error stopping record: $e');
    }
  }

  Future<void> _onTimerComplete() async {
    await _stopRecording();
    if (_currentStep == 3) {
      _evaluateAndMoveToNext('image_description');
    } else if (_currentStep == 4) {
      _evaluateAndMoveToNext('confidence_check');
    }
  }

  Future<void> _evaluateAndMoveToNext(String moduleType) async {
    if (_recordedFilePath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please record your answer first.')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final userId =
          SupabaseService.client.auth.currentUser?.id ?? 'test_user_123';

      // Determine context for AI
      String contextText = '';
      if (moduleType == 'sentence_formation') {
        contextText = _currentQuestion == 1
            ? _selectedSentenceWords[0]
            : "${_selectedSentenceWords[1]}, ${_selectedSentenceWords[2]}";
      } else if (moduleType == 'image_description') {
        contextText = "A park scene with people and nature";
      } else if (moduleType == 'confidence_check') {
        contextText = _selectedConfidenceTopic;
      }

      final errorMsg = await ApiService.evaluateAssessment(
        userId: userId,
        moduleType: moduleType,
        context: contextText,
        audioPath: _recordedFilePath!,
        secondAudioPath: moduleType == 'sentence_formation' ? _firstRecordedFilePath : null,
      );

      if (errorMsg == null && mounted) {
        setState(() {
          if (_currentStep < 4) {
            _currentStep++;
            _currentQuestion = 1;
          } else {
            _submitAssessment();
          }
          _recordedFilePath = null;
          _isSubmitting = false;
        });
      } else if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMsg ?? 'Evaluation failed. Please try again.'),
            backgroundColor: Colors.redAccent,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  void _nextStep() {
    setState(() {
      if (_currentStep == 1) {
        if (_currentQuestion < 5) {
          _currentQuestion++;
          _selectedVocabOption = -1;
        } else {
          // Save vocab score immediately after 5th question
          final userId = SupabaseService.client.auth.currentUser?.id ?? 'test_user_123';
          SupabaseService.updateModuleScore(
            userId: userId,
            column: 'vocabulary_score',
            score: _vocabScore.toDouble(),
          );
          
          _currentStep = 2;
          _currentQuestion = 1;
        }
      } else if (_currentStep == 2) {
        // Handle transitions in Sentence Formation
        if (_currentQuestion < 2) {
          if (_recordedFilePath == null) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Please record your answer first.')),
            );
            return;
          }
          _firstRecordedFilePath = _recordedFilePath;
          _currentQuestion++;
          _recordedFilePath = null; // Clear current for the second word
        } else {
          // Transition to Step 3 (Image Description)
          _evaluateAndMoveToNext('sentence_formation');
        }
      } else if (_currentStep == 3) {
        // Transition to Confidence Check
        _evaluateAndMoveToNext('image_description');
      } else if (_currentStep == 4) {
        // Final evaluation for Confidence Check
        _evaluateAndMoveToNext('confidence_check');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 900;

    if (_isCheckingStatus) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primaryRed),
        ),
      );
    }

    if (_isAssessmentCompleted) {
      return const DashboardPage();
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: const Navbar(),
      endDrawer: const MobileDrawer(),
      body: Stack(
        children: [
          Row(
            children: [
              if (isDesktop) _buildSidebar(),
              Expanded(
                child: Column(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        padding: EdgeInsets.all(isDesktop ? 32 : 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildTopHeader(),
                            const SizedBox(height: 32),
                            _buildStepper(),
                            const SizedBox(height: 32),
                            _buildMainContentCard(),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (_isSubmitting)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: Colors.white),
                    SizedBox(height: 24),
                    Text(
                      'Analyzing your assessment...',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
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

  Widget _buildSidebar() {
    return Container(
      width: 260,
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: AppColors.bodyGray),
                  onPressed: () => Navigator.pushReplacementNamed(context, '/'),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                const SizedBox(width: 8),
                Text(
                  'ASSESSMENT',
                  style: AppTextStyles.label.copyWith(
                    color: AppColors.bodyGray,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            _buildSidebarItem(1, 'Vocabulary Check', Icons.chat_bubble_outline),
            _buildSidebarItem(2, 'Sentence Formation', Icons.edit_note),
            _buildSidebarItem(3, 'Image Description', Icons.image_outlined),
            _buildSidebarItem(4, 'Confidence Check', Icons.mic_none),
            const SizedBox(height: 32),
            _buildSidebarItem(
              0,
              'Reset Assessment',
              Icons.refresh,
              onTap: () async {
                final userId =
                    SupabaseService.client.auth.currentUser?.id ??
                    'test_user_123';
                await SupabaseService.clearPerformanceHistory(userId);
                if (mounted) {
                  Navigator.pushReplacementNamed(
                    context,
                    '/personalized-learning',
                  );
                }
              },
            ),
            const SizedBox(height: 48),
            _buildProgressCard(),
            const SizedBox(height: 24),
            _buildStudyTipCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildSidebarItem(
    int step,
    String title,
    IconData icon, {
    VoidCallback? onTap,
  }) {
    final isActive = _currentStep == step;
    final isCompleted = _currentStep > step;

    Color iconColor;
    Color bgColor;
    Color textColor = isActive ? AppColors.primaryRed : AppColors.bodyGray;
    FontWeight fontWeight = isActive ? FontWeight.bold : FontWeight.normal;

    if (isCompleted) {
      iconColor = Colors.white;
      bgColor = Colors.green;
      textColor = AppColors.charcoal;
    } else if (isActive) {
      iconColor = Colors.white;
      bgColor = AppColors.primaryRed;
    } else {
      iconColor = AppColors.bodyGray;
      bgColor = AppColors.lightGray;
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 24),
        padding: isActive ? const EdgeInsets.all(12) : EdgeInsets.zero,
        decoration: isActive
            ? BoxDecoration(
                color: AppColors.primaryRed.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(8),
                border: const Border(
                  left: BorderSide(color: AppColors.primaryRed, width: 3),
                ),
              )
            : null,
        child: Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle),
              child: Center(
                child: isCompleted
                    ? const Icon(Icons.check, size: 14, color: Colors.white)
                    : Text(
                        step == 0 ? '' : '$step',
                        style: TextStyle(
                          color: iconColor,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: textColor,
                  fontSize: 14,
                  fontWeight: fontWeight,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primaryRed.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primaryRed.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.emoji_events_outlined,
                color: AppColors.primaryRed,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Your Progress',
                style: AppTextStyles.cardTitle.copyWith(fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text('Step $_currentStep of 4', style: AppTextStyles.bodySmall),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: _currentStep / 4.0,
            backgroundColor: AppColors.borderGray,
            valueColor: const AlwaysStoppedAnimation<Color>(
              AppColors.primaryRed,
            ),
            minHeight: 6,
            borderRadius: BorderRadius.circular(3),
          ),
        ],
      ),
    );
  }

  Widget _buildStudyTipCard() {
    String tipText = '';
    switch (_currentStep) {
      case 1:
        tipText = 'Try to use the new word in a story to remember it better!';
        break;
      case 2:
        tipText = 'Think of a simple sentence that uses the word.';
        break;
      case 3:
        tipText = 'Tell me about the colors and things you see in the picture.';
        break; // Tip is already generic enough but I'll keep it as is or slightly adjust if needed. Actually it's fine.
      case 4:
        tipText = 'Just be yourself and speak clearly. You are doing great!';
        break;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primaryRed.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryRed.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.lightbulb_outline,
                color: AppColors.primaryRed,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Study Tip',
                style: AppTextStyles.cardTitle.copyWith(
                  fontSize: 14,
                  color: AppColors.primaryRed,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(tipText, style: AppTextStyles.bodySmall.copyWith(height: 1.5)),
        ],
      ),
    );
  }

  Widget _buildTopHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back, color: AppColors.charcoal),
              onPressed: () => Navigator.pushReplacementNamed(context, '/'),
            ),
            const SizedBox(width: 8),
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.primaryRed,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.school, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 16),
            Text(
              'Personalised Learning Module',
              style: AppTextStyles.sectionHeading,
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.primaryRed.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: AppColors.primaryRed.withValues(alpha: 0.2),
            ),
          ),
          child: Text(
            'Step $_currentStep of 4',
            style: const TextStyle(
              color: AppColors.primaryRed,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStepper() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 48),
      child: Row(
        children: [
          _buildStepIndicator(1, 'Vocabulary Check'),
          _buildStepLine(1),
          _buildStepIndicator(2, 'Sentence Formation'),
          _buildStepLine(2),
          _buildStepIndicator(3, 'Image Description'),
          _buildStepLine(3),
          _buildStepIndicator(4, 'Confidence Check'),
        ],
      ),
    );
  }

  Widget _buildStepIndicator(int step, String title) {
    final isActive = _currentStep == step;
    final isCompleted = _currentStep > step;

    Color bgColor = isCompleted
        ? Colors.green
        : (isActive ? AppColors.primaryRed : Colors.white);
    Color borderColor = isCompleted
        ? Colors.green
        : (isActive ? AppColors.primaryRed : AppColors.borderGray);
    Color iconColor = (isCompleted || isActive)
        ? Colors.white
        : AppColors.bodyGray;

    return Column(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: bgColor,
            shape: BoxShape.circle,
            border: Border.all(color: borderColor, width: 2),
          ),
          child: Center(
            child: isCompleted
                ? const Icon(Icons.check, size: 16, color: Colors.white)
                : Text(
                    '$step',
                    style: TextStyle(
                      color: iconColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 12,
            color: isActive ? AppColors.primaryRed : AppColors.bodyGray,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  Widget _buildStepLine(int step) {
    final isCompleted = _currentStep > step;
    return Expanded(
      child: Container(
        height: 2,
        margin: const EdgeInsets.only(bottom: 24, left: 8, right: 8),
        color: isCompleted ? Colors.green : AppColors.borderGray,
      ),
    );
  }

  Widget _buildMainContentCard() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildContentHeader(),
          const SizedBox(height: 24),
          if (_currentStep == 1) _buildVocabularyCheck(),
          if (_currentStep == 2) _buildSentenceFormation(),
          if (_currentStep == 3) _buildImageDescription(),
          if (_currentStep == 4) _buildConfidenceCheck(),
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: _currentStep == 2
                ? MainAxisAlignment.spaceBetween
                : MainAxisAlignment.end,
            children: [
              if (_currentStep == 2)
                OutlinedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.refresh, size: 18),
                  label: const Text('Reset'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.charcoal,
                    side: const BorderSide(color: AppColors.borderGray),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                  ),
                ),
              ElevatedButton(
                onPressed: (_isSubmitting)
                    ? null
                    : (_currentStep == 1 && _selectedVocabOption == -1)
                    ? null
                    : _nextStep,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryRed,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                  disabledBackgroundColor: AppColors.borderGray,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _currentStep == 4 ? 'Submit Assessment' : 'Next',
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.arrow_forward, size: 18),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _submitAssessment() async {
    setState(() => _isSubmitting = true);

    try {
      final userId =
          SupabaseService.client.auth.currentUser?.id ?? 'test_user_123';

      // 1. Collect all assessment data
      final assessmentData = {
        'user_id': userId,
        'vocab_score': _vocabScore,
        'sentences': _userSentences,
        'image_narration': _imageNarrationText,
        'confidence_check': _confidenceCheckText,
      };

      // 2. Call Python backend (via ApiService)
      final results = await ApiService.computeAssessmentValues(assessmentData);

      if (results != null) {
        // 3. Insert computed values into user_performance_history
        await SupabaseService.savePerformanceHistory(
          userId: userId,
          vocabulary: _vocabScore.toDouble(),
          sentenceFormation: (results['sentence_formation_score'] ?? 0)
              .toDouble(),
          imageNarration: (results['image_narration_score'] ?? 0).toDouble(),
          aiInteraction: (results['ai_interaction_score'] ?? 0).toDouble(),
        );

        // 4. Update UI to show dashboard
        if (mounted) {
          setState(() {
            _isAssessmentCompleted = true;
            _isSubmitting = false;
          });
        }
      } else {
        // Handle error
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to process assessment. Please try again.'),
            ),
          );
          setState(() => _isSubmitting = false);
        }
      }
    } catch (e) {
      print('Error submitting assessment: $e');
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Widget _buildContentHeader() {
    String title = '';
    String counter = '';
    switch (_currentStep) {
      case 1:
        title = 'Vocabulary Check';
        counter = '$_currentQuestion/5';
        break;
      case 2:
        title = 'Sentence Formation';
        counter = '$_currentQuestion/2';
        break;
      case 3:
        title = 'Image Description';
        counter = '1/1';
        break;
      case 4:
        title = 'Confidence Check';
        counter = '1/1';
        break;
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: AppTextStyles.sectionHeading.copyWith(fontSize: 24)),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.lightGray,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            counter,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  Widget _buildVocabularyCheck() {
    final question = _generatedVocabQuestions[_currentQuestion - 1];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Choose the correct meaning for the word below:',
          style: AppTextStyles.bodyText,
        ),
        const SizedBox(height: 24),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 32),
          decoration: BoxDecoration(
            color: AppColors.primaryRed.withOpacity(0.05),
            border: Border.all(color: AppColors.primaryRed.withOpacity(0.2)),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Center(
            child: Text(
              question.word[0].toUpperCase() + question.word.substring(1),
              style: AppTextStyles.heroHeading.copyWith(
                color: AppColors.primaryRed,
                fontSize: 36,
                letterSpacing: 1.2,
              ),
            ),
          ),
        ),
        const SizedBox(height: 32),
        const Text(
          'Select the correct definition:',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 16),
        ...List.generate(question.options.length, (index) {
          return _buildVocabOption(index, question.options[index]);
        }),
      ],
    );
  }

  Widget _buildVocabOption(int index, String text) {
    final question = _generatedVocabQuestions[_currentQuestion - 1];
    final isSelected = _selectedVocabOption == index;
    final hasAnswered = _selectedVocabOption != -1;
    final isCorrect = index == question.correctIndex;

    Color bgColor = Colors.white;
    Color borderColor = AppColors.borderGray;
    Widget? icon;

    if (hasAnswered) {
      if (isCorrect) {
        bgColor = Colors.green.withOpacity(0.1);
        borderColor = Colors.green;
        icon = const Icon(Icons.check_circle, color: Colors.green, size: 24);
      } else if (isSelected) {
        bgColor = Colors.red.withOpacity(0.1);
        borderColor = Colors.red;
        icon = const Icon(Icons.cancel, color: Colors.red, size: 24);
      } else {
        bgColor = Colors.white;
        borderColor = AppColors.borderGray.withOpacity(0.5);
      }
    } else {
      if (isSelected) {
        bgColor = AppColors.primaryRed.withOpacity(0.05);
        borderColor = AppColors.primaryRed;
      }
    }

    return GestureDetector(
      onTap: hasAnswered
          ? null
          : () {
              setState(() {
                _selectedVocabOption = index;
                if (index == question.correctIndex) {
                  _vocabScore += 2;
                }
              });
            },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: bgColor,
          border: Border.all(
            color: borderColor,
            width: isSelected || (hasAnswered && isCorrect) ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: isSelected && !hasAnswered
              ? [
                  BoxShadow(
                    color: AppColors.primaryRed.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            if (icon != null) ...[
              icon,
              const SizedBox(width: 16),
            ] else ...[
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primaryRed : Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected
                        ? AppColors.primaryRed
                        : AppColors.borderGray,
                  ),
                ),
                child: isSelected
                    ? const Icon(Icons.check, color: Colors.white, size: 16)
                    : null,
              ),
              const SizedBox(width: 16),
            ],
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                  fontSize: 16,
                  color: hasAnswered && !isCorrect && !isSelected
                      ? AppColors.charcoal.withOpacity(0.5)
                      : AppColors.charcoal,
                  fontWeight: isSelected || (hasAnswered && isCorrect)
                      ? FontWeight.w600
                      : FontWeight.normal,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSentenceFormation() {
    // Determine which words to show
    final List<String> currentWords = [];
    if (_currentQuestion == 1) {
      currentWords.add(_selectedSentenceWords[0]);
    } else {
      currentWords.add(_selectedSentenceWords[1]);
      currentWords.add(_selectedSentenceWords[2]);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _currentQuestion == 1
              ? 'Make a fun sentence using the word below!'
              : 'Make a sentence using BOTH words below!',
          style: AppTextStyles.bodyText,
        ),
        const SizedBox(height: 24),
        Center(
          child: Wrap(
            spacing: 16,
            runSpacing: 16,
            alignment: WrapAlignment.center,
            children: currentWords
                .map(
                  (word) => Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primaryRed.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.primaryRed.withOpacity(0.3),
                      ),
                    ),
                    child: Text(
                      word.toUpperCase(),
                      style: AppTextStyles.sectionHeading.copyWith(
                        color: AppColors.primaryRed,
                        letterSpacing: 2,
                        fontSize: 20,
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        ),
        const SizedBox(height: 32),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: AppColors.lightGray.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.borderGray),
          ),
          child: Column(
            children: [
              // Audio Recording Controls
              GestureDetector(
                onTap: _isRecording ? _stopRecording : _startRecording,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: _isRecording ? AppColors.primaryRed : Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color:
                            (_isRecording ? AppColors.primaryRed : Colors.black)
                                .withOpacity(0.2),
                        blurRadius: 10,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Icon(
                    _isRecording ? Icons.stop : Icons.mic,
                    size: 40,
                    color: _isRecording ? Colors.white : AppColors.primaryRed,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                _isRecording
                    ? 'Recording... Tap to Stop'
                    : 'Tap to Start Recording',
                style: TextStyle(
                  color: _isRecording
                      ? AppColors.primaryRed
                      : AppColors.bodyGray,
                  fontWeight: _isRecording
                      ? FontWeight.bold
                      : FontWeight.normal,
                  fontSize: 16,
                ),
              ),
              if (_recordedFilePath != null && !_isRecording) ...[
                const SizedBox(height: 12),
                const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.check_circle, color: Colors.green, size: 16),
                    SizedBox(width: 8),
                    Text(
                      'Audio captured successfully',
                      style: TextStyle(color: Colors.green, fontSize: 14),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildImageDescription() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Look at the image and describe what you see in 3-5 simple sentences.',
          style: AppTextStyles.bodyText,
        ),
        const SizedBox(height: 8),
        Text(
          'You have 60 seconds to speak. Be creative!',
          style: AppTextStyles.bodyText,
        ),
        const SizedBox(height: 24),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 2,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  'https://images.unsplash.com/photo-1542601906990-b4d3fb778b09?ixlib=rb-4.0.3&auto=format&fit=crop&w=800&q=80',
                  height: 300,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(width: 24),
            Expanded(flex: 1, child: _buildTimerAndMic()),
          ],
        ),
        const SizedBox(height: 16),
        const Center(
          child: Text(
            'Tap the microphone to start / stop speaking',
            style: TextStyle(color: AppColors.bodyGray),
          ),
        ),
      ],
    );
  }

  Widget _buildConfidenceCheck() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tell us about the topic below. You can speak for a minute!',
          style: AppTextStyles.bodyText,
        ),
        const SizedBox(height: 8),
        Text(
          'Don\'t worry, just speak naturally and have fun!',
          style: AppTextStyles.bodyText,
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: Container(
                height: 280,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.primaryRed.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Topic',
                      style: AppTextStyles.sectionHeading.copyWith(
                        color: AppColors.primaryRed,
                        fontSize: 20,
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Icon(
                      Icons.format_quote,
                      color: AppColors.primaryRed,
                      size: 32,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _selectedConfidenceTopic,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 18,
                        height: 1.5,
                        color: AppColors.charcoal,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const Spacer(),
                    const Align(
                      alignment: Alignment.bottomRight,
                      child: Icon(
                        Icons.format_quote,
                        color: AppColors.primaryRed,
                        size: 32,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 24),
            Expanded(child: SizedBox(height: 280, child: _buildTimerAndMic())),
          ],
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.green.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              const Icon(Icons.star, color: Colors.green),
              const SizedBox(width: 12),
              Text(
                'Wonderful effort! Keep practicing to speak even more smoothly.',
                style: TextStyle(
                  color: AppColors.charcoal,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTimerAndMic() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderGray),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'Time Left',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 8),
          Text(
            '00:${_secondsLeft.toString().padLeft(2, '0')}',
            style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          GestureDetector(
            onTap: _isRecording ? _stopRecording : _startRecording,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: _isRecording ? AppColors.primaryRed : Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: (_isRecording ? AppColors.primaryRed : Colors.black)
                        .withOpacity(0.2),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Icon(
                _isRecording ? Icons.stop : Icons.mic,
                color: _isRecording ? Colors.white : AppColors.primaryRed,
                size: 48,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            _isRecording ? 'Recording... Tap to Stop' : 'Tap to Start Speaking',
            style: TextStyle(
              color: _isRecording ? AppColors.primaryRed : AppColors.bodyGray,
              fontWeight: _isRecording ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          if (_recordedFilePath != null && !_isRecording) ...[
            const SizedBox(height: 8),
            const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle, color: Colors.green, size: 14),
                SizedBox(width: 4),
                Text(
                  'Recorded',
                  style: TextStyle(color: Colors.green, fontSize: 12),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAnalysisBar(
    String label,
    double value,
    Color color,
    IconData icon,
  ) {
    return Row(
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(width: 8),
        Expanded(
          flex: 2,
          child: Text(label, style: const TextStyle(fontSize: 12)),
        ),
        Expanded(
          flex: 3,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: value,
              backgroundColor: AppColors.borderGray,
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 8,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '${(value * 100).toInt()}%',
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}

class _VocabQuestion {
  final String word;
  final String correctDefinition;
  final List<String> options;
  final int correctIndex;

  _VocabQuestion({
    required this.word,
    required this.correctDefinition,
    required this.options,
    required this.correctIndex,
  });
}

const Map<String, String> _vocabDefinitions = {
  'active': 'Busy with a particular activity or being in physical motion.',
  'ankle': 'The joint connecting the foot with the leg.',
  'anyway': 'Used to confirm or support a point or idea just mentioned.',
  'argue':
      'Give reasons or cite evidence in support of an idea, action, or theory.',
  'article':
      'A piece of writing included with others in a newspaper, magazine, or other publication.',
  'author': 'A writer of a book, article, or report.',
  'avoid': 'Keep away from or stop oneself from doing (something).',
  'believe': 'Accept (something) as true; feel sure of the truth of.',
  'blank': 'A space that is left to be filled in a document.',
  'blow': 'A strong wind or a current of air.',
  'castle':
      'A large building, typically of the medieval period, fortified against attack.',
  'cause':
      'A person or thing that gives rise to an action, phenomenon, or condition.',
  'cent':
      'A monetary unit in various countries, equal to one hundredth of a dollar, euro, or other unit.',
  'celebrity': 'A famous person.',
  'check':
      'Examine (something) in order to determine its accuracy, quality, or condition.',
  'clearly': 'In a way that is easy to see, hear, or understand.',
  'clever': 'Quick to understand, learn, and devise ideas; intelligent.',
  'cloud':
      'A visible mass of condensed water vapor floating in the atmosphere.',
  'coach': 'An instructor or trainer in sport.',
  'coast': 'The part of the land adjoining or near the sea.',
  'collect':
      'Bring or gather together (things, typically when scattered or widespread).',
  'college': 'An educational institution or establishment.',
  'corner': 'A place or angle where two or more sides or edges meet.',
  'cover':
      'Put something over or on top of something else, typically in order to protect or conceal it.',
  'crazy':
      'Mentally deranged, especially as manifested in a wild or aggressive way.',
  'crime':
      'An action or omission that constitutes an offense that may be prosecuted by the state.',
  'crowd':
      'A large number of people gathered together in a disorganized or unruly way.',
  'deal':
      'An agreement entered into by two or more parties for their mutual benefit.',
  'dentist':
      'A person qualified to treat the diseases and conditions that affect the teeth and gums.',
  'destroy':
      'Put an end to the existence of (something) by damaging or attacking it.',
  'device':
      'A thing made or adapted for a particular purpose, especially a piece of mechanical or electronic equipment.',
  'diary':
      'A book in which one keeps a daily record of events and experiences.',
  'disagree': 'Have or express a different opinion.',
  'disease':
      'A disorder of structure or function in a human, animal, or plant.',
  'desert':
      'A barren area of landscape where little precipitation occurs and consequently living conditions are hostile.',
  'design':
      'A plan or drawing produced to show the look and function or workings of a building, garment, or other object.',
  'discuss': 'Talk about (something) with another person or group of people.',
  'distance': 'An amount of space between two things or people.',
  'divorced':
      'No longer married because the marriage has been legally dissolved.',
  'drop': 'Let or make (something) fall vertically.',
  'dry': 'Free from moisture or liquid; not wet or moist.',
  'early': 'Happening or done before the usual or expected time.',
  'earn': 'Obtain (money) in return for labor or services.',
  'effect':
      'A change which is a result or consequence of an action or other cause.',
  'energy':
      'The strength and vitality required for sustained physical or mental activity.',
  'error': 'A mistake.',
  'event': 'A thing that happens, especially one of importance.',
  'everyday': 'Happening or used every day; daily.',
  'everywhere': 'In or to all places.',
  'exact': 'Not approximated in any way; precise.',
  'exactly': 'Used to emphasize the accuracy of a figure or description.',
  'exercise':
      'Activity requiring physical effort, carried out to sustain or improve health and fitness.',
  'expert':
      'A person who has a comprehensive and authoritative knowledge of or skill in a particular area.',
  'fact': 'A thing that is known or proved to be true.',
  'factor':
      'A circumstance, fact, or influence that contributes to a result or outcome.',
  'farm':
      'An area of land and its buildings used for growing crops and rearing animals.',
  'farming': 'The activity or business of growing crops and raising livestock.',
  'fear':
      'An unpleasant emotion caused by the belief that someone or something is dangerous, likely to cause pain, or a threat.',
  'feed': 'Give food to.',
  'field':
      'An area of open land, especially one planted with crops or used for pasture.',
  'illness': 'A disease or period of sickness affecting the body or mind.',
  'imagine': 'Form a mental image or concept of.',
  'injury': 'An instance of being injured.',
  'insect':
      'A small arthropod animal that has six legs and generally one or two pairs of wings.',
  'introduce':
      'Bring (something, especially a product, measure, or concept) into use or operation for the first time.',
  'invitation':
      'A written or verbal request inviting someone to go somewhere or to do something.',
  'invite':
      'Make a polite, formal, or friendly request to (someone) to go somewhere or to do something.',
  'item':
      'An individual article or unit, especially one that is part of a list, collection, or set.',
  'jewellery': 'Personal ornaments, such as necklaces, rings, or bracelets.',
  'joke': 'A thing that someone says to cause amusement or laughter.',
  'journalist':
      'A person who writes for newspapers, magazines, or news websites.',
  'journey': 'An act of traveling from one place to another.',
  'knowledge':
      'Facts, information, and skills acquired by a person through experience or education.',
  'lazy': 'Unwilling to work or use energy.',
  'lead':
      'Cause (a person or animal) to go with one by holding them by the hand, a halter, a rope, etc.',
  'leave': 'Go away from.',
  'lifestyle': 'The way in which a person or group lives.',
  'loud': 'Producing or capable of producing much noise.',
  'mail': 'Letters and packages conveyed by the postal system.',
  'material': 'The matter from which a thing is or can be made.',
  'meaning': 'What is meant by a word, text, concept, or action.',
  'medical': 'Relating to the science or practice of medicine.',
  'narrow': 'Of small width in relation to length.',
  'natural':
      'Existing in or caused by nature; not made or caused by humankind.',
  'nature':
      'The phenomena of the physical world collectively, including plants, animals, the landscape, and other features.',
  'pair': 'A set of two things used together or regarded as a unit.',
  'period': 'A length or portion of time.',
  'population': 'All the inhabitants of a particular town, area, or country.',
  'position': 'A place where someone or something is located or has been put.',
  'prison':
      'A building in which people are legally held as a punishment for a crime they have committed.',
  'prize':
      'A thing given as a reward to the winner of a competition or in recognition of an outstanding achievement.',
  'professor': 'A teacher of the highest rank in a college or university.',
  'protect': 'Keep safe from harm or injury.',
  'pull':
      'Exert force on (someone or something) so as to cause movement towards oneself.',
  'raise': 'Lift or move to a higher position or level.',
  'receive': 'Be given, presented with, or paid (something).',
  'recent': 'Having happened, begun, or been done only a short time ago.',
  'recently': 'At a recent time; not long ago.',
  'react': 'Act in response to something; respond in a particular way.',
  'reduce': 'Make smaller or less in amount, degree, or size.',
  'request': 'An act of asking politely or formally for something.',
  'respond': 'Say something in reply.',
  'replace': 'Take the place of.',
  'scary': 'Causing fear.',
  'skin':
      'The thin layer of tissue forming the natural outer covering of the body of a person or animal.',
  'spell': 'Write or name the letters that form (a word) in correct sequence.',
  'stair':
      'A set of steps leading from one floor of a building to another, typically inside the building.',
  'store': 'A shop of any size or kind.',
  'stupid': 'Having or showing a great lack of intelligence or common sense.',
  'succeed': 'Achieve the desired aim or result.',
  'system':
      'A set of things working together as parts of a mechanism or an interconnecting network.',
  'task': 'A piece of work to be done or undertaken.',
  'team': 'A group of players forming one side in a competitive game or sport.',
  'telephone':
      'A system for transmitting voices over a distance using wire or radio.',
  'television':
      'A system for transmitting visual images and sound that are reproduced on screens.',
  'thick': 'With opposite sides or surfaces a relatively large distance apart.',
  'thief': 'A person who steals another person\'s property.',
  'thin': 'With opposite sides or surfaces a relatively small distance apart.',
  'tip': 'A small but useful piece of practical advice.',
  'abroad': 'In or to a foreign country or countries.',
  'accept': 'Consent to receive (a thing offered).',
  'accident':
      'An unfortunate incident that happens unexpectedly and unintentionally.',
  'actually': 'Used to emphasize the real or exact truth of a situation.',
  'advantage':
      'A condition or circumstance that puts one in a favorable or superior position.',
  'adventure':
      'An unusual and exciting, typically hazardous, experience or activity.',
  'advertise':
      'Describe or draw attention to (a product, service, or event) in a public medium.',
  'advertisement':
      'A notice or announcement in a public medium promoting a product, service, or event.',
  'advice':
      'Guidance or recommendations offered with regard to prudent future action.',
  'affect': 'Have an effect on; make a difference to.',
  'afraid': 'Feeling fear or anxiety; frightened.',
  'airline':
      'An organization providing a regular public service of air transport.',
  'almost': 'Very nearly but not quite.',
  'alternative': 'Available as another possibility.',
  'amazing': 'Causing great surprise or wonder; astonishing.',
  'ancient': 'Belonging to the very distant past and no longer in existence.',
  'appearance': 'The way that someone or something looks.',
  'arrangement':
      'The action, process, or result of arranging or being arranged.',
  'asleep': 'In a state of sleep.',
  'assistant':
      'A person who ranks below a senior person and whose job is to help them.',
  'athlete':
      'A person who is proficient in sports and other forms of physical exercise.',
  'attack':
      'Take aggressive military action against (a place or enemy forces).',
  'attend': 'Be present at (an event, meeting, or function).',
  'attractive': 'Pleasing or appealing to the senses.',
  'audience': 'The assembled spectators or listeners at a public event.',
  'average':
      'A number expressing the central or typical value in a set of data.',
  'beautiful': 'Pleasing the senses or mind aesthetically.',
  'become': 'Begin to be.',
  'begin': 'Start; perform the first part of (an action or activity).',
  'beginning': 'The point in time or space at which something starts.',
  'behave': 'Act or conduct oneself in a specified way.',
  'behaviour': 'The way in which one acts or conducts oneself.',
  'belong': 'Be the property of.',
  'benefit': 'An advantage or profit gained from something.',
  'better': 'More desirable, satisfactory, or effective.',
  'between':
      'At, into, or across the space separating (two objects or regions).',
  'blonde': 'Fair-haired.',
  'boot': 'A sturdy item of footwear covering the foot and ankle.',
  'bored': 'Feeling weary and restless through lack of interest.',
  'boring': 'Not interesting; tedious.',
  'borrow':
      'Take and use (something that belongs to someone else) with the intention of returning it.',
  'bread': 'Food made of flour, water, and yeast or another leavening agent.',
  'bright': 'Giving out or reflecting a lot of light; shining.',
  'brilliant': 'Exceptionally clever or talented.',
  'busy': 'Having a great deal to do.',
  'butter': 'A pale yellow edible fatty substance made by churning cream.',
  'button': 'A small disk or knob sewn onto a garment.',
  'camp':
      'A place with temporary accommodation of huts, tents, or other structures.',
  'camping': 'The activity of spending a holiday living in a tent.',
  'capital': 'The most important city or town of a country or region.',
  'career':
      'An occupation undertaken for a significant period of a person\'s life.',
  'careful': 'Making sure of avoiding potential danger, mishap, or harm.',
  'carefully': 'In a way that deliberately avoids harm or errors; cautiously.',
  'carpet': 'A floor covering made from thick woven fabric.',
  'certain': 'Known for sure; established beyond doubt.',
  'certainly':
      'Used to emphasize the speaker\'s belief in what they are saying.',
  'charity':
      'An organization set up to provide help and raise money for those in need.',
  'classical':
      'Relating to ancient Greek or Latin literature, art, or culture.',
  'competition': 'The activity or condition of competing.',
  'complain': 'Express dissatisfaction or annoyance about something.',
  'complete': 'Having all the necessary or appropriate parts.',
  'completely': 'Totally; utterly.',
  'computer': 'An electronic device for storing and processing data.',
  'concert': 'A musical performance given in public.',
  'condition':
      'The state of something with regard to its appearance, quality, or working order.',
  'conference': 'A formal meeting for discussion.',
  'connect':
      'Bring together or into contact so that a real or notional link is established.',
  'connected': 'Joined or linked together.',
  'consider':
      'Think carefully about (something), typically before making a decision.',
  'contain': 'Have or hold (someone or something) within.',
  'context':
      'The circumstances that form the setting for an event, statement, or idea.',
  'continent': 'Any of the world\'s main continuous expanses of land.',
  'continue': 'Persist in an activity or process.',
  'control':
      'The power to influence or direct people\'s behavior or the course of events.',
  'conversation':
      'A talk, especially an informal one, between two or more people.',
  'creative': 'Relating to or involving the imagination or original ideas.',
  'criminal': 'A person who has committed a crime.',
  'crowded': 'Full of people, leaving little or no room for movement.',
  'culture':
      'The arts and other manifestations of human intellectual achievement.',
  'dancing':
      'The activity of dancing for pleasure or in order to entertain others.',
  'dangerous': 'Able or likely to cause harm or injury.',
  'decide': 'Come to a resolution in the mind as a result of consideration.',
  'decision': 'A conclusion or resolution reached after consideration.',
  'deep': 'Extending far down from the top or surface.',
  'definitely': 'Without doubt.',
  'degree':
      'The amount, level, or extent to which something happens or is present.',
  'delicious': 'Highly pleasant to the taste.',
  'department':
      'A division of a large organization such as a government, university, or business.',
  'depend': 'Be controlled or determined by.',
  'describe': 'Give an account in words of (someone or something).',
  'description':
      'A spoken or written representation or account of a person, object, or event.',
  'designer':
      'A person who plans the look or workings of something prior to it being made.',
  'detective':
      'A person, especially a police officer, whose occupation is to investigate and solve crimes.',
  'develop':
      'Grow or cause to grow and become more mature, advanced, or elaborate.',
  'difference': 'A point or way in which people or things are not the same.',
  'different': 'Not the same as another or each other.',
  'differently': 'In another way.',
  'digital':
      'Relating to or using signals or information represented by digits.',
  'direct':
      'Extending or moving from one place to another by the shortest way.',
  'direction': 'A course along which someone or something moves.',
  'director':
      'A person who is in charge of an activity, department, or organization.',
  'disappear': 'Cease to be visible.',
  'disaster':
      'A sudden event, such as an accident or a natural catastrophe, that causes great damage.',
  'discover': 'Find unexpectedly or during a search.',
  'discovery': 'The action or process of discovering or being discovered.',
  'drug':
      'A medicine or other substance which has a physiological effect when ingested.',
  'electric': 'Of, worked by, or charged with electricity.',
  'electrical': 'Concerned with, operating by, or producing electricity.',
  'electronic':
      'Having or operating with the aid of many small components, especially microchips.',
  'email':
      'Messages distributed by electronic means from one computer user to one or more recipients.',
  'employ': 'Give work to (someone) and pay them for it.',
  'employee': 'A person employed for wages or salary.',
  'employer': 'A person or organization that employs people.',
  'ending': 'An end or final part of something.',
  'enormous': 'Very large in size, quantity, or extent.',
  'environment':
      'The surroundings or conditions in which a person, animal, or plant lives.',
  'equipment': 'The necessary items for a particular purpose.',
  'especially':
      'Used to single out one person, thing, or situation over all others.',
  'tool': 'A device or implement used to carry out a particular function.',
  'figure': 'A number, especially one which forms part of official statistics.',
  'flu': 'Influenza.',
  'form': 'The visible shape or configuration of something.',
  'foreign':
      'Of, from, in, or characteristic of a country or language other than one\'s own.',
  'government': 'The governing body of a nation, state, or community.',
  'guess':
      'Estimate or suppose (something) without sufficient information to be sure of being correct.',
  'guest':
      'A person who is invited to visit someone\'s home or attend a particular social occasion.',
  'hide': 'Put or keep out of sight.',
  'hold': 'Grasp, carry, or support with one\'s arms or hands.',
  'hour': 'A period of time equal to a twenty-fourth part of a day.',
  'explain':
      'Make (an idea, situation, or problem) clear to someone by describing it in more detail.',
  'explanation': 'A statement or account that makes something clear.',
  'express':
      'Convey (a thought or feeling) in words or by gestures and conduct.',
  'expression': 'The action of making known one\'s thoughts or feelings.',
  'extreme': 'Reaching a high or the highest degree; very great.',
  'extremely': 'To a very great degree; very.',
  'feeling': 'An emotional state or reaction.',
  'fiction':
      'Literature in the form of prose, especially short stories and novels.',
  'focus': 'The center of interest or activity.',
  'follow': 'Go or come after (a person or thing proceeding ahead).',
  'following': 'Coming after or as a result of.',
  'fork':
      'An implement with two or more prongs used for lifting food to the mouth.',
  'fortunately': 'It is fortunate that.',
  'forward': 'In the direction that one is facing or traveling.',
  'friendly': 'Kind and pleasant.',
  'funny': 'Causing laughter or amusement.',
  'furniture':
      'Large movable equipment, such as tables and chairs, used to make a house or office suitable for living.',
  'further': 'At, to, or by a greater distance.',
  'future':
      'The time or a period of time following the moment of speaking or writing.',
  'gallery': 'A room or building for the display or sale of works of art.',
  'general': 'Affecting or concerning all or most people, places, or things.',
  'greet': 'Give a polite word of recognition or sign of welcome when meeting.',
  'guide': 'A person who shows the way to others.',
  'however':
      'Used to introduce a statement that contrasts with or seems to contradict something.',
  'identify': 'Establish or indicate who or what (someone or something) is.',
  'immediately': 'At once; instantly.',
  'important': 'Of great value; significant.',
  'impossible': 'Not able to occur, exist, or be done.',
  'include': 'Comprise or contain as part of a whole.',
  'included': 'Contained as part of a whole being considered.',
  'increase': 'Become or make greater in size, amount, intensity, or degree.',
  'incredible': 'Impossible to believe; extraordinary.',
  'independent':
      'Free from outside control; not depending on another\'s authority.',
  'individual': 'Single; separate.',
  'industry':
      'Economic activity concerned with the processing of raw materials.',
  'informal':
      'Having a relaxed, friendly, or unofficial style, manner, or nature.',
  'information': 'Facts provided or learned about something or someone.',
  'instead': 'As an alternative or substitute.',
  'instruction': 'A direction or order.',
  'instructor': 'A person who teaches something.',
  'instrument':
      'A tool or implement, especially one for delicate or scientific work.',
  'interest':
      'The state of wanting to know or learn about something or someone.',
  'interested': 'Showing curiosity or concern about something or someone.',
  'interesting':
      'Arousing curiosity or interest; holding or catching the attention.',
  'international':
      'Existing, occurring, or carried on between two or more nations.',
  'invent': 'Create or design (something that has not existed before).',
  'invention':
      'The action of inventing something, typically a process or device.',
  'tourism':
      'The commercial organization and operation of vacations and visits to places of interest.',
  'traveller': 'A person who is traveling or who often travels.',
  'upstairs': 'On or to an upper floor of a building.',
  'vacation':
      'An extended period of recreation, especially one spent away from home or in traveling.',
  'visitor':
      'A person visiting someone or a place, especially socially or as a tourist.',
  'waiter':
      'A man whose job is to serve customers at their tables in a restaurant.',
  'worst': 'Of the poorest quality or the lowest standard.',
  'act': 'Take action; do something.',
  'ability': 'Possession of the means or skill to do something.',
  'manager':
      'A person responsible for controlling or administering all or part of a company.',
  'manner': 'A way in which a thing is done or happens.',
  'match':
      'A contest in which people or teams compete against each other in a particular sport.',
  'matter': 'Physical substance in general.',
  'mean': 'Intend to convey, indicate, or refer to.',
  'meet':
      'Come into the presence or company of (someone) by chance or arrangement.',
  'meeting':
      'An assembly of people for a particular purpose, especially for formal discussion.',
  'member': 'A person, animal, or plant belonging to a particular group.',
  'memory': 'The faculty by which the mind stores and remembers information.',
  'mention': 'Refer to (something) briefly and without going into detail.',
  'mile': 'A unit of linear measure equal to 5,280 feet.',
  'million': 'The number 1,000,000.',
  'modern': 'Relating to the present or recent times.',
  'moment': 'A very brief period of time.',
  'mostly': 'As regards the greater part or number.',
  'movement': 'An act of changing physical location or position.',
  'musician':
      'A person who plays a musical instrument or is musically talented.',
  'nearly': 'Very close to; almost.',
  'necessary': 'Required to be done, achieved, or present; essential.',
  'nervous': 'Easily agitated or alarmed; apprehensive or anxious.',
  'noisy': 'Making or given to making a lot of noise.',
  'notice': 'The fact of observing or paying attention to something.',
  'nowhere': 'Not in or to any place.',
  'opinion': 'A view or judgment formed about something.',
  'opportunity':
      'A set of circumstances that makes it possible to do something.',
  'ordinary': 'With no special or distinctive features; normal.',
  'organization': 'An organized body of people with a particular purpose.',
  'organize': 'Make arrangements or preparations for (an event or activity).',
  'oven':
      'An enclosed compartment, as in a kitchen range, for cooking and heating food.',
  'owner': 'A person who owns something.',
  'pack':
      'Fill (a suitcase or bag) with clothes and other items needed for a trip.',
  'paragraph':
      'A distinct section of a piece of writing, usually dealing with a single theme.',
  'particular':
      'Used to single out an individual member of a specified group or class.',
  'passenger':
      'A traveler on a public or private conveyance other than the driver.',
  'passport':
      'An official document issued by a government, certifying the holder\'s identity and citizenship.',
  'past': 'Gone by in time and no longer existing.',
  'patient':
      'Able to accept or tolerate delays, problems, or suffering without becoming annoyed.',
  'pattern': 'A repeated decorative design.',
  'peace': 'Freedom from disturbance; tranquility.',
  'penny':
      'A British coin and monetary unit equal to one hundredth of a pound.',
  'pepper':
      'A pungent hot-tasting powder prepared from dried and ground peppercorns.',
  'perform':
      'Carry out, accomplish, or fulfill (an action, task, or function).',
  'permission': 'Consent; authorization.',
  'personality':
      'The combination of characteristics or qualities that form an individual\'s distinctive character.',
  'phrase': 'A small group of words standing together as a conceptual unit.',
  'piano': 'A large keyboard musical instrument with a wooden case.',
  'picture': 'A painting or drawing.',
  'piece': 'A portion of an object or of material.',
  'colleague': 'A person with whom one works.',
  'comfortable': 'Providing physical ease and relaxation.',
  'comment': 'A verbal or written remark expressing an opinion or reaction.',
  'common': 'Occurring, found, or done often; prevalent.',
  'communicate': 'Share or exchange information, news, or ideas.',
  'community':
      'A group of people living in the same place or having a particular characteristic in common.',
  'compete':
      'Strive to gain or win something by defeating or establishing superiority over others.',
  'professional': 'Relating to or connected with a profession.',
  'program': 'A planned series of future events, items, or performances.',
  'programme':
      'A set of related measures or activities with a particular long-term aim.',
  'progress': 'Forward or onward movement towards a destination.',
  'project':
      'An individual or collaborative enterprise that is carefully planned.',
  'pronounce':
      'Make the sound of (a word or part of a word) in the correct way.',
  'provide': 'Make available for use; supply.',
  'publish':
      'Prepare and issue (a book, journal, piece of music, or other work) for public sale.',
  'purpose': 'The reason for which something is done or created.',
  'quantity': 'The amount or number of a material or immaterial thing.',
  'reach':
      'Stretch out an arm in a specified direction in order to touch or grasp something.',
  'realize': 'Become fully aware of (something) as a fact.',
  'reception':
      'The action or process of receiving something sent, given, or inflicted.',
  'recipe': 'A set of instructions for preparing a particular dish.',
  'recognize':
      'Identify (someone or something) from having encountered them before.',
  'recommend':
      'Put forward (someone or something) with approval as being suitable for a particular purpose.',
  'recycle': 'Convert (waste) into reusable material.',
  'refer': 'Mention or allude to.',
  'refuse': 'Indicate or show that one is not willing to do something.',
  'region': 'An area or division, especially part of a country or the world.',
  'regular': 'Arranged in or constituting a constant or definite pattern.',
  'remember': 'Have in or be able to bring to one\'s mind an awareness of.',
  'report':
      'A spoken or written account of something that one has observed, heard, done, or investigated.',
  'research':
      'The systematic investigation into and study of materials and sources in order to establish facts.',
  'researcher': 'A person who carries out academic or scientific research.',
  'response': 'A reaction to something.',
  'review':
      'A formal assessment or examination of something with the possibility or intention of instituting change.',
  'sail':
      'Travel in a ship with sails, especially as a sport or for recreation.',
  'sailing': 'The action of sailing in a ship or boat.',
  'salad': 'A cold dish of various mixtures of raw or cooked vegetables.',
  'scared': 'Fearful; frightened.',
  'schedule': 'A plan for carrying out a process or procedure.',
  'season': 'Each of the four divisions of the year.',
  'secondly': 'In the second place.',
  'secretary':
      'A person employed by an individual or in an office to assist with correspondence.',
  'section':
      'Any of the more or less distinct parts into which something is or may be divided.',
  'sense': 'A faculty by which the body perceives an external stimulus.',
  'separate': 'Forming or viewed as a unit apart or by itself.',
  'series':
      'A number of things, events, or people of a similar kind or related nature coming one after another.',
  'serious': 'Demanding or characterized by deep thought or care.',
  'serve':
      'Perform duties or services for (another person or an organization).',
  'service': 'The action of helping or doing work for someone.',
  'shall': 'Used to express a strong assertion or intention.',
  'sheet': 'A large rectangular piece of cotton or other fabric.',
  'should': 'Used to indicate obligation, duty, or correctness.',
  'shut': 'Move (something) into position to block an opening.',
  'sick': 'Affected by physical or mental illness.',
  'similar': 'Resembling without being identical.',
  'simple': 'Easily understood or done; presenting no difficulty.',
  'essay': 'A short piece of writing on a particular subject.',
  'euro': 'The single European currency.',
  'evening':
      'The period of time from the end of the afternoon to when one goes to bed.',
  'evidence':
      'The available body of facts or information indicating whether a belief or proposition is true.',
  'excited': 'Very enthusiastic and eager.',
  'exciting': 'Causing great enthusiasm and eagerness.',
  'expect': 'Regard (something) as likely to happen.',
  'expensive': 'Costing a lot of money.',
  'experience': 'Practical contact with and observation of facts or events.',
  'experiment':
      'A scientific procedure undertaken to make a discovery, test a hypothesis, or demonstrate a known fact.',
  'storm':
      'A violent disturbance of the atmosphere with strong winds and usually rain, thunder, lightning, or snow.',
  'straight':
      'Extending or moving in one direction only; without a curve or bend.',
  'strange': 'Unusual or surprising; difficult to understand or explain.',
  'strategy':
      'A plan of action or policy designed to achieve a major or overall aim.',
  'structure':
      'The arrangement of and relations between the parts or elements of something complex.',
  'successful': 'Accomplishing an aim or purpose.',
  'suddenly': 'Quickly and unexpectedly.',
  'suggest': 'Put forward for consideration.',
  'suit': 'A set of outer clothes made of the same fabric.',
  'suppose': 'Think or assume that something is true or probable.',
  'surprised': 'Feeling or showing surprise.',
  'surprising': 'Causing surprise; unexpected.',
  'survey':
      'Investigate the opinions or experience of (a group of people) by asking them questions.',
  'sweater': 'A knitted garment typically with long sleeves.',
  'symbol': 'A thing that represents or stands for something else.',
  'technology':
      'The application of scientific knowledge for practical purposes.',
  'term': 'A word or phrase used to describe a thing or express a concept.',
  'terrible': 'Extremely bad or serious.',
  'thinking':
      'The process of using one\'s mind to consider or reason about something.',
  'thirsty': 'Feeling a need to drink.',
  'thought': 'An idea or opinion produced by thinking.',
  'tidy': 'Arranged neatly and in order.',
  'tired': 'In need of sleep or rest; weary.',
  'together': 'With or in proximity to another person or people.',
  'tooth': 'Each of a set of hard, bony enamel-coated structures in the jaws.',
  'topic':
      'A matter dealt with in a text, discourse, or conversation; a subject.',
  'track': 'A rough path or minor road.',
  'trainer': 'A person who trains people or animals.',
  'training':
      'The action of teaching a person or animal a particular skill or type of behavior.',
  'trouble': 'Difficulty or problems.',
  'trousers':
      'An outer garment covering the body from the waist to the ankles.',
  'typical': 'Characteristic of a particular person or thing.',
  'understand':
      'Perceive the intended meaning of (words, a language, or a speaker).',
  'understanding': 'The ability to understand something; comprehension.',
  'unfortunately': 'It is unfortunate that.',
  'university':
      'An educational institution designed for instruction, examination, or both, of students in many branches of advanced learning.',
  'unusual': 'Not habitually or commonly occurring or done.',
  'useful': 'Able to be used for a practical purpose or in several ways.',
  'usual': 'Habitually or typically occurring or done; customary.',
  'usually': 'Under normal conditions; generally.',
  'valley':
      'A low area of land between hills or mountains, typically with a river or stream flowing through it.',
  'variety': 'The quality or state of being different or diverse.',
  'way': 'A method, style, or manner of doing something.',
  'weak':
      'Lacking the power to perform physically demanding tasks; lacking physical strength and energy.',
  'wedding': 'A marriage ceremony.',
  'wet': 'Covered or saturated with water or another liquid.',
  'worried': 'Anxious or troubled about actual or potential problems.',
  'worry':
      'Feel or cause to feel anxious or troubled about actual or potential problems.',
  'worse': 'Of poorer quality or lower standard; less good or desirable.',
  'abandon': 'Cease to support or look after (someone); desert.',
  'pilot': 'A person who operates the flying controls of an aircraft.',
  'singing': 'The activity of performing songs or tunes with the voice.',
  'involve': 'Include (something) as a necessary part or result.',
  'jam':
      'A sweet spread or conserve made from fruit and sugar boiled to a thick consistency.',
  'jazz': 'A type of music of black American origin.',
  'knock': 'Strike a surface noisily to attract attention.',
  'know': 'Be aware of through observation, inquiry, or information.',
  'laugh':
      'Make the spontaneous sounds and movements of the face and body that are the instinctive expressions of lively amusement.',
  'laughter': 'The action or sound of laughing.',
  'law':
      'The system of rules which a particular country or community recognizes as regulating the actions of its members.',
  'learn':
      'Acquire knowledge of or skill in (something) by study, experience, or being taught.',
  'learning':
      'The acquisition of knowledge or skills through experience, study, or by being taught.',
  'lecture':
      'An educational talk to an audience, especially to students in a university.',
  'lend':
      'Grant to (someone) the use of (something) on the understanding that it shall be returned.',
  'likely': 'Such as well might happen or be true; probable.',
  'line': 'A long, narrow mark or band.',
  'link': 'A relationship between two things or situations.',
  'listener': 'A person who listens.',
  'machine':
      'An apparatus using or applying mechanical power and having several parts.',
  'magazine': 'A periodical publication containing articles and illustrations.',
  'major': 'Important, serious, or significant.',
  'manage': 'Be in charge of (a business, organization, or undertaking).',
  'ambition':
      'A strong desire to do or to achieve something, typically requiring determination and hard work.',
  'anger': 'A strong feeling of annoyance, displeasure, or hostility.',
  'anniversary': 'The date on which an event occurred in a previous year.',
  'anxious': 'Experiencing worry, unease, or nervousness.',
  'apparent': 'Clearly visible or understood; obvious.',
  'apparently': 'As far as one can see or tell.',
  'application': 'A formal request to an authority for something.',
  'appreciate': 'Recognize the full worth of.',
  'appropriate': 'Suitable or proper in the circumstances.',
  'amount':
      'A quantity of something, especially the total of a thing or things in number, size, value, or extent.',
  'annoyed': 'Slightly angry; irritated.',
  'annoying': 'Causing irritation or annoyance.',
  'artificial':
      'Made or produced by human beings rather than occurring naturally.',
  'artistic': 'Having or revealing natural creative skill.',
  'ashamed':
      'Embarrassed or guilty because of one\'s actions, characteristics, or associations.',
  'associate':
      'Connect (someone or something) with something else in one\'s mind.',
  'association': 'A group of people organized for a joint purpose.',
  'arrival': 'The action or process of arriving.',
  'attempt':
      'Make an effort to achieve or complete (something, typically a difficult task or action).',
  'authority':
      'The power or right to give orders, make decisions, and enforce obedience.',
  'backwards': 'In the direction of one\'s back.',
  'barrier': 'A fence or other obstacle that prevents movement or access.',
  'broadcast':
      'Transmit (a program or some information) by radio or television.',
  'campaign':
      'A series of military operations intended to achieve a particular objective.',
  'candidate': 'A person who applies for a job or is nominated for election.',
  'capable': 'Having the power or ability needed to do something.',
  'category':
      'A class or division of people or things regarded as having particular shared characteristics.',
  'ceremony':
      'A formal religious or public occasion, especially one celebrating a particular event or anniversary.',
  'celebration':
      'The action of marking one\'s pleasure at an important event or occasion by engaging in enjoyable, typically social, activity.',
  'characteristic':
      'A feature or quality belonging typically to a person, place, or thing and serving to identify it.',
  'cheerful': 'Noticeably happy and optimistic.',
  'circumstance':
      'A fact or condition connected with or relevant to an event or action.',
  'citizen':
      'A legally recognized subject or national of a state or commonwealth.',
  'classic':
      'Judged over a period of time to be of the highest quality and outstanding of its kind.',
  'clause':
      'A unit of grammatical organization next below the sentence in rank.',
  'collapse': 'Fall down or in; give way.',
  'collection': 'The action or process of collecting someone or something.',
  'combination': 'A joining or merging of different parts or qualities.',
  'platform': 'A raised floor or stage.',
  'please': 'Used in polite requests or questions.',
  'pleased': 'Feeling or showing pleasure and satisfaction.',
  'point': 'A sharp or tapering end of something.',
  'polite':
      'Having or showing behavior that is respectful and considerate of other people.',
  'possession': 'The state of having, owning, or controlling something.',
  'possibility': 'A thing that may happen or be the case.',
  'possible': 'Able to be done or achieved to happen.',
  'pound': 'The basic monetary unit of the UK.',
  'predict':
      'Say or estimate that (a specified thing) will happen in the future.',
  'prefer': 'Like (one thing or person) better than another or others.',
  'prepare': 'Make (something) ready for use or consideration.',
  'present': 'Existing or occurring now.',
  'pretty': 'Attractive in a delicate way.',
  'prevent': 'Keep (something) from happening or arising.',
  'probably': 'Almost certainly; as far as one knows or can tell.',
  'process':
      'A series of actions or steps taken in order to achieve a particular end.',
  'produce': 'Make or manufacture from components or raw materials.',
  'consumer': 'A person who purchases goods and services for personal use.',
  'contemporary': 'Living or occurring at the same time.',
  'continuous': 'Forming an unbroken whole; without interruption.',
  'contract': 'A written or spoken agreement.',
  'contrast':
      'The state of being strikingly different from something else in juxtaposition or close association.',
  'confident': 'Feeling or showing confidence in oneself; self-assured.',
  'confirm':
      'Establish the truth or correctness of (something previously believed, suspected, or feared).',
  'confuse': 'Make (someone) bewildered or perplexed.',
  'consume': 'Eat, drink, or ingest (food or drink).',
  'contact': 'The state or condition of physical touching.',
  'content': 'In a state of peaceful happiness.',
  'contribute':
      'Give (something, especially money) in order to help achieve or provide something.',
  'convenient':
      'Fitting in well with a person\'s needs, activities, and plans.',
  'convince': 'Cause (someone) to believe firmly in the truth of something.',
  'core': 'The tough central part of various fruits.',
  'cottage':
      'A small simple house, typically one near the sea or in the country.',
  'council':
      'An advisory, deliberative, or legislative body of people formally constituted and meeting regularly.',
  'constant': 'Occurring continuously over a period of time.',
  'construct': 'Build or erect (something, typically a large structure).',
  'convert': 'Cause to change in form, character, or function.',
  'contest':
      'An event in which people compete for supremacy in a particular activity or area.',
  'corporate': 'Relating to a large company or group.',
  'countryside': 'The land and scenery of a rural area.',
  'creation': 'The action or process of bringing something into existence.',
  'creature': 'An animal, as distinct from a human being.',
  'crisis': 'A time of intense difficulty, trouble, or danger.',
  'criterion':
      'A principle or standard by which something may be judged or decided.',
  'critic': 'A person who expresses an unfavorable opinion of something.',
  'criticism':
      'The expression of disapproval of someone or something based on perceived faults or mistakes.',
  'criticize':
      'Indicate the faults of (someone or something) in a disapproving way.',
  'crucial':
      'Decisive or critical, especially in the success or failure of something.',
  'currency': 'A system of money in general use in a particular country.',
  'county':
      'A territorial division of some countries, forming the chief unit of local administration.',
  'critical': 'Expressing adverse or disapproving comments or judgments.',
  'curved': 'Having the form of a curve; bent.',
  'debate':
      'A formal discussion on a particular topic in a public meeting or legislative assembly.',
  'decoration': 'The process or art of decorating something.',
  'deeply': 'Very much; to a great degree.',
  'defeat': 'Win a victory over (someone) in a battle or other contest.',
  'single': 'Only one; not one of several.',
  'situation': 'A set of circumstances in which one finds oneself.',
  'ski':
      'Each of a pair of long, narrow pieces of hard, flexible material fastened to boots for gliding over snow.',
  'skiing': 'The action of traveling over snow on skis.',
  'skirt':
      'A garment fastened around the waist and hanging down around the legs.',
  'social': 'Relating to society or its organization.',
  'society':
      'The aggregate of people living together in a more or less ordered community.',
  'sock': 'A garment for the foot and lower part of the leg.',
  'solution':
      'A means of solving a problem or dealing with a difficult situation.',
  'sometimes': 'Occasionally, rather than all of the time.',
  'soon': 'In or after a short time.',
  'sort': 'A category of things or people with a common feature; a type.',
  'soup':
      'A liquid dish, typically made by boiling meat, fish, or vegetables, in stock or water.',
  'speaker': 'A person who speaks.',
  'specific': 'Clearly defined or identified.',
  'spelling':
      'The process or activity of writing or naming the letters of a word.',
  'statement':
      'A definite or clear expression of something in speech or writing.',
  'station': 'A stopping place on a public transportation route.',
  'steal':
      'Take (another person\'s property) without permission or legal right and without intending to return it.',
  'detect': 'Discover or identify the presence or existence of.',
  'determined':
      'Having made a firm decision and being resolved not to change it.',
  'development': 'The process of developing or being developed.',
  'discipline':
      'The practice of training people to obey rules or a code of behavior.',
  'dishonest': 'Not honest.',
  'dismiss': 'Order or allow to leave; send away.',
  'distribute': 'Give shares of (something); apportion.',
  'distribution':
      'The action of sharing something out among a number of recipients.',
  'district': 'An area of a country or city.',
  'division': 'The action of separating something into parts.',
  'documentary':
      'A movie or a television or radio program that provides a factual record or report.',
  'domestic': 'Relating to the running of a home or to family relations.',
  'dominate': 'Have a commanding influence on; exercise control over.',
  'downwards': 'Towards a lower place or level.',
  'draft': 'A preliminary version of a piece of writing.',
  'define': 'State or describe exactly the nature, scope, or meaning of.',
  'determine': 'Cause (something) to occur in a particular way.',
  'directly': 'Without changing direction or stopping.',
  'disappointed':
      'Sad or displeased because someone or something has failed to fulfill one\'s hopes or expectations.',
  'disappointing': 'Failing to fulfill someone\'s hopes or expectations.',
  'dislike': 'Feel distaste for or hostility towards.',
  'display': 'A collection of objects arranged for public viewing.',
  'divide': 'Separate or be separated into parts.',
  'double': 'Consisting of two equal, identical, or similar parts or things.',
  'dramatic': 'Relating to drama or the performance or study of drama.',
  'delivery': 'The action of delivering letters, packages, or ordered goods.',
  'depth': 'The distance from the top or surface to the bottom of something.',
  'detail': 'An individual fact or item.',
  'disadvantage':
      'An unfavorable circumstance or condition that reduces the chances of success or effectiveness.',
  'discount': 'A deduction from the usual cost of something.',
  'document':
      'A piece of written, printed, or electronic matter that provides information or evidence.',
  'drag':
      'Pull (someone or something) along forcefully, roughly, or with difficulty.',
  'dressed': 'Wearing clothes.',
  'dust':
      'Fine, dry powder consisting of tiny particles of earth or waste matter.',
  'eastern': 'Situated in, directed towards, or facing the east.',
  'economic': 'Relating to economics or the economy.',
  'economy': 'The wealth and resources of a country or region.',
  'edge': 'The outside limit of an object, area, or surface.',
  'edition': 'A particular form or version of a published text.',
  'effective': 'Successful in producing a desired or intended result.',
  'accommodation':
      'A room, group of rooms, or building in which someone may live or stay.',
  'accompany': 'Go somewhere with (someone) as a companion or escort.',
  'accurate': 'Correct in all details; exact.',
  'accuse': 'Charge (someone) with an offense or crime.',
  'acquire': 'Buy or obtain (an asset or object) for oneself.',
  'adapt': 'Make (something) suitable for a new use or purpose; modify.',
  'admire':
      'Regard (an object, quality, or person) with respect or warm approval.',
  'adopt': 'Legally take (another\'s child) and bring it up as one\'s own.',
  'acknowledge': 'Accept or admit the existence or truth of.',
  'afford': 'Have enough money to pay for.',
  'afterwards': 'At a later or subsequent time.',
  'agenda': 'A list of items to be discussed at a formal meeting.',
  'aggressive': 'Ready or likely to attack or confront.',
  'aircraft': 'An airplane, helicopter, or other machine capable of flight.',
  'alter':
      'Change or cause to change in character or composition, typically in a comparatively small but significant way.',
  'ambitious':
      'Having or showing a strong desire and determination to succeed.',
  'analyse':
      'Examine methodically and in detail the constitution or structure of (something, especially information).',
  'analysis': 'Detailed examination of the elements or structure of something.',
  'amazed': 'Greatly surprised; astonished.',
  'exhibition': 'A public display of works of art or other items of interest.',
  'existence': 'The fact or state of living or having objective reality.',
  'expectation':
      'A strong belief that something will happen or be the case in the future.',
  'expense': 'The cost required for something; the money spent on something.',
  'exploration':
      'The action of traveling in or through an unfamiliar area in order to learn about it.',
  'expose': 'Make (something) visible by uncovering it.',
  'episode':
      'An event or a group of events occurring as part of a larger sequence.',
  'equal': 'Being the same in quantity, size, degree, or value.',
  'establish':
      'Set up (an organization, system, or set of rules) on a firm or permanent basis.',
  'evaluate': 'Form an idea of the amount, number, or value of; assess.',
  'examination': 'A detailed inspection or study.',
  'expected': 'Regarded as likely; anticipated.',
  'expedition':
      'A journey or voyage undertaken by a group of people with a particular purpose.',
  'explosion':
      'A violent and destructive shattering or blowing apart of something.',
  'extend': 'Make larger in area; enlarge.',
  'extent': 'The area covered by something.',
  'extraordinary': 'Very unusual or remarkable.',
  'facility':
      'A place, amenity, or piece of equipment provided for a particular purpose.',
  'fairly': 'With justice.',
  'familiar': 'Well known from long or close association.',
  'fascinating': 'Extremely interesting.',
  'fashionable':
      'Characteristic of, influenced by, or representing a current popular style.',
  'fasten': 'Close or join securely.',
  'fault':
      'An unattractive or unsatisfactory feature, especially in a piece of work or in a person\'s character.',
  'estate': 'An area or amount of land or property.',
  'examine':
      'Inspect (someone or something) in detail to determine their nature or condition.',
  'exchange':
      'An act of giving one thing and receiving another (especially of the same kind) in return.',
  'excuse':
      'Attempt to lessen the blame attaching to (a fault or offense); seek to justify.',
  'explore':
      'Travel in or through (an unfamiliar country or area) in order to learn about or familiarize oneself with it.',
  'fancy': 'Feel a desire or liking for.',
  'favour': 'An act of kindness beyond what is due or usual.',
  'feather': 'Any of the flat macromolecules that form the plumage of birds.',
  'fee':
      'A payment made to a professional person or public body in exchange for advice or services.',
  'fence':
      'A barrier, railing, or other upright structure, typically of wood or wire.',
  'finance':
      'The management of large amounts of money, especially by governments or large companies.',
  'financial': 'Relating to finance.',
  'firm': 'Having a solid, unyielding surface or structure.',
  'defend': 'Resist an attack made on (someone or something).',
  'flame':
      'A hot glowing body of ignited gas that is generated by something on fire.',
  'comfort': 'A state of physical ease and freedom from pain or constraint.',
  'command': 'Give an authoritative order.',
  'commercial': 'Concerned with or engaged in commerce.',
  'commission':
      'An instruction, command, or duty given to a person or group of people.',
  'commitment':
      'The state or quality of being dedicated to a cause, activity, etc.',
  'committee':
      'A group of people appointed for a specific function by a larger group.',
  'commonly': 'Very often; frequently.',
  'competitor':
      'An organization or person that is engaged in commercial or economic competition with others.',
  'complex': 'Consisting of many different and connected parts.',
  'complicated':
      'Consisting of many interconnecting parts or elements; intricate.',
  'component': 'A part or element of a larger whole.',
  'concentrate':
      'Focus one\'s attention or mental effort on a particular object or activity.',
  'concept': 'An abstract idea; a general notion.',
  'concerned': 'Worried, troubled, or anxious.',
  'conclude': 'Bring (something) to an end.',
  'conclusion': 'The end or finish of an event or process.',
  'confidence':
      'The feeling or belief that one can rely on someone or something; firm trust.',
  'conflict': 'A serious disagreement or argument, typically a protracted one.',
  'confusing': 'Bewildering or perplexing.',
  'conscious': 'Aware of and responding to one\'s surroundings; awake.',
  'consequence': 'A result or effect of an action or condition.',
  'concentration':
      'The action or power of focusing one\'s attention or mental effort.',
  'concern': 'Relate to; be about.',
  'conduct': 'The manner in which a person behaves.',
  'conservative':
      'Holding to traditional values and cautious about change or innovation.',
  'consideration': 'Careful thought, typically over a period of time.',
  'consistent': 'Acting or done in the same way over time.',
  'constantly': 'Continuously over a period of time; always.',
  'construction': 'The building of something, typically a large structure.',
  'holy': 'Dedicated or consecrated to God or a religious purpose.',
  'honour': 'High respect; esteem.',
  'host': 'A person who receives or entertains other people as guests.',
  'household': 'A house and its occupants regarded as a unit.',
  'housing': 'Houses and apartments considered collectively.',
  'humorous': 'Causing lighthearted laughter and amusement.',
  'humour':
      'The quality of being amusing or comic, especially as expressed in literature or speech.',
  'hunting':
      'The activity of chasing and killing wild animals for food or sport.',
  'hurricane':
      'A storm with a violent wind, in particular a tropical cyclone in the Caribbean.',
  'hunt': 'Chase and kill (a wild animal) for food or sport.',
  'hurry': 'Move or act with great haste.',
  'ideal': 'Satisfying one\'s conception of what is perfect; most suitable.',
  'illegal': 'Contrary to or forbidden by law, especially criminal law.',
  'illustrate': 'Provide (a book, newspaper, etc.) with pictures.',
  'illustration': 'A picture illustrating a book, newspaper, etc.',
  'imaginary': 'Existing only in the imagination.',
  'imagination':
      'The faculty or action of forming new ideas, or images or concepts of external objects.',
  'immigrant': 'A person who comes to live permanently in a foreign country.',
  'impatient':
      'Having or showing a tendency to be quickly irritated or provoked.',
  'imply':
      'Strongly suggest the truth or existence of (something not expressly stated).',
  'importance': 'The state or fact of being of great significance or value.',
  'impose':
      'Force (something unwelcome or unfamiliar) to be accepted or put in place.',
  'impressed': 'Feeling admiration and respect for someone or something.',
  'impression':
      'An idea, feeling, or opinion about something or someone, especially one formed without conscious thought.',
  'identity': 'The fact of being who or what a person or thing is.',
  'ignore': 'Refuse to take notice of or acknowledge.',
  'immediate': 'Occurring or done at once; instant.',
  'impress': 'Make (someone) feel admiration and respect.',
  'deliberate': 'Done consciously and intentionally.',
  'deliberately': 'Consciously and intentionally; on purpose.',
  'demonstrate':
      'Clearly show the existence or truth of (something) by giving proof or evidence.',
  'debt': 'Something, typically money, that is owed or due.',
  'decade': 'A period of ten years.',
  'decent':
      'Conforming with generally accepted standards of respectable or moral behavior.',
  'defence': 'The action of defending from or resisting attack.',
  'definition':
      'A statement of the exact meaning of a word, especially in a dictionary.',
  'delight': 'Great pleasure.',
  'delighted': 'Feeling or showing great pleasure.',
  'departure': 'The action of leaving, especially to start a journey.',
  'depressed': 'Feeling utterly dispirited or dejected.',
  'depressing': 'Causing or resulting in a feeling of miserable dejection.',
  'deserve':
      'Do something or have or show qualities worthy of reward or punishment.',
  'desire':
      'A strong feeling of wanting to have something or wishing for something to happen.',
  'desperate':
      'Feeling, showing, or involving a hopeless sense that a situation is so bad as to be impossible to deal with.',
  'dig':
      'Break up and move earth with a tool or a machine, or with hands, paws, etc.',
  'disc': 'A flat, thin, circular object.',
  'declare': 'Say something in a solemn and emphatic manner.',
  'decline': 'Become smaller, fewer, or less; decrease.',
  'decorate':
      'Make (something) look more attractive by adding extra items or images to it.',
  'definite': 'Clearly stated or decided; not vague or doubtful.',
  'delay': 'A period of time by which something is late or postponed.',
  'deliver':
      'Bring and hand over (a letter, package, or ordered goods) to the proper recipient or address.',
  'demand': 'An insistent and peremptory request, made as if by right.',
  'deny': 'State that one refuses to admit the truth or existence of.',
  'destination':
      'The place to which someone or something is going or being sent.',
  'detailed': 'Having many details.',
  'interpret': 'Explain the meaning of (information, words, or actions).',
  'interrupt': 'Stop the continuous progress of (an activity or process).',
  'investigation':
      'The action of investigating something or someone; formal or systematic examination or research.',
  'investment':
      'The action or process of investing money for profit or material result.',
  'issue': 'An important topic or problem for debate or discussion.',
  'joy': 'A feeling of great pleasure and happiness.',
  'judgement':
      'The ability to make considered decisions or come to sensible conclusions.',
  'junior': 'For or relating to young people.',
  'justice': 'Just behavior or treatment.',
  'justify': 'Show or prove to be right or reasonable.',
  'labour': 'Work, especially hard physical work.',
  'largely': 'To a great extent; on the whole.',
  'latest': 'Of most recent date.',
  'leadership': 'The action of leading a group of people or an organization.',
  'league':
      'A collection of people, countries, or groups that combine for a particular purpose.',
  'level':
      'A horizontal plane or line with respect to the distance above or below a given point.',
  'licence':
      'A permit from an authority to own or use something, do a particular thing, or carry on a trade.',
  'limited': 'Restricted in size, amount, or extent; few, small, or short.',
  'lively': 'Full of life and energy; active and outgoing.',
  'load':
      'A heavy or bulky thing that is being carried or is about to be carried.',
  'loan':
      'A thing that is borrowed, especially a sum of money that is expected to be paid back with interest.',
  'landscape': 'All the visible features of an area of countryside or land.',
  'launch':
      'Set (a boat) in motion by pushing it off the ground or by letting it slide into the water.',
  'layer':
      'A sheet, quantity, or thickness of material, typically one of several, covering a surface or body.',
  'leading': 'Most important.',
  'lean': 'Be in or move into a sloping position.',
  'leather':
      'A material made from the skin of an animal by tanning or a similar process.',
  'legal': 'Relating to the law.',
  'leisure': 'Time when one is not working or occupied; free time.',
  'effectively': 'In such a manner as to achieve a desired result.',
  'efficient':
      'Achieving maximum productivity with minimum wasted effort or expense.',
  'elderly': 'Old or aging.',
  'elect':
      'Choose (someone) to hold public office or some other position by voting.',
  'elsewhere': 'In, at, or to some other place or other places.',
  'emerge': 'Move out of or away from something and come into view.',
  'emphasis': 'Special importance, value, or prominence given to something.',
  'emphasize':
      'Give special importance or prominence to (something) in speaking or writing.',
  'enable':
      'Give (someone or something) the authority or means to do something.',
  'encounter':
      'Unexpectedly experience or be faced with (something difficult or hostile).',
  'engage': 'Occupy, attract, or involve (someone\'s interest or attention).',
  'engaged': 'Occupied; busy.',
  'engineering':
      'The branch of science and technology concerned with the design, building, and use of engines, machines, and structures.',
  'enhance':
      'Intensify, increase, or further improve the quality, value, or extent of.',
  'enquiry': 'An act of asking for information.',
  'ensure': 'Make certain that (something) shall occur or be the case.',
  'educational': 'Relating to the provision of education.',
  'embarrassed': 'Feeling or showing embarrassment.',
  'embarrassing': 'Causing embarrassment.',
  'enthusiasm': 'Intense and eager enjoyment, interest, or approval.',
  'enthusiastic':
      'Having or showing intense and eager enjoyment, interest, or approval.',
  'entirely': 'Completely (often used for emphasis).',
  'entrance':
      'An opening, such as a door, passage, or gate, that allows access to a place.',
  'essential': 'Absolutely necessary; extremely important.',
  'estimate':
      'Roughly calculate or judge the value, number, quantity, or extent of.',
  'ethical':
      'Relating to moral principles or the branch of knowledge dealing with these.',
  'eventually':
      'In the end, especially after a long delay, dispute, or series of problems.',
  'evil': 'Profoundly immoral and malevolent.',
  'excitement': 'A feeling of great enthusiasm and eagerness.',
  'executive': 'Having the power to put plans, actions, or laws into effect.',
  'musical': 'Relating to music.',
  'moral': 'Concerned with the principles of right and wrong behavior.',
  'mysterious': 'Difficult or impossible to understand, explain, or identify.',
  'mystery':
      'Something that is difficult or impossible to understand or explain.',
  'narrative': 'A spoken or written account of connected events; a story.',
  'national':
      'Relating to a nation; common to or characteristic of a whole nation.',
  'naturally': 'As may be expected; of course.',
  'neat': 'Done with or characterized by such skill or care.',
  'necessarily': 'As a necessary result; inevitably.',
  'neither': 'Not either; not the one nor the other.',
  'nerve':
      'A whitish fiber or bundle of fibers that transmits impulses of sensation to the brain or spinal cord.',
  'nevertheless': 'In spite of that; notwithstanding; all the same.',
  'nightmare': 'A frightening or unpleasant dream or frightening experience.',
  'notion': 'A conception of or belief about something.',
  'numerous': 'Great in number; many.',
  'objective':
      'Not influenced by personal feelings or opinions in considering and representing facts.',
  'obligation':
      'An act or course of action to which a person is morally or legally bound; a duty or commitment.',
  'observation':
      'The action or process of observing something or someone carefully or in order to gain information.',
  'observe':
      'Notice or perceive (something) and register it as being significant.',
  'obviously': 'In a way that is easily perceived or understood; clearly.',
  'occasion': 'A particular time or instance of an event.',
  'occasionally': 'At infrequent or irregular intervals; now and then.',
  'offence': 'A breach of a law or rule; an illegal act.',
  'offensive':
      'Causing resentful displeasure; highly irritating, angering, or annoying.',
  'official':
      'Relating to an authority or public body and its duties, actions, and responsibilities.',
  'opening': 'An aperture or gap, especially one allowing access.',
  'operate': 'Control the functioning of (a machine, process, or system).',
  'operation': 'The action of functioning or being active.',
  'flash': 'A sudden brief burst of bright light.',
  'flexible': 'Capable of bending easily without breaking.',
  'fold':
      'Bend (something flexible and relatively flat) over on itself so that one part of it covers another.',
  'folding': 'That can be folded.',
  'folk': 'People in general.',
  'force': 'Strength or energy as an attribute of physical action or movement.',
  'forgive':
      'Stop feeling angry or resentful towards (someone) for an offense, flaw, or mistake.',
  'fortune':
      'Chance or luck as an external, arbitrary force affecting human affairs.',
  'frozen': 'Turned into ice or another solid as a result of extreme cold.',
  'furthermore':
      'In addition; besides (used to introduce a fresh consideration or an important point).',
  'garage':
      'An establishment which sells fuel or which repairs and services motor vehicles.',
  'generate': 'Cause (a situation, or emotion) to arise or come about.',
  'genre': 'A category of artistic composition.',
  'govern':
      'Conduct the policy, actions, and affairs of (a state, organization, or people).',
  'grab': 'Grasp or seize suddenly and roughly.',
  'grade':
      'A particular level of rank, quality, proficiency, intensity, or value.',
  'gradually': 'In a gradual way; by degrees.',
  'grant': 'Agree to give or allow (something requested) to.',
  'guilty': 'Culpable of or responsible for a specified wrongdoing.',
  'handle': 'Feel or manipulate with the hands.',
  'hardly':
      'Scarcely (used to qualify a statement by saying that it is true to an insignificant degree).',
  'harmful': 'Causing or likely to cause harm.',
  'hearing': 'The faculty of perceiving sounds.',
  'heel': 'The back part of the human foot below the ankle.',
  'hesitate': 'Pause before saying or doing something.',
  'highly': 'To a high degree or level.',
  'historic': 'Famous or important in history, or potentially so.',
  'hollow': 'Having a hole or empty space inside.',
  'phase':
      'A distinct period or stage in a series of events or a process of change.',
  'package':
      'An object or group of objects wrapped in paper or packed in a box.',
  'passion': 'Strong and barely controllable emotion.',
  'peaceful': 'Free from disturbance; tranquil.',
  'performance':
      'An act of staging or presenting a play, concert, or other form of entertainment.',
  'persuade': 'Cause (someone) to do something through reasoning or argument.',
  'phenomenon': 'A fact or situation that is observed to exist or happen.',
  'philosophy':
      'The study of the fundamental nature of knowledge, reality, and existence.',
  'pitch':
      'The quality of a sound governed by the rate of vibrations producing it.',
  'plain': 'Not decorated or elaborate; simple or ordinary in character.',
  'planning': 'The process of making plans for something.',
  'pleasant': 'Giving a sense of happy satisfaction or enjoyment.',
  'pleasure': 'A feeling of happy satisfaction and enjoyment.',
  'pile': 'A heap of things laid or lying one on top of another.',
  'plot': 'The main events of a play, novel, movie, or similar work.',
  'poetry':
      'Literary work in which special intensity is given to the expression of feelings and ideas.',
  'pointed': 'Having a sharpened or tapered tip or end.',
  'poisonous':
      'Capable of causing the illness or death of a living organism when introduced or absorbed.',
  'popularity':
      'The state or condition of being liked, admired, or supported by many people.',
  'portrait':
      'A painting, drawing, photograph, or engraving of a person, especially one depicting only the face or head and shoulders.',
  'possess': 'Have as belonging to oneself; own.',
  'possibly': 'Perhaps (used to indicate doubt or hesitancy).',
  'potential':
      'Having or showing the capacity to become or develop into something in the future.',
  'poverty': 'The state of being extremely poor.',
  'powerful': 'Having great power, prestige, or influence.',
  'practical':
      'Of or concerned with the actual doing or use of something rather than with theory and ideas.',
  'impressive': 'Evoking admiration through size, quality, or skill.',
  'improvement':
      'A thing that makes something better or is better than something else.',
  'inch': 'A unit of linear measure equal to one twelfth of a foot (2.54 cm).',
  'incident': 'An event or occurrence.',
  'income':
      'Money received, especially on a regular basis, for work or through investments.',
  'increasingly': 'To an increasing extent; more and more.',
  'incredibly': 'To a great degree; extremely.',
  'indeed':
      'Used to emphasize a statement or response confirming something already suggested.',
  'indicate': 'Point out; show.',
  'indirect': 'Not done directly; conducted through intermediaries.',
  'indoor': 'Situated, conducted, or used within a building or under cover.',
  'indoors': 'Into or within a building.',
  'industrial': 'Relating to or characterized by industry.',
  'infection': 'The process of infecting or the state of being infected.',
  'influence':
      'The capacity to have an effect on the character, development, or behavior of someone or something.',
  'hurt': 'Cause physical pain or injury to.',
  'import': 'Bring (goods or services) into a country from abroad for sale.',
  'inform': 'Give (someone) facts or information.',
  'ingredient':
      'Any of the foods or substances that are combined to make a particular dish.',
  'initiative': 'The ability to assess and initiate things independently.',
  'injure': 'Do physical harm or damage to (someone).',
  'injured': 'Harmed, damaged, or impaired.',
  'inner': 'Situated inside or further in; internal.',
  'innocent': 'Not guilty of a crime or offense.',
  'insight':
      'The capacity to gain an accurate and deep intuitive understanding of a person or thing.',
  'insist': 'Demand something forcefully, not accepting refusal.',
  'inspire':
      'Fill (someone) with the urge or ability to do or feel something, especially to do something creative.',
  'install': 'Place or fix (equipment or machinery) in position ready for use.',
  'instance': 'An example or single occurrence of something.',
  'institute':
      'A society or organization having a particular object or common factor, especially a scientific, educational, or social one.',
  'institution':
      'A society or organization founded for a religious, educational, social, or similar purpose.',
  'insurance':
      'A practice or arrangement by which a company or government agency provides a guarantee of compensation for specified loss, damage, illness, or death.',
  'intelligence': 'The ability to acquire and apply knowledge and skills.',
  'intend': 'Have (a course of action) as one\'s purpose or objective; plan.',
  'intended': 'Planned or meant.',
  'impact':
      'The action of one object coming forcibly into contact with another.',
  'initial': 'Existing or occurring at the beginning.',
  'initially': 'At first.',
  'intense': 'Of extreme force, degree, or strength.',
  'internal': 'Of or situated on the inside.',
  'publication': 'The action of making something generally known.',
  'pupil': 'A student in school.',
  'purchase': 'Acquire (something) by paying money for it; buy.',
  'pure': 'Not mixed or adulterated with any other substance or material.',
  'pursue': 'Follow (someone or something) in order to catch or attack them.',
  'qualification':
      'A pass of an examination or an official completion of a course.',
  'print':
      'Produce (books, newspapers, magazines, etc.), especially in large quantities, by a mechanical process.',
  'production':
      'The action of making or manufacturing from components or raw materials, or the process of being so manufactured.',
  'profession':
      'A paid occupation, especially one that involves prolonged training and a formal qualification.',
  'proper': 'Truly what something is said or regarded to be; genuine.',
  'properly': 'In the correct or satisfactory way.',
  'proposal':
      'A plan or suggestion, especially a formal or written one, put forward for consideration or discussion by others.',
  'propose': 'Put forward (a plan or suggestion) for consideration by others.',
  'prospect': 'The possibility or likelihood of some future event occurring.',
  'protection': 'The action of protecting someone or something.',
  'protest':
      'A statement or action expressing disapproval of or objection to something.',
  'psychologist': 'An expert or specialist in psychology.',
  'psychology': 'The scientific study of the human mind and its functions.',
  'literature':
      'Written works, especially those considered of superior or lasting artistic merit.',
  'lung':
      'Each of the pair of organs situated within the rib cage, consisting of elastic sacs with branching passages into which air is drawn, so that oxygen can pass into the blood and carbon dioxide be removed.',
  'lord':
      'Someone or something having power, authority, or influence; a master or ruler.',
  'lower': 'Move (someone or something) down.',
  'maintain': 'Cause or enable (a condition or state of affairs) to continue.',
  'majority': 'The greater number.',
  'massive': 'Large and heavy or solid.',
  'matching': 'Corresponding in pattern, color, or design; complementary.',
  'maximum': 'As great, high, or intense as possible or permitted.',
  'means': 'An action or system by which a result is brought about; a method.',
  'meanwhile': 'In the intervening period of time.',
  'measurement': 'The action of measuring something.',
  'medium': 'An agency or means of doing something.',
  'melt': 'Make or become liquefied by heating.',
  'mineral': 'A solid inorganic substance of natural occurrence.',
  'minimum':
      'The least or smallest amount or quantity possible, attainable, or required.',
  'minor': 'Lesser in importance, seriousness, or significance.',
  'minority':
      'The smaller number or part, especially a number or part representing less than half of the whole.',
  'mission':
      'An important assignment carried out for political, religious, or commercial purposes.',
  'mistake': 'An action or judgment that is misguided or wrong.',
  'measure':
      'Ascertain the size, amount, or degree of (something) by using an instrument or device marked in standard units.',
  'mental': 'Relating to the mind.',
  'mess': 'A dirty or untidy state of things or of a place.',
  'mild': 'Gentle and not easily provoked.',
  'mix': 'Combine or put together to form one substance or mass.',
  'mixed': 'Consisting of different qualities or elements.',
  'mixture': 'A substance made by mixing other substances together.',
  'model':
      'A three-dimensional representation of a person or thing or of a proposed structure, typically on a smaller scale than the original.',
  'modify':
      'Make partial or minor changes to (something), typically so as to improve it or to make it less extreme.',
  'monitor': 'A screen which displays an image generated by a computer.',
  'motor':
      'A machine, especially one powered by electricity or internal combustion, that supplies motive power for a vehicle or for some other device with moving parts.',
  'move': 'Go in a specified direction or manner; change position.',
  'mud': 'Soft, sticky matter resulting from the mixing of earth and water.',
  'multiple': 'Having or involving several parts, elements, or members.',
  'multiply': 'Increase or cause to increase greatly in number or quantity.',
  'muscle':
      'A band or bundle of fibrous tissue in a human or animal body that has the ability to contract, producing movement in or maintaining the position of parts of the body.',
  'reward':
      'A thing given in recognition of one\'s service, effort, or achievement.',
  'rhythm': 'A strong, regular, repeated pattern of movement or sound.',
  'rid':
      'Make someone or something free of (a troublesome or unwanted person or thing).',
  'root':
      'The part of a plant which attaches it to the ground or to a support, typically underground, conveying water and nourishment to the rest of the plant via numerous branches and fibers.',
  'round': 'Shaped like a circle or cylinder.',
  'routine': 'A sequence of actions regularly followed.',
  'relevant':
      'Closely connected or appropriate to what is being done or considered.',
  'relief':
      'A feeling of reassurance and relaxation following release from anxiety or distress.',
  'resolve':
      'Settle or find a solution to (a problem, dispute, or contentious matter).',
  'resort':
      'A place that is a popular destination for vacations or recreation, or which is frequented for a particular purpose or quality.',
  'responsibility':
      'The state or fact of having a duty to deal with something or of having control over someone.',
  'responsible':
      'Having an obligation to do something, or having control over or care for someone, as part of one\'s job or role.',
  'retain': 'Continue to have (something); keep possession of.',
  'reveal': 'Make (previously unknown or secret information) known to others.',
  'revolution':
      'A forcible overthrow of a government or social order, in favor of a new system.',
  'scream':
      'Give a long, loud, piercing cry or cries expressing excitement, great emotion, or pain.',
  'screen':
      'A flat surface on which images and data are displayed, as on a television or computer.',
  'seed': 'The unit of reproduction of a flowering plant.',
  'sensitive':
      'Quick to detect or respond to slight changes, signals, or influences.',
  'opponent':
      'Someone who competes against or fights another in a contest, game, or argument.',
  'oppose': 'Disapprove of and attempt to prevent, especially by argument.',
  'opposed': 'Anxious to prevent or put an end to; disagreeing with.',
  'nation':
      'A large body of people united by common descent, history, culture, or language, inhabiting a particular country or territory.',
  'native':
      'A person born in a specified place or associated with a place by birth.',
  'needle':
      'A very fine slender piece of metal with a point at one end and a hole or eye for thread at the other, used in sewing.',
  'neighbourhood':
      'A district, especially one forming a community within a town or city.',
  'nuclear': 'Relating to or constituting the nucleus of an atom.',
  'obey':
      'Comply with the command, direction, or request of (a person or a law); submit to the authority of.',
  'object': 'A material thing that can be seen and touched.',
  'obtain': 'Get, acquire, or secure (something).',
  'obvious': 'Easily perceived or understood; self-evident or apparent.',
  'occur': 'Happen; take place.',
  'offend': 'Cause to feel upset, annoyed, or resentful.',
  'opposition': 'Resistance or dissent, expressed in action or argument.',
  'organ':
      'A part of an organism that is typically self-contained and has a specific vital function.',
  'organized': 'Arranged in a systematic way, especially on a large scale.',
  'organizer': 'A person who organizes.',
  'origin': 'The point or place where something begins, arises, or is derived.',
  'originally': 'From or in the beginning; at first.',
  'otherwise': 'In other respects; apart from that.',
  'outer': 'Outside; external.',
  'outline':
      'A line or set of lines enclosing or indicating the shape of an object in a sketch or diagram.',
  'overall': 'Taking everything into account.',
  'owe':
      'Have an obligation to pay or repay (something, especially money) in return for something received.',
  'pace': 'A single step taken when walking or running.',
  'pale': 'Light in color or having little color.',
  'panel':
      'A flat or curved component, typically rectangular, that forms part of a surface.',
  'parliament':
      'The highest legislature, consisting of the Sovereign, the House of Lords, and the House of Commons.',
  'participant': 'A person who takes part in something.',
  'participate': 'Be involved; take part.',
  'particularly': 'To a higher degree than is usual or average.',
  'partly': 'To some extent; in some degree; not wholly.',
  'passage':
      'The action or process of moving through or past something on the way from one place to another.',
  'pension':
      'A regular payment made during a person\'s retirement from an investment fund to which that person or their employer has contributed during their working life.',
  'permanent': 'Lasting or intended to last or remain unchanged indefinitely.',
  'permit': 'Give authorization or consent to (someone) to do something.',
  'perspective':
      'The art of drawing solid objects on a two-dimensional surface so as to give the right impression of their height, width, depth, and position in relation to each other when viewed from a particular point.',
  'suspect':
      'Have an idea or impression of the existence, presence, or truth of (something) without certain proof.',
  'swear':
      'Make a solemn statement or promise undertaking to do something or affirming that something is true.',
  'sweep': 'Clean (an area) by brushing away dirt or litter.',
  'switch':
      'A device for making and breaking the connection in an electric circuit.',
  'sympathy': 'Feelings of pity and sorrow for someone else\'s misfortune.',
  'symptom':
      'A physical or mental feature which is regarded as indicating a condition of disease.',
  'tale':
      'A fictitious or true narrative or story, especially one that is imaginatively recounted.',
  'talented': 'Having a natural aptitude or skill for something.',
  'tank':
      'A large receptacle or storage chamber, especially for liquid or gas.',
  'silence': 'Complete absence of sound.',
  'sincere': 'Free from pretense or deceit; proceeding from genuine feelings.',
  'slide':
      'Move along a smooth surface while maintaining continuous contact with it.',
  'slightly': 'To a small degree; not considerably.',
  'software':
      'The programs and other operating information used by a computer.',
  'somewhat': 'To a moderate extent or by a moderate amount.',
  'specifically': 'In a way that is exact and clear; precisely.',
  'spoken': 'Uttered by the mouth; oral.',
  'sponsor':
      'A person or organization that provides funds for a project or activity carried out by another, in particular a person or organization that pays for or contributes to the costs involved in equipping a sporting or artistic event in return for advertising rights.',
  'spot':
      'A small round or roundish mark, differing in color or texture from the surface around it.',
  'spread': 'Open out (something) so as to extend it over a larger area.',
  'praise': 'Express warm approval or admiration of.',
  'prediction': 'A thing predicted; a forecast.',
  'preparation':
      'The action or process of making ready or being made ready for use or consideration.',
  'presence':
      'The state or fact of being present; the state of being with or in the same place as someone or something.',
  'preserve': 'Maintain (something) in its original or existing state.',
  'pressure':
      'The continuous physical force exerted on or against an object by something in contact with it.',
  'previous': 'Existing or occurring before in time or order.',
  'previously': 'At a previous or earlier time; before.',
  'priest':
      'An ordained minister of the Catholic, Orthodox, or Anglican Church having the authority to perform certain rites and administer certain sacraments.',
  'prime': 'Of first importance; main.',
  'printing': 'The production of books, newspapers, or other printed material.',
  'priority':
      'The fact or condition of being regarded or treated as more important.',
  'prisoner':
      'A person legally committed to prison as a punishment for a crime or while awaiting trial.',
  'privacy':
      'The state or condition of being free from being observed or disturbed by other people.',
  'procedure': 'An established or official way of doing something.',
  'perfectly': 'In a manner or way that could not be better.',
  'policy':
      'A course or principle of action adopted or proposed by a government, party, business, or individual.',
  'politician':
      'A person who is professionally involved in politics, especially as a holder of or a candidate for an elected office.',
  'prepared': 'Ready to do or deal with something.',
  'presentation':
      'The giving of something to someone, especially at a formal ceremony.',
  'pretend':
      'Speak and act so as to make it appear that something is the case when in fact it is not.',
  'private':
      'Belonging to or for the use of one particular person or group of people only.',
  'principle':
      'A fundamental truth or proposition that serves as the foundation for a system of belief or behavior or for a chain of reasoning.',
  'thus': 'As a result or consequence of this; therefore.',
  'tough':
      'Strong enough to withstand adverse conditions or rough or careless handling.',
  'trade': 'The action of buying and selling goods and services.',
  'translate': 'Express the sense of (words or text) in another language.',
  'translation':
      'The process of translating words or text from one language into another.',
  'treat': 'Behave towards or deal with in a certain way.',
  'treatment':
      'The manner in which someone behaves towards or deals with someone or something.',
  'uncomfortable': 'Causing or feeling slight pain or physical discomfort.',
  'unconscious': 'Not conscious.',
  'unemployed': 'Without a job.',
  'unemployment': 'The state of being unemployed.',
  'unexpected': 'Not expected or regarded as likely to happen.',
  'unfair':
      'Not based on or behaving according to the principles of equality and justice.',
  'union':
      'The action or fact of joining or being joined, especially in a political context.',
  'unique': 'Being the only one of its kind; unlike anything else.',
  'universe': 'All existing matter and space considered as a whole.',
  'unnecessary': 'Not needed.',
  'unpleasant': 'Causing discomfort, unhappiness, or revulsion; disagreeable.',
  'upset': 'Make (someone) unhappy, disappointed, or worried.',
  'upwards': 'Towards a higher place, point, or level.',
  'qualified':
      'Officially recognized as being trained to perform a particular job; certified.',
  'queue':
      'A line or sequence of people or vehicles awaiting their turn to be attended to or to proceed.',
  'range':
      'The area of variation between upper and lower limits on a particular scale.',
  'rapid': 'Happening in a short time or at a great rate.',
  'rapidly': 'Very quickly; at a great rate.',
  'rarely': 'Not often; seldom.',
  'raw': 'Not cooked.',
  'realistic':
      'Having or showing a sensible and practical idea of what can be achieved or expected.',
  'reasonable': 'As much as is appropriate or fair; moderate.',
  'recall':
      'Bring (a fact, event, or situation) back into one\'s mind, especially so as to recount it to others; remember.',
  'recover': 'Return to a normal state of health, mind, or strength.',
  'reduction':
      'The action or fact of making a specified thing smaller or less in amount, degree, or size.',
  'reference': 'The action of mentioning or alluding to something.',
  'regard': 'Consider or think of (someone or something) in a specified way.',
  'regional': 'Relating to or characteristic of a region.',
  'register':
      'An official list or record, for example of births, marriages, and deaths, of shipping, or of historic places.',
  'regret':
      'Feel sad, repentant, or disappointed over (something that has happened or been done, especially a loss or missed opportunity).',
  'regulation': 'A rule or directive made and maintained by an authority.',
  'rate':
      'A measure, quantity, or frequency, typically one measured against some other quantity or measure.',
  'receipt':
      'A written acknowledgment that a specified article or sum of money has been received.',
  'recommendation':
      'A suggestion or proposal as to the best course of action, especially one formally put forward by a council or other body.',
  'reflect': 'Throw back (heat, light, or sound) without absorbing it.',
  'regularly':
      'With a constant or definite pattern, especially with the same space between individual items or instances.',
  'relative': 'A person connected by blood or marriage.',
  'relatively': 'In relation, comparison, or proportion to something else.',
  'relaxing': 'Reducing tension or anxiety.',
  'release': 'Allow or enable to escape from confinement; set free.',
  'reliable':
      'Consistently good in quality or performance; able to be trusted.',
  'religion':
      'The belief in and worship of a superhuman controlling power, especially a personal God or gods.',
  'religious': 'Relating to or believing in a religion.',
  'rely': 'Depend on with full trust or confidence.',
  'remark': 'A written or spoken comment.',
  'repeated': 'Done or occurring again and again of a thing.',
  'represent':
      'Be entitled to speak or act for (someone), especially in an official capacity.',
  'representative':
      'A person chosen or appointed to act or speak for another or others, in particular.',
  'reputation':
      'The beliefs or opinions that are generally held about someone or something.',
  'require': 'Need for a particular purpose.',
  'requirement': 'A thing that is needed or wanted.',
  'rescue': 'Save (someone) from a dangerous or distressing situation.',
  'reserve':
      'Refrain from using or disposing of (something); retain for future use.',
  'resident':
      'A person who lives somewhere permanently or on a long-term basis.',
  'resist': 'Withstand the action or effect of.',
  'respect':
      'A feeling of deep admiration for someone or something elicited by their abilities, qualities, or achievements.',
  'retired':
      'Having left one\'s job and ceased to work, typically upon reaching the normal age for leaving service.',
  'revise':
      'Reconsider and alter (something) in the light of further evidence.',
  'sentence':
      'A set of words that is complete in itself, typically containing a subject and predicate, conveying a statement, question, exclamation, or command, and consisting of a main clause and sometimes one or more subordinate clauses.',
  'sequence':
      'A particular order in which related events, movements, or things follow each other.',
  'session': 'A period devoted to a particular activity.',
  'settle': 'Resolve or reach an agreement about (an argument or problem).',
  'severe': 'Very great; intense.',
  'shade':
      'Comparative darkness and coolness caused by shelter from direct sunlight.',
  'shadow':
      'A dark area or shape produced by an object coming between rays of light and a surface.',
  'shallow': 'Of little depth.',
  'shame':
      'A painful feeling of humiliation or distress caused by the consciousness of wrong or foolish behavior.',
  'shape':
      'The external form or appearance of characteristic of someone or something; the outline of an area or figure.',
  'shell': 'The hard protective outer case of a mollusk or crustacean.',
  'shift':
      'Move or cause to move from one place to another, especially over a small distance.',
  'shocked': 'Feeling or showing surprise and dismay.',
  'sight': 'The faculty or power of seeing.',
  'significant':
      'Sufficiently great or important to be worthy of attention; noteworthy.',
  'significantly':
      'In a sufficiently great or important way as to be worthy of attention.',
  'similarity': 'The state or fact of being similar.',
  'slave':
      'A person who is the legal property of another and is forced to obey them.',
  'slight': 'Small in degree; inconsiderable.',
  'slip': 'Lose one\'s footing and slide unintentionally for a short distance.',
  'slope':
      'A surface of which one end or side is at a higher level than another; a rising or falling ground.',
  'solar': 'Relating to or determined by the sun.',
  'specialist':
      'A person who concentrates on a particular subject or activity; a person highly skilled in a specific and restricted field.',
  'species':
      'A group of living organisms consisting of similar individuals capable of exchanging genes or interbreeding.',
  'spending': 'The action of spending money.',
  'spirit':
      'The nonphysical part of a person which is the seat of emotions and character; the soul.',
  'spiritual':
      'Relating to or affecting the human spirit or soul as opposed to material or physical things.',
  'split':
      'Break or cause to break forcibly into parts, especially into halves or along the grain.',
  'spring':
      'The season after winter and before summer, in which vegetation begins to appear.',
  'stare':
      'Look fixedly or vacantly at someone or something with one\'s eyes wide open.',
  'statistic':
      'A fact or piece of data from a study of a large quantity of numerical data.',
  'steady': 'Firmly fixed, supported, or balanced; not shaking or moving.',
  'steep': 'Rising or falling sharply; nearly vertical.',
  'sticky': 'Tending or designed to stick to things on contact.',
  'stiff': 'Not easily bent or changed in shape; rigid.',
  'stock':
      'The goods or merchandise kept on the premises of a business or warehouse and available for sale or distribution.',
  'stream': 'A small, narrow river.',
  'strict': 'Demanding that rules concerning behavior are obeyed and observed.',
  'strike':
      'Hit forcibly and deliberately with one\'s hand or a weapon or other implement.',
  'struggle':
      'Make forceful or violent efforts to get free of restraint or constriction.',
  'subject':
      'A person or thing that is being discussed, described, or dealt with.',
  'substance': 'A particular kind of matter with uniform properties.',
  'successfully': 'In a way that accomplishes a desired aim or result.',
  'sum':
      'The total amount resulting from the addition of two or more numbers, amounts, or items.',
  'surgery':
      'The treatment of injuries or disorders of the body by incision or manipulation, especially with instruments.',
  'surround': 'Be all around (someone or something).',
  'surrounding': 'All round a particular place or thing.',
  'stable': 'Not likely to change or fail; firmly established.',
  'stage': 'A point, period, or step in a process or development.',
  'stand': 'Have or maintain an upright position, supported by one\'s feet.',
  'status':
      'The relative social, professional, or other standing of someone or something.',
  'steel':
      'A hard, strong, gray or bluish-gray alloy of iron with carbon and usually other elements, used extensively as a structural and fabricating material.',
  'step':
      'An act or movement of lifting and setting down one\'s foot in walking or running.',
  'violence':
      'Behavior involving physical force intended to hurt, damage, or kill someone or something.',
  'tax':
      'A compulsory contribution to state revenue, levied by the government on workers\' income and business profits, or added to the cost of some goods, services, and transactions.',
  'tear': 'Pull or rip (something) apart or to pieces with force.',
  'technical':
      'Relating to a particular subject, art, or craft, or its techniques.',
  'technique':
      'A way of carrying out a particular task, especially the execution or performance of an artistic work or a scientific procedure.',
  'temporary': 'Lasting for only a limited period of time; not permanent.',
  'theme':
      'The subject of a talk, a piece of writing, a person\'s thoughts, or an exhibition; a topic.',
  'theory':
      'A supposition or a system of ideas intended to explain something, especially one based on general principles independent of the thing to be explained.',
  'therapy': 'Treatment intended to relieve or heal a disorder.',
  'threat':
      'A statement of an intention to inflict pain, injury, damage, or other hostile action on someone in retribution for something done or not done.',
  'threaten':
      'State one\'s intention to take hostile action against someone in retribution for something done or not done.',
  'throat':
      'The passage which leads from the back of the mouth of a person or animal, through which food passes to the esophagus and air passes to the lungs.',
  'tiny': 'Very small.',
  'tone':
      'A musical or vocal sound with reference to its pitch, quality, and strength.',
  'transfer': 'Move from one place to another.',
  'transform':
      'Make a thorough or dramatic change in the form, appearance, or character of.',
  'transition':
      'The process of changing from one state or condition to another.',
  'trial':
      'A formal examination of evidence before a judge, and typically before a jury, in order to decide guilt in a case of criminal or civil proceedings.',
  'trip': 'A journey or excursion, especially for pleasure.',
  'tropical': 'Of, typical of, or peculiar to the tropics.',
  'truly': 'In a truthful way.',
  'tune':
      'A melody, especially one which characterizes a particular piece of music.',
  'tunnel':
      'An artificial underground passage, especially one built through a hill or under a building, road, or river.',
  'ultimately': 'Finally; in the end.',
  'self':
      'A person\'s essential being that distinguishes them from others, especially considered as the object of introspection or reflexive action.',
  'shelter': 'A place giving temporary protection from bad weather or danger.',
  'soul':
      'The spiritual or immaterial part of a human being or animal, regarded as immortal.',
  'southern': 'Situated in, or coming from the south.',
  'standard': 'A level of quality or attainment.',
  'stretch':
      'Be capable of being made longer or wider without tearing or breaking.',
  'stuff':
      'Matter, material, articles, or activities of a specified or indeterminate kind that are being referred to, indicated, or implied.',
  'submit':
      'Accept or yield to a superior force or to the authority or will of another person.',
  'suffer': 'Experience or be subjected to (something bad or unpleasant).',
  'summarize': 'Give a brief statement of the main points of (something).',
  'summary': 'A brief statement or account of the main points of something.',
  'surely':
      'Used to emphasize the speaker\'s firm belief that what they are saying is true and often their surprise that there is any doubt of this.',
  'tail':
      'The part of an animal\'s body that sticks out from the back end and can usually be moved.',
  'target': 'A person, object, or place selected as the aim of an attack.',
  'urban': 'In, relating to, or characteristic of a town or city.',
  'urge':
      'Try earnestly or persistently to persuade (someone) to do something.',
  'value':
      'The regard that something is held to deserve; the importance, worth, or usefulness of something.',
  'vary':
      'Differ in size, amount, degree, or nature from something else of the same general class.',
  'vast': 'Of very great extent or quantity; immense.',
  'venue':
      'The place where something happens, especially an organized event such as a concert, conference, or sports competition.',
  'version':
      'A particular form of something differing in certain respects from an earlier form or other forms of the same type of thing.',
  'victim':
      'A person harmed, injured, or killed as a result of a crime, accident, or other event or action.',
  'victory':
      'An act of defeating an enemy or opponent in a battle, game, or other competition.',
  'viewer': 'A person who looks at or inspects something, in particular.',
  'violent':
      'Using or involving physical force intended to hurt, damage, or kill someone or something.',
  'virtual':
      'Almost or nearly as described, but not completely or according to strict definition.',
  'vision': 'The faculty or state of being able to see.',
  'visual': 'Relating to seeing or sight.',
  'vital': 'Absolutely necessary or important; essential.',
  'volume': 'A book forming part of a work or series.',
  'wage':
      'A fixed regular payment, typically paid on a daily or weekly basis, made by an employer to an employee, especially to a manual or unskilled worker.',
  'wealth': 'An abundance of valuable possessions or money.',
  'wealthy': 'Having a great deal of money, resources, or assets; rich.',
  'whisper':
      'Speak very softly using one\'s breath without one\'s vocal cords, especially for the sake of privacy.',
  'widely': 'Over a large area or range; extensively.',
  'wildlife':
      'Wild animals collectively; the native fauna (and sometimes flora) of a region.',
  'willing': 'Ready, eager, or prepared to do something.',
  'wire': 'Metal drawn out into the form of a thin flexible thread or rod.',
  'wise': 'Having or showing experience, knowledge, and good judgment.',
  'witness':
      'A person who sees an event, typically a crime or accident, take place.',
  'worldwide': 'Extending or reaching throughout the world.',
  'worth': 'Equivalent in value to the sum or item specified.',
  'wound':
      'An injury to living tissue caused by a cut, blow, or other impact, typically one in which the skin is cut or broken.',
  'wrap': 'Cover or enclose (someone or something) in paper or soft material.',
  'yard': 'A unit of linear measure equal to 3 feet (91.44 cm).',
  'youth': 'The period between childhood and adult age.',
  'zone':
      'An area or stretch of land having a particular characteristic, purpose, or use, or subject to particular restrictions.',
};

const List<String> _allVocabWords = [
  'active',
  'ankle',
  'anyway',
  'argue',
  'article',
  'author',
  'avoid',
  'believe',
  'blank',
  'blow',
  'castle',
  'cause',
  'cent',
  'celebrity',
  'check',
  'clearly',
  'clever',
  'cloud',
  'coach',
  'coast',
  'collect',
  'college',
  'corner',
  'cover',
  'crazy',
  'crime',
  'crowd',
  'deal',
  'dentist',
  'destroy',
  'device',
  'diary',
  'disagree',
  'disease',
  'desert',
  'design',
  'discuss',
  'distance',
  'divorced',
  'drop',
  'dry',
  'early',
  'earn',
  'effect',
  'energy',
  'error',
  'event',
  'everyday',
  'everywhere',
  'exact',
  'exactly',
  'exercise',
  'expert',
  'fact',
  'factor',
  'farm',
  'farming',
  'fear',
  'feed',
  'field',
  'illness',
  'imagine',
  'injury',
  'insect',
  'introduce',
  'invitation',
  'invite',
  'item',
  'jewellery',
  'joke',
  'journalist',
  'journey',
  'knowledge',
  'lazy',
  'lead',
  'leave',
  'lifestyle',
  'loud',
  'mail',
  'material',
  'meaning',
  'medical',
  'narrow',
  'natural',
  'nature',
  'pair',
  'period',
  'population',
  'position',
  'prison',
  'prize',
  'professor',
  'protect',
  'pull',
  'raise',
  'receive',
  'recent',
  'recently',
  'react',
  'reduce',
  'request',
  'respond',
  'replace',
  'scary',
  'skin',
  'spell',
  'stair',
  'store',
  'stupid',
  'succeed',
  'system',
  'task',
  'team',
  'telephone',
  'television',
  'thick',
  'thief',
  'thin',
  'tip',
  'abroad',
  'accept',
  'accident',
  'actually',
  'advantage',
  'adventure',
  'advertise',
  'advertisement',
  'advertising',
  'advice',
  'affect',
  'afraid',
  'afternoon',
  'airline',
  'almost',
  'alternative',
  'amazing',
  'ancient',
  'appearance',
  'arrangement',
  'asleep',
  'assistant',
  'athlete',
  'attack',
  'attend',
  'attractive',
  'audience',
  'average',
  'beautiful',
  'become',
  'begin',
  'beginning',
  'behave',
  'behaviour',
  'belong',
  'benefit',
  'better',
  'between',
  'blonde',
  'boot',
  'bored',
  'boring',
  'borrow',
  'bread',
  'bright',
  'brilliant',
  'busy',
  'butter',
  'button',
  'camp',
  'camping',
  'capital',
  'career',
  'careful',
  'carefully',
  'carpet',
  'certain',
  'certainly',
  'charity',
  'classical',
  'competition',
  'complain',
  'complete',
  'completely',
  'computer',
  'concert',
  'condition',
  'conference',
  'connect',
  'connected',
  'consider',
  'contain',
  'context',
  'continent',
  'continue',
  'control',
  'conversation',
  'creative',
  'criminal',
  'crowded',
  'culture',
  'dancing',
  'dangerous',
  'decide',
  'decision',
  'deep',
  'definitely',
  'degree',
  'delicious',
  'department',
  'depend',
  'describe',
  'description',
  'designer',
  'detective',
  'develop',
  'difference',
  'different',
  'differently',
  'digital',
  'direct',
  'direction',
  'director',
  'disappear',
  'disaster',
  'discover',
  'discovery',
  'drug',
  'electric',
  'electrical',
  'electronic',
  'email',
  'employ',
  'employee',
  'employer',
  'ending',
  'enormous',
  'environment',
  'equipment',
  'especially',
  'tool',
  'figure',
  'flu',
  'form',
  'foreign',
  'government',
  'guess',
  'guest',
  'hide',
  'hold',
  'hour',
  'explain',
  'explanation',
  'express',
  'expression',
  'extreme',
  'extremely',
  'feeling',
  'fiction',
  'focus',
  'follow',
  'following',
  'fork',
  'fortunately',
  'forward',
  'friendly',
  'funny',
  'furniture',
  'further',
  'future',
  'gallery',
  'general',
  'greet',
  'guide',
  'however',
  'identify',
  'immediately',
  'important',
  'impossible',
  'include',
  'included',
  'increase',
  'incredible',
  'independent',
  'individual',
  'industry',
  'informal',
  'information',
  'instead',
  'instruction',
  'instructor',
  'instrument',
  'interest',
  'interested',
  'interesting',
  'international',
  'invent',
  'invention',
  'tourism',
  'traveller',
  'upstairs',
  'vacation',
  'visitor',
  'waiter',
  'worst',
  'act',
  'ability',
  'manager',
  'manner',
  'match',
  'matter',
  'mean',
  'meet',
  'meeting',
  'member',
  'memory',
  'mention',
  'mile',
  'million',
  'modern',
  'moment',
  'mostly',
  'movement',
  'musician',
  'nearly',
  'necessary',
  'nervous',
  'noisy',
  'notice',
  'nowhere',
  'opinion',
  'opportunity',
  'ordinary',
  'organization',
  'organize',
  'oven',
  'owner',
  'pack',
  'paragraph',
  'particular',
  'passenger',
  'passport',
  'past',
  'patient',
  'pattern',
  'peace',
  'penny',
  'pepper',
  'perform',
  'permission',
  'personality',
  'phrase',
  'piano',
  'picture',
  'piece',
  'colleague',
  'comfortable',
  'comment',
  'common',
  'communicate',
  'community',
  'compete',
  'professional',
  'program',
  'programme',
  'progress',
  'project',
  'pronounce',
  'provide',
  'publish',
  'purpose',
  'quantity',
  'reach',
  'realize',
  'reception',
  'recipe',
  'recognize',
  'recommend',
  'recycle',
  'refer',
  'refuse',
  'region',
  'regular',
  'remember',
  'report',
  'research',
  'researcher',
  'response',
  'review',
  'sail',
  'sailing',
  'salad',
  'scared',
  'schedule',
  'season',
  'secondly',
  'secretary',
  'section',
  'sense',
  'separate',
  'series',
  'serious',
  'serve',
  'service',
  'shall',
  'sheet',
  'should',
  'shut',
  'sick',
  'similar',
  'simple',
  'essay',
  'euro',
  'evening',
  'evidence',
  'excited',
  'exciting',
  'expect',
  'expensive',
  'experience',
  'experiment',
  'storm',
  'straight',
  'strange',
  'strategy',
  'structure',
  'successful',
  'suddenly',
  'suggest',
  'suit',
  'suppose',
  'surprised',
  'surprising',
  'survey',
  'sweater',
  'symbol',
  'technology',
  'term',
  'terrible',
  'thinking',
  'thirsty',
  'thought',
  'tidy',
  'tired',
  'together',
  'tooth',
  'topic',
  'track',
  'trainer',
  'training',
  'trouble',
  'trousers',
  'typical',
  'understand',
  'understanding',
  'unfortunately',
  'university',
  'unusual',
  'useful',
  'usual',
  'usually',
  'valley',
  'variety',
  'way',
  'weak',
  'wedding',
  'wet',
  'worried',
  'worry',
  'worse',
  'abandon',
  'pilot',
  'singing',
  'involve',
  'jam',
  'jazz',
  'knock',
  'know',
  'laugh',
  'laughter',
  'law',
  'learn',
  'learning',
  'lecture',
  'lend',
  'likely',
  'line',
  'link',
  'listener',
  'machine',
  'magazine',
  'major',
  'manage',
  'ambition',
  'anger',
  'anniversary',
  'anxious',
  'apparent',
  'apparently',
  'application',
  'appreciate',
  'appropriate',
  'amount',
  'annoyed',
  'annoying',
  'artificial',
  'artistic',
  'ashamed',
  'associate',
  'association',
  'arrival',
  'attempt',
  'authority',
  'backwards',
  'barrier',
  'broadcast',
  'campaign',
  'candidate',
  'capable',
  'category',
  'ceremony',
  'celebration',
  'characteristic',
  'cheerful',
  'circumstance',
  'citizen',
  'classic',
  'clause',
  'collapse',
  'collection',
  'combination',
  'platform',
  'please',
  'pleased',
  'point',
  'polite',
  'possession',
  'possibility',
  'possible',
  'pound',
  'predict',
  'prefer',
  'prepare',
  'present',
  'pretty',
  'prevent',
  'probably',
  'process',
  'produce',
  'consumer',
  'contemporary',
  'continuous',
  'contract',
  'contrast',
  'confident',
  'confirm',
  'confuse',
  'consume',
  'contact',
  'content',
  'contribute',
  'convenient',
  'convince',
  'core',
  'cottage',
  'council',
  'constant',
  'construct',
  'convert',
  'contest',
  'corporate',
  'countryside',
  'creation',
  'creature',
  'crisis',
  'criterion',
  'critic',
  'criticism',
  'criticize',
  'crucial',
  'currency',
  'county',
  'critical',
  'curved',
  'debate',
  'decoration',
  'deeply',
  'defeat',
  'single',
  'situation',
  'ski',
  'skiing',
  'skirt',
  'social',
  'society',
  'sock',
  'solution',
  'sometimes',
  'soon',
  'sort',
  'soup',
  'speaker',
  'specific',
  'spelling',
  'statement',
  'station',
  'steal',
  'detect',
  'determined',
  'development',
  'discipline',
  'dishonest',
  'dismiss',
  'distribute',
  'distribution',
  'district',
  'division',
  'documentary',
  'domestic',
  'dominate',
  'downwards',
  'draft',
  'define',
  'determine',
  'directly',
  'disappointed',
  'disappointing',
  'dislike',
  'display',
  'divide',
  'double',
  'dramatic',
  'delivery',
  'depth',
  'detail',
  'disadvantage',
  'discount',
  'document',
  'drag',
  'dressed',
  'dust',
  'eastern',
  'economic',
  'economy',
  'edge',
  'edition',
  'effective',
  'accommodation',
  'accompany',
  'accurate',
  'accuse',
  'acquire',
  'adapt',
  'admire',
  'adopt',
  'acknowledge',
  'afford',
  'afterwards',
  'agenda',
  'aggressive',
  'aircraft',
  'alter',
  'ambitious',
  'analyse',
  'analysis',
  'amazed',
  'exhibition',
  'existence',
  'expectation',
  'expense',
  'exploration',
  'expose',
  'episode',
  'equal',
  'establish',
  'evaluate',
  'examination',
  'expected',
  'expedition',
  'explosion',
  'extend',
  'extent',
  'extraordinary',
  'facility',
  'fairly',
  'familiar',
  'fascinating',
  'fashionable',
  'fasten',
  'fault',
  'estate',
  'examine',
  'exchange',
  'excuse',
  'explore',
  'fancy',
  'favour',
  'feather',
  'fee',
  'fence',
  'finance',
  'financial',
  'firm',
  'defend',
  'flame',
  'comfort',
  'command',
  'commercial',
  'commission',
  'commitment',
  'committee',
  'commonly',
  'competitor',
  'complex',
  'complicated',
  'component',
  'concentrate',
  'concept',
  'concerned',
  'conclude',
  'conclusion',
  'confidence',
  'conflict',
  'confusing',
  'conscious',
  'consequence',
  'concentration',
  'concern',
  'conduct',
  'conservative',
  'consideration',
  'consistent',
  'constantly',
  'construction',
  'holy',
  'honour',
  'host',
  'household',
  'housing',
  'humorous',
  'humour',
  'hunting',
  'hurricane',
  'hunt',
  'hurry',
  'ideal',
  'illegal',
  'illustrate',
  'illustration',
  'imaginary',
  'imagination',
  'immigrant',
  'impatient',
  'imply',
  'importance',
  'impose',
  'impressed',
  'impression',
  'identity',
  'ignore',
  'immediate',
  'impress',
  'deliberate',
  'deliberately',
  'demonstrate',
  'debt',
  'decade',
  'decent',
  'defence',
  'definition',
  'delight',
  'delighted',
  'departure',
  'depressed',
  'depressing',
  'deserve',
  'desire',
  'desperate',
  'dig',
  'disc',
  'declare',
  'decline',
  'decorate',
  'definite',
  'delay',
  'deliver',
  'demand',
  'deny',
  'destination',
  'detailed',
  'interpret',
  'interrupt',
  'investigation',
  'investment',
  'issue',
  'joy',
  'judgement',
  'junior',
  'justice',
  'justify',
  'labour',
  'largely',
  'latest',
  'leadership',
  'league',
  'level',
  'licence',
  'limited',
  'lively',
  'load',
  'loan',
  'landscape',
  'launch',
  'layer',
  'leading',
  'lean',
  'leather',
  'legal',
  'leisure',
  'effectively',
  'efficient',
  'elderly',
  'elect',
  'elsewhere',
  'emerge',
  'emphasis',
  'emphasize',
  'enable',
  'encounter',
  'engage',
  'engaged',
  'engineering',
  'enhance',
  'enquiry',
  'ensure',
  'educational',
  'embarrassed',
  'embarrassing',
  'enthusiasm',
  'enthusiastic',
  'entirely',
  'entrance',
  'essential',
  'estimate',
  'ethical',
  'eventually',
  'evil',
  'excitement',
  'executive',
  'musical',
  'moral',
  'mysterious',
  'mystery',
  'narrative',
  'national',
  'naturally',
  'neat',
  'necessarily',
  'neither',
  'nerve',
  'nevertheless',
  'nightmare',
  'notion',
  'numerous',
  'objective',
  'obligation',
  'observation',
  'observe',
  'obviously',
  'occasion',
  'occasionally',
  'offence',
  'offensive',
  'official',
  'opening',
  'operate',
  'operation',
  'flash',
  'flexible',
  'fold',
  'folding',
  'folk',
  'force',
  'forgive',
  'fortune',
  'frozen',
  'furthermore',
  'garage',
  'generate',
  'genre',
  'govern',
  'grab',
  'grade',
  'gradually',
  'grant',
  'guilty',
  'handle',
  'hardly',
  'harmful',
  'hearing',
  'heel',
  'hesitate',
  'highly',
  'historic',
  'hollow',
  'phase',
  'package',
  'passion',
  'peaceful',
  'performance',
  'persuade',
  'phenomenon',
  'philosophy',
  'pitch',
  'plain',
  'planning',
  'pleasant',
  'pleasure',
  'pile',
  'plot',
  'poetry',
  'pointed',
  'poisonous',
  'popularity',
  'portrait',
  'possess',
  'possibly',
  'potential',
  'poverty',
  'powerful',
  'practical',
  'impressive',
  'improvement',
  'inch',
  'incident',
  'income',
  'increasingly',
  'incredibly',
  'indeed',
  'indicate',
  'indirect',
  'indoor',
  'indoors',
  'industrial',
  'infection',
  'influence',
  'hurt',
  'import',
  'inform',
  'ingredient',
  'initiative',
  'injure',
  'injured',
  'inner',
  'innocent',
  'insight',
  'insist',
  'inspire',
  'install',
  'instance',
  'institute',
  'institution',
  'insurance',
  'intelligence',
  'intend',
  'intended',
  'impact',
  'initial',
  'initially',
  'intense',
  'internal',
  'publication',
  'pupil',
  'purchase',
  'pure',
  'pursue',
  'qualification',
  'print',
  'production',
  'profession',
  'proper',
  'properly',
  'proposal',
  'propose',
  'prospect',
  'protection',
  'protest',
  'psychologist',
  'psychology',
  'literature',
  'lung',
  'lord',
  'lower',
  'maintain',
  'majority',
  'massive',
  'matching',
  'maximum',
  'means',
  'meanwhile',
  'measurement',
  'medium',
  'melt',
  'mineral',
  'minimum',
  'minor',
  'minority',
  'mission',
  'mistake',
  'measure',
  'mental',
  'mess',
  'mild',
  'mix',
  'mixed',
  'mixture',
  'model',
  'modify',
  'monitor',
  'motor',
  'move',
  'mud',
  'multiple',
  'multiply',
  'muscle',
  'reward',
  'rhythm',
  'rid',
  'root',
  'round',
  'routine',
  'relevant',
  'relief',
  'resolve',
  'resort',
  'responsibility',
  'responsible',
  'retain',
  'reveal',
  'revolution',
  'scream',
  'screen',
  'seed',
  'sense',
  'sensitive',
  'opponent',
  'oppose',
  'opposed',
  'nation',
  'native',
  'needle',
  'neighbourhood',
  'nuclear',
  'obey',
  'object',
  'obtain',
  'obvious',
  'occur',
  'offend',
  'opposition',
  'organ',
  'organized',
  'organizer',
  'origin',
  'originally',
  'otherwise',
  'outer',
  'outline',
  'overall',
  'owe',
  'pace',
  'pale',
  'panel',
  'parliament',
  'participant',
  'participate',
  'particularly',
  'partly',
  'passage',
  'pension',
  'permanent',
  'permit',
  'perspective',
  'suspect',
  'swear',
  'sweep',
  'switch',
  'sympathy',
  'symptom',
  'tale',
  'talented',
  'tank',
  'silence',
  'sincere',
  'slide',
  'slightly',
  'software',
  'somewhat',
  'specifically',
  'spoken',
  'sponsor',
  'spot',
  'spread',
  'praise',
  'prediction',
  'preparation',
  'presence',
  'preserve',
  'pressure',
  'previous',
  'previously',
  'priest',
  'prime',
  'printing',
  'priority',
  'prisoner',
  'privacy',
  'procedure',
  'perfectly',
  'policy',
  'politician',
  'prepared',
  'presentation',
  'pretend',
  'private',
  'principle',
  'thus',
  'tough',
  'trade',
  'translate',
  'translation',
  'treat',
  'treatment',
  'uncomfortable',
  'unconscious',
  'unemployed',
  'unemployment',
  'unexpected',
  'unfair',
  'union',
  'unique',
  'universe',
  'unnecessary',
  'unpleasant',
  'upset',
  'upwards',
  'qualified',
  'queue',
  'range',
  'rapid',
  'rapidly',
  'rarely',
  'raw',
  'realistic',
  'reasonable',
  'recall',
  'recover',
  'reduction',
  'reference',
  'regard',
  'regional',
  'register',
  'regret',
  'regulation',
  'rate',
  'receipt',
  'recommendation',
  'reflect',
  'regularly',
  'relative',
  'relatively',
  'relaxing',
  'release',
  'reliable',
  'religion',
  'religious',
  'rely',
  'remark',
  'repeated',
  'represent',
  'representative',
  'reputation',
  'require',
  'requirement',
  'rescue',
  'reserve',
  'resident',
  'resist',
  'respect',
  'retired',
  'revise',
  'sentence',
  'sequence',
  'session',
  'settle',
  'severe',
  'shade',
  'shadow',
  'shallow',
  'shame',
  'shape',
  'shell',
  'shift',
  'shocked',
  'sight',
  'significant',
  'significantly',
  'similarity',
  'slave',
  'slight',
  'slip',
  'slope',
  'solar',
  'specialist',
  'species',
  'spending',
  'spirit',
  'spiritual',
  'split',
  'spring',
  'stare',
  'statistic',
  'steady',
  'steep',
  'sticky',
  'stiff',
  'stock',
  'stream',
  'strict',
  'strike',
  'struggle',
  'subject',
  'substance',
  'successfully',
  'sum',
  'surgery',
  'surround',
  'surrounding',
  'stable',
  'stage',
  'stand',
  'status',
  'steel',
  'step',
  'violence',
  'tax',
  'tear',
  'technical',
  'technique',
  'temporary',
  'theme',
  'theory',
  'therapy',
  'threat',
  'threaten',
  'throat',
  'tiny',
  'tone',
  'transfer',
  'transform',
  'transition',
  'trial',
  'trip',
  'tropical',
  'truly',
  'tune',
  'tunnel',
  'ultimately',
  'self',
  'shelter',
  'soul',
  'southern',
  'standard',
  'stretch',
  'stuff',
  'submit',
  'suffer',
  'summarize',
  'summary',
  'surely',
  'tail',
  'target',
  'urban',
  'urge',
  'value',
  'vary',
  'vast',
  'venue',
  'version',
  'victim',
  'victory',
  'viewer',
  'violent',
  'virtual',
  'vision',
  'visual',
  'vital',
  'volume',
  'wage',
  'wealth',
  'wealthy',
  'whisper',
  'widely',
  'wildlife',
  'willing',
  'wire',
  'wise',
  'witness',
  'worldwide',
  'worth',
  'wound',
  'wrap',
  'yard',
  'youth',
  'zone',
];
