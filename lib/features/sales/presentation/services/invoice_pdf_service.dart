import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:pharmacy/features/products/data/model/medicine_model.dart';
import 'package:pharmacy/features/representatives/data/model/representative_model.dart';
import 'package:pharmacy/features/sales/data/model/sale_model.dart';
import 'package:pharmacy/widgets/app_formatters.dart';

class InvoicePdfService {
  const InvoicePdfService._();
  static Future<Uint8List> build(
    List<SaleModel> sales,
    Map<String, MedicineModel> products,
    RepresentativeModel? representative,
  ) async {
    final document = pw.Document();
    final sale = sales.first;
    final total = sales.fold<double>(0, (sum, item) => sum + item.total);
    final paid = sales.fold<double>(
      0,
      (sum, item) => sum + (item.amountPaid ?? item.total),
    );
    final remaining = total - paid;
    document.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (_) => pw.Padding(
          padding: const pw.EdgeInsets.all(32),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'Pharmacy Inventory',
                style: pw.TextStyle(
                  fontSize: 24,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 8),
              pw.Text(
                'Invoice ${AppFormatters.invoiceNumber(sale.invoiceId ?? sale.id)}',
              ),
              pw.Text('Date: ${sale.date}'),
              pw.Divider(),
              pw.Text('Customer: ${sale.customerName ?? 'Walk-in customer'}'),
              pw.Text('Phone: ${sale.customerPhone ?? '-'}'),
              if (representative != null)
                pw.Text('Representative: ${representative.name}'),
              pw.SizedBox(height: 20),
              pw.Table.fromTextArray(
                headers: const ['Medicine', 'Quantity', 'Unit price', 'Total'],
                data: sales
                    .map(
                      (item) => [
                        products[item.productId]?.name ?? 'Unknown product',
                        '${item.quantity}',
                        item.unitPrice.toStringAsFixed(2),
                        item.total.toStringAsFixed(2),
                      ],
                    )
                    .toList(),
              ),
              pw.SizedBox(height: 20),
              pw.Align(
                alignment: pw.Alignment.centerRight,
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text('Subtotal: ${total.toStringAsFixed(2)} EGP'),
                    pw.Text('Discount: 0.00 EGP'),
                    pw.Text(
                      'Grand total: ${total.toStringAsFixed(2)} EGP',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                    ),
                    pw.Text(
                      'Paid: ${paid.toStringAsFixed(2)} EGP',
                    ),
                    pw.Text('Remaining: ${remaining.toStringAsFixed(2)} EGP'),
                    pw.Text(
                      remaining <= 0
                          ? 'Payment status: Paid'
                          : 'Payment status: Pending',
                    ),
                  ],
                ),
              ),
              pw.Spacer(),
              pw.Center(child: pw.Text('Thank you for your business.')),
            ],
          ),
        ),
      ),
    );
    return document.save();
  }

  static Future<void> print(
    List<SaleModel> sales,
    Map<String, MedicineModel> products,
    RepresentativeModel? representative,
  ) => Printing.layoutPdf(
    onLayout: (_) => build(sales, products, representative),
  );
  static Future<void> share(
    List<SaleModel> sales,
    Map<String, MedicineModel> products,
    RepresentativeModel? representative,
  ) async {
    final bytes = await build(sales, products, representative);
    await Printing.sharePdf(
      bytes: bytes,
      filename:
          '${AppFormatters.invoiceNumber(sales.first.invoiceId ?? sales.first.id)}.pdf',
    );
  }
}
