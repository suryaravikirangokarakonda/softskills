import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

class AboutSection extends StatelessWidget {
  const AboutSection({super.key});

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
          child: isDesktop
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      flex: 4,
                      child: _buildImageSection(),
                    ),
                    const SizedBox(width: 80),
                    Expanded(
                      flex: 6,
                      child: _buildTextContent(),
                    ),
                  ],
                )
              : Column(
                  children: [
                    _buildImageSection(),
                    const SizedBox(height: 48),
                    _buildTextContent(),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildImageSection() {
    return SizedBox(
      height: 400,
      child: Stack(
        children: [
          // Main Image
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              image: const DecorationImage(
                image: AssetImage('assets/images/about_main.png'),
                fit: BoxFit.cover,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
          ),
          // Floating Chat Bubble
          Positioned(
            bottom: -15,
            left: -15,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: BoxDecoration(
                color: const Color(0xFFE86B32), // Orange
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                  bottomLeft: Radius.circular(4),
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFE86B32).withOpacity(0.3),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Icon(Icons.more_horiz, color: Colors.white, size: 32),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'About SoftSkills Empowerment',
          style: AppTextStyles.heroHeading.copyWith(fontSize: 32),
        ),
        const SizedBox(height: 32),
        _buildParagraph(
          'SoftSkills Empowerment is an AI-powered communication platform designed to transform how individuals ',
          'think, speak, and express ideas',
          ' in real-world situations.',
        ),
        const SizedBox(height: 16),
        _buildParagraph(
          'Instead of traditional learning methods, our system actively ',
          'analyzes how you communicate',
          ' — evaluating your vocabulary, sentence structure, idea flow, and confidence from every response you give.',
        ),
        const SizedBox(height: 16),
        _buildParagraph(
          'Based on this deep analysis, the platform dynamically guides you through ',
          'targeted practice modules',
          ' such as vocabulary building, image-based storytelling, real-life roleplay, and AI-driven conversations.',
        ),
        const SizedBox(height: 16),
        _buildParagraph(
          'Each module is part of a ',
          'connected learning system',
          ' that tracks your progress, identifies skill gaps, and continuously improves your communication ability step by step.',
        ),
        const SizedBox(height: 16),
        _buildParagraph(
          'The result is a structured, intelligent learning experience where you don\'t just learn English — you develop ',
          'clarity of thought, confidence in speaking, and the ability to communicate effectively',
          ' in any situation.',
        ),
      ],
    );
  }

  Widget _buildParagraph(String part1, String highlight, String part2) {
    return RichText(
      text: TextSpan(
        style: AppTextStyles.bodyText.copyWith(color: AppColors.charcoal, height: 1.6, fontSize: 14),
        children: [
          TextSpan(text: part1),
          TextSpan(
            text: highlight,
            style: const TextStyle(
              color: Color(0xFFE86B32),
              fontWeight: FontWeight.bold,
            ),
          ),
          TextSpan(text: part2),
        ],
      ),
    );
  }
}
