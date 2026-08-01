import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pharmacy/features/products/data/model/medicine_model.dart';
import 'package:printing/printing.dart';
import 'package:pharmacy/widgets/app_formatters.dart';

class ProductsPdfService {
  const ProductsPdfService._();

  static Future<Uint8List> build(List<MedicineModel> products) async {
    final baseFont = await PdfGoogleFonts.cairoRegular();
    final boldFont = await PdfGoogleFonts.cairoBold();
    final document = pw.Document(
      theme: pw.ThemeData.withFont(base: baseFont, bold: boldFont),
    );
    document.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (_) => [
          pw.Directionality(
            textDirection: pw.TextDirection.rtl,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'قائمة المنتجات - مرعى مستحضرات تجميل',
                  style: pw.TextStyle(
                    fontSize: 20,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 8),
                pw.Text(
                  'تاريخ التصدير: ${AppFormatters.dateTime.format(DateTime.now())}',
                ),
                pw.SizedBox(height: 16),
                pw.TableHelper.fromTextArray(
                  headers: const [
                    'المنتج',
                    'التصنيف',
                    'الباركود',
                    'الكمية',
                    'سعر البيع',
                  ],
                  data: products
                      .map(
                        (product) => [
                          product.name,
                          product.category,
                          product.barcode,
                          '${product.quantity}',
                          AppFormatters.currency.format(product.sellingPrice),
                        ],
                      )
                      .toList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
    return document.save();
  }

  static Future<void> share(List<MedicineModel> products) async {
    final bytes = await build(products);
    await Printing.sharePdf(bytes: bytes, filename: 'products.pdf');
  }
}
