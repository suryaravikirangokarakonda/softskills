import 'package:flutter/material.dart';
import '../widgets/navbar.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/feedback_report_widget.dart';
import '../services/supabase_service.dart';

class IndividualFeedbackPage extends StatefulWidget {
  const IndividualFeedbackPage({super.key});

  @override
  State<IndividualFeedbackPage> createState() => _IndividualFeedbackPageState();
}

class _IndividualFeedbackPageState extends State<IndividualFeedbackPage> {
  Map<String, dynamic>? _latestPerformance;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchPerformance();
  }

  Future<void> _fetchPerformance() async {
    try {
      final userId = SupabaseService.client.auth.currentUser?.id ?? 'test_user_123';
      final history = await SupabaseService.getPerformanceHistory(userId);
      if (history.isNotEmpty) {
        setState(() {
          _latestPerformance = history.last;
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      print('Error fetching performance: $e');
      setState(() => _isLoading = false);
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
            child: Row(
              children: [
                if (isDesktop) _buildSidebar(context),
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.all(isDesktop ? 32 : 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHeader(isDesktop),
                        const SizedBox(height: 32),
                        const FeedbackReportWidget(),
                        const SizedBox(height: 32),
                        _buildScoreCards(isDesktop),
                        const SizedBox(height: 32),
                        _buildMiddleSection(isDesktop),
                        const SizedBox(height: 32),
                        _buildSessionLog(isDesktop),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // === TOP BAR ===
  Widget _buildTopBar(BuildContext context, bool isDesktop) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 24 : 16,
        vertical: 12,
      ),
      decoration: const BoxDecoration(
        color: AppColors.black,
        border: Border(bottom: BorderSide(color: AppColors.borderGray)),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.white),
            onPressed: () => Navigator.pushReplacementNamed(context, '/'),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          const SizedBox(width: 16),
          if (!isDesktop)
            IconButton(
              icon: const Icon(Icons.menu, color: AppColors.white),
              onPressed: () => Scaffold.of(context).openDrawer(),
            ),
          Text(
            'SOFTSKILL ',
            style: AppTextStyles.navLink.copyWith(
              color: AppColors.primaryRed,
              fontWeight: FontWeight.w900,
            ),
          ),
          Text(
            'DEVELOPMENT',
            style: AppTextStyles.navLink.copyWith(
              color: AppColors.white,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(width: 32),
          if (isDesktop) ...[
            _buildTopNavItem('DASHBOARD', true),
            _buildTopNavItem('MODULES', false),
            _buildTopNavItem('ASSESSMENT', false),
            _buildTopNavItem('ENTERPRISE', false),
          ],
          const Spacer(),
          const Icon(Icons.notifications_outlined, color: AppColors.white, size: 20),
          const SizedBox(width: 16),
          const Icon(Icons.settings_outlined, color: AppColors.white, size: 20),
          const SizedBox(width: 16),
          const CircleAvatar(
            radius: 14,
            backgroundColor: AppColors.primaryRed,
            child: Icon(Icons.person, size: 16, color: AppColors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildTopNavItem(String label, bool isActive) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Text(
        label,
        style: AppTextStyles.navLink.copyWith(
          color: isActive ? AppColors.primaryRed : AppColors.white,
          decoration: isActive ? TextDecoration.underline : null,
          decorationColor: AppColors.primaryRed,
        ),
      ),
    );
  }

  // === SIDEBAR ===
  Widget _buildSidebar(BuildContext context) {
    return Container(
      width: 180,
      color: AppColors.lightGray,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('SoftSkill\nDevelopment', style: AppTextStyles.cardTitle.copyWith(fontSize: 16)),
          Text('V1.0.4 PRO', style: AppTextStyles.label.copyWith(fontSize: 9, color: AppColors.bodyGray)),
          const SizedBox(height: 32),
          // Removed navigation items to focus on Individual Feedback
          const Spacer(),
          _buildSidebarItem(Icons.help_outline, 'HELP', false),
          _buildSidebarItem(Icons.logout, 'LOGOUT', false),
        ],
      ),
    );
  }

  Widget _buildSidebarItem(IconData icon, String label, bool isActive) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isActive ? AppColors.black : Colors.transparent,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: isActive ? AppColors.white : AppColors.mediumGray),
          const SizedBox(width: 10),
          Text(
            label,
            style: AppTextStyles.navLink.copyWith(
              color: isActive ? AppColors.white : AppColors.mediumGray,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileDrawer(BuildContext context) {
    return Drawer(
      backgroundColor: AppColors.lightGray,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('SoftSkill\nDevelopment', style: AppTextStyles.cardTitle.copyWith(fontSize: 16)),
                  Text('V1.0.4 PRO', style: AppTextStyles.label.copyWith(fontSize: 9, color: AppColors.bodyGray)),
                ],
              ),
            ),
            const Divider(height: 1),
            // Removed navigation items to focus on Individual Feedback
            const Spacer(),
            _buildSidebarItem(Icons.help_outline, 'HELP', false),
            _buildSidebarItem(Icons.logout, 'LOGOUT', false),
          ],
        ),
      ),
    );
  }

  // === HEADER ===
  Widget _buildHeader(bool isDesktop) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'PERFORMANCE OVERVIEW',
                style: AppTextStyles.label,
              ),
              const SizedBox(height: 8),
              Text(
                'INDIVIDUAL',
                style: isDesktop
                    ? AppTextStyles.sectionHeading.copyWith(fontSize: 48)
                    : AppTextStyles.sectionHeading.copyWith(fontSize: 32),
              ),
              Text(
                'FEEDBACK',
                style: isDesktop
                    ? AppTextStyles.sectionHeadingItalic.copyWith(
                        fontSize: 48,
                        color: AppColors.primaryRed,
                      )
                    : AppTextStyles.sectionHeadingItalic.copyWith(
                        fontSize: 32,
                        color: AppColors.primaryRed,
                      ),
              ),
            ],
          ),
        ),
        // Global ranking card
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.primaryRed,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'GLOBAL RANKING',
                style: AppTextStyles.label.copyWith(
                  color: AppColors.white.withValues(alpha: 0.8),
                  fontSize: 9,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Top 4%',
                style: AppTextStyles.sectionHeading.copyWith(
                  color: AppColors.white,
                  fontSize: 32,
                ),
              ),
              const SizedBox(height: 4),
              SizedBox(
                width: 180,
                child: Text(
                  'Outperforming 12.4k peers in Communication Precision.',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.white.withValues(alpha: 0.9),
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // === SCORE CARDS ===
  Widget _buildScoreCards(bool isDesktop) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primaryRed));
    }

    final vocab = _latestPerformance?['vocabulary_score']?.toString() ?? '0.0';
    final sentence = _latestPerformance?['sentence_formation_score']?.toString() ?? '0.0';
    final confidence = _latestPerformance?['ai_interaction_score']?.toString() ?? '0.0';

    final cards = [
      _ScoreData(Icons.chat_bubble_outline, 'VOCABULARY PRECISION', vocab, 'Update', AppColors.primaryRed),
      _ScoreData(Icons.architecture, 'STRUCTURAL FRAMING', sentence, 'Update', AppColors.primaryRed),
      _ScoreData(Icons.emoji_emotions_outlined, 'CONFIDENCE SCORE', confidence, 'Optimal', AppColors.primaryRed),
    ];

    if (isDesktop) {
      return Row(
        children: cards
            .map((c) => Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: _buildScoreCard(c),
                  ),
                ))
            .toList(),
      );
    }
    return Column(
      children: cards.map((c) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: _buildScoreCard(c),
      )).toList(),
    );
  }

  Widget _buildScoreCard(_ScoreData data) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.lightGray,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.borderGray),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(data.icon, color: AppColors.primaryRed, size: 20),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primaryRed.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  data.change,
                  style: AppTextStyles.label.copyWith(fontSize: 10, color: AppColors.primaryRed),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            data.label,
            style: AppTextStyles.label.copyWith(color: AppColors.bodyGray, fontSize: 10),
          ),
          const SizedBox(height: 8),
          Text(
            '${data.value} / 10',
            style: AppTextStyles.sectionHeading.copyWith(fontSize: 40),
          ),
          const SizedBox(height: 8),
          Container(
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.borderGray,
              borderRadius: BorderRadius.circular(2),
            ),
            child: FractionallySizedBox(
              widthFactor: (double.tryParse(data.value) ?? 0.0) / 10.0,
              alignment: Alignment.centerLeft,
              child: Container(
                decoration: BoxDecoration(
                  color: data.color,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // === MIDDLE SECTION (Chart + Recommended) ===
  Widget _buildMiddleSection(bool isDesktop) {
    if (isDesktop) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(flex: 6, child: _buildGrowthVelocity()),
          const SizedBox(width: 24),
          Expanded(flex: 4, child: _buildRecommendedModules()),
        ],
      );
    }
    return Column(
      children: [
        _buildGrowthVelocity(),
        const SizedBox(height: 24),
        _buildRecommendedModules(),
      ],
    );
  }

  Widget _buildGrowthVelocity() {
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
            children: [
              Text('GROWTH VELOCITY', style: AppTextStyles.cardTitle),
              const Spacer(),
              Row(
                children: [
                  Container(width: 8, height: 8, decoration: const BoxDecoration(color: AppColors.primaryRed, shape: BoxShape.circle)),
                  const SizedBox(width: 4),
                  Text('You', style: AppTextStyles.bodySmall.copyWith(fontSize: 11)),
                  const SizedBox(width: 12),
                  Container(width: 8, height: 8, decoration: const BoxDecoration(color: AppColors.bodyGray, shape: BoxShape.circle)),
                  const SizedBox(width: 4),
                  Text('Global Avg', style: AppTextStyles.bodySmall.copyWith(fontSize: 11)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Chart placeholder
          Container(
            height: 200,
            decoration: BoxDecoration(
              color: AppColors.lightGray,
              borderRadius: BorderRadius.circular(4),
            ),
            child: CustomPaint(
              size: const Size(double.infinity, 200),
              painter: _ChartPainter(),
            ),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.primaryRed,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text('NOW', style: AppTextStyles.buttonText.copyWith(color: AppColors.white, fontSize: 10)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendedModules() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('RECOMMENDED MODULES', style: AppTextStyles.cardTitle),
        const SizedBox(height: 16),
        _buildRecommendedCard(
          Icons.edit_outlined,
          'EXECUTIVE BREVITY',
          'Reduce filler words and improve impact in 1-on-1s.',
          '15 MINS',
        ),
        const SizedBox(height: 12),
        _buildRecommendedCard(
          Icons.chat_outlined,
          'ACTIVE SYNTHESIS',
          'Master the art of summarizing complex feedback loops.',
          '25 MINS',
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryRed,
              foregroundColor: AppColors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
              elevation: 0,
            ),
            child: Text('LAUNCH FULL TRAINING', style: AppTextStyles.buttonText.copyWith(color: AppColors.white)),
          ),
        ),
      ],
    );
  }

  Widget _buildRecommendedCard(IconData icon, String title, String desc, String time) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.borderGray),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.primaryRed, size: 18),
              const Spacer(),
              Text(time, style: AppTextStyles.label.copyWith(color: AppColors.bodyGray, fontSize: 9)),
            ],
          ),
          const SizedBox(height: 12),
          Text(title, style: AppTextStyles.cardTitle),
          const SizedBox(height: 6),
          Text(desc, style: AppTextStyles.bodySmall),
        ],
      ),
    );
  }

  // === SESSION LOG ===
  Widget _buildSessionLog(bool isDesktop) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('RECENT SESSION LOG', style: AppTextStyles.cardTitle),
            const Spacer(),
            Text('VIEW ALL HISTORY', style: AppTextStyles.label.copyWith(color: AppColors.primaryRed)),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.borderGray),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: const BoxDecoration(
                  color: AppColors.lightGray,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(8),
                    topRight: Radius.circular(8),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(flex: 3, child: Text('TIMESTAMP', style: AppTextStyles.label.copyWith(color: AppColors.bodyGray, fontSize: 9))),
                    Expanded(flex: 3, child: Text('MODULE NAME', style: AppTextStyles.label.copyWith(color: AppColors.bodyGray, fontSize: 9))),
                    Expanded(flex: 3, child: Text('PRIMARY METRIC', style: AppTextStyles.label.copyWith(color: AppColors.bodyGray, fontSize: 9))),
                    Expanded(flex: 2, child: Text('SENTIMENT', style: AppTextStyles.label.copyWith(color: AppColors.bodyGray, fontSize: 9))),
                    const SizedBox(width: 24),
                  ],
                ),
              ),
              _buildSessionRow('2023.10.24 14:30', 'PRESENTATION PITCH V4', 0.82, 'ASSERTIVE', AppColors.primaryRed),
              _buildSessionRow('2023.10.22 09:15', 'CRISIS DE-ESCALATION', 0.68, 'NEUTRAL', AppColors.bodyGray),
              _buildSessionRow('2023.10.21 16:45', 'SALARY NEGOTIATION', 0.95, 'EMPATHETIC', AppColors.primaryRed),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSessionRow(String time, String module, double metric, String sentiment, Color sentimentColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.borderGray)),
      ),
      child: Row(
        children: [
          Expanded(flex: 3, child: Text(time, style: AppTextStyles.bodySmall.copyWith(fontSize: 12))),
          Expanded(flex: 3, child: Text(module, style: AppTextStyles.cardTitle.copyWith(fontSize: 11))),
          Expanded(
            flex: 3,
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.borderGray,
                      borderRadius: BorderRadius.circular(2),
                    ),
                    child: FractionallySizedBox(
                      widthFactor: metric,
                      alignment: Alignment.centerLeft,
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColors.primaryRed,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text('${(metric * 100).toInt()}%', style: AppTextStyles.bodySmall.copyWith(fontSize: 11)),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: sentimentColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                sentiment,
                style: AppTextStyles.label.copyWith(fontSize: 9, color: sentimentColor),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          const SizedBox(width: 8),
          const Icon(Icons.arrow_forward_ios, size: 12, color: AppColors.bodyGray),
        ],
      ),
    );
  }
}

