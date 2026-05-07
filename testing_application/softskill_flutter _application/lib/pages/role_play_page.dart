import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';
import '../widgets/navbar.dart';
import '../widgets/voice_interaction_widget.dart';

class RolePlayPage extends StatefulWidget {
  const RolePlayPage({super.key});

  @override
  State<RolePlayPage> createState() => _RolePlayPageState();
}

class _RolePlayPageState extends State<RolePlayPage> {
  final String _activeTab = 'Role Play';

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isDesktop = width > 1024;

    return Scaffold(
      backgroundColor: const Color(0xFFFBFBFE),
      appBar: const Navbar(),
      endDrawer: const MobileDrawer(),
      body: Row(
        children: [
          if (isDesktop) _buildSidebar(),
          Expanded(
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: isDesktop ? 64 : 16,
                        vertical: 32,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildHeader(),
                          const SizedBox(height: 40),
                          _buildScenarioCard(isDesktop),
                          const SizedBox(height: 40),
                          _buildConversationSection(),
                          const SizedBox(height: 40),
                          _buildMetricsSection(),
                          const SizedBox(height: 64),
                        ],
                      ),
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

  Widget _buildSidebar() {
    return Container(
      width: 280,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 32),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(right: BorderSide(color: Colors.black.withOpacity(0.05))),
      ),
      child: Column(
        children: [
          _buildSidebarItem('AI Interaction', Icons.chat_bubble_outline, '/ai-interaction'),
          const SizedBox(height: 8),
          _buildSidebarItem('Role Play', Icons.people_outline, '/role-play'),
        ],
      ),
    );
  }

  Widget _buildSidebarItem(String title, IconData icon, String route) {
    final isActive = _activeTab == title;
    return GestureDetector(
      onTap: () {
        if (!isActive) Navigator.pushReplacementNamed(context, route);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: isActive ? AppColors.peach : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isActive ? AppColors.groqOrange : AppColors.mediumGray,
              size: 22,
            ),
            const SizedBox(width: 16),
            Text(
              title,
              style: GoogleFonts.sourceSans3(
                fontSize: 16,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                color: isActive ? AppColors.groqOrange : AppColors.mediumGray,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'ACTIVE SCENARIO',
          style: GoogleFonts.sourceSans3(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
            color: AppColors.groqOrange,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Resolving a Team Disagreement',
          style: GoogleFonts.sourceSans3(
            fontSize: 36,
            fontWeight: FontWeight.bold,
            color: AppColors.black,
            height: 1.1,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Practice real-life communication through interactive conversational scenarios.',
          style: GoogleFonts.sourceSans3(
            fontSize: 18,
            color: AppColors.mediumGray,
          ),
        ),
      ],
    );
  }

  Widget _buildScenarioCard(bool isDesktop) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.black.withOpacity(0.06)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isDesktop)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 3, child: _buildScenarioDetails()),
                const SizedBox(width: 48),
                Expanded(flex: 2, child: _buildRoleColumn()),
              ],
            )
          else
            Column(
              children: [
                _buildScenarioDetails(),
                const SizedBox(height: 32),
                _buildRoleColumn(),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildScenarioDetails() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'SCENARIO CONTEXT',
          style: GoogleFonts.sourceSans3(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
            color: AppColors.black,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'You are a team leader in a group project. Two of your teammates have a disagreement about the design approach. You need to mediate, listen to both sides, and help the team reach a consensus.',
          style: GoogleFonts.sourceSans3(
            fontSize: 15,
            height: 1.6,
            color: AppColors.mediumGray,
          ),
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            _buildTag('COMMUNICATION'),
            const SizedBox(width: 12),
            _buildTag('CONFLICT RESOLUTION'),
          ],
        ),
      ],
    );
  }

  Widget _buildTag(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.peach,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: GoogleFonts.sourceSans3(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: AppColors.groqOrange,
        ),
      ),
    );
  }

  Widget _buildRoleColumn() {
    return Column(
      children: [
        _buildRoleItem('YOUR ROLE', 'Team Leader', Icons.person_outline),
        const SizedBox(height: 16),
        _buildRoleItem('AI ROLE', 'Team Member (Priya)', Icons.smart_toy_outlined),
      ],
    );
  }

  Widget _buildRoleItem(String label, String name, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 20, color: AppColors.groqOrange),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.sourceSans3(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: AppColors.bodyGray,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                name,
                style: GoogleFonts.sourceSans3(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppColors.black,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildConversationSection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.black.withOpacity(0.06)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAFB),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              border: Border(bottom: BorderSide(color: Colors.black.withOpacity(0.04))),
            ),
            child: Row(
              children: [
                Text(
                  'CONVERSATION',
                  style: GoogleFonts.sourceSans3(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: AppColors.black,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.peach,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'ROUND 3 OF 5',
                    style: GoogleFonts.sourceSans3(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: AppColors.groqOrange,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.all(32),
            child: VoiceInteractionWidget(
              endpoint: 'ai-interaction',
              tableName: 'role_play_logs',
              initialPrompt: 'Tap the mic to respond to Priya...',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'LIVE PERFORMANCE METRICS',
          style: GoogleFonts.sourceSans3(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.black,
          ),
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(child: _buildMetricCard('RESPONSE TIME', '2.4s', Icons.timer_outlined)),
            const SizedBox(width: 16),
            Expanded(child: _buildMetricCard('FLUENCY', '87%', Icons.waves_outlined)),
            const SizedBox(width: 16),
            Expanded(child: _buildMetricCard('CONFIDENCE', '78%', Icons.psychology_outlined)),
          ],
        ),
      ],
    );
  }

  Widget _buildMetricCard(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black.withOpacity(0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 24, color: AppColors.groqOrange),
          const SizedBox(height: 20),
          Text(
            label,
            style: GoogleFonts.sourceSans3(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: AppColors.bodyGray,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.sourceSans3(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: AppColors.black,
            ),
          ),
        ],
      ),
    );
  }
}
