// lib/data/repositories/currency_repository.dart
import '../datasources/currency_remote_datasource.dart';

class CurrencyRepository {
  final CurrencyRemoteDataSource remote;
  CurrencyRepository(this.remote);

  // Memoize per session: code -> 1 unit of code in USD
  final Map<String, double> _perUnitUsdCache = {};

  Future<double> convertToUSD(double amount, String currency) async {
    final code = currency.toUpperCase().trim();
    if (code == 'USD') return amount;

    var perUnitUsd = _perUnitUsdCache[code];
    if (perUnitUsd == null) {
      final json = await remote.fetchLatestUsdJson();
      final rates = (json['conversion_rates'] as Map).cast<String, dynamic>();
      final perUsd = rates[code];
      if (perUsd == null) {
        throw Exception('Currency $code not found in conversion_rates');
      }
      perUnitUsd = 1 / (perUsd as num).toDouble(); // 1 code -> USD
      _perUnitUsdCache[code] = perUnitUsd;
    }

    return amount * perUnitUsd;
  }
}
