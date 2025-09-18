import 'dart:convert';
import 'package:http/http.dart' as http;

class CurrencyApi {
  static const _baseUrl = "https://api.exchangerate.host/convert";

  /// Convert from [fromCurrency] to USD
  static Future<double> convertToUSD(double amount, String fromCurrency) async {
    final uri = Uri.parse("$_baseUrl?from=$fromCurrency&to=USD&amount=$amount");

    final response = await http.get(uri);
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return (data["result"] as num).toDouble();
    } else {
      throw Exception("Failed to fetch currency conversion");
    }
  }
}
