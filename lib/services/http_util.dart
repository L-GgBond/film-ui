import 'dart:async';
import 'package:http/http.dart' as http;

/// 统一 HTTP GET：附带 User-Agent、超时与一次重试，降低公共接口（archive.org /
/// TMDB / 用户自配 CMS）偶发失败率，并避免匿名请求被部分服务器拒绝。
class HttpUtil {
  static const String _ua =
      'film-ui/0.1 (https://github.com/L-GgBond/film-ui)';

  static Future<http.Response> get(
    Uri uri, {
    Map<String, String>? headers,
    Duration? timeout,
    int retries = 1,
  }) async {
    final effectiveHeaders = {'User-Agent': _ua, ...?headers};
    Exception? last;
    for (var attempt = 0; attempt <= retries; attempt++) {
      try {
        final res = await http
            .get(uri, headers: effectiveHeaders)
            .timeout(timeout ?? const Duration(seconds: 8));
        if (res.statusCode >= 500) throw Exception('HTTP ${res.statusCode}');
        return res;
      } on Exception catch (e) {
        last = e;
        if (attempt < retries) {
          await Future.delayed(const Duration(milliseconds: 300));
        }
      }
    }
    throw last ?? Exception('请求失败: $uri');
  }
}
