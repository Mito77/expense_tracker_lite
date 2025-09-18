import 'package:hive/hive.dart';

part 'fx_rates.g.dart';

@HiveType(typeId: 1)
class FxRates extends HiveObject {
  @HiveField(0)
  final String result;
  @HiveField(1)
  final String baseCode; // USD
  @HiveField(2)
  final DateTime lastUpdateUtc;
  @HiveField(3)
  final DateTime nextUpdateUtc;
  @HiveField(4)
  final Map<String, double> rates; // code -> per USD

  FxRates({
    required this.result,
    required this.baseCode,
    required this.lastUpdateUtc,
    required this.nextUpdateUtc,
    required this.rates,
  });

  factory FxRates.fromJson(Map<String, dynamic> json) {
    final cr = (json['conversion_rates'] as Map<String, dynamic>?) ?? {};
    final map = <String, double>{};
    cr.forEach((k, v) {
      if (v is num) map[k] = v.toDouble();
    });

    DateTime parseOrUnix(String? iso, num? unix) =>
        DateTime.tryParse(iso ?? '') ??
        DateTime.fromMillisecondsSinceEpoch(
          ((unix ?? 0).toInt()) * 1000,
          isUtc: true,
        );

    return FxRates(
      result: json['result'] ?? 'error',
      baseCode: json['base_code'] ?? 'USD',
      lastUpdateUtc: parseOrUnix(
        json['time_last_update_utc'],
        json['time_last_update_unix'],
      ),
      nextUpdateUtc: parseOrUnix(
        json['time_next_update_utc'],
        json['time_next_update_unix'],
      ),
      rates: map,
    );
  }

  double convert(double amount, {required String from, required String to}) {
    final f = rates[from.toUpperCase()];
    final t = rates[to.toUpperCase()];
    if (f == null || t == null)
      throw ArgumentError('Missing rate for $from or $to');
    return (amount / f) * t; // from -> base(USD) -> to
  }

  bool get isOk => result.toLowerCase() == 'success';
}
