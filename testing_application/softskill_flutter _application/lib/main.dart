import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'theme/app_theme.dart';
import 'pages/home_page.dart';
import 'pages/learning_module_page.dart';
import 'pages/sentence_formation_page.dart';
import 'pages/modules_page.dart';
import 'pages/role_play_page.dart';
import 'pages/assessment_page.dart';
import 'pages/dashboard_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Supabase.initialize(
    url: 'https://ssktamuozmtzezgiqiql.supabase.co',
    anonKey: 'sb_publishable_K1CDZRWbcZ9Xz8bINwM0PQ_cf42NTaY',
  );

  runApp(const SoftSkillApp());
}

class SoftSkillApp extends StatelessWidget {
  const SoftSkillApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SoftSkills Empowerment',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      initialRoute: '/',
      routes: {
        // Landing page
        '/': (context) => const HomePage(),
        // Module 1: Personalized Learning Module (initial assessment)
        '/personalized-learning': (context) => const LearningModulePage(),
        // Module 2a: Vocabulary & Sentence Formation
        '/vocabulary': (context) => const SentenceFormationPage(),
        // Module 2b: Image Description
        '/image-description': (context) => const ModulesPage(),
        // Module 2c: Role Play
        '/role-play': (context) => const RolePlayPage(),
        // Module 2d: AI Interaction
        '/ai-interaction': (context) => const AssessmentPage(),
        // Module 3: Individual Feedback
        '/feedback': (context) => const DashboardPage(),
      },
    );
  }
}
