import 'dart:convert';
import 'package:http/http.dart' as http;

import 'package:flutter/foundation.dart';

class ApiService {
  // Use a generic local host approach
  // localhost works for web and most desktop environments.
  // We can use defaultTargetPlatform to detect Android safely without dart:io
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://127.0.0.1:8000/api/v1/module';
    } else if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:8000/api/v1/module';
    } else {
      return 'http://127.0.0.1:8000/api/v1/module';
    }
  }

  static Future<Map<String, dynamic>> sendAudioToBackend(
      String endpoint, String audioPathOrUrl, String userId, [Map<String, String>? extraParams]) async {
    final uri = Uri.parse('$baseUrl/$endpoint');
    final request = http.MultipartRequest('POST', uri);
    request.fields['user_id'] = userId;
    
    if (extraParams != null) {
      request.fields.addAll(extraParams);
    }

    // To handle Web and Mobile uniformly, we fetch the bytes from the path/URL.
    // If it's a web blob URL, http.get handles it. If local File path, it usually also works 
    // but flutter's http on web cannot read local files as straightforwardly. On web, the 
    // audio recorder returns a blob URL anyway.
    try {
      final fileBytesRes = await http.get(Uri.parse(audioPathOrUrl));
      final bytes = fileBytesRes.bodyBytes;
      request.files.add(http.MultipartFile.fromBytes(
        'audio',
        bytes,
        filename: 'recording.webm',
      ));
    } catch (e) {
      // Fallback for native file path if http.get fails
      request.files.add(await http.MultipartFile.fromPath('audio', audioPathOrUrl));
    }

    final response = await request.send();

    if (response.statusCode == 200) {
      // Headers in http package are case-insensitive, but we use lowercase for consistency
      final fullText = response.headers['x-response-text'] ?? 
                       response.headers['X-Response-Text'] ?? '';
      
      final transcribedText = response.headers['x-user-transcribed'] ?? 
                              response.headers['X-User-Transcribed'] ?? '';
      
      // Get the response audio wav bytes
      final responseData = await response.stream.toBytes();

      return {
        'audioBytes': responseData,
        'fullText': fullText,
        'userText': transcribedText,
      };
    } else {
      final respStr = await response.stream.bytesToString();
      throw Exception('Server error: ${response.statusCode} - $respStr');
    }
  }

  static Future<String> getFeedback(String userId) async {
    final uri = Uri.parse('$baseUrl/feedback?user_id=$userId');
    final response = await http.get(uri);
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['feedback_report'] ?? 'No feedback';
    } else {
      throw Exception('Failed to load feedback');
    }
  }
}
