import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../services/supabase_service.dart';
import '../widgets/navbar.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  bool _isLoading = true;
  Map<String, dynamic>? _latestPerformance;
  List<Map<String, dynamic>> _history = [];
  final String _userId = SupabaseService.client.auth.currentUser?.id ?? 'test_user_123';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final history = await SupabaseService.getPerformanceHistory(_userId);
    setState(() {
      _history = history;
      if (history.isNotEmpty) {
        _latestPerformance = history.last;
      }
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 1100;

    return Scaffold(
      backgroundColor: const Color(0xFFFDF7F2), // Warm beige background from image
      appBar: !isDesktop ? const Navbar() : null,
      endDrawer: !isDesktop ? const MobileDrawer() : null,
      body: Row(
        children: [
          if (isDesktop) _buildSidebar(),
          Expanded(
            child: _isLoading 
              ? const Center(child: CircularProgressIndicator(color: AppColors.primaryRed))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(),
                      const SizedBox(height: 32),
                      _buildTopSection(isDesktop),
                      const SizedBox(height: 32),
                      _buildRecommendedModules(),
                      const SizedBox(height: 32),
                      _buildBottomSection(isDesktop),
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
      width: 280,
      color: const Color(0xFFFDF7F2),
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primaryRed.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.auto_awesome, color: AppColors.primaryRed),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('SoftSkill', style: AppTextStyles.cardTitle.copyWith(fontSize: 18, color: AppColors.charcoal)),
                  Text('Development', style: AppTextStyles.bodySmall.copyWith(fontSize: 12)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 48),
          _buildSidebarItem(Icons.grid_view_rounded, 'Dashboard', isActive: true),
          _buildSidebarItem(Icons.settings_outlined, 'Settings'),
          const SizedBox(height: 16),
          _buildSidebarItem(
            Icons.refresh_rounded, 
            'Retake Assessment', 
            onTap: () async {
              await SupabaseService.clearPerformanceHistory(_userId);
              if (mounted) {
                Navigator.pushReplacementNamed(context, '/personalized-learning');
              }
            }
          ),
          const Spacer(),
          _buildKeepItUpCard(),
        ],
      ),
    );
  }

  Widget _buildSidebarItem(IconData icon, String title, {bool isActive = false, VoidCallback? onTap}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isActive ? AppColors.primaryRed.withOpacity(0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Icon(icon, color: isActive ? AppColors.primaryRed : AppColors.bodyGray),
        title: Text(
          title,
          style: TextStyle(
            color: isActive ? AppColors.primaryRed : AppColors.bodyGray,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _buildKeepItUpCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF0E7),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.star, color: Color(0xFFE67E22)),
          const SizedBox(height: 12),
          Text('Keep it up!', style: AppTextStyles.cardTitle.copyWith(fontSize: 14)),
          const SizedBox(height: 8),
          Text(
            'Consistency is the key to mastering communication skills.',
            style: AppTextStyles.bodySmall.copyWith(fontSize: 12, height: 1.5),
          ),
          const SizedBox(height: 16),
          // Mock illustration
          Container(
            height: 60,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(child: Icon(Icons.people_outline, color: AppColors.primaryRed)),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Dashboard', style: AppTextStyles.heroHeading.copyWith(fontSize: 32, color: AppColors.charcoal)),
            const SizedBox(height: 4),
            Text('Your personalized learning overview', style: AppTextStyles.bodyText.copyWith(color: AppColors.bodyGray)),
          ],
        ),
        const Spacer(),
        _buildAutoUpdateStatus(),
        const SizedBox(width: 24),
        _buildUserIcon(),
      ],
    );
  }

  Widget _buildAutoUpdateStatus() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: Row(
        children: [
          const Icon(Icons.sync, color: AppColors.bodyGray, size: 20),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Auto update', style: AppTextStyles.bodySmall.copyWith(fontSize: 10)),
              Text('Every 3 days', style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.bold, fontSize: 12)),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: SizedBox(height: 24, child: VerticalDivider(color: AppColors.borderGray)),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Next update in', style: AppTextStyles.bodySmall.copyWith(fontSize: 10)),
              Text('02d : 15h', style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.bold, fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUserIcon() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
          ),
          child: const Icon(Icons.person_outline, color: AppColors.bodyGray),
        ),
        const SizedBox(width: 12),
        Text('Ravi Kumar', style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.bold, color: AppColors.charcoal)),
        const Icon(Icons.keyboard_arrow_down, color: AppColors.bodyGray),
      ],
    );
  }

  Widget _buildTopSection(bool isDesktop) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(flex: 3, child: _buildUserProfileCard()),
        const SizedBox(width: 32),
        Expanded(flex: 7, child: _buildProgressComparison()),
      ],
    );
  }

  Widget _buildUserProfileCard() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 20)],
      ),
      child: Column(
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFFDAB9), Color(0xFFFFF1EB)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Text('R', style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: Color(0xFFE67E22))),
            ),
          ),
          const SizedBox(height: 20),
          Text('Ravi Kumar', style: AppTextStyles.cardTitle.copyWith(fontSize: 22)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF0E7),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text('Intermediate', style: TextStyle(color: Color(0xFFE67E22), fontWeight: FontWeight.bold, fontSize: 12)),
          ),
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildUserStat('Streak', '7 Days', Icons.local_fire_department),
              _buildUserStat('Confidence', '72%', Icons.psychology),
              _buildUserStat('Total Practice', '18 Sessions', Icons.history),
            ],
          ),
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFFDF7F2),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFFEF0E7)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.format_quote, color: Color(0xFFE67E22), size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Great progress! Keep practicing consistently to reach the next level.',
                    style: AppTextStyles.bodySmall.copyWith(height: 1.5, fontStyle: FontStyle.italic),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserStat(String label, String value, IconData icon) {
    String displayValue = value;
    if (label == 'Confidence' && _latestPerformance != null) {
      final score = (_latestPerformance!['ai_interaction_score'] ?? 0.0) as double;
      displayValue = '${(score * 10).toInt()}%';
    }
    return Column(
      children: [
        Text(label, style: AppTextStyles.bodySmall.copyWith(fontSize: 10)),
        const SizedBox(height: 4),
        Row(
          children: [
            Text(displayValue, style: AppTextStyles.cardTitle.copyWith(fontSize: 14)),
            if (label == 'Streak') const SizedBox(width: 4),
            if (label == 'Streak') Icon(icon, size: 14, color: Colors.orange),
          ],
        ),
      ],
    );
  }

  Widget _buildProgressComparison() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 20)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Progress Comparison', style: AppTextStyles.cardTitle),
                  Text('Current vs Previous 3 Days', style: AppTextStyles.bodySmall),
                ],
              ),
              _buildPeriodDropdown(),
            ],
          ),
          const SizedBox(height: 32),
          Row(
            children: [
              Expanded(child: _buildComparisonBar('Fluency', 'image_narration_score')),
              Expanded(child: _buildComparisonBar('Vocabulary', 'vocabulary_score')),
              Expanded(child: _buildComparisonBar('Grammar', 'sentence_formation_score')),
              Expanded(child: _buildComparisonBar('Confidence', 'ai_interaction_score')),
              const SizedBox(width: 32),
              _buildOverallImprovement(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildComparisonBar(String title, String column) {
    double currentScore = 0.0;
    double delta = 0.0;

    if (_latestPerformance != null) {
      currentScore = (_latestPerformance![column] ?? 0.0).toDouble();
      
      if (_history.length > 1) {
        final previousScore = (_history[_history.length - 2][column] ?? 0.0).toDouble();
        delta = currentScore - previousScore;
      }
    }

    final isPositive = delta >= 0;
    final percentage = currentScore / 10.0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(title, style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(width: 4),
              const Icon(Icons.info_outline, size: 14, color: AppColors.bodyGray),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(currentScore.toStringAsFixed(1), style: AppTextStyles.cardTitle.copyWith(fontSize: 20)),
              const SizedBox(width: 4),
              if (_history.length > 1)
                Text(
                  '${isPositive ? "+" : ""}${delta.toStringAsFixed(1)}',
                  style: TextStyle(
                    color: isPositive ? Colors.green : Colors.red,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 20),
          Stack(
            alignment: Alignment.bottomCenter,
            children: [
              Container(
                height: 120,
                width: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFFFDF7F2),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              Container(
                height: (120 * percentage).clamp(5.0, 120.0),
                width: 24,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primaryRed.withOpacity(0.4),
                      AppColors.primaryRed,
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Prev', style: AppTextStyles.bodySmall.copyWith(fontSize: 9)),
              Text('Curr', style: AppTextStyles.bodySmall.copyWith(fontSize: 9, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            isPositive ? 'Improved' : 'Needs Work',
            style: TextStyle(
              color: isPositive ? Colors.green : Colors.red,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverallImprovement() {
    return Container(
      width: 140,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFDF7F2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFFEF0E7)),
      ),
      child: Column(
        children: [
          Text('Overall Improvement', style: AppTextStyles.bodySmall.copyWith(fontSize: 11, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 80,
                height: 80,
                child: CircularProgressIndicator(
                  value: 0.12,
                  strokeWidth: 8,
                  backgroundColor: Colors.white,
                  valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primaryRed),
                  strokeCap: StrokeCap.round,
                ),
              ),
              Text('+12%', style: AppTextStyles.cardTitle.copyWith(fontSize: 18, color: AppColors.primaryRed)),
            ],
          ),
          const SizedBox(height: 16),
          Text('Better than last 3 days', style: AppTextStyles.bodySmall.copyWith(fontSize: 9), textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _buildPeriodDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFFDF7F2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderGray),
      ),
      child: Row(
        children: [
          Text('Last 3 Days', style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(width: 8),
          const Icon(Icons.keyboard_arrow_down, size: 16, color: AppColors.bodyGray),
        ],
      ),
    );
  }

  Widget _buildRecommendedModules() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Recommended Modules for You', style: AppTextStyles.sectionHeading.copyWith(fontSize: 20)),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(child: _buildModuleCard('Vocabulary & Sentence Formation', 'Improve vocabulary usage and sentence structure.', Icons.font_download_outlined, color: const Color(0xFF8E44AD), priority: 'High Priority', progress: 0.4)),
            const SizedBox(width: 20),
            Expanded(child: _buildModuleCard('AI Interaction Module', 'Practice real conversations with AI and improve fluency.', Icons.smart_toy_outlined, color: const Color(0xFF2980B9), priority: 'Recommended', progress: 0.6)),
            const SizedBox(width: 20),
            Expanded(child: _buildModuleCard('Role Play Module', 'Enhance confidence through real-life role play scenarios.', Icons.people_outline, color: const Color(0xFFD35400), priority: 'Recommended', progress: 0.3)),
            const SizedBox(width: 20),
            Expanded(child: _buildModuleCard('Image Narration Module', 'Observe, think and narrate stories effectively.', Icons.image_outlined, color: const Color(0xFF16A085), priority: 'Recommended', progress: 0.8)),
          ],
        ),
      ],
    );
  }

  Widget _buildModuleCard(String title, String desc, IconData icon, {required Color color, required String priority, required double progress}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 20)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(child: Text(title, style: AppTextStyles.cardTitle.copyWith(fontSize: 14), maxLines: 2)),
            ],
          ),
          const SizedBox(height: 16),
          Text(desc, style: AppTextStyles.bodySmall.copyWith(fontSize: 11, height: 1.5), maxLines: 2),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(color: color.withOpacity(0.05), borderRadius: BorderRadius.circular(4)),
            child: Text(priority, style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: progress,
            backgroundColor: AppColors.borderGray,
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 4,
            borderRadius: BorderRadius.circular(2),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryRed,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 12),
                elevation: 0,
              ),
              child: const Text('Resume Practice', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomSection(bool isDesktop) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(flex: 6, child: _buildPerformanceTrends()),
        const SizedBox(width: 32),
        Expanded(flex: 4, child: _buildAiInsights()),
      ],
    );
  }

  Widget _buildPerformanceTrends() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 20)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Performance Trends (Last 3 Updates)', style: AppTextStyles.cardTitle),
          const SizedBox(height: 32),
          SizedBox(
            height: 200,
            child: CustomPaint(
              painter: LineChartPainter(),
              child: Container(),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildTrendLabel('Current (18 May)'),
              _buildTrendLabel('2 Updates Ago (12 May)'),
              _buildTrendLabel('Last Update (15 May)'),
              _buildTrendLabel('Current (18 May)'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTrendLabel(String text) {
    return Text(text, style: AppTextStyles.bodySmall.copyWith(fontSize: 10));
  }

  Widget _buildAiInsights() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 20)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('AI Insights & Feedback', style: AppTextStyles.cardTitle),
          const SizedBox(height: 24),
          _buildInsightSection('What You Did Well', [
            'Your fluency has improved significantly.',
            'Better use of complex vocabulary.',
            'More confidence in expressing ideas.',
          ], isPositive: true),
          const SizedBox(height: 24),
          _buildInsightSection('Areas to Improve', [
            'Work on grammar accuracy in longer sentences.',
            'Reduce pauses and fillers while speaking.',
            'Practice sentence connectivity.',
          ], isPositive: false),
          const SizedBox(height: 32),
          _buildPersonalizedTip(),
        ],
      ),
    );
  }

  Widget _buildInsightSection(String title, List<String> items, {required bool isPositive}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(title, style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.bold, color: AppColors.charcoal)),
            const Spacer(),
            const Icon(Icons.info_outline, size: 14, color: AppColors.bodyGray),
          ],
        ),
        const SizedBox(height: 16),
        ...items.map((item) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                isPositive ? Icons.check_circle : Icons.warning_rounded,
                color: isPositive ? Colors.green : Colors.orange,
                size: 16,
              ),
              const SizedBox(width: 12),
              Expanded(child: Text(item, style: AppTextStyles.bodySmall.copyWith(fontSize: 11, height: 1.4))),
            ],
          ),
        )),
      ],
    );
  }

  Widget _buildPersonalizedTip() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF0E7),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(color: Color(0xFFE67E22), shape: BoxShape.circle),
            child: const Icon(Icons.lightbulb_outline, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text('Personalized Tip', style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.bold, fontSize: 11)),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(color: const Color(0xFF16A085).withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
                      child: const Text('New Tip - Last 1 Day Cycle', style: TextStyle(color: Color(0xFF16A085), fontSize: 8, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text('Try focusing on breath control to reduce unnecessary pauses.', style: AppTextStyles.bodySmall.copyWith(fontSize: 10)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class LineChartPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.primaryRed.withOpacity(0.3)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final path = Path();
    path.moveTo(0, size.height * 0.8);
    path.quadraticBezierTo(size.width * 0.3, size.height * 0.6, size.width * 0.6, size.height * 0.4);
    path.quadraticBezierTo(size.width * 0.8, size.height * 0.3, size.width, size.height * 0.2);

    canvas.drawPath(path, paint);

    // Draw dots
    final dotPaint = Paint()..color = AppColors.primaryRed;
    canvas.drawCircle(Offset(0, size.height * 0.8), 4, dotPaint);
    canvas.drawCircle(Offset(size.width * 0.5, size.height * 0.46), 4, dotPaint);
    canvas.drawCircle(Offset(size.width * 0.75, size.height * 0.32), 4, dotPaint);
    canvas.drawCircle(Offset(size.width, size.height * 0.2), 4, dotPaint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
