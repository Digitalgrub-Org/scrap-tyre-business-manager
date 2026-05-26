import 'dart:io';

import 'package:cross_file/cross_file.dart';
import 'package:excel/excel.dart' as excel;
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/report_row.dart';
import '../providers/business_provider.dart';
import '../constants/app_constants.dart';
import '../utils/formatters.dart';

class ReportExportService {
  List<ReportRow> rowsFor({
    required BusinessProvider provider,
    required String type,
    required DateTimeRange range,
    required String search,
  }) {
    final term = search.toLowerCase().trim();
    bool matches(String text) =>
        term.isEmpty || text.toLowerCase().contains(term);
    final purchases = provider.purchasesIn(range).where((entry) {
      return matches('${entry.itemName} ${entry.supplierName}');
    }).toList();
    final sales = provider.salesIn(range).where((entry) {
      return matches('${entry.itemName} ${entry.customerName}');
    }).toList();
    final expenses = provider.expensesIn(range).where((entry) {
      return matches('${entry.type} ${entry.notes}');
    }).toList();

    if (type == 'Stock Report') {
      return provider.stock
          .where((entry) => matches('${entry.itemName} ${entry.category}'))
          .map(
            (entry) => ReportRow(
              title: entry.itemName,
              detail:
                  '${AppFormatters.weight(entry.availableWeight)} | '
                  '${AppFormatters.quantity.format(entry.availableQuantity)} qty',
              amount: entry.totalStockValue,
            ),
          )
          .toList();
    }
    if (type == 'Expense Report') {
      return [
        ...expenses.map(
          (entry) => ReportRow(
            title: entry.type,
            detail: '${AppFormatters.date.format(entry.date)} | ${entry.notes}',
            amount: entry.amount,
          ),
        ),
        ...sales
            .where((entry) => entry.transportCharges > 0)
            .map(
              (entry) => ReportRow(
                title: 'Transport - ${entry.customerName}',
                detail: AppFormatters.date.format(entry.date),
                amount: entry.transportCharges,
              ),
            ),
      ];
    }
    if (type == 'Customer-wise Sales') {
      final totals = <String, double>{};
      for (final sale in sales) {
        totals[sale.customerName] =
            (totals[sale.customerName] ?? 0) + sale.totalAmount;
      }
      return totals.entries
          .map(
            (entry) => ReportRow(
              title: entry.key,
              detail: 'Customer total sales',
              amount: entry.value,
            ),
          )
          .toList();
    }
    if (type == 'Supplier-wise Purchases') {
      final totals = <String, double>{};
      for (final purchase in purchases) {
        totals[purchase.supplierName] =
            (totals[purchase.supplierName] ?? 0) + purchase.totalAmount;
      }
      return totals.entries
          .map(
            (entry) => ReportRow(
              title: entry.key,
              detail: 'Supplier total purchases',
              amount: entry.value,
            ),
          )
          .toList();
    }
    if (type == 'Item-wise Profit') {
      final amounts = <String, List<double>>{};
      for (final purchase in purchases) {
        amounts.putIfAbsent(purchase.itemName, () => [0, 0])[0] +=
            purchase.totalAmount;
      }
      for (final sale in sales) {
        amounts.putIfAbsent(sale.itemName, () => [0, 0])[1] +=
            sale.totalAmount - sale.transportCharges;
      }
      return amounts.entries
          .map(
            (entry) => ReportRow(
              title: entry.key,
              detail:
                  'Purchase ${AppFormatters.money(entry.value[0])} | '
                  'Sales ${AppFormatters.money(entry.value[1])}',
              amount: entry.value[1] - entry.value[0],
            ),
          )
          .toList();
    }
    return [
      ...purchases.map(
        (entry) => ReportRow(
          title: 'Purchase - ${entry.itemName}',
          detail:
              '${AppFormatters.date.format(entry.date)} | ${entry.supplierName}',
          amount: -entry.totalAmount,
        ),
      ),
      ...sales.map(
        (entry) => ReportRow(
          title: 'Sale - ${entry.itemName}',
          detail:
              '${AppFormatters.date.format(entry.date)} | ${entry.customerName}',
          amount: entry.totalAmount,
        ),
      ),
      ...expenses.map(
        (entry) => ReportRow(
          title: 'Expense - ${entry.type}',
          detail: AppFormatters.date.format(entry.date),
          amount: -entry.amount,
        ),
      ),
    ];
  }

