// HTTP client. v0 uses an X-User-Id header instead of real auth — see
// backend/src/app/routers/deps.py. Replace before any real user touches this.
import 'package:dio/dio.dart';

class Api {
  Api(this.baseUrl, String userId)
      : _dio = Dio(
          BaseOptions(
            baseUrl: baseUrl,
            headers: {if (userId.isNotEmpty) 'X-User-Id': userId},
            connectTimeout: const Duration(seconds: 5),
            receiveTimeout: const Duration(seconds: 60),
          ),
        );

  final String baseUrl;
  final Dio _dio;

  Future<Map<String, dynamic>> getAssessment() async {
    final resp = await _dio.get('/onboarding/assessment');
    return resp.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> submitAssessment({
    required Map<String, int> answers,
    required String backgroundSummary,
    required String preferredStyle,
  }) async {
    final resp = await _dio.post(
      '/onboarding/assessment',
      data: {
        'answers': answers,
        'background_summary': backgroundSummary,
        'preferred_style': preferredStyle,
      },
    );
    return resp.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getTodayQuest() async {
    final resp = await _dio.get('/quest/today');
    return resp.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> submitAnswer(
    String questId, {
    required int questionIndex,
    required int choiceIndex,
  }) async {
    final resp = await _dio.post(
      '/quest/$questId/answer',
      data: {'question_index': questionIndex, 'choice_index': choiceIndex},
    );
    return resp.data as Map<String, dynamic>;
  }

  Future<String> tutorChat({
    required List<Map<String, String>> history,
    required String message,
  }) async {
    final resp = await _dio.post(
      '/tutor/chat',
      data: {'history': history, 'message': message},
    );
    return (resp.data as Map<String, dynamic>)['reply'] as String;
  }

  Future<Map<String, dynamic>> getMemory() async {
    final resp = await _dio.get('/memory');
    return resp.data as Map<String, dynamic>;
  }
}
