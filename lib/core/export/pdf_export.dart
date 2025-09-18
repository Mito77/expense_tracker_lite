import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../../data/models/expense_model.dart';

class PdfExport {
  static Future<File> buildAndSave({
    required List<ExpenseModel> items,
    required double totalIncome,
    required double totalExpenses,
    required double totalBalance,
    required String fileName,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build:
            (ctx) => [
              pw.Text(
                'Expenses Report',
                style: pw.TextStyle(
                  fontSize: 20,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 8),
              pw.Text('Income:  \$${totalIncome.toStringAsFixed(2)}'),
              pw.Text('Expenses:\$${totalExpenses.toStringAsFixed(2)}'),
              pw.Text('Balance: \$${totalBalance.toStringAsFixed(2)}'),
              pw.SizedBox(height: 12),
              pw.Table.fromTextArray(
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                headerDecoration: const pw.BoxDecoration(
                  color: PdfColors.grey300,
                ),
                cellStyle: const pw.TextStyle(fontSize: 10),
                headers: const ['Date', 'Category', 'Amount', 'USD'],
                data:
                    items.map((e) {
                      return [
                        e.date.toIso8601String(),
                        e.category,
                        e.amount.toStringAsFixed(2),
                        e.usdAmount.toStringAsFixed(2),
                      ];
                    }).toList(),
              ),
            ],
      ),
    );

    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/$fileName.pdf');
    await file.writeAsBytes(await pdf.save());
    return file;
  }
}
