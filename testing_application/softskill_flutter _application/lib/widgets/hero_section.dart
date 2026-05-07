import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

class HeroSection extends StatelessWidget {
  const HeroSection({super.key});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isDesktop = width > 900;

    return Container(
      color: AppColors.white,
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 64 : 20,
        vertical: isDesktop ? 80 : 40,
      ),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: isDesktop ? _buildDesktopLayout(context) : _buildMobileLayout(context),
        ),
      ),
    );
  }

  Widget _buildDesktopLayout(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          flex: 5,
          child: _buildTextContent(context, true),
        ),
        const SizedBox(width: 64),
        Expanded(
          flex: 5,
          child: _buildVisualElement(),
        ),
      ],
    );
  }

  Widget _buildMobileLayout(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _buildTextContent(context, false),
        const SizedBox(height: 48),
        _buildVisualElement(),
      ],
    );
  }

  Widget _buildVisualElement() {
    return SizedBox(
      height: 600,
      width: double.infinity,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Dotted connecting lines
          Positioned.fill(
            child: CustomPaint(
              painter: _DottedLinesPainter(),
            ),
          ),
          // The central image container
          Container(
            width: 500, // Widened to match the landscape format of the 2nd screenshot
            height: 340,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(32),
              color: const Color(0xFFFDECE4), // Fallback color
              image: const DecorationImage(
                image: AssetImage('assets/images/hero_main.png'),
                fit: BoxFit.cover,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 24,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
          ),
          // Top Left Card
          Positioned(
            top: 20,
            left: 0,
            child: _buildFloatingCard(
              icon: Icons.mic_none,
              iconColor: const Color(0xFFE86B32),
              title: 'Speak Confidently',
              description: 'Build confidence and express your ideas effectively.',
            ),
          ),
          // Top Right Card
          Positioned(
            top: 40,
            right: 0,
            child: _buildFloatingCard(
              icon: Icons.lightbulb_outline,
              iconColor: const Color(0xFF4ADE80),
              title: 'Think Clearly',
              description: 'Organize your thoughts and communicate with clarity.',
            ),
          ),
          // Bottom Left Card
          Positioned(
            bottom: 60,
            left: 10,
            child: _buildFloatingCard(
              icon: Icons.chat_bubble_outline,
              iconColor: const Color(0xFF3B82F6),
              title: 'Practice & Improve',
              description: 'Engage in targeted modules and real-life practice.',
            ),
          ),
          // Bottom Right Card
          Positioned(
            bottom: 20,
            right: 10,
            child: _buildFloatingCard(
              icon: Icons.trending_up,
              iconColor: const Color(0xFFA855F7), // Purple icon to match 2nd screenshot
              title: 'Grow Continuously',
              description: 'Track your progress and become a confident communicator.',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String description,
  }) {
    return Container(
      width: 200,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    title,
                    style: AppTextStyles.cardTitle.copyWith(fontSize: 13, height: 1.2),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            description,
            style: AppTextStyles.bodySmall.copyWith(fontSize: 11, color: AppColors.charcoal, height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildTextContent(BuildContext context, bool isDesktop) {
    return Column(
      crossAxisAlignment: isDesktop ? CrossAxisAlignment.start : CrossAxisAlignment.center,
      children: [
        // Tag
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFFFDECE4), // Light orange background
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            'AI-POWERED COMMUNICATION PLATFORM',
            style: AppTextStyles.label.copyWith(
              fontSize: 10,
              letterSpacing: 1.0,
              color: const Color(0xFFE86B32),
            ),
          ),
        ),
        const SizedBox(height: 32),
        // Heading
        RichText(
          textAlign: isDesktop ? TextAlign.start : TextAlign.center,
          text: TextSpan(
            style: isDesktop
                ? AppTextStyles.heroHeading.copyWith(fontSize: 64, letterSpacing: -2.0, color: const Color(0xFF1E293B))
                : AppTextStyles.heroHeading.copyWith(fontSize: 48, letterSpacing: -1.5, color: const Color(0xFF1E293B)),
            children: const [
              TextSpan(text: 'Master Your\nSoftSkills with\n'),
              TextSpan(
                text: 'SoftSkills\nEmpowerment.',
                style: TextStyle(color: Color(0xFFE86B32)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        // Subtitle
        SizedBox(
          width: isDesktop ? 500 : double.infinity,
          child: Text(
            'AI-driven learning that helps you think clearly, speak confidently, and communicate effectively in real-world situations.',
            textAlign: isDesktop ? TextAlign.start : TextAlign.center,
            style: AppTextStyles.bodyText.copyWith(color: AppColors.bodyGray, height: 1.5),
          ),
        ),
        const SizedBox(height: 36),
        // Buttons
        Wrap(
          alignment: isDesktop ? WrapAlignment.start : WrapAlignment.center,
          spacing: 16,
          runSpacing: 16,
          children: [
            ElevatedButton(
              onPressed: () => Navigator.pushNamed(context, '/personalized-learning'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE86B32),
                foregroundColor: AppColors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                elevation: 0,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Start Free Assessment',
                    style: AppTextStyles.buttonText.copyWith(color: AppColors.white),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.arrow_forward, size: 16, color: Colors.white),
                ],
              ),
            ),
            OutlinedButton(
              onPressed: () => Navigator.pushNamed(context, '/personalized-learning'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.charcoal,
                backgroundColor: AppColors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                side: const BorderSide(color: AppColors.charcoal, width: 1.5),
              ),
              child: Text(
                'View Curriculum',
                style: AppTextStyles.buttonText.copyWith(color: AppColors.charcoal),
              ),
            ),
          ],
        ),
        const SizedBox(height: 48),
        // Trusted by / Join thousands
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFDECE4),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.person_outline, color: Color(0xFFE86B32)),
            ),
            const SizedBox(width: 16),
            Text(
              'Join thousands of learners\nimproving their communication skills',
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.charcoal, height: 1.4),
            ),
          ],
        ),
      ],
    );
  }
}

class _DottedLinesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFE0E0E0)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    void drawDashedPath(Path path) {
      const dashWidth = 6.0;
      const dashSpace = 6.0;
      double distance = 0.0;
      for (ui.PathMetric pathMetric in path.computeMetrics()) {
        while (distance < pathMetric.length) {
          canvas.drawPath(
            pathMetric.extractPath(distance, distance + dashWidth),
            paint,
          );
          distance += dashWidth + dashSpace;
        }
        distance = 0.0;
      }
    }

    // Top left connecting line
    final path1 = Path();
    path1.moveTo(100, 80);
    path1.quadraticBezierTo(size.width / 2, 40, size.width / 2, size.height / 2);
    drawDashedPath(path1);

    // Top right connecting line
    final path2 = Path();
    path2.moveTo(size.width - 100, 100);
    path2.quadraticBezierTo(size.width / 2, 60, size.width / 2, size.height / 2);
    drawDashedPath(path2);

    // Bottom left connecting line
    final path3 = Path();
    path3.moveTo(110, size.height - 120);
    path3.quadraticBezierTo(size.width / 2, size.height - 60, size.width / 2, size.height / 2);
    drawDashedPath(path3);

    // Bottom right connecting line
    final path4 = Path();
    path4.moveTo(size.width - 110, size.height - 80);
    path4.quadraticBezierTo(size.width / 2, size.height - 40, size.width / 2, size.height / 2);
    drawDashedPath(path4);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

