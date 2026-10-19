import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/app_utils.dart';
import '../../providers/finance_provider.dart';
import '../../models/models.dart';

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  DateTime _startDate =
      DateTime(DateTime.now().year, DateTime.now().month, 1);
  DateTime _endDate = DateTime.now();

  Map<String, dynamic> _summary = {};
  List<TransactionModel> _transactions = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadReport());
  }

  Future<void> _loadReport() async {
    setState(() => _isLoading = true);
    final fp = context.read<FinanceProvider>();
    final summary = await fp.loadSummaryForReport(_startDate, _endDate);
    final transactions =
        await fp.loadTransactionsForReport(_startDate, _endDate);
    setState(() {
      _summary = summary;
      _transactions = transactions;
      _isLoading = false;
    });
  }

  // DIUBAH: pilih tanggal mulai satu per satu (showDatePicker biasa)
  Future<void> _pickStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(2020),
      lastDate: _endDate,
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: AppTheme.deepBlue,
            onPrimary: Colors.white,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() => _startDate = picked);
      await _loadReport();
    }
  }

  // DIUBAH: pilih tanggal selesai
  Future<void> _pickEndDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate,
      firstDate: _startDate,
      lastDate: DateTime.now(),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: AppTheme.deepBlue,
            onPrimary: Colors.white,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() => _endDate = picked);
      await _loadReport();
    }
  }

  Future<void> _exportPdf() async {
    final pdf = pw.Document();
    final income = (_summary['income'] ?? 0.0) as double;
    final expense = (_summary['expense'] ?? 0.0) as double;
    final balance = (_summary['balance'] ?? 0.0) as double;
    final expTotals =
        (_summary['expenseTotals'] ?? <CategoryTotal>[]) as List<CategoryTotal>;
    final incTotals =
        (_summary['incomeTotals'] ?? <CategoryTotal>[]) as List<CategoryTotal>;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (ctx) => [
          // Header
          pw.Container(
            padding: const pw.EdgeInsets.all(16),
            decoration: pw.BoxDecoration(
              color: PdfColors.blue800,
              borderRadius: pw.BorderRadius.circular(8),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'DompetKu — Laporan Keuangan',
                  style: pw.TextStyle(
                    color: PdfColors.white,
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  'Periode: ${AppUtils.formatDateDisplay(_startDate)} — ${AppUtils.formatDateDisplay(_endDate)}',
                  style: const pw.TextStyle(
                    color: PdfColors.white,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 16),

          // Ringkasan
          pw.Text(
            'Ringkasan',
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.grey300),
            children: [
              _pdfRow('Total Pemasukan', AppUtils.formatCurrency(income),
                  PdfColors.green50),
              _pdfRow('Total Pengeluaran', AppUtils.formatCurrency(expense),
                  PdfColors.red50),
              _pdfRow('Saldo', AppUtils.formatCurrency(balance),
                  balance >= 0 ? PdfColors.lightBlue50 : PdfColors.orange50),
            ],
          ),
          pw.SizedBox(height: 16),

          // Kategori Pengeluaran
          if (expTotals.isNotEmpty) ...[
            pw.Text(
              'Pengeluaran per Kategori',
              style: pw.TextStyle(
                  fontSize: 13, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 8),
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey300),
              children: [
                _pdfHeader('Kategori', 'Total', ''),
                ...expTotals.map(
                  (e) => _pdfRow3(
                    e.categoryName,
                    AppUtils.formatCurrency(e.total),
                    '',
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 16),
          ],

          // Kategori Pemasukan
          if (incTotals.isNotEmpty) ...[
            pw.Text(
              'Pemasukan per Kategori',
              style: pw.TextStyle(
                  fontSize: 13, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 8),
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey300),
              children: [
                _pdfHeader('Kategori', 'Total', ''),
                ...incTotals.map(
                  (e) => _pdfRow3(
                    e.categoryName,
                    AppUtils.formatCurrency(e.total),
                    '',
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 16),
          ],

          // Detail Transaksi
          pw.Text(
            'Detail Transaksi (${_transactions.length})',
            style: pw.TextStyle(
                fontSize: 13, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 8),
          if (_transactions.isEmpty)
            pw.Text('Tidak ada transaksi pada periode ini.')
          else
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey300),
              columnWidths: {
                0: const pw.FlexColumnWidth(2),
                1: const pw.FlexColumnWidth(2),
                2: const pw.FlexColumnWidth(1),
                3: const pw.FlexColumnWidth(2),
              },
              children: [
                _pdfHeaderFull(),
                ..._transactions.map(_pdfTransactionRow),
              ],
            ),
        ],
      ),
    );

    final Uint8List bytes = await pdf.save();
    await Printing.sharePdf(
      bytes: bytes,
      filename:
          'DompetKu_${AppUtils.formatDateDisplay(_startDate)}_${AppUtils.formatDateDisplay(_endDate)}.pdf',
    );
  }

  pw.TableRow _pdfRow(String label, String value, PdfColor bg) {
    return pw.TableRow(
      decoration: pw.BoxDecoration(color: bg),
      children: [
        pw.Padding(
          padding: const pw.EdgeInsets.all(6),
          child: pw.Text(label,
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.all(6),
          child: pw.Text(value),
        ),
      ],
    );
  }

  pw.TableRow _pdfHeader(String c1, String c2, String c3) {
    return pw.TableRow(
      decoration: const pw.BoxDecoration(color: PdfColors.blue800),
      children: [c1, c2, c3].map((t) {
        return pw.Padding(
          padding: const pw.EdgeInsets.all(6),
          child: pw.Text(
            t,
            style: pw.TextStyle(
              color: PdfColors.white,
              fontWeight: pw.FontWeight.bold,
              fontSize: 10,
            ),
          ),
        );
      }).toList(),
    );
  }

  pw.TableRow _pdfRow3(String c1, String c2, String c3) {
    return pw.TableRow(
      children: [c1, c2, c3].map((t) {
        return pw.Padding(
          padding: const pw.EdgeInsets.all(6),
          child: pw.Text(t, style: const pw.TextStyle(fontSize: 10)),
        );
      }).toList(),
    );
  }

  pw.TableRow _pdfHeaderFull() {
    return pw.TableRow(
      decoration: const pw.BoxDecoration(color: PdfColors.blue800),
      children: ['Tanggal', 'Nama / Kategori', 'Jenis', 'Nominal'].map((t) {
        return pw.Padding(
          padding: const pw.EdgeInsets.all(6),
          child: pw.Text(
            t,
            style: pw.TextStyle(
              color: PdfColors.white,
              fontWeight: pw.FontWeight.bold,
              fontSize: 10,
            ),
          ),
        );
      }).toList(),
    );
  }

  pw.TableRow _pdfTransactionRow(TransactionModel t) {
    final isIncome = t.type == 'income';
    return pw.TableRow(
      children: [
        pw.Padding(
          padding: const pw.EdgeInsets.all(5),
          child: pw.Text(AppUtils.formatDate(t.date),
              style: const pw.TextStyle(fontSize: 9)),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.all(5),
          child: pw.Text('${t.displayName}\n${t.categoryName}',
              style: const pw.TextStyle(fontSize: 9)),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.all(5),
          child: pw.Text(
            isIncome ? 'Masuk' : 'Keluar',
            style: pw.TextStyle(
              fontSize: 9,
              color: isIncome ? PdfColors.green700 : PdfColors.red700,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.all(5),
          child: pw.Text(
            '${isIncome ? '+' : '-'}${AppUtils.formatCurrency(t.amount)}',
            style: pw.TextStyle(
              fontSize: 9,
              color: isIncome ? PdfColors.green700 : PdfColors.red700,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final income = (_summary['income'] ?? 0.0) as double;
    final expense = (_summary['expense'] ?? 0.0) as double;
    final balance = (_summary['balance'] ?? 0.0) as double;
    final expTotals =
        (_summary['expenseTotals'] ?? <CategoryTotal>[]) as List<CategoryTotal>;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Laporan Keuangan'),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf_rounded),
            tooltip: 'Export PDF',
            onPressed: _isLoading ? null : _exportPdf,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadReport,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  children: [
                    // ── Filter Periode (2 tombol terpisah) ────────
                    Container(
                      color: AppTheme.deepBlue,
                      padding:
                          const EdgeInsets.fromLTRB(16, 10, 16, 14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Periode Laporan',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),

                          Row(
                            children: [
                              // Tombol Tanggal Mulai
                              Expanded(
                                child: GestureDetector(
                                  onTap: _pickStartDate,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 10),
                                    decoration: BoxDecoration(
                                      color:
                                          Colors.white.withOpacity(0.15),
                                      borderRadius:
                                          BorderRadius.circular(10),
                                      border: Border.all(
                                          color: Colors.white
                                              .withOpacity(0.3)),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Dari',
                                          style: TextStyle(
                                            color: Colors.white60,
                                            fontSize: 10,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Row(
                                          children: [
                                            const Icon(
                                              Icons.calendar_today_rounded,
                                              color: Colors.white,
                                              size: 13,
                                            ),
                                            const SizedBox(width: 6),
                                            Text(
                                              AppUtils.formatDateDisplay(
                                                  _startDate),
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 12,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),

                              // Ikon panah tengah
                              const Padding(
                                padding:
                                    EdgeInsets.symmetric(horizontal: 8),
                                child: Icon(
                                  Icons.arrow_forward_rounded,
                                  color: Colors.white54,
                                  size: 18,
                                ),
                              ),

                              // Tombol Tanggal Selesai
                              Expanded(
                                child: GestureDetector(
                                  onTap: _pickEndDate,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 10),
                                    decoration: BoxDecoration(
                                      color:
                                          Colors.white.withOpacity(0.15),
                                      borderRadius:
                                          BorderRadius.circular(10),
                                      border: Border.all(
                                          color: Colors.white
                                              .withOpacity(0.3)),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Sampai',
                                          style: TextStyle(
                                            color: Colors.white60,
                                            fontSize: 10,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Row(
                                          children: [
                                            const Icon(
                                              Icons.calendar_today_rounded,
                                              color: Colors.white,
                                              size: 13,
                                            ),
                                            const SizedBox(width: 6),
                                            Text(
                                              AppUtils.formatDateDisplay(
                                                  _endDate),
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 12,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),

                          // Tombol Muat Ulang
                          const SizedBox(height: 8),
                          SizedBox(
                            width: double.infinity,
                            child: TextButton.icon(
                              onPressed: _loadReport,
                              icon: const Icon(Icons.refresh_rounded,
                                  color: Colors.white70, size: 16),
                              label: const Text(
                                'Muat Ulang Laporan',
                                style: TextStyle(
                                    color: Colors.white70, fontSize: 12),
                              ),
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                    vertical: 8),
                                backgroundColor:
                                    Colors.white.withOpacity(0.08),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // ── Kartu Ringkasan ────────────────────────────
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          Expanded(
                            child: _SummaryCard(
                              label: 'Pemasukan',
                              value: AppUtils.formatCurrency(income),
                              color: AppTheme.mintGreen,
                              icon: Icons.arrow_downward_rounded,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _SummaryCard(
                              label: 'Pengeluaran',
                              value: AppUtils.formatCurrency(expense),
                              color: AppTheme.errorRed,
                              icon: Icons.arrow_upward_rounded,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: _SummaryCard(
                        label: 'Saldo Periode',
                        value: AppUtils.formatCurrency(balance),
                        color: balance >= 0
                            ? AppTheme.deepBlue
                            : AppTheme.errorRed,
                        icon: Icons.account_balance_wallet_rounded,
                        fullWidth: true,
                      ),
                    ),

                    // ── Pengeluaran per Kategori ────────────────────
                    if (expTotals.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          children: [
                            Icon(Icons.pie_chart_outline_rounded,
                                size: 18, color: AppTheme.deepBlue),
                            SizedBox(width: 8),
                            Text(
                              'Pengeluaran per Kategori',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.charcoal,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      Padding(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 16),
                        child: Column(
                          children: expTotals
                              .map((e) => _CategoryRow(
                                    category: e,
                                    total: expense,
                                    color: AppTheme.errorRed,
                                  ))
                              .toList(),
                        ),
                      ),
                    ],

                    // ── Detail Transaksi ────────────────────────────
                    const SizedBox(height: 20),
                    Padding(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          const Icon(Icons.list_alt_rounded,
                              size: 18, color: AppTheme.deepBlue),
                          const SizedBox(width: 8),
                          Text(
                            'Detail Transaksi (${_transactions.length})',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.charcoal,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    if (_transactions.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(
                            horizontal: 16, vertical: 24),
                        child: Center(
                          child: Text(
                            'Tidak ada transaksi pada periode ini',
                            style: TextStyle(color: AppTheme.darkGrey),
                          ),
                        ),
                      )
                    else
                      Padding(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 16),
                        child: Column(
                          children: _transactions
                              .map((t) => _ReportTransactionRow(
                                  transaction: t))
                              .toList(),
                        ),
                      ),
                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isLoading ? null : _exportPdf,
        backgroundColor: AppTheme.deepBlue,
        icon: const Icon(Icons.picture_as_pdf_rounded,
            color: Colors.white),
        label: const Text('Export PDF',
            style: TextStyle(color: Colors.white)),
      ),
    );
  }
}

// ─── Widget Helpers ──────────────────────────────────────────────────

class _SummaryCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;
  final bool fullWidth;

  const _SummaryCard({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
    this.fullWidth = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: fullWidth ? double.infinity : null,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppTheme.darkGrey,
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryRow extends StatelessWidget {
  final CategoryTotal category;
  final double total;
  final Color color;

  const _CategoryRow({
    required this.category,
    required this.total,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final pct = total > 0 ? (category.total / total) : 0.0;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 4,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  category.categoryName,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.charcoal,
                  ),
                ),
              ),
              Text(
                AppUtils.formatCurrency(category.total),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: pct.clamp(0.0, 1.0),
              backgroundColor: color.withOpacity(0.1),
              valueColor: AlwaysStoppedAnimation(color),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${(pct * 100).toStringAsFixed(1)}% dari total pengeluaran',
            style: const TextStyle(
              fontSize: 11,
              color: AppTheme.darkGrey,
            ),
          ),
        ],
      ),
    );
  }
}

class _ReportTransactionRow extends StatelessWidget {
  final TransactionModel transaction;

  const _ReportTransactionRow({required this.transaction});

  @override
  Widget build(BuildContext context) {
    final isIncome = transaction.type == 'income';
    final color = isIncome ? AppTheme.mintGreen : AppTheme.errorRed;

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 4,
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction.displayName,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.charcoal,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${transaction.categoryName} • ${AppUtils.formatDate(transaction.date)}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppTheme.darkGrey,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '${isIncome ? '+' : '-'}${AppUtils.formatCurrency(transaction.amount)}',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}