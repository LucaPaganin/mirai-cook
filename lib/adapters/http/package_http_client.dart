import 'package:http/http.dart' as http;

import '../../application/ports/http_client.dart';

/// [HttpClient] adapter on `package:http`.
class PackageHttpClient implements HttpClient {
  PackageHttpClient([http.Client? client]) : _client = client ?? http.Client();

  final http.Client _client;

  static const _headers = {
    'User-Agent':
        'Mozilla/5.0 (Linux; Android 14) AppleWebKit/537.36 (KHTML, like Gecko) '
        'Chrome/130.0 Mobile Safari/537.36',
    'Accept': 'text/html,application/xhtml+xml,image/*;q=0.9,*/*;q=0.8',
    'Accept-Language': 'it-IT,it;q=0.9',
  };

  @override
  Future<HttpResponse> get(Uri url) async {
    final r = await _client
        .get(url, headers: _headers)
        .timeout(const Duration(seconds: 20));
    return HttpResponse(r.statusCode, r.bodyBytes);
  }
}
