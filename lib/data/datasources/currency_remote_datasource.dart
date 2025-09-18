import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../utils/constant.dart';

class CurrencyRemoteDataSource {
  final http.Client client;

  CurrencyRemoteDataSource(this.client);

  Future<Map<String, dynamic>> fetchLatestUsdJson() async {
    final url = Uri.parse(
      'https://v6.exchangerate-api.com/v6/${Constant.apiKey}/latest/USD',
    );

    final res = await client.get(url).timeout(const Duration(seconds: 10));

    if (res.statusCode != 200) {
      throw Exception('FX HTTP ${res.statusCode}: ${res.body}');
    }

    final data = jsonDecode(res.body) as Map<String, dynamic>;

    if (data['result'] != 'success') {
      final msg = data['error-type'] ?? 'unknown';
      throw Exception('FX API error: $msg');
    }

    if (data['conversion_rates'] is! Map) {
      throw Exception('FX response missing conversion_rates');
    }

    return data;
  }
}
