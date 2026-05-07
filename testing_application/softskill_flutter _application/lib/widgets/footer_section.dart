import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

class FooterSection extends StatelessWidget {
  const FooterSection({super.key});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isDesktop = width > 900;

    return Container(
      color: AppColors.white,
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 48 : 20,
        vertical: 60,
      ),
      child: Column(
        children: [
          isDesktop ? _buildDesktopFooter() : _buildMobileFooter(),
          const SizedBox(height: 48),
          const Divider(color: AppColors.borderGray, height: 1),
          const SizedBox(height: 24),
          _buildBottomBar(isDesktop),
        ],
      ),
    );
  }

  Widget _buildDesktopFooter() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Logo + description
        Expanded(
          flex: 3,
          child: _buildBrandColumn(),
        ),
        const SizedBox(width: 48),
        // Links columns
        Expanded(flex: 2, child: _buildLinksColumn('PRODUCT', ['Dashboard', 'Modules', 'Pricing', 'Enterprise'])),
        Expanded(flex: 2, child: _buildLinksColumn('COMPANY', ['About Us', 'Careers', 'Contact', 'Blog'])),
        Expanded(flex: 2, child: _buildLinksColumn('LEGAL', ['Privacy Policy', 'Terms', 'Cookie Policy'])),
        Expanded(flex: 2, child: _buildLinksColumn('CONNECT', ['Twitter', 'LinkedIn', 'GitHub'])),
      ],
    );
  }

  Widget _buildMobileFooter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildBrandColumn(),
        const SizedBox(height: 32),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: _buildLinksColumn('PRODUCT', ['Dashboard', 'Modules', 'Pricing', 'Enterprise'])),
            Expanded(child: _buildLinksColumn('COMPANY', ['About Us', 'Careers', 'Contact', 'Blog'])),
          ],
        ),
        const SizedBox(height: 24),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: _buildLinksColumn('LEGAL', ['Privacy Policy', 'Terms', 'Cookie Policy'])),
            Expanded(child: _buildLinksColumn('CONNECT', ['Twitter', 'LinkedIn', 'GitHub'])),
          ],
        ),
      ],
    );
  }

  Widget _buildBrandColumn() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'SOFTSKILL',
              style: AppTextStyles.navLink.copyWith(
                color: AppColors.primaryRed,
                fontWeight: FontWeight.w900,
                fontSize: 14,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              'DEVELOPMENT',
              style: AppTextStyles.navLink.copyWith(
                fontWeight: FontWeight.w900,
                fontSize: 14,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: 280,
          child: Text(
            'The next generation of professional development powered by artificial intelligence.',
            style: AppTextStyles.bodySmall,
          ),
        ),
      ],
    );
  }

  Widget _buildLinksColumn(String title, List<String> links) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: AppTextStyles.footerHeading),
        const SizedBox(height: 16),
        ...links.map((link) => Padding(
          padding: const EdgeInsets.only(bottom: 2),
          child: Text(link, style: AppTextStyles.footerLink),
        )),
      ],
    );
  }

  Widget _buildBottomBar(bool isDesktop) {
    return Row(
      children: [
        Text(
          '© 2024 SOFTSKILL EMPOWERMENT. ALL RIGHTS RESERVED.',
          style: AppTextStyles.label.copyWith(
            color: AppColors.bodyGray,
            fontSize: 10,
            letterSpacing: 1.0,
          ),
        ),
        const Spacer(),
        if (isDesktop)
          Row(
            children: [
              _buildSocialIcon(Icons.close), // X/Twitter
              const SizedBox(width: 12),
              _buildSocialIcon(Icons.link),
              const SizedBox(width: 12),
              _buildSocialIcon(Icons.code),
            ],
          ),
      ],
    );
  }

  Widget _buildSocialIcon(IconData icon) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.borderGray),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Icon(icon, size: 16, color: AppColors.mediumGray),
    );
  }
}
