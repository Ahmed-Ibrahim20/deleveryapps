import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import '../models/reports_model.dart';
import '../models/shop_reports_model.dart';
import '../models/delivery_reports_model.dart';

class PDFService {
  static final DateFormat _dateFormatter = DateFormat('yyyy/MM/dd');
  static final DateFormat _timeFormatter = DateFormat('HH:mm:ss');

  /// إنشاء PDF للأدمن
  static Future<Uint8List> generateAdminReportPDF({
    required AdminReportsModel reportsData,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final pdf = pw.Document();
    final data = reportsData.data;
    final summary = data.summary;
    final generalStats = data.generalStatistics;
    final topPerformance = data.topPerformance;

    // إنشاء عنوان التقرير
    String reportTitle = 'تقرير الأدمن الشامل';
    String periodText = '';
    if (startDate != null && endDate != null) {
      periodText = 'من ${_dateFormatter.format(startDate)} إلى ${_dateFormatter.format(endDate)}';
    } else {
      periodText = 'جميع البيانات';
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        textDirection: pw.TextDirection.rtl,
        build: (pw.Context context) {
          return [
            // رأس التقرير
            _buildReportHeader(reportTitle, periodText),
            pw.SizedBox(height: 20),

            // ملخص التقارير
            _buildAdminSummarySection(summary),
            pw.SizedBox(height: 20),

            // الإحصائيات العامة
            _buildGeneralStatsSection(generalStats),
            pw.SizedBox(height: 20),

            // أفضل الأداء
            _buildTopPerformanceSection(topPerformance),
            pw.SizedBox(height: 20),

            // تذييل التقرير
            _buildReportFooter(),
          ];
        },
      ),
    );

    return pdf.save();
  }

  /// إنشاء PDF للمتجر
  static Future<Uint8List> generateShopReportPDF({
    required ShopReportsModel reportsData,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final pdf = pw.Document();
    final data = reportsData.data;

    // إنشاء عنوان التقرير
    String reportTitle = 'تقرير المتجر';
    String periodText = '';
    if (startDate != null && endDate != null) {
      periodText = 'من ${_dateFormatter.format(startDate)} إلى ${_dateFormatter.format(endDate)}';
    } else {
      periodText = 'جميع البيانات';
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        textDirection: pw.TextDirection.rtl,
        build: (pw.Context context) {
          return [
            // رأس التقرير
            _buildReportHeader(reportTitle, periodText),
            pw.SizedBox(height: 20),

            // بيانات المتجر
            _buildShopDataSection(data),
            pw.SizedBox(height: 20),

            // تذييل التقرير
            _buildReportFooter(),
          ];
        },
      ),
    );

    return pdf.save();
  }

  /// إنشاء PDF للسائق
  static Future<Uint8List> generateDeliveryReportPDF({
    required DeliveryReportsModel reportsData,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final pdf = pw.Document();
    final data = reportsData.data;

    // إنشاء عنوان التقرير
    String reportTitle = 'تقرير السائق';
    String periodText = '';
    if (startDate != null && endDate != null) {
      periodText = 'من ${_dateFormatter.format(startDate)} إلى ${_dateFormatter.format(endDate)}';
    } else {
      periodText = 'جميع البيانات';
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        textDirection: pw.TextDirection.rtl,
        build: (pw.Context context) {
          return [
            // رأس التقرير
            _buildReportHeader(reportTitle, periodText),
            pw.SizedBox(height: 20),

            // بيانات السائق
            _buildDeliveryDataSection(data),
            pw.SizedBox(height: 20),

            // تذييل التقرير
            _buildReportFooter(),
          ];
        },
      ),
    );

    return pdf.save();
  }

