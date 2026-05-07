import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

class StatsStripSection extends StatelessWidget {
  const StatsStripSection({super.key});

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
          decoration: BoxDecoration(
            color: const Color(0xFFFFF9F5), // Light orange/beige background
            borderRadius: BorderRadius.circular(16),
          ),
          child: isDesktop
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildStatItem(Icons.groups_outlined, '10,000+', 'Active Learners'),
                    _buildStatItem(Icons.assignment_turned_in_outlined, '500K+', 'Assessments Completed'),
                    _buildStatItem(Icons.bar_chart, '95%', 'Learner Satisfaction'),
                    _buildStatItem(Icons.language, '20+', 'Countries Reached'),
                  ],
                )
              : Column(
                  children: [
                    _buildStatItem(Icons.groups_outlined, '10,000+', 'Active Learners'),
                    const SizedBox(height: 32),
                    _buildStatItem(Icons.assignment_turned_in_outlined, '500K+', 'Assessments Completed'),
                    const SizedBox(height: 32),
                    _buildStatItem(Icons.bar_chart, '95%', 'Learner Satisfaction'),
                    const SizedBox(height: 32),
                    _buildStatItem(Icons.language, '20+', 'Countries Reached'),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String value, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: const Color(0xFFE86B32), size: 40),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: AppTextStyles.heroHeading.copyWith(fontSize: 24, letterSpacing: -0.5, color: AppColors.black),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.charcoal, fontSize: 12),
            ),
          ],
        ),
      ],
    );
  }
}
