import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  static final SupabaseClient client = Supabase.instance.client;

  /// Example: Fetch user profile
  static Future<Map<String, dynamic>?> getUserProfile(String userId) async {
    try {
      final response = await client
          .from('profiles')
          .select()
          .eq('id', userId)
          .single();
      return response;
    } catch (e) {
      print('Error fetching user profile: $e');
      return null;
    }
  }

  /// Example: Save sentence formation progress
  static Future<void> saveProgress({
    required String userId,
    required String module,
    required double accuracy,
    required String data,
  }) async {
    try {
      await client.from('progress').insert({
        'user_id': userId,
        'module': module,
        'accuracy': accuracy,
        'data': data,
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print('Error saving progress: $e');
    }
  }
  /// Check if user has completed the initial assessment
  static Future<bool> hasCompletedAssessment(String userId) async {
    try {
      final response = await client
          .from('user_performance_history')
          .select()
          .eq('user_id', userId)
          .maybeSingle();
      return response != null;
    } catch (e) {
      print('Error checking assessment status: $e');
      return false;
    }
  }

  /// Save performance history after assessment
  static Future<void> savePerformanceHistory({
    required String userId,
    required double vocabulary,
    required double sentenceFormation,
    required double imageNarration,
    required double aiInteraction,
  }) async {
    try {
      await client.from('user_performance_history').insert({
        'user_id': userId,
        'vocabulary_score': vocabulary,
        'sentence_formation_score': sentenceFormation,
        'image_narration_score': imageNarration,
        'ai_interaction_score': aiInteraction,
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print('Error saving performance history: $e');
    }
  }

  /// Fetch performance history for dashboard
  static Future<List<Map<String, dynamic>>> getPerformanceHistory(String userId) async {
    try {
      final response = await client
          .from('user_performance_history')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: true);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error fetching performance history: $e');
      return [];
    }
  }

  /// Clear performance history (Reset assessment)
  static Future<void> clearPerformanceHistory(String userId) async {
    try {
      await client
          .from('user_performance_history')
          .delete()
          .eq('user_id', userId);
    } catch (e) {
      print('Error clearing performance history: $e');
    }
  }

  /// Update a single module score
  static Future<void> updateModuleScore({
    required String userId,
    required String column,
    required double score,
  }) async {
    try {
      final existing = await client
          .from('user_performance_history')
          .select('id')
          .eq('user_id', userId)
          .maybeSingle();

      if (existing != null) {
        await client
            .from('user_performance_history')
            .update({column: score})
            .eq('user_id', userId);
      } else {
        await client.from('user_performance_history').insert({
          'user_id': userId,
          column: score,
          'created_at': DateTime.now().toIso8601String(),
        });
      }
    } catch (e) {
      print('Error updating module score: $e');
    }
  }
}
