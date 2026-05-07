import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';

class Navbar extends StatelessWidget implements PreferredSizeWidget {
  const Navbar({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(80);

  static const List<Map<String, String>> _navItems = [
    {'label': 'Home', 'route': '/'},
    {'label': 'Personalized Learning', 'route': '/personalized-learning'},
    {'label': 'Vocabulary & Sentence Formation', 'route': '/vocabulary'},
    {'label': 'Image Narration', 'route': '/image-description'},
    {'label': 'AI Interaction', 'route': '/ai-interaction'},
    {'label': 'Individual Feedback', 'route': '/feedback'},
  ];

  static const Color groqOrange = Color(0xFFFF5A1F);
  static const Color navyBlue = Color(0xFF1E293B);

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isDesktop = width > 1300;
    final currentRoute = ModalRoute.of(context)?.settings.name;

    return Container(
      height: 100,
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            children: [
              // Left: Logo
              GestureDetector(
                onTap: () => Navigator.pushNamedAndRemoveUntil(context, '/', (r) => false),
                child: _buildLogo(),
              ),
              
              const SizedBox(width: 20),
              
              if (isDesktop) ...[
                // Center: Navigation Items
                Expanded(
                  child: _buildNavLinks(context, currentRoute),
                ),
                // Right: CTA Button and Profile
                _buildRightSection(context),
              ] else ...[
                const Spacer(),
                Builder(
                  builder: (ctx) => IconButton(
                    icon: const Icon(Icons.menu_rounded, color: AppColors.black),
                    onPressed: () => Scaffold.of(ctx).openEndDrawer(),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset(
          'assets/images/logo.png',
          height: 45,
          errorBuilder: (context, error, stackTrace) => Icon(Icons.psychology, color: groqOrange, size: 40),
        ),
        const SizedBox(width: 12),
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'SoftSkills',
              style: GoogleFonts.sourceSans3(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: groqOrange,
                height: 1.0,
              ),
            ),
            Text(
              'Empowerment',
              style: GoogleFonts.sourceSans3(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.black.withOpacity(0.7),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildNavLinks(BuildContext context, String? currentRoute) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: _navItems.map((item) {
        final isActive = currentRoute == item['route'] || (currentRoute == null && item['route'] == '/');
        return _NavItem(
          label: item['label'] ?? '',
          route: item['route'] ?? '/',
          isActive: isActive,
        );
      }).toList(),
    );
  }

  Widget _buildRightSection(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildStartButton(context),
        const SizedBox(width: 20),
        _buildProfileIcon(),
      ],
    );
  }

  Widget _buildStartButton(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: groqOrange.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: () => Navigator.pushNamed(context, '/personalized-learning'),
        style: ElevatedButton.styleFrom(
          backgroundColor: groqOrange,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 0,
        ),
        child: const Text(
          'Start Assessment',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.2,
          ),
        ),
      ),
    );
  }

  Widget _buildProfileIcon() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.grey.withOpacity(0.1),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.black.withOpacity(0.05)),
          ),
          child: Center(
            child: Text(
              'SA',
              style: GoogleFonts.sourceSans3(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.black.withOpacity(0.7),
              ),
            ),
          ),
        ),
        const SizedBox(width: 4),
        Icon(Icons.keyboard_arrow_down, size: 16, color: Colors.black.withOpacity(0.5)),
      ],
    );
  }
}

class _NavItem extends StatefulWidget {
  final String label;
  final String route;
  final bool isActive;

  const _NavItem({
    required this.label,
    required this.route,
    required this.isActive,
  });

  @override
  State<_NavItem> createState() => _NavItemState();
}

class _NavItemState extends State<_NavItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: () {
          if (!widget.isActive) {
            Navigator.pushNamed(context, widget.route);
          }
        },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Text(
                widget.label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: widget.isActive ? FontWeight.bold : FontWeight.w500,
                  color: widget.isActive ? Navbar.groqOrange : Navbar.navyBlue.withOpacity(_isHovered ? 1.0 : 0.7),
                  height: 1.2,
                ),
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              height: 2,
              width: widget.isActive ? 30 : 0,
              decoration: BoxDecoration(
                color: Navbar.groqOrange,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MobileDrawer extends StatelessWidget {
  const MobileDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final currentRoute = ModalRoute.of(context)?.settings.name;

    return Drawer(
      backgroundColor: Colors.white,
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  const Text(
                    'SoftSkills Empowerment',
                    style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView(
                children: Navbar._navItems.map((item) {
                  final isActive = currentRoute == item['route'];
                  return ListTile(
                    title: Text(
                      item['label'] ?? '',
                      style: TextStyle(
                        fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                        color: isActive ? Navbar.groqOrange : Colors.black87,
                      ),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      if (!isActive) Navigator.pushNamed(context, item['route'] ?? '/');
                    },
                  );
                }).toList(),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, '/personalized-learning');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Navbar.groqOrange,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('Start Assessment', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
