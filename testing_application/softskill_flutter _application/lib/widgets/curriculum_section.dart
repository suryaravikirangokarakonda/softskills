import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

class CurriculumSection extends StatelessWidget {
  const CurriculumSection({super.key});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isDesktop = width > 900;

    return Container(
      color: AppColors.white,
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 64 : 20,
        vertical: 80,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Header
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Our Learning Modules',
                      style: isDesktop
                          ? AppTextStyles.heroHeading.copyWith(fontSize: 32, letterSpacing: -1.0)
                          : AppTextStyles.heroHeading.copyWith(fontSize: 28, letterSpacing: -1.0),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Comprehensive modules designed to improve every aspect of your communication.',
                      style: AppTextStyles.bodyText.copyWith(fontSize: 14),
                    ),
                  ],
                ),
              ),
              if (isDesktop)
                Row(
                  children: [
                    _buildArrowButton(Icons.arrow_back),
                    const SizedBox(width: 8),
                    _buildArrowButton(Icons.arrow_forward),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 48),
          // Modules Row/List
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildModuleCard(
                  number: '1',
                  title: 'Vocabulary &\nSentence Formation',
                  icon: Icons.text_fields,
                  iconBgColor: const Color(0xFFF96623), // Orange
                  points: [
                    'Learn to use new words naturally in real conversations',
                    'Build structured and connected sentences',
                    'Improve grammar and speaking clarity',
                    'Develop soft skill-based communication (leadership, teamwork)',
                  ],
                  focus: 'Fluency + Vocabulary Depth',
                  focusColor: const Color(0xFFF96623),
                  cardBgColor: const Color(0xFFFFF9F5),
                ),
                const SizedBox(width: 20),
                _buildModuleCard(
                  number: '2',
                  title: 'Image Description\nModule',
                  icon: Icons.image_outlined,
                  iconBgColor: const Color(0xFF4CAF50), // Green
                  points: [
                    'Convert visual scenes into meaningful stories',
                    'Improve spontaneous thinking and storytelling',
                    'Learn structured speaking (beginning – middle – end)',
                    'Build emotional and logical expression',
                  ],
                  focus: 'Thinking + Storytelling Ability',
                  focusColor: const Color(0xFF4CAF50),
                  cardBgColor: const Color(0xFFF5FCF5),
                ),
                const SizedBox(width: 20),
                _buildModuleCard(
                  number: '3',
                  title: 'Role Play\nModule',
                  icon: Icons.groups_outlined,
                  iconBgColor: const Color(0xFFFFB300), // Yellow/Orange
                  points: [
                    'Practice real-life communication scenarios',
                    'Improve instant response and confidence',
                    'Learn how to handle conversations naturally',
                    'Develop situational communication skills',
                  ],
                  focus: 'Confidence + Real-world Communication',
                  focusColor: const Color(0xFFFFB300),
                  cardBgColor: const Color(0xFFFFFDF5),
                ),
                const SizedBox(width: 20),
                _buildModuleCard(
                  number: '4',
                  title: 'AI Interaction\nModule',
                  icon: Icons.chat_bubble_outline,
                  iconBgColor: const Color(0xFFF44336), // Red
                  points: [
                    'Engage in open-topic conversations with AI',
                    'Improve sentence framing and idea clarity',
                    'Practice public speaking style communication',
                    'Reduce hesitation and nervousness',
                  ],
                  focus: 'Thinking Speed + Clarity',
                  focusColor: const Color(0xFFF44336),
                  cardBgColor: const Color(0xFFFFF5F5),
                ),
                const SizedBox(width: 20),
                _buildModuleCard(
                  number: '5',
                  title: 'Individual\nFeedback Module',
                  icon: Icons.person_outline,
                  iconBgColor: const Color(0xFF9C27B0), // Purple
                  points: [
                    'Get personalized feedback on every response',
                    'Understand strengths and improvement areas',
                    'Receive actionable suggestions to grow faster',
                  ],
                  focus: 'Self-Awareness + Continuous Growth',
                  focusColor: const Color(0xFF9C27B0),
                  cardBgColor: const Color(0xFFFAF5FF),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModuleCard({
    required String number,
    required String title,
    required IconData icon,
    required Color iconBgColor,
    required List<String> points,
    required String focus,
    required Color focusColor,
    required Color cardBgColor,
  }) {
    return Container(
      width: 280,
      height: 440,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cardBgColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: iconBgColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  '$number. $title',
                  style: AppTextStyles.cardTitle.copyWith(
                    fontSize: 14,
                    letterSpacing: 0,
                    height: 1.3,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          ...points.map((point) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('• ', style: TextStyle(color: AppColors.mediumGray, fontSize: 14)),
                Expanded(
                  child: Text(
                    point,
                    style: AppTextStyles.bodySmall.copyWith(
                      fontSize: 12,
                      height: 1.4,
                      color: AppColors.charcoal,
                    ),
                  ),
                ),
              ],
            ),
          )),
          const Spacer(),
          Text(
            'Focus: $focus',
            style: AppTextStyles.label.copyWith(
              color: focusColor,
              fontSize: 11,
              letterSpacing: 0,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildArrowButton(IconData icon) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.borderGray, width: 1.0),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, size: 16, color: AppColors.black),
    );
  }
}