  /// بناء رأس التقرير
  static pw.Widget _buildReportHeader(String title, String period) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(20),
      decoration: pw.BoxDecoration(
        color: PdfColors.blue100,
        border: pw.Border.all(color: PdfColors.blue, width: 2),
        borderRadius: pw.BorderRadius.circular(10),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          pw.Text(
            title,
            style: pw.TextStyle(
              fontSize: 24,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.blue900,
            ),
            textDirection: pw.TextDirection.rtl,
          ),
          pw.SizedBox(height: 10),
          pw.Text(
            period,
            style: pw.TextStyle(
              fontSize: 16,
              color: PdfColors.blue700,
            ),
            textDirection: pw.TextDirection.rtl,
          ),
          pw.SizedBox(height: 10),
          pw.Text(
            'تاريخ الإنشاء: ${_dateFormatter.format(DateTime.now())} - ${_timeFormatter.format(DateTime.now())}',
            style: pw.TextStyle(
              fontSize: 12,
              color: PdfColors.grey600,
            ),
            textDirection: pw.TextDirection.rtl,
          ),
        ],
      ),
    );
  }

  /// بناء قسم ملخص الأدمن
  static pw.Widget _buildAdminSummarySection(ReportsSummary summary) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(15),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.blue, width: 1),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'ملخص التقارير',
            style: pw.TextStyle(
              fontSize: 18,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.blue900,
            ),
            textDirection: pw.TextDirection.rtl,
          ),
          pw.SizedBox(height: 15),
          _buildDataRow('عدد الطلبات المكتملة:', '${summary.completedOrdersCount} طلب'),
          _buildDataRow('إجمالي قيمة الطلبات:', '${summary.totalOrdersValue.toStringAsFixed(2)} جنيه'),
          _buildDataRow('إجمالي رسوم التوصيل:', '${summary.totalDeliveryFees.toStringAsFixed(2)} جنيه'),
          _buildDataRow('عمولة التطبيق (من المتاجر):', '${summary.shopCommissionTotal.toStringAsFixed(2)} جنيه'),
          _buildDataRow('عمولة التطبيق (من السائقين):', '${summary.driverCommissionTotal.toStringAsFixed(2)} جنيه'),
          pw.Divider(color: PdfColors.grey400, thickness: 1),
          _buildDataRow(
            'إجمالي إيرادات المنصة:',
            '${summary.totalPlatformRevenue.toStringAsFixed(2)} جنيه',
            isHighlight: true,
          ),
        ],
      ),
    );
  }

  /// بناء قسم الإحصائيات العامة
  static pw.Widget _buildGeneralStatsSection(GeneralStatistics stats) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(15),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.orange, width: 1),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'إحصائيات عامة',
            style: pw.TextStyle(
              fontSize: 18,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.orange900,
            ),
            textDirection: pw.TextDirection.rtl,
          ),
          pw.SizedBox(height: 15),
          _buildDataRow('عدد المتاجر:', '${stats.totalShopsCount} متجر'),
          _buildDataRow('عدد السائقين:', '${stats.totalDriversCount} دليفري'),
          _buildDataRow('المتاجر النشطة:', '${stats.activeShopsCount}'),
          _buildDataRow('السائقين النشطين:', '${stats.activeDriversCount}'),
        ],
      ),
    );
  }

  /// بناء قسم أفضل الأداء
  static pw.Widget _buildTopPerformanceSection(TopPerformance performance) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(15),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.green, width: 1),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'أفضل الأداء',
            style: pw.TextStyle(
              fontSize: 18,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.green900,
            ),
            textDirection: pw.TextDirection.rtl,
          ),
          pw.SizedBox(height: 15),
          
          // أكثر المتاجر نشاطاً
          pw.Text(
            'أكثر المتاجر نشاطاً:',
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.green700,
            ),
            textDirection: pw.TextDirection.rtl,
          ),
          pw.SizedBox(height: 8),
          ...performance.topShops.asMap().entries.map((entry) {
            final index = entry.key;
            final shop = entry.value;
            return _buildRankingRow(
              '${index + 1}',
              shop.name,
              '${shop.ordersCount} طلب',
              '${shop.totalOrdersValue.toStringAsFixed(0)} جنيه',
            );
          }).toList(),
          
          pw.SizedBox(height: 15),
          
          // أكثر السائقين نشاطاً
          pw.Text(
            'أكثر السائقين نشاطاً:',
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.green700,
            ),
            textDirection: pw.TextDirection.rtl,
          ),
          pw.SizedBox(height: 8),
          ...performance.topDrivers.asMap().entries.map((entry) {
            final index = entry.key;
            final driver = entry.value;
            return _buildRankingRow(
              '${index + 1}',
              driver.name,
              '${driver.ordersCount} طلب',
              '${driver.totalDeliveryFees.toStringAsFixed(0)} جنيه',
            );
          }).toList(),
        ],
      ),
    );
  }

  /// بناء قسم بيانات المتجر
  static pw.Widget _buildShopDataSection(ShopReportsData data) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(15),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.blue, width: 1),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'تفاصيل أداء المتجر',
            style: pw.TextStyle(
              fontSize: 18,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.blue900,
            ),
            textDirection: pw.TextDirection.rtl,
          ),
          pw.SizedBox(height: 15),
          _buildDataRow('عدد الطلبات:', '${data.completedOrdersCount} طلب'),
          _buildDataRow('إجمالي قيمة الطلبات:', '${data.totalOrdersValue.toStringAsFixed(2)} جنيه'),
          _buildDataRow('إجمالي تكلفة التوصيل:', '${data.totalDeliveryFees.toStringAsFixed(2)} جنيه'),
          _buildDataRow('نسبة التطبيق:', '${data.applicationPercentage}%'),
          _buildDataRow('عمولة التطبيق:', '${data.applicationCommission.toStringAsFixed(2)} جنيه'),
          pw.Divider(color: PdfColors.grey400, thickness: 1),
          _buildDataRow(
            'صافي الأرباح:',
            '${data.netProfit.toStringAsFixed(2)} جنيه',
            isHighlight: true,
          ),
        ],
      ),
    );
  }

  /// بناء قسم بيانات السائق
  static pw.Widget _buildDeliveryDataSection(DeliveryReportsData data) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(15),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.blue, width: 1),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'تفاصيل أداء السائق',
            style: pw.TextStyle(
              fontSize: 18,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.blue900,
            ),
            textDirection: pw.TextDirection.rtl,
          ),
          pw.SizedBox(height: 15),
          _buildDataRow('عدد الطلبات:', '${data.completedOrdersCount} طلب'),
          _buildDataRow('إجمالي تكلفة التوصيل:', '${data.totalDeliveryFees.toStringAsFixed(2)} جنيه'),
          _buildDataRow('نسبة التطبيق:', '${data.applicationPercentage}%'),
          _buildDataRow('عمولة التطبيق:', '${data.applicationCommission.toStringAsFixed(2)} جنيه'),
          pw.Divider(color: PdfColors.grey400, thickness: 1),
          _buildDataRow(
            'صافي الأرباح:',
            '${data.netProfit.toStringAsFixed(2)} جنيه',
            isHighlight: true,
          ),
        ],
      ),
    );
  }

  /// بناء صف البيانات
  static pw.Widget _buildDataRow(String label, String value, {bool isHighlight = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Expanded(
            flex: 2,
            child: pw.Text(
              label,
              style: pw.TextStyle(
                fontSize: isHighlight ? 14 : 12,
                fontWeight: pw.FontWeight.bold,
                color: isHighlight ? PdfColors.green900 : PdfColors.black,
              ),
              textDirection: pw.TextDirection.rtl,
            ),
          ),
          pw.Expanded(
            flex: 1,
            child: pw.Text(
              value,
              style: pw.TextStyle(
                fontSize: isHighlight ? 14 : 12,
                fontWeight: isHighlight ? pw.FontWeight.bold : pw.FontWeight.normal,
                color: isHighlight ? PdfColors.green700 : PdfColors.grey700,
              ),
              textDirection: pw.TextDirection.rtl,
              textAlign: pw.TextAlign.left,
            ),
          ),
        ],
      ),
    );
  }

  /// بناء صف الترتيب
  static pw.Widget _buildRankingRow(String rank, String name, String orders, String amount) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 3),
      child: pw.Row(
        children: [
          pw.Container(
            width: 25,
            height: 25,
            decoration: pw.BoxDecoration(
              color: PdfColors.green100,
              border: pw.Border.all(color: PdfColors.green, width: 1),
              borderRadius: pw.BorderRadius.circular(12.5),
            ),
            child: pw.Center(
              child: pw.Text(
                rank,
                style: pw.TextStyle(
                  fontSize: 10,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.green900,
                ),
              ),
            ),
          ),
          pw.SizedBox(width: 10),
          pw.Expanded(
            flex: 2,
            child: pw.Text(
              name,
              style: pw.TextStyle(
                fontSize: 11,
                fontWeight: pw.FontWeight.bold,
              ),
              textDirection: pw.TextDirection.rtl,
            ),
          ),
          pw.Expanded(
            flex: 1,
            child: pw.Text(
              orders,
              style: const pw.TextStyle(fontSize: 10),
              textDirection: pw.TextDirection.rtl,
              textAlign: pw.TextAlign.center,
            ),
          ),
          pw.Expanded(
            flex: 1,
            child: pw.Text(
              amount,
              style: pw.TextStyle(
                fontSize: 10,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.green700,
              ),
              textDirection: pw.TextDirection.rtl,
              textAlign: pw.TextAlign.left,
            ),
          ),
        ],
      ),
    );
  }

  /// بناء تذييل التقرير
  static pw.Widget _buildReportFooter() {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(15),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        border: pw.Border.all(color: PdfColors.grey400, width: 1),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          pw.Text(
            'تطبيق التوصيل',
            style: pw.TextStyle(
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.blue900,
            ),
            textDirection: pw.TextDirection.rtl,
          ),
          pw.SizedBox(height: 5),
          pw.Text(
            'تم إنشاء هذا التقرير تلقائياً بواسطة النظام',
            style: pw.TextStyle(
              fontSize: 10,
              color: PdfColors.grey600,
            ),
            textDirection: pw.TextDirection.rtl,
          ),
          pw.Text(
            'جميع الحقوق محفوظة © ${DateTime.now().year}',
            style: pw.TextStyle(
              fontSize: 10,
              color: PdfColors.grey600,
            ),
            textDirection: pw.TextDirection.rtl,
          ),
        ],
      ),
    );
  }

  /// حفظ PDF في الجهاز
  static Future<String> savePDFToDevice(Uint8List pdfBytes, String fileName) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/$fileName');
      await file.writeAsBytes(pdfBytes);
      return file.path;
    } catch (e) {
      throw Exception('فشل في حفظ الملف: $e');
    }
  }

  /// مشاركة PDF
  static Future<void> sharePDF(Uint8List pdfBytes, String fileName) async {
    try {
      await Printing.sharePdf(
        bytes: pdfBytes,
        filename: fileName,
      );
    } catch (e) {
      throw Exception('فشل في مشاركة الملف: $e');
    }
  }

  /// طباعة PDF
  static Future<void> printPDF(Uint8List pdfBytes) async {
    try {
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdfBytes,
      );
    } catch (e) {
      throw Exception('فشل في طباعة الملف: $e');
    }
  }

  /// معاينة PDF
  static Future<void> previewPDF(BuildContext context, Uint8List pdfBytes, String title) async {
    try {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => Scaffold(
            appBar: AppBar(
              title: Text(title),
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
            body: PdfPreview(
              build: (format) => pdfBytes,
              allowPrinting: true,
              allowSharing: true,
              canChangePageFormat: false,
            ),
          ),
        ),
      );
    } catch (e) {
      throw Exception('فشل في معاينة الملف: $e');
    }
  }
}
