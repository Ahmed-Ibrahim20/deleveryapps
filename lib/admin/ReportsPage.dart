import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;
import '../services/Api/reports_service.dart';
import '../models/reports_model.dart';
import '../services/pdf_service.dart';

class ReportsPageDesign extends StatefulWidget {
  const ReportsPageDesign({super.key});

  @override
  State<ReportsPageDesign> createState() => _ReportsPageDesignState();
}

class _ReportsPageDesignState extends State<ReportsPageDesign> {
  final ReportsService _reportsService = ReportsService();

  // حالة التحميل والبيانات
  ReportsLoadingState _loadingState = ReportsLoadingState.initial;
  AdminReportsModel? _reportsData;
  ReportsError? _error;

  // تواريخ الفلترة
  DateTime? _startDate;
  DateTime? _endDate;

  // تنسيق التواريخ
  final DateFormat _dateFormatter = DateFormat('yyyy-MM-dd');
  final DateFormat _displayFormatter = DateFormat('yyyy/MM/dd');

  // دالة لتحويل التاريخ للعربية
  String _formatDateInArabic(DateTime date) {
    final months = [
      'يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو',
      'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  @override
  void initState() {
    super.initState();
    // البدء بدون تواريخ افتراضية لعرض كل البيانات
    _startDate = null;
    _endDate = null;

    // جلب البيانات عند بدء الصفحة (كل البيانات)
    _loadReports();
  }

  /// جلب تقارير الأدمن
  Future<void> _loadReports() async {
    setState(() {
      _loadingState = ReportsLoadingState.loading;
      _error = null;
    });

    try {
      final response = await _reportsService.getAdminReports(
        startDate: _startDate != null
            ? _dateFormatter.format(_startDate!)
            : null,
        endDate: _endDate != null ? _dateFormatter.format(_endDate!) : null,
      );

      if (response.statusCode == 200) {
        final reportsModel = AdminReportsModel.fromJson(response.data);
        setState(() {
          _reportsData = reportsModel;
          _loadingState = ReportsLoadingState.loaded;
        });
      } else {
        throw Exception('فشل في جلب التقارير: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        _error = ReportsError.fromException(e);
        _loadingState = ReportsLoadingState.error;
      });
      debugPrint('خطأ في جلب التقارير: $e');
    }
  }

  /// اختيار تاريخ البداية
  Future<void> _selectStartDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate:
          _startDate ?? DateTime.now().subtract(const Duration(days: 30)),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (picked != null && picked != _startDate) {
      setState(() {
        _startDate = picked;
        // التأكد من أن تاريخ البداية قبل تاريخ النهاية
        if (_endDate != null && _startDate!.isAfter(_endDate!)) {
          _endDate = _startDate;
        }
      });
      _loadReports();
    }
  }

  /// اختيار تاريخ النهاية
  Future<void> _selectEndDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _endDate ?? DateTime.now(),
      firstDate: _startDate ?? DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (picked != null && picked != _endDate) {
      setState(() {
        _endDate = picked;
        // التأكد من أن تاريخ النهاية بعد تاريخ البداية
        if (_startDate != null && _endDate!.isBefore(_startDate!)) {
          _startDate = _endDate;
        }
      });
      _loadReports();
    }
  }

  /// إعادة تعيين التواريخ لعرض كل البيانات
  void _resetDates() {
    setState(() {
      _startDate = null;
      _endDate = null;
    });
    _loadReports();
  }

