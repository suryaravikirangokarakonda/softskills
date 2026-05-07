import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

class CtaSection extends StatelessWidget {
  const CtaSection({super.key});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isDesktop = width > 900;

    return Container(
      width: double.infinity,
      margin: EdgeInsets.symmetric(
        horizontal: isDesktop ? 64 : 20,
        vertical: 40,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A), // Dark navy blue
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: isDesktop ? _buildDesktopLayout(context) : _buildMobileLayout(context),
    );
  }

  Widget _buildDesktopLayout(BuildContext context) {
    return SizedBox(
      height: 280,
      child: Stack(
        children: [
          // Left chat bubbles
          Positioned(
            left: -40,
            bottom: 20,
            child: _buildChatBubbles(),
          ),
          // Center Text
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 200),
              child: _buildTextAndButtons(context, CrossAxisAlignment.center, TextAlign.center),
            ),
          ),
          // Right image
          Positioned(
            right: 0,
            bottom: 0,
            top: 0,
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                topRight: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
              child: Image.asset(
                'assets/images/scene3.png',
                width: 300,
                fit: BoxFit.cover,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileLayout(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(32),
          child: _buildTextAndButtons(context, CrossAxisAlignment.center, TextAlign.center),
        ),
        ClipRRect(
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(16),
            bottomRight: Radius.circular(16),
          ),
          child: Image.asset(
            'assets/images/scene3.png',
            height: 200,
            width: double.infinity,
            fit: BoxFit.cover,
          ),
        ),
      ],
    );
  }

  Widget _buildChatBubbles() {
    return SizedBox(
      width: 200,
      height: 200,
      child: Stack(
        children: [
          Positioned(
            top: 40,
            left: 80,
            child: _buildBubble(Colors.white, const Color(0xFF0F172A)),
          ),
          Positioned(
            bottom: 40,
            left: 40,
            child: _buildBubble(const Color(0xFFE86B32), Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildBubble(Color bgColor, Color dotColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildDot(dotColor),
          const SizedBox(width: 4),
          _buildDot(dotColor),
          const SizedBox(width: 4),
          _buildDot(dotColor),
        ],
      ),
    );
  }

  Widget _buildDot(Color color) {
    return Container(
      width: 6,
      height: 6,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }

  Widget _buildTextAndButtons(BuildContext context, CrossAxisAlignment crossAxisAlignment, TextAlign textAlign) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: crossAxisAlignment,
      children: [
        Text(
          'Ready to Transform Your\nCommunication Skills?',
          textAlign: textAlign,
          style: AppTextStyles.heroHeading.copyWith(fontSize: 28, color: Colors.white, height: 1.2),
        ),
        const SizedBox(height: 16),
        Text(
          'Join thousands of learners who are speaking with clarity,\nconfidence, and impact.',
          textAlign: textAlign,
          style: AppTextStyles.bodyText.copyWith(color: Colors.white70, fontSize: 13),
        ),
        const SizedBox(height: 32),
        Wrap(
          alignment: textAlign == TextAlign.center ? WrapAlignment.center : WrapAlignment.start,
          spacing: 16,
          runSpacing: 12,
          children: [
            ElevatedButton(
              onPressed: () => Navigator.pushNamed(context, '/personalized-learning'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE86B32),
                foregroundColor: AppColors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
                elevation: 0,
              ),
              child: Text(
                'Start 14-Day Assessment',
                style: AppTextStyles.buttonText.copyWith(
                  color: AppColors.white,
                ),
              ),
            ),
            OutlinedButton(
              onPressed: () => Navigator.pushNamed(context, '/contact'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: Colors.transparent,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
                side: const BorderSide(color: Colors.white, width: 1.5),
              ),
              child: Text(
                'Enterprise Demo',
                style: AppTextStyles.buttonText.copyWith(color: Colors.white),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