  Future<XFile> exportPdf({
    required BusinessProvider provider,
    required String type,
    required DateTimeRange range,
    required String search,
  }) async {
    final rows = rowsFor(
      provider: provider,
      type: type,
      range: range,
      search: search,
    );
    final summary = provider.summaryFor(range);
    final businessName = provider.profile.isConfigured
        ? provider.profile.businessName
        : AppConstants.appName;
    final document = pw.Document();
    String rs(double value) => 'Rs ${value.toStringAsFixed(2)}';
    document.addPage(
      pw.MultiPage(
        build: (_) => [
          pw.Text(
            businessName,
            style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
          ),
          if (provider.profile.address.isNotEmpty)
            pw.Text(provider.profile.address),
          if (provider.profile.phone.isNotEmpty)
            pw.Text('Phone: ${provider.profile.phone}'),
          pw.SizedBox(height: 4),
          pw.Text(
            '$type | ${AppFormatters.date.format(range.start)} - '
            '${AppFormatters.date.format(range.end)}',
          ),
          pw.SizedBox(height: 18),
          pw.Wrap(
            spacing: 16,
            runSpacing: 8,
            children: [
              pw.Text('Purchases: ${rs(summary.purchaseTotal)}'),
              pw.Text('Sales: ${rs(summary.salesTotal)}'),
              pw.Text('Expenses: ${rs(summary.expensesTotal)}'),
              pw.Text('Net Profit: ${rs(summary.netProfit)}'),
            ],
          ),
          pw.SizedBox(height: 18),
          pw.TableHelper.fromTextArray(
            headers: const ['Description', 'Details', 'Amount'],
            data: rows
                .map((entry) => [entry.title, entry.detail, rs(entry.amount)])
                .toList(),
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
          ),
        ],
      ),
    );
    final directory = await getTemporaryDirectory();
    final output = File(
      '${directory.path}/${_fileName(type, range, extension: 'pdf')}',
    );
    await output.writeAsBytes(await document.save());
    return XFile(output.path);
  }

  Future<XFile> exportExcel({
    required BusinessProvider provider,
    required String type,
    required DateTimeRange range,
    required String search,
  }) async {
    final rows = rowsFor(
      provider: provider,
      type: type,
      range: range,
      search: search,
    );
    final summary = provider.summaryFor(range);
    final businessName = provider.profile.isConfigured
        ? provider.profile.businessName
        : AppConstants.appName;
    final workbook = excel.Excel.createExcel();
    final sheet = workbook['Report'];
    workbook.delete('Sheet1');
    sheet.appendRow([excel.TextCellValue(businessName)]);
    if (provider.profile.address.isNotEmpty ||
        provider.profile.phone.isNotEmpty) {
      sheet.appendRow([
        excel.TextCellValue(provider.profile.address),
        excel.TextCellValue(provider.profile.phone),
      ]);
    }
    sheet.appendRow([
      excel.TextCellValue(type),
      excel.TextCellValue(
        '${AppFormatters.date.format(range.start)} - ${AppFormatters.date.format(range.end)}',
      ),
    ]);
    sheet.appendRow([]);
    sheet.appendRow([
      excel.TextCellValue('Total Purchase'),
      excel.DoubleCellValue(summary.purchaseTotal),
      excel.TextCellValue('Total Sales'),
      excel.DoubleCellValue(summary.salesTotal),
      excel.TextCellValue('Expenses'),
      excel.DoubleCellValue(summary.expensesTotal),
      excel.TextCellValue('Net Profit'),
      excel.DoubleCellValue(summary.netProfit),
    ]);
    sheet.appendRow([]);
    sheet.appendRow([
      excel.TextCellValue('Description'),
      excel.TextCellValue('Details'),
      excel.TextCellValue('Amount'),
    ]);
    for (final row in rows) {
      sheet.appendRow([
        excel.TextCellValue(row.title),
        excel.TextCellValue(row.detail),
        excel.DoubleCellValue(row.amount),
      ]);
    }
    final bytes = workbook.encode();
    if (bytes == null) throw StateError('Unable to create Excel report.');
    final directory = await getTemporaryDirectory();
    final output = File(
      '${directory.path}/${_fileName(type, range, extension: 'xlsx')}',
    );
    await output.writeAsBytes(bytes);
    return XFile(output.path);
  }

  String _fileName(
    String type,
    DateTimeRange range, {
    required String extension,
  }) {
    final safeType = type.toLowerCase().replaceAll(' ', '_');
    final date = AppFormatters.databaseDate.format(range.end);
    return '${safeType}_$date.$extension';
  }
}
