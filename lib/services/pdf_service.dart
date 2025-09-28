import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  
  // خطوط عربية للـ PDF
  static pw.Font? _arabicFont;
  static pw.Font? _arabicBoldFont;
  
  /// تحميل الخطوط العربية والإنجليزية
  static Future<void> _loadArabicFonts() async {
    if (_arabicFont == null || _arabicBoldFont == null) {
      try {
        // استخدام خط مدمج في Flutter يدعم العربية
        final fontData = await rootBundle.load('fonts/NotoSansArabic-Regular.ttf');
        final boldFontData = await rootBundle.load('fonts/NotoSansArabic-Bold.ttf');
        
        _arabicFont = pw.Font.ttf(fontData);
        _arabicBoldFont = pw.Font.ttf(boldFontData);
      } catch (e) {
        try {
          // محاولة مع Google Fonts كـ fallback
          _arabicFont = await PdfGoogleFonts.notoSansArabicRegular();
          _arabicBoldFont = await PdfGoogleFonts.notoSansArabicBold();
        } catch (e2) {
          try {
            // محاولة مع Amiri font للعربية
            _arabicFont = await PdfGoogleFonts.amiriRegular();
            _arabicBoldFont = await PdfGoogleFonts.amiriBold();
          } catch (e3) {
            try {
              // محاولة أخيرة مع Cairo
              _arabicFont = await PdfGoogleFonts.cairoRegular();
              _arabicBoldFont = await PdfGoogleFonts.cairoBold();
            } catch (e4) {
              // استخدام الخط الافتراضي مع تحذير
              print('فشل في تحميل جميع الخطوط العربية: $e4');
              _arabicFont = null;
              _arabicBoldFont = null;
            }
          }
        }
      }
    }
  }

  /// تنسيق التاريخ
  static String _formatDate(String? dateString) {
    if (dateString == null || dateString.isEmpty) return 'غير محدد';
    try {
      final DateTime date = DateTime.parse(dateString);
      return _dateFormatter.format(date);
    } catch (e) {
      return 'غير محدد';
    }
  }

  /// بناء عنوان القسم - تصميم بسيط بدون ألوان
  static pw.Widget _buildSectionTitle(String title) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(vertical: 10, horizontal: 0),
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          bottom: pw.BorderSide(color: PdfColors.black, width: 1),
        ),
      ),
      child: pw.Text(
        title,
        style: pw.TextStyle(
          fontSize: 16,
          fontWeight: pw.FontWeight.bold,
          font: _arabicBoldFont ?? _arabicFont,
          color: PdfColors.black,
        ),
        textDirection: pw.TextDirection.rtl,
      ),
    );
  }

  /// إنشاء PDF للأدمن
  static Future<Uint8List> generateAdminReportPDF({
    required AdminReportsModel reportsData,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    // تحميل الخطوط العربية أولاً
    await _loadArabicFonts();
    
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
    // تحميل الخطوط العربية أولاً
    await _loadArabicFonts();
    
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
    // تحميل الخطوط العربية أولاً
    await _loadArabicFonts();
    
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

  /// بناء رأس التقرير - تصميم بسيط بدون ألوان
  static pw.Widget _buildReportHeader(String title, String period) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(20),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.black, width: 2),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          pw.Text(
            title,
            style: pw.TextStyle(
              fontSize: 22,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.black,
              font: _arabicBoldFont,
            ),
            textDirection: pw.TextDirection.rtl,
          ),
          pw.SizedBox(height: 8),
          pw.Text(
            period,
            style: pw.TextStyle(
              fontSize: 14,
              color: PdfColors.black,
              font: _arabicFont,
            ),
            textDirection: pw.TextDirection.rtl,
          ),
          pw.SizedBox(height: 8),
          pw.Text(
            'تاريخ الإنشاء: ${_dateFormatter.format(DateTime.now())} - ${_timeFormatter.format(DateTime.now())}',
            style: pw.TextStyle(
              fontSize: 11,
              color: PdfColors.black,
              font: _arabicFont,
            ),
            textDirection: pw.TextDirection.rtl,
          ),
        ],
      ),
    );
  }

  /// بناء قسم ملخص الأدمن - تصميم بسيط
  static pw.Widget _buildAdminSummarySection(ReportsSummary summary) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('ملخص التقارير'),
        pw.SizedBox(height: 10),
        pw.Container(
          width: double.infinity,
          padding: const pw.EdgeInsets.all(15),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.black, width: 1),
          ),
          child: pw.Column(
            children: [
              _buildDataRow('عدد الطلبات المكتملة:', '${summary.completedOrdersCount} طلب'),
              _buildDataRow('إجمالي قيمة الطلبات:', '${summary.totalOrdersValue.toStringAsFixed(2)} جنيه'),
              _buildDataRow('إجمالي رسوم التوصيل:', '${summary.totalDeliveryFees.toStringAsFixed(2)} جنيه'),
              _buildDataRow('عمولة التطبيق (من المتاجر):', '${summary.shopCommissionTotal.toStringAsFixed(2)} جنيه'),
              _buildDataRow('عمولة التطبيق (من السائقين):', '${summary.driverCommissionTotal.toStringAsFixed(2)} جنيه'),
              pw.Divider(color: PdfColors.black, thickness: 1),
              _buildDataRow(
                'إجمالي إيرادات المنصة:',
                '${summary.totalPlatformRevenue.toStringAsFixed(2)} جنيه',
                isHighlight: true,
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// بناء قسم الإحصائيات العامة - تصميم بسيط
  static pw.Widget _buildGeneralStatsSection(GeneralStatistics stats) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('إحصائيات عامة'),
        pw.SizedBox(height: 10),
        pw.Container(
          width: double.infinity,
          padding: const pw.EdgeInsets.all(15),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.black, width: 1),
          ),
          child: pw.Column(
            children: [
              _buildDataRow('عدد المتاجر:', '${stats.totalShopsCount} متجر'),
              _buildDataRow('عدد السائقين:', '${stats.totalDriversCount} دليفري'),
              _buildDataRow('المتاجر النشطة:', '${stats.activeShopsCount}'),
              _buildDataRow('السائقين النشطين:', '${stats.activeDriversCount}'),
            ],
          ),
        ),
      ],
    );
  }

  /// بناء قسم أفضل الأداء - تصميم بسيط
  static pw.Widget _buildTopPerformanceSection(TopPerformance performance) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('أفضل الأداء'),
        pw.SizedBox(height: 10),
        pw.Container(
          width: double.infinity,
          padding: const pw.EdgeInsets.all(15),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.black, width: 1),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // أكثر المتاجر نشاطاً
              pw.Text(
                'أكثر المتاجر نشاطاً:',
                style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.black,
                  font: _arabicBoldFont,
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
                  color: PdfColors.black,
                  font: _arabicBoldFont,
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
        ),
      ],
    );
  }

  /// بناء قسم بيانات المتجر - تصميم بسيط
  static pw.Widget _buildShopDataSection(ShopReportsData data) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('تفاصيل أداء المتجر'),
        pw.SizedBox(height: 10),
        pw.Container(
          width: double.infinity,
          padding: const pw.EdgeInsets.all(15),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.black, width: 1),
          ),
          child: pw.Column(
            children: [
              _buildDataRow('عدد الطلبات:', '${data.completedOrdersCount} طلب'),
              _buildDataRow('إجمالي قيمة الطلبات:', '${data.totalOrdersValue.toStringAsFixed(2)} جنيه'),
              _buildDataRow('إجمالي تكلفة التوصيل:', '${data.totalDeliveryFees.toStringAsFixed(2)} جنيه'),
              _buildDataRow('نسبة التطبيق:', '${data.applicationPercentage}%'),
              _buildDataRow('عمولة التطبيق:', '${data.applicationCommission.toStringAsFixed(2)} جنيه'),
              pw.Divider(color: PdfColors.black, thickness: 1),
              _buildDataRow(
                'صافي الأرباح:',
                '${data.netProfit.toStringAsFixed(2)} جنيه',
                isHighlight: true,
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// بناء قسم بيانات السائق - تصميم بسيط
  static pw.Widget _buildDeliveryDataSection(DeliveryReportsData data) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('تفاصيل أداء السائق'),
        pw.SizedBox(height: 10),
        pw.Container(
          width: double.infinity,
          padding: const pw.EdgeInsets.all(15),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.black, width: 1),
          ),
          child: pw.Column(
            children: [
              _buildDataRow('عدد الطلبات:', '${data.completedOrdersCount} طلب'),
              _buildDataRow('إجمالي تكلفة التوصيل:', '${data.totalDeliveryFees.toStringAsFixed(2)} جنيه'),
              _buildDataRow('نسبة التطبيق:', '${data.applicationPercentage}%'),
              _buildDataRow('عمولة التطبيق:', '${data.applicationCommission.toStringAsFixed(2)} جنيه'),
              pw.Divider(color: PdfColors.black, thickness: 1),
              _buildDataRow(
                'صافي الأرباح:',
                '${data.netProfit.toStringAsFixed(2)} جنيه',
                isHighlight: true,
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// بناء صف البيانات - تصميم بسيط بدون ألوان
  static pw.Widget _buildDataRow(String label, String value, {bool isHighlight = false}) {
    return pw.Container(
      margin: const pw.EdgeInsets.symmetric(vertical: 4),
      padding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 0),
      decoration: pw.BoxDecoration(
        border: pw.Border(
          bottom: pw.BorderSide(
            color: PdfColors.grey400, 
            width: 0.5,
          ),
        ),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Expanded(
            flex: 3,
            child: pw.Text(
              label,
              style: pw.TextStyle(
                fontSize: isHighlight ? 13 : 12,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.black,
                font: _arabicBoldFont ?? _arabicFont,
              ),
              textDirection: pw.TextDirection.rtl,
            ),
          ),
          pw.SizedBox(width: 15),
          pw.Expanded(
            flex: 2,
            child: pw.Text(
              value,
              style: pw.TextStyle(
                fontSize: isHighlight ? 13 : 12,
                fontWeight: isHighlight ? pw.FontWeight.bold : pw.FontWeight.normal,
                color: PdfColors.black,
                font: _arabicFont,
              ),
              textDirection: pw.TextDirection.rtl,
              textAlign: pw.TextAlign.left,
            ),
          ),
        ],
      ),
    );
  }

  /// بناء صف الترتيب - تصميم بسيط بدون ألوان
  static pw.Widget _buildRankingRow(String rank, String name, String orders, String amount) {
    return pw.Container(
      margin: const pw.EdgeInsets.symmetric(vertical: 3),
      padding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 0),
      decoration: pw.BoxDecoration(
        border: pw.Border(
          bottom: pw.BorderSide(
            color: PdfColors.grey300, 
            width: 0.5,
          ),
        ),
      ),
      child: pw.Row(
        children: [
          pw.Container(
            width: 20,
            height: 20,
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.black, width: 1),
              borderRadius: pw.BorderRadius.circular(10),
            ),
            child: pw.Center(
              child: pw.Text(
                rank,
                style: pw.TextStyle(
                  fontSize: 10,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.black,
                  font: _arabicBoldFont,
                ),
              ),
            ),
          ),
          pw.SizedBox(width: 10),
          pw.Expanded(
            flex: 3,
            child: pw.Text(
              name,
              style: pw.TextStyle(
                fontSize: 11,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.black,
                font: _arabicBoldFont ?? _arabicFont,
              ),
              textDirection: pw.TextDirection.rtl,
            ),
          ),
          pw.SizedBox(width: 8),
          pw.Expanded(
            flex: 2,
            child: pw.Text(
              orders,
              style: pw.TextStyle(
                fontSize: 10,
                color: PdfColors.black,
                font: _arabicFont,
              ),
              textDirection: pw.TextDirection.rtl,
              textAlign: pw.TextAlign.center,
            ),
          ),
          pw.SizedBox(width: 8),
          pw.Expanded(
            flex: 2,
            child: pw.Text(
              amount,
              style: pw.TextStyle(
                fontSize: 10,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.black,
                font: _arabicBoldFont ?? _arabicFont,
              ),
              textDirection: pw.TextDirection.rtl,
              textAlign: pw.TextAlign.left,
            ),
          ),
        ],
      ),
    );
  }

  /// بناء تذييل التقرير - تصميم بسيط بدون ألوان
  static pw.Widget _buildReportFooter() {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(15),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.black, width: 1),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          pw.Text(
            'تطبيق التوصيل',
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.black,
              font: _arabicBoldFont,
            ),
            textDirection: pw.TextDirection.rtl,
          ),
          pw.SizedBox(height: 5),
          pw.Text(
            'تم إنشاء هذا التقرير تلقائياً بواسطة النظام',
            style: pw.TextStyle(
              fontSize: 10,
              color: PdfColors.black,
              font: _arabicFont,
            ),
            textDirection: pw.TextDirection.rtl,
          ),
          pw.Text(
            'جميع الحقوق محفوظة ${DateTime.now().year}',
            style: pw.TextStyle(
              fontSize: 10,
              color: PdfColors.black,
              font: _arabicFont,
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
      if (kIsWeb) {
        // على الويب، استخدم مشاركة الملف مباشرة
        await Printing.sharePdf(bytes: pdfBytes, filename: fileName);
        return 'تم تحميل الملف بنجاح';
      } else {
        // على الموبايل، احفظ في مجلد التحميلات
        final directory = await getApplicationDocumentsDirectory();
        final file = File('${directory.path}/$fileName');
        await file.writeAsBytes(pdfBytes);
        return file.path;
      }
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

  /// إنشاء PDF للطلبات السابقة للمتاجر
  static Future<String> generateShopOrdersPDF(Map<String, dynamic> data, String fileName) async {
    try {
      // تحميل الخطوط العربية أولاً
      await _loadArabicFonts();
      
      final pdf = pw.Document();
      final orders = data['orders'] as List<Map<String, dynamic>>? ?? [];
      
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          textDirection: pw.TextDirection.rtl,
          build: (pw.Context context) {
            return [
              // رأس التقرير
              _buildReportHeader(
                'تقرير الطلبات السابقة - ${data['shop_name'] ?? 'المتجر'}',
                data['from_date'] != null && data['to_date'] != null
                    ? 'من ${_formatDate(data['from_date'])} إلى ${_formatDate(data['to_date'])}'
                    : 'جميع الطلبات',
              ),
              
              pw.SizedBox(height: 20),
              
              // ملخص الطلبات
              _buildShopOrdersSummarySection(data),
              
              pw.SizedBox(height: 20),
              
              // قائمة الطلبات
              if (orders.isNotEmpty) ...[
                _buildSectionTitle('تفاصيل الطلبات'),
                pw.SizedBox(height: 10),
                ...orders.map((order) => _buildOrderRow(order)).toList(),
              ] else ...[
                pw.Center(
                  child: pw.Text(
                    'لا توجد طلبات في الفترة المحددة',
                    style: pw.TextStyle(
                      fontSize: 16,
                      font: _arabicFont,
                      color: PdfColors.grey700,
                    ),
                    textDirection: pw.TextDirection.rtl,
                  ),
                ),
              ],
              
              pw.SizedBox(height: 30),
              
              // تذييل التقرير
              _buildReportFooter(),
            ];
          },
        ),
      );

      final pdfBytes = await pdf.save();
      return await savePDFToDevice(pdfBytes, fileName);
    } catch (e) {
      throw Exception('فشل في إنشاء تقرير الطلبات: $e');
    }
  }

  /// معاينة PDF للطلبات السابقة للمتاجر
  static Future<void> previewShopOrdersPDF(Map<String, dynamic> data) async {
    try {
      // تحميل الخطوط العربية أولاً
      await _loadArabicFonts();
      
      final pdf = pw.Document();
      final orders = data['orders'] as List<Map<String, dynamic>>? ?? [];
      
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          textDirection: pw.TextDirection.rtl,
          build: (pw.Context context) {
            return [
              // رأس التقرير
              _buildReportHeader(
                'تقرير الطلبات السابقة - ${data['shop_name'] ?? 'المتجر'}',
                data['from_date'] != null && data['to_date'] != null
                    ? 'من ${_formatDate(data['from_date'])} إلى ${_formatDate(data['to_date'])}'
                    : 'جميع الطلبات',
              ),
              
              pw.SizedBox(height: 20),
              
              // ملخص الطلبات
              _buildShopOrdersSummarySection(data),
              
              pw.SizedBox(height: 20),
              
              // قائمة الطلبات
              if (orders.isNotEmpty) ...[
                _buildSectionTitle('تفاصيل الطلبات'),
                pw.SizedBox(height: 10),
                ...orders.map((order) => _buildOrderRow(order)).toList(),
              ] else ...[
                pw.Center(
                  child: pw.Text(
                    'لا توجد طلبات في الفترة المحددة',
                    style: pw.TextStyle(
                      fontSize: 16,
                      font: _arabicFont,
                      color: PdfColors.grey700,
                    ),
                    textDirection: pw.TextDirection.rtl,
                  ),
                ),
              ],
              
              pw.SizedBox(height: 30),
              
              // تذييل التقرير
              _buildReportFooter(),
            ];
          },
        ),
      );

      final pdfBytes = await pdf.save();
      await Printing.sharePdf(
        bytes: pdfBytes,
        filename: 'معاينة_تقرير_الطلبات_السابقة.pdf',
      );
    } catch (e) {
      throw Exception('فشل في معاينة تقرير الطلبات: $e');
    }
  }

  /// بناء قسم ملخص طلبات المتجر - تصميم بسيط
  static pw.Widget _buildShopOrdersSummarySection(Map<String, dynamic> data) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('ملخص الطلبات'),
        pw.SizedBox(height: 10),
        pw.Container(
          padding: const pw.EdgeInsets.all(16),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.black, width: 1),
          ),
          child: pw.Column(
            children: [
              _buildDataRow('اسم المتجر', data['shop_name']?.toString() ?? 'غير محدد'),
              _buildDataRow('رقم الهاتف', data['phone']?.toString() ?? 'غير محدد'),
              _buildDataRow('عدد الطلبات', data['total_orders']?.toString() ?? '0'),
              _buildDataRow('إجمالي رسوم التوصيل', '${data['total_delivery_fees']?.toString() ?? '0'} جنيه', isHighlight: true),
            ],
          ),
        ),
      ],
    );
  }

  /// بناء صف طلب واحد - تصميم بسيط بدون ألوان
  static pw.Widget _buildOrderRow(Map<String, dynamic> order) {
    return pw.Container(
      margin: const pw.EdgeInsets.symmetric(vertical: 4),
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.black, width: 0.5),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          // معلومات الطلب الأساسية
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'طلب رقم ${order['id']?.toString() ?? 'غير محدد'}',
                style: pw.TextStyle(
                  fontSize: 12,
                  fontWeight: pw.FontWeight.bold,
                  font: _arabicBoldFont ?? _arabicFont,
                  color: PdfColors.black,
                ),
                textDirection: pw.TextDirection.rtl,
              ),
              pw.Text(
                '${order['delivery_fee']?.toString() ?? '0'} جنيه',
                style: pw.TextStyle(
                  fontSize: 12,
                  fontWeight: pw.FontWeight.bold,
                  font: _arabicBoldFont ?? _arabicFont,
                  color: PdfColors.black,
                ),
                textDirection: pw.TextDirection.rtl,
              ),
            ],
          ),
          pw.SizedBox(height: 6),
          
          // معلومات العميل
          pw.Row(
            children: [
              pw.Text(
                'العميل: ',
                style: pw.TextStyle(
                  fontSize: 10,
                  font: _arabicFont,
                  color: PdfColors.black,
                ),
                textDirection: pw.TextDirection.rtl,
              ),
              pw.Expanded(
                child: pw.Text(
                  order['customer_name']?.toString() ?? 'غير محدد',
                  style: pw.TextStyle(
                    fontSize: 10,
                    font: _arabicFont,
                    color: PdfColors.black,
                  ),
                  textDirection: pw.TextDirection.rtl,
                ),
              ),
              pw.SizedBox(width: 20),
              pw.Text(
                'الهاتف: ${order['customer_phone']?.toString() ?? 'غير محدد'}',
                style: pw.TextStyle(
                  fontSize: 10,
                  font: _arabicFont,
                  color: PdfColors.black,
                ),
                textDirection: pw.TextDirection.rtl,
              ),
            ],
          ),
          pw.SizedBox(height: 4),
          
          // العنوان والتاريخ
          pw.Row(
            children: [
              pw.Text(
                'العنوان: ',
                style: pw.TextStyle(
                  fontSize: 10,
                  font: _arabicFont,
                  color: PdfColors.black,
                ),
                textDirection: pw.TextDirection.rtl,
              ),
              pw.Expanded(
                child: pw.Text(
                  order['customer_address']?.toString() ?? 'غير محدد',
                  style: pw.TextStyle(
                    fontSize: 10,
                    font: _arabicFont,
                    color: PdfColors.black,
                  ),
                  textDirection: pw.TextDirection.rtl,
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 4),
          
          pw.Text(
            'التاريخ: ${_formatDate(order['created_at']?.toString() ?? '')}',
            style: pw.TextStyle(
              fontSize: 9,
              font: _arabicFont,
              color: PdfColors.black,
            ),
            textDirection: pw.TextDirection.rtl,
          ),
        ],
      ),
    );
  }
}
