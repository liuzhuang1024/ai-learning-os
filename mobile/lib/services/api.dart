// HTTP client. v0 uses an X-User-Id header instead of real auth — see
// backend/src/app/routers/deps.py. Replace before any real user touches this.
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Api {
  Api._(this._dio);

  final Dio _dio;

  static Future<Api> create({String baseUrl = 'http://localhost:8000'}) async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('user_id') ?? '';
    final dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        headers: {'X-User-Id': userId},
        connectTimeout: const Duration(seconds: 5),
        receiveTimeout: const Duration(seconds: 30),
      ),
    );
    return Api._(dio);
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
