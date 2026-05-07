import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

class FeaturesSection extends StatelessWidget {
  const FeaturesSection({super.key});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isDesktop = width > 900;

    return Container(
      color: AppColors.white,
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 64 : 20,
        vertical: 40,
      ),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 1200),
          padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
          decoration: const BoxDecoration(
            border: Border(
              top: BorderSide(color: Color(0xFFF0F0F0), width: 1),
              bottom: BorderSide(color: Color(0xFFF0F0F0), width: 1),
            ),
          ),
          child: isDesktop
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(child: _buildFeatureItem(Icons.verified_user_outlined, 'Expert-Designed\nLearning System')),
                    Expanded(child: _buildFeatureItem(Icons.grid_view, 'Interactive & Practical\nModules')),
                    Expanded(child: _buildFeatureItem(Icons.person_outline, 'Personalized\nLearning Path')),
                    Expanded(child: _buildFeatureItem(Icons.trending_up, 'Real-Time Feedback &\nContinuous Improvement')),
                  ],
                )
              : Column(
                  children: [
                    _buildFeatureItem(Icons.verified_user_outlined, 'Expert-Designed Learning System'),
                    const SizedBox(height: 24),
                    _buildFeatureItem(Icons.grid_view, 'Interactive & Practical Modules'),
                    const SizedBox(height: 24),
                    _buildFeatureItem(Icons.person_outline, 'Personalized Learning Path'),
                    const SizedBox(height: 24),
                    _buildFeatureItem(Icons.trending_up, 'Real-Time Feedback & Continuous Improvement'),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildFeatureItem(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFFE86B32).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: const Color(0xFFE86B32), size: 28),
        ),
        const SizedBox(width: 16),
        Text(
          text,
          style: AppTextStyles.cardTitle.copyWith(fontSize: 13, height: 1.4),
        ),
      ],
    );
  }
}