class _ScoreData {
  final IconData icon;
  final String label;
  final String value;
  final String change;
  final Color color;
  const _ScoreData(this.icon, this.label, this.value, this.change, this.color);
}

class _ChartPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // User line (red)
    final userPaint = Paint()
      ..color = AppColors.primaryRed
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final userPath = Path();
    userPath.moveTo(0, size.height * 0.8);
    userPath.cubicTo(
      size.width * 0.2, size.height * 0.7,
      size.width * 0.4, size.height * 0.5,
      size.width * 0.6, size.height * 0.35,
    );
    userPath.cubicTo(
      size.width * 0.8, size.height * 0.2,
      size.width * 0.9, size.height * 0.15,
      size.width, size.height * 0.1,
    );
    canvas.drawPath(userPath, userPaint);

    // Global avg line (gray)
    final avgPaint = Paint()
      ..color = AppColors.bodyGray
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final avgPath = Path();
    avgPath.moveTo(0, size.height * 0.75);
    avgPath.cubicTo(
      size.width * 0.2, size.height * 0.7,
      size.width * 0.5, size.height * 0.6,
      size.width * 0.7, size.height * 0.55,
    );
    avgPath.cubicTo(
      size.width * 0.85, size.height * 0.5,
      size.width * 0.95, size.height * 0.48,
      size.width, size.height * 0.45,
    );
    canvas.drawPath(avgPath, avgPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