  /// تصدير التقرير إلى PDF وحفظه
  Future<void> _exportToPDF() async {
    if (_reportsData == null) return;

    try {
      // عرض مؤشر التحميل
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      // إنشاء PDF
      final pdfBytes = await PDFService.generateAdminReportPDF(
        reportsData: _reportsData!,
        startDate: _startDate,
        endDate: _endDate,
      );

      // إنشاء اسم الملف
      final fileName = _generateFileName('تقرير_الأدمن');

      // حفظ الملف
      final filePath = await PDFService.savePDFToDevice(pdfBytes, fileName);

      // إغلاق مؤشر التحميل
      Navigator.of(context).pop();

      // عرض رسالة النجاح
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تم حفظ التقرير بنجاح في: $filePath'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 4),
          action: SnackBarAction(
            label: 'مشاركة',
            textColor: Colors.white,
            onPressed: () => PDFService.sharePDF(pdfBytes, fileName),
          ),
        ),
      );
    } catch (e) {
      // إغلاق مؤشر التحميل
      Navigator.of(context).pop();

      // عرض رسالة الخطأ
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('خطأ في تصدير PDF: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  /// معاينة PDF قبل الحفظ
  Future<void> _previewPDF() async {
    if (_reportsData == null) return;

    try {
      // عرض مؤشر التحميل
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      // إنشاء PDF
      final pdfBytes = await PDFService.generateAdminReportPDF(
        reportsData: _reportsData!,
        startDate: _startDate,
        endDate: _endDate,
      );

      // إغلاق مؤشر التحميل
      Navigator.of(context).pop();

      // عرض معاينة PDF
      await PDFService.previewPDF(
        context,
        pdfBytes,
        'معاينة تقرير الأدمن',
      );
    } catch (e) {
      // إغلاق مؤشر التحميل
      Navigator.of(context).pop();

      // عرض رسالة الخطأ
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('خطأ في معاينة PDF: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  /// إنشاء اسم الملف
  String _generateFileName(String prefix) {
    final now = DateTime.now();
    final dateStr = DateFormat('yyyy-MM-dd_HH-mm-ss').format(now);
    String periodStr = '';
    
    if (_startDate != null && _endDate != null) {
      final startStr = DateFormat('yyyy-MM-dd').format(_startDate!);
      final endStr = DateFormat('yyyy-MM-dd').format(_endDate!);
      periodStr = '_من_${startStr}_إلى_$endStr';
    } else {
      periodStr = '_جميع_البيانات';
    }
    
    return '${prefix}${periodStr}_$dateStr.pdf';
  }

  /// الحصول على عنوان الملخص
  String _getSummaryTitle(ReportsSummary summary) {
    if (_startDate == null && _endDate == null) {
      return 'الملخص (كل البيانات)';
    }
    return 'الملخص (من ${summary.period.startDate} إلى ${summary.period.endDate})';
  }

  /// بناء فلاتر التواريخ
  Widget _buildDateFilters() {
    return Column(
      children: [
        // تاريخ البداية
        ElevatedButton.icon(
          onPressed: _selectStartDate,
          icon: const Icon(Icons.calendar_today, color: Colors.white),
          label: Text(
            'من: ${_startDate != null ? _formatDateInArabic(_startDate!) : 'اختر التاريخ'}',
            style: const TextStyle(color: Colors.white),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            minimumSize: const Size(double.infinity, 48),
          ),
        ),
        const SizedBox(height: 8),
        // تاريخ النهاية
        ElevatedButton.icon(
          onPressed: _selectEndDate,
          icon: const Icon(Icons.calendar_today, color: Colors.white),
          label: Text(
            'إلى: ${_endDate != null ? _formatDateInArabic(_endDate!) : 'اختر التاريخ'}',
            style: const TextStyle(color: Colors.white),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            minimumSize: const Size(double.infinity, 48),
          ),
        ),
        const SizedBox(height: 8),
        // زر إعادة تعيين التواريخ (عرض كل البيانات)
        if (_startDate != null || _endDate != null)
          ElevatedButton.icon(
            onPressed: _resetDates,
            icon: const Icon(Icons.clear_all, color: Colors.white),
            label: const Text(
              'عرض كل البيانات (إلغاء الفلترة)',
              style: TextStyle(color: Colors.white),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              minimumSize: const Size(double.infinity, 48),
            ),
          ),
      ],
    );
  }

  /// بناء المحتوى حسب حالة التحميل
  Widget _buildContent() {
    switch (_loadingState) {
      case ReportsLoadingState.loading:
        return const Center(
          child: Padding(
            padding: EdgeInsets.all(50),
            child: Column(
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('جاري تحميل التقارير...'),
              ],
            ),
          ),
        );

      case ReportsLoadingState.error:
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                const Icon(Icons.error, color: Colors.red, size: 64),
                const SizedBox(height: 16),
                Text(
                  _error?.message ?? 'حدث خطأ غير متوقع',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                if (_error?.details != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    _error!.details!,
                    style: const TextStyle(color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                ],
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: _loadReports,
                  icon: const Icon(Icons.refresh),
                  label: const Text('إعادة المحاولة'),
                ),
              ],
            ),
          ),
        );

      case ReportsLoadingState.loaded:
        return _buildReportsContent();

      default:
        return const SizedBox.shrink();
    }
  }

  /// بناء محتوى التقارير
  Widget _buildReportsContent() {
    if (_reportsData == null) return const SizedBox.shrink();

    final data = _reportsData!.data;
    final summary = data.summary;
    final generalStats = data.generalStatistics;
    final topPerformance = data.topPerformance;

    return Column(
      children: [
        // ملخص التقارير
        _buildSummaryCard(summary),
        const SizedBox(height: 20),

        // الإحصائيات العامة
        _buildGeneralStatsCard(generalStats),
        const SizedBox(height: 20),

        // أفضل الأداء
        _buildTopPerformanceCard(topPerformance),
        const SizedBox(height: 30),

        // خيارات التصدير
        _buildExportOptions(),
      ],
    );
  }

  /// بطاقة الملخص
  Widget _buildSummaryCard(ReportsSummary summary) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Colors.blue, width: 1.2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionTitle(_getSummaryTitle(summary)),
            const SizedBox(height: 12),
            _buildDataRow(
              'عدد الطلبات المكتملة:',
              '${summary.completedOrdersCount} طلب',
              Icons.list_alt,
            ),
            _buildDataRow(
              'إجمالي رسوم التوصيل:',
              '${summary.totalDeliveryFees.toStringAsFixed(2)} جنيه',
              Icons.delivery_dining,
            ),
            _buildDataRow(
              'عمولة التطبيق (من المتاجر):',
              '${summary.shopCommissionTotal.toStringAsFixed(2)} جنيه',
              Icons.store,
            ),
            _buildDataRow(
              'عمولة التطبيق (من السائقين):',
              '${summary.driverCommissionTotal.toStringAsFixed(2)} جنيه',
              Icons.motorcycle,
            ),
            const Divider(height: 30),
            _buildDataRow(
              'إجمالي إيرادات المنصة:',
              '${summary.totalPlatformRevenue.toStringAsFixed(2)} جنيه',
              Icons.account_balance_wallet,
              isHighlight: true,
            ),
          ],
        ),
      ),
    );
  }

  /// بطاقة الإحصائيات العامة
  Widget _buildGeneralStatsCard(GeneralStatistics stats) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Colors.orange, width: 1.2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionTitle('إحصائيات عامة'),
            const SizedBox(height: 12),
            _buildTextRow(
              'عدد المتاجر:',
              '${stats.totalShopsCount} متجر',
              Icons.storefront,
            ),
            _buildTextRow(
              'عدد السائقين:',
              '${stats.totalDriversCount} دليفري',
              Icons.motorcycle,
            ),
            _buildTextRow(
              'المتاجر النشطة:',
              '${stats.activeShopsCount}',
              Icons.check_circle,
            ),
            _buildTextRow(
              'السائقين النشطين:',
              '${stats.activeDriversCount}',
              Icons.check_circle_outline,
            ),
          ],
        ),
      ),
    );
  }

  /// بطاقة أفضل الأداء
  Widget _buildTopPerformanceCard(TopPerformance performance) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Colors.green, width: 1.2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionTitle('أفضل الأداء'),
            const SizedBox(height: 12),

            // Top Stores
            Row(
              children: [
                Icon(Icons.storefront, color: Colors.green, size: 24),
                const SizedBox(width: 8),
                const Text(
                  'أكثر المتاجر نشاطاً',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...performance.topShops.asMap().entries.map((entry) {
              final index = entry.key;
              final shop = entry.value;
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.green.shade100,
                    child: Text(
                      '${index + 1}',
                      style: TextStyle(
                        color: Colors.green.shade800,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  title: Text(
                    shop.name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text('${shop.ordersCount} طلب'),
                  trailing: Text(
                    '${shop.totalOrdersValue.toStringAsFixed(0)} جنيه',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ),
              );
            }).toList(),

            const SizedBox(height: 20),

            // Top Drivers
            Row(
              children: [
                Icon(Icons.delivery_dining, color: Colors.green, size: 24),
                const SizedBox(width: 8),
                const Text(
                  'أكثر السائقين نشاطاً',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...performance.topDrivers.asMap().entries.map((entry) {
              final index = entry.key;
              final driver = entry.value;
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.green.shade100,
                    child: Text(
                      '${index + 1}',
                      style: TextStyle(
                        color: Colors.green.shade800,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  title: Text(
                    driver.name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text('${driver.ordersCount} طلب'),
                  trailing: Text(
                    '${driver.totalDeliveryFees.toStringAsFixed(0)} جنيه',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  /// خيارات التصدير
  Widget _buildExportOptions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('خيارات التصدير'),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _reportsData != null ? () => _exportToPDF() : null,
                icon: const Icon(Icons.picture_as_pdf, color: Colors.white),
                label: const Text(
                  'تحميل PDF',
                  style: TextStyle(color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  disabledBackgroundColor: Colors.grey,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _reportsData != null ? () => _previewPDF() : null,
                icon: const Icon(Icons.preview, color: Colors.white),
                label: const Text(
                  'معاينة PDF',
                  style: TextStyle(color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  disabledBackgroundColor: Colors.grey,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('التقارير'),
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
        ),
        body: RefreshIndicator(
          onRefresh: _loadReports,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const SizedBox(height: 12),

              // فلترة التواريخ
              _buildDateFilters(),

              const SizedBox(height: 20),

              // عرض المحتوى حسب حالة التحميل
              _buildContent(),
            ],
          ),
        ),
      ),
    );
  }

  /// بناء صف البيانات
  Widget _buildDataRow(
    String label,
    String value,
    IconData icon, {
    bool isHighlight = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, color: isHighlight ? Colors.green : Colors.blue, size: 22),
          const SizedBox(width: 8),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: TextStyle(
                  fontSize: isHighlight ? 18 : 16,
                  color: Colors.black,
                  fontWeight: isHighlight ? FontWeight.bold : FontWeight.normal,
                ),
                children: [
                  TextSpan(
                    text: '$label ',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  TextSpan(
                    text: value,
                    style: TextStyle(
                      color: isHighlight ? Colors.green : Colors.black87,
                      fontWeight: isHighlight
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, color: Colors.blue, size: 22),
          const SizedBox(width: 8),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(fontSize: 16, color: Colors.black),
                children: [
                  TextSpan(
                    text: '$label ',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  TextSpan(text: value),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.blue,
        ),
      ),
    );
  }
}
