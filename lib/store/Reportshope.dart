import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;
import '../services/Api/shop_reports_service.dart';
import '../models/shop_reports_model.dart';
import '../services/pdf_service.dart';

class report_shope extends StatefulWidget {
  final String phone;

  const report_shope({super.key, required this.phone});

  @override
  State<report_shope> createState() => _ReportShopeState();
}

class _ReportShopeState extends State<report_shope> {
  final ShopReportsService _reportsService = ShopReportsService();

  // حالة التحميل والبيانات
  ShopReportsLoadingState _loadingState = ShopReportsLoadingState.initial;
  ShopReportsModel? _reportsData;
  ShopReportsError? _error;

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

  /// جلب تقارير المتجر
  Future<void> _loadReports() async {
    setState(() {
      _loadingState = ShopReportsLoadingState.loading;
      _error = null;
    });

    try {
      final response = await _reportsService.getMyShopReports(
        startDate: _startDate != null
            ? _dateFormatter.format(_startDate!)
            : null,
        endDate: _endDate != null ? _dateFormatter.format(_endDate!) : null,
      );

      if (response.statusCode == 200) {
        final reportsModel = ShopReportsModel.fromJson(response.data);
        setState(() {
          _reportsData = reportsModel;
          _loadingState = ShopReportsLoadingState.loaded;
        });
      } else {
        throw Exception('فشل في جلب التقارير: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        _error = ShopReportsError.fromException(e);
        _loadingState = ShopReportsLoadingState.error;
      });
      debugPrint('خطأ في جلب تقارير المتجر: $e');
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
        if (_endDate != null && picked.isAfter(_endDate!)) {
          _endDate = picked;
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
      final pdfBytes = await PDFService.generateShopReportPDF(
        reportsData: _reportsData!,
        startDate: _startDate,
        endDate: _endDate,
      );

      // إنشاء اسم الملف
      final fileName = _generateFileName('تقرير_المتجر');

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
      final pdfBytes = await PDFService.generateShopReportPDF(
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
        'معاينة تقرير المتجر',
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
  String _getSummaryTitle() {
    if (_startDate == null && _endDate == null) {
      return 'الملخص (كل البيانات)';
    }
    final startStr = _startDate != null ? _displayFormatter.format(_startDate!) : '';
    final endStr = _endDate != null ? _displayFormatter.format(_endDate!) : '';
    return 'الملخص ($startStr → $endStr)';
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
      case ShopReportsLoadingState.loading:
        return const Center(
          child: Padding(
            padding: EdgeInsets.all(50),
            child: Column(
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text(
                  'جارٍ تحميل التقارير...',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              ],
            ),
          ),
        );

      case ShopReportsLoadingState.error:
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                const Icon(Icons.error, size: 64, color: Colors.red),
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
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                ],
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: _loadReports,
                  icon: const Icon(Icons.refresh),
                  label: const Text('إعادة المحاولة'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        );

      case ShopReportsLoadingState.loaded:
        return _buildReportsContent();

      default:
        return const SizedBox.shrink();
    }
  }

  /// بناء محتوى التقارير
  Widget _buildReportsContent() {
    if (_reportsData == null) return const SizedBox.shrink();

    final data = _reportsData!.data;

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
            _sectionTitle(_getSummaryTitle()),
            const SizedBox(height: 16),
            _buildDataRow(
              'عدد الطلبات:',
              '${data.completedOrdersCount} طلب',
              Icons.list_alt,
            ),
            _buildDataRow(
              'إجمالي قيمة الطلبات:',
              '${data.totalOrdersValue.toStringAsFixed(2)} جنيه',
              Icons.shopping_cart,
            ),
            _buildDataRow(
              'إجمالي تكلفة التوصيل:',
              '${data.totalDeliveryFees.toStringAsFixed(2)} جنيه',
              Icons.delivery_dining,
            ),
            _buildDataRow(
              'نسبة التطبيق:',
              '${data.applicationPercentage}%',
              Icons.pie_chart,
            ),
            _buildDataRow(
              'عمولة التطبيق:',
              '${data.applicationCommission.toStringAsFixed(2)} جنيه',
              Icons.account_balance_wallet,
            ),
            _buildDataRow(
              'صافي الأرباح:',
              '${data.netProfit.toStringAsFixed(2)} جنيه',
              Icons.trending_up,
              isHighlight: true,
            ),
            const SizedBox(height: 20),
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
                      minimumSize: const Size(double.infinity, 48),
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
                      minimumSize: const Size(double.infinity, 48),
                    ),
                  ),
                ),
              ],
            ),
          ],
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
                text: label,
                style: TextStyle(
                  fontSize: isHighlight ? 18 : 16,
                  color: Colors.black,
                  fontWeight: isHighlight ? FontWeight.bold : FontWeight.normal,
                ),
                children: [
                  TextSpan(
                    text: ' $value',
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


  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        title,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue),
      ),
    );
  }
}