import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config.dart';
import '../models/feedback.dart';

/// Thrown when the API responds with a non-2xx status.
class FeedbackApiException implements Exception {
  FeedbackApiException(this.statusCode, this.message);
  final int statusCode;
  final String message;

  @override
  String toString() => 'FeedbackApiException($statusCode): $message';
}

class FeedbackClient {
  FeedbackClient(this._config, {http.Client? httpClient})
      : _http = httpClient ?? http.Client();

  final AppConfig _config;
  final http.Client _http;

  static const Duration _timeout = Duration(seconds: 15);

  Future<void> submit(Feedback feedback) async {
    final uri = Uri.parse('${_config.apiBaseUrl}/api/v1/feedback');
    final headers = <String, String>{'Content-Type': 'application/json'};
    if (_config.apiKey.isNotEmpty) {
      headers['X-API-Key'] = _config.apiKey;
    }

    final response = await _http
        .post(uri, headers: headers, body: jsonEncode(feedback.toJson()))
        .timeout(_timeout);

    if (response.statusCode == 201) return;

    throw FeedbackApiException(response.statusCode, _extractError(response));
  }

  void close() => _http.close();

  String _extractError(http.Response r) {
    try {
      final decoded = jsonDecode(r.body);
      if (decoded is Map && decoded['error'] is String) {
        return decoded['error'] as String;
      }
    } catch (_) {
      // fall through
    }
    return r.body.isEmpty ? r.reasonPhrase ?? 'unknown error' : r.body;
  }
}
