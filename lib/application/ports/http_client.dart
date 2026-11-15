import 'dart:convert';

class HttpResponse {
  const HttpResponse(this.statusCode, this.bodyBytes);

  final int statusCode;
  final List<int> bodyBytes;

  bool get isOk => statusCode >= 200 && statusCode < 300;
  String get body => utf8.decode(bodyBytes, allowMalformed: true);
}

/// Network access, behind a port so tests never hit the network.
abstract interface class HttpClient {
  Future<HttpResponse> get(Uri url);
}
