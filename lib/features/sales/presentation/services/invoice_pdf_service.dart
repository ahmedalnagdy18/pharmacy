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
    final baseFont = await PdfGoogleFonts.cairoRegular();
    final boldFont = await PdfGoogleFonts.cairoBold();
    final document = pw.Document(
      theme: pw.ThemeData.withFont(base: baseFont, bold: boldFont),
    );
    final sale = sales.first;
    final total = sales.fold<double>(0, (sum, item) => sum + item.total);
    final paid = sale.amountPaid ?? total;
    final remaining = total - paid;
    document.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (_) => pw.Directionality(
          textDirection: pw.TextDirection.rtl,
          child: pw.Padding(
            padding: const pw.EdgeInsets.all(32),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'مرعى مستحضرات تجميل',
                  style: pw.TextStyle(
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 8),
                pw.Text(
                  'فاتورة رقم ${AppFormatters.invoiceNumber(sale.invoiceId ?? sale.id)}',
                ),
                pw.Text('التاريخ: ${AppFormatters.dateTime.format(sale.date)}'),
                pw.Text('الهاتف: 01024521310'),
                pw.Divider(),
                pw.Text('العميل: ${sale.customerName ?? 'عميل نقدي'}'),
                pw.Text('هاتف العميل: ${sale.customerPhone ?? '-'}'),
                if (representative != null)
                  pw.Text('المندوب: ${representative.name}'),
                pw.SizedBox(height: 20),
                pw.TableHelper.fromTextArray(
                  headers: const ['المنتج', 'الكمية', 'سعر الوحدة', 'الاجمالي'],
                  data: sales
                      .map(
                        (item) => [
                          products[item.productId]?.name ?? 'منتج غير معروف',
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
                      pw.Text(
                        'الإجمالي الفرعي: ${total.toStringAsFixed(2)} ج.م',
                      ),
                      pw.Text(
                        'الإجمالي: ${total.toStringAsFixed(2)} ج.م',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                      ),
                      pw.Text(
                        'المدفوع: ${paid.toStringAsFixed(2)} ج.م',
                      ),
                      pw.Text('المتبقي: ${remaining.toStringAsFixed(2)} ج.م'),
                      pw.Text(
                        remaining <= 0
                            ? 'حالة الدفع: مدفوع'
                            : 'حالة الدفع: متبقي',
                      ),
                    ],
                  ),
                ),
                pw.Spacer(),
                pw.Center(child: pw.Text('شكرًا لتعاملكم معنا')),
              ],
            ),
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
