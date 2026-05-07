import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

class WhyLearnersLoveSection extends StatelessWidget {
  const WhyLearnersLoveSection({super.key});

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
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Column(
            children: [
              _buildHeader(),
              const SizedBox(height: 64),
              isDesktop
                  ? IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(child: _buildCard(
                            number: '1',
                            icon: Icons.person_outline,
                            iconColor: const Color(0xFFE86B32),
                            bgColor: const Color(0xFFFFF9F5),
                            title: 'Personalized Learning',
                            desc: 'Our platform creates a personalized learning path for every student based on their performance, strengths, and areas of improvement.',
                          )),
                          const SizedBox(width: 20),
                          Expanded(child: _buildCard(
                            number: '2',
                            icon: Icons.people_outline,
                            iconColor: const Color(0xFF3B82F6),
                            bgColor: const Color(0xFFF5F9FF),
                            title: 'Human in the Loop',
                            desc: 'We actively involve human guidance throughout the learning process to ensure feedback is accurate, meaningful, and aligned with real-world communication.',
                          )),
                          const SizedBox(width: 20),
                          Expanded(child: _buildCard(
                            number: '3',
                            icon: Icons.stars_outlined,
                            iconColor: const Color(0xFF4ADE80),
                            bgColor: const Color(0xFFF5FCF5),
                            title: 'Individual Feedback',
                            desc: 'Every student receives detailed, individual feedback on their performance to help them understand mistakes and improve effectively.',
                          )),
                          const SizedBox(width: 20),
                          Expanded(child: _buildCard(
                            number: '4',
                            icon: Icons.workspace_premium_outlined,
                            iconColor: const Color(0xFFA855F7),
                            bgColor: const Color(0xFFFAF5FF),
                            title: 'Learning with\nProven Approach',
                            desc: 'Our modules are built on a proven learning approach designed to develop real communication skills through structured practice and continuous improvement.',
                          )),
                        ],
                      ),
                    )
                  : Column(
                      children: [
                        _buildCard(
                          number: '1',
                          icon: Icons.person_outline,
                          iconColor: const Color(0xFFE86B32),
                          bgColor: const Color(0xFFFFF9F5),
                          title: 'Personalized Learning',
                          desc: 'Our platform creates a personalized learning path for every student based on their performance, strengths, and areas of improvement.',
                        ),
                        const SizedBox(height: 24),
                        _buildCard(
                          number: '2',
                          icon: Icons.people_outline,
                          iconColor: const Color(0xFF3B82F6),
                          bgColor: const Color(0xFFF5F9FF),
                          title: 'Human in the Loop',
                          desc: 'We actively involve human guidance throughout the learning process to ensure feedback is accurate, meaningful, and aligned with real-world communication.',
                        ),
                        const SizedBox(height: 24),
                        _buildCard(
                          number: '3',
                          icon: Icons.stars_outlined,
                          iconColor: const Color(0xFF4ADE80),
                          bgColor: const Color(0xFFF5FCF5),
                          title: 'Individual Feedback',
                          desc: 'Every student receives detailed, individual feedback on their performance to help them understand mistakes and improve effectively.',
                        ),
                        const SizedBox(height: 24),
                        _buildCard(
                          number: '4',
                          icon: Icons.workspace_premium_outlined,
                          iconColor: const Color(0xFFA855F7),
                          bgColor: const Color(0xFFFAF5FF),
                          title: 'Learning with\nProven Approach',
                          desc: 'Our modules are built on a proven learning approach designed to develop real communication skills through structured practice and continuous improvement.',
                        ),
                      ],
                    ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        RichText(
          textAlign: TextAlign.center,
          text: TextSpan(
            style: AppTextStyles.heroHeading.copyWith(fontSize: 32, color: AppColors.black),
            children: const [
              TextSpan(text: 'Why Learners '),
              TextSpan(
                text: 'Love',
                style: TextStyle(
                  color: Color(0xFFE86B32),
                ),
              ),
              TextSpan(text: ' Our Platform'),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'A smarter way to build communication skills that stay with you for life.',
          style: AppTextStyles.bodyText.copyWith(color: AppColors.bodyGray, fontSize: 16),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildCard({
    required String number,
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
    required String title,
    required String desc,
  }) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: bgColor,
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
                  color: iconColor,
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
                    fontWeight: FontWeight.bold,
                    height: 1.3,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            desc,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.charcoal, 
              height: 1.7,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}
