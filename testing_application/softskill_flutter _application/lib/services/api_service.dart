import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;

class ApiService {
  // Placeholder URL - User will provide the actual endpoint later
  static const String _baseUrl = 'http://localhost:8000';

  static Future<Map<String, dynamic>?> computeAssessmentValues(
    Map<String, dynamic> assessmentData,
  ) async {
    try {
      // final response = await http.post(
      //   Uri.parse('$_baseUrl/compute-scores'),
      //   headers: {'Content-Type': 'application/json'},
      //   body: jsonEncode(assessmentData),
      // );

      // if (response.statusCode == 200) {
      //   return jsonDecode(response.body);
      // }

      // Mocking the response for now until the user provides the API
      await Future.delayed(const Duration(seconds: 2));
      return {
        'vocabulary_score': 85.0,
        'sentence_formation_score': 78.0,
        'image_narration_score': 92.0,
        'ai_interaction_score': 88.0,
      };
    } catch (e) {
      print('Error calling Python backend: $e');
      return null;
    }
  }

  static Future<String?> evaluateAssessment({
    required String userId,
    required String moduleType,
    required String context,
    required String audioPath,
    String? secondAudioPath,
  }) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$_baseUrl/api/v1/assessment/evaluate'),
      );

      request.fields['user_id'] = userId;
      request.fields['module_type'] = moduleType;
      request.fields['context'] = context;

      // Handle audio files (considering Flutter Web blob URLs)
      if (kIsWeb && audioPath.startsWith('blob:')) {
        final bytes = await http.readBytes(Uri.parse(audioPath));
        request.files.add(
          http.MultipartFile.fromBytes('audio', bytes, filename: 'audio.m4a'),
        );
      } else {
        request.files.add(
          await http.MultipartFile.fromPath('audio', audioPath),
        );
      }

      if (secondAudioPath != null) {
        if (kIsWeb && secondAudioPath.startsWith('blob:')) {
          final bytes = await http.readBytes(Uri.parse(secondAudioPath));
          request.files.add(
            http.MultipartFile.fromBytes('second_audio', bytes, filename: 'audio2.m4a'),
          );
        } else {
          request.files.add(
            await http.MultipartFile.fromPath('second_audio', secondAudioPath),
          );
        }
      }

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        return null; // Success
      } else {
        print('Evaluation failed: ${response.statusCode} - ${response.body}');
        return 'Server Error (${response.statusCode}): ${response.body}';
      }
    } catch (e) {
      print('Error in evaluateAssessment: $e');
      return 'Connection Error: $e';
    }
  }
}
