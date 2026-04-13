import 'dart:convert';

import 'package:http/http.dart' as http;

/// GET-only JSON client for the local SuperMarket StockTake mod API.
/// Default base: `http://localhost:8080`.
class StockTakeApiClient {
  StockTakeApiClient({
    http.Client? httpClient,
    this.baseUrl = 'http://localhost:8080',
  }) : _http = httpClient ?? http.Client();

  final http.Client _http;
  final String baseUrl;

  Uri _uri(String path) {
    final base = baseUrl.endsWith('/') ? baseUrl.substring(0, baseUrl.length - 1) : baseUrl;
    final p = path.startsWith('/') ? path : '/$path';
    return Uri.parse('$base$p');
  }

  Future<http.Response> get(String path) => _http.get(_uri(path));

  Future<Object?> getJson(String path) async {
    final res = await get(path);
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw StockTakeApiException(res.statusCode, res.body);
    }
    return jsonDecode(utf8.decode(res.bodyBytes));
  }

  Future<Map<String, dynamic>?> getJsonMap(String path) async {
    final decoded = await getJson(path);
    if (decoded is Map<String, dynamic>) return decoded;
    if (decoded is Map) return Map<String, dynamic>.from(decoded);
    throw FormatException('Expected JSON object, got ${decoded.runtimeType}');
  }

  void close() => _http.close();
}

class StockTakeApiException implements Exception {
  StockTakeApiException(this.statusCode, this.body);

  final int statusCode;
  final String body;

  @override
  String toString() => 'StockTakeApiException($statusCode): $body';
}
