import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../api_service.dart';

class FeedbackReportWidget extends StatefulWidget {
  const FeedbackReportWidget({super.key});

  @override
  State<FeedbackReportWidget> createState() => _FeedbackReportWidgetState();
}

class _FeedbackReportWidgetState extends State<FeedbackReportWidget> {
  String _report = 'Loading feedback from AI...';

  @override
  void initState() {
    super.initState();
    _loadFeedback();
  }

  Future<void> _loadFeedback() async {
    try {
      final report = await ApiService.getFeedback('test_user_1');
      setState(() {
        _report = report;
      });
    } catch (e) {
      setState(() {
        _report = 'Error loading feedback: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.lightGray,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.primaryRed, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.psychology, color: AppColors.primaryRed, size: 24),
              const SizedBox(width: 12),
              Text('AI COACHING REPORT', style: AppTextStyles.sectionHeading.copyWith(fontSize: 20)),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            _report,
            style: AppTextStyles.bodyText.copyWith(fontSize: 14),
          ),
        ],
      ),
    );
  }
}
