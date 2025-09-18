import 'dart:io';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import '../../data/models/expense_model.dart';

class ExportService {
  static Future<File> exportCsv({
    required List<ExpenseModel> items,
    required String fileName, // no extension
  }) async {
    final rows = <List<dynamic>>[
      ['ID', 'Category', 'Amount', 'Currency', 'USD Amount', 'Date'],
      ...items.map(
        (e) => [
          e.id,
          e.category,
          e.amount,
          e.currency,
          e.usdAmount,
          e.date.toIso8601String(),
        ],
      ),
    ];

    final csv = const ListToCsvConverter().convert(rows);
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/$fileName.csv');
    await file.writeAsString(csv);
    return file;
  }
}
