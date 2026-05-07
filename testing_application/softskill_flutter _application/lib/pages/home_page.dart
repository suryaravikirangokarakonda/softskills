import 'package:flutter/material.dart';
import '../widgets/navbar.dart';
import '../widgets/hero_section.dart';
import '../widgets/features_section.dart';
import '../widgets/about_section.dart';
import '../widgets/why_learners_love_section.dart';
import '../widgets/curriculum_section.dart';
import '../widgets/stats_strip.dart';
import '../widgets/cta_section.dart';
import '../widgets/footer_section.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      endDrawer: const MobileDrawer(),
      appBar: const Navbar(),
      body: const SingleChildScrollView(
        child: Column(
          children: [
            HeroSection(),
            FeaturesSection(),
            AboutSection(),
            WhyLearnersLoveSection(),
            CurriculumSection(),
            StatsStripSection(),
            CtaSection(),
            FooterSection(),
          ],
        ),
      ),
    );
  }
}
