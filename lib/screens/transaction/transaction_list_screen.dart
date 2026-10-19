import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/app_utils.dart';
import '../../providers/finance_provider.dart';
import '../../models/models.dart';
import 'add_income_screen.dart';
import 'add_expense_screen.dart';

class TransactionListScreen extends StatefulWidget {
  const TransactionListScreen({super.key});

  @override
  State<TransactionListScreen> createState() => _TransactionListScreenState();
}

class _TransactionListScreenState extends State<TransactionListScreen> {
  DateTime _startDate =
      DateTime(DateTime.now().year, DateTime.now().month, 1);
  DateTime _endDate = DateTime.now();
  String? _selectedCategory;
  List<TransactionModel> _filteredTransactions = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final fp = context.read<FinanceProvider>();
    final all = await fp.loadTransactionsForReport(
      _startDate,
      _endDate,
      categoryName: _selectedCategory,
    );
    setState(() {
      _filteredTransactions = all;
      _isLoading = false;
    });
  }

  // DIUBAH: pilih tanggal satu per satu pakai showDatePicker biasa
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
      await _loadData();
    }
  }

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
      await _loadData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Riwayat Transaksi'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadData,
          ),
        ],
      ),
      body: Consumer<FinanceProvider>(
        builder: (context, fp, _) {
          final allCategories = [
            ...fp.incomeCategories,
            ...fp.expenseCategories,
          ];
          final uniqueCategories = <String>{};
          for (final c in allCategories) {
            uniqueCategories.add(c.name);
          }

          return Column(
            children: [
              // ── Filter Bar ──────────────────────────────────
              Container(
                color: AppTheme.deepBlue,
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Label
                    const Text(
                      'Filter Periode',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Dua tombol tanggal: Mulai dan Selesai
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
                                color: Colors.white.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                    color: Colors.white.withOpacity(0.3)),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
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
                                      const Icon(Icons.calendar_today_rounded,
                                          color: Colors.white, size: 13),
                                      const SizedBox(width: 6),
                                      Text(
                                        AppUtils.formatDateDisplay(_startDate),
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
                          padding: EdgeInsets.symmetric(horizontal: 8),
                          child: Icon(Icons.arrow_forward_rounded,
                              color: Colors.white54, size: 18),
                        ),

                        // Tombol Tanggal Selesai
                        Expanded(
                          child: GestureDetector(
                            onTap: _pickEndDate,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 10),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                    color: Colors.white.withOpacity(0.3)),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
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
                                      const Icon(Icons.calendar_today_rounded,
                                          color: Colors.white, size: 13),
                                      const SizedBox(width: 6),
                                      Text(
                                        AppUtils.formatDateDisplay(_endDate),
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
                    const SizedBox(height: 8),

                    // Category Dropdown Filter
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String?>(
                          value: _selectedCategory,
                          isExpanded: true,
                          dropdownColor: AppTheme.deepBlue,
                          iconEnabledColor: Colors.white70,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                          hint: const Text(
                            'Semua Kategori',
                            style: TextStyle(
                                color: Colors.white, fontSize: 12),
                          ),
                          onChanged: (val) async {
                            setState(() => _selectedCategory = val);
                            await _loadData();
                          },
                          items: [
                            const DropdownMenuItem<String?>(
                              value: null,
                              child: Text('Semua Kategori'),
                            ),
                            ...uniqueCategories.map(
                              (cat) => DropdownMenuItem<String?>(
                                value: cat,
                                child: Text(cat),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // ── Info jumlah hasil filter ─────────────────────
              if (!_isLoading)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 8),
                  color: AppTheme.softGrey,
                  child: Text(
                    '${_filteredTransactions.length} transaksi ditemukan'
                    '${_selectedCategory != null ? ' • Kategori: $_selectedCategory' : ''}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.darkGrey,
                    ),
                  ),
                ),

              // ── List Transaksi ───────────────────────────────
              if (_isLoading)
                const Expanded(
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_filteredTransactions.isEmpty)
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.receipt_long_outlined,
                            size: 60, color: AppTheme.medGrey),
                        const SizedBox(height: 12),
                        const Text(
                          'Tidak ada transaksi',
                          style: TextStyle(
                              fontSize: 16, color: AppTheme.darkGrey),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Coba ubah filter tanggal atau kategori',
                          style: TextStyle(
                              fontSize: 13, color: AppTheme.medGrey),
                        ),
                      ],
                    ),
                  ),
                )
              else
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _filteredTransactions.length,
                    itemBuilder: (ctx, i) => _TransactionCard(
                      transaction: _filteredTransactions[i],
                      onDelete: () async {
                        final confirm = await showDialog<bool>(
                          context: ctx,
                          builder: (dctx) => AlertDialog(
                            title: const Text('Hapus Transaksi?'),
                            content: const Text(
                                'Transaksi ini akan dihapus permanen.'),
                            actions: [
                              TextButton(
                                onPressed: () =>
                                    Navigator.pop(dctx, false),
                                child: const Text('Batal'),
                              ),
                              ElevatedButton(
                                onPressed: () =>
                                    Navigator.pop(dctx, true),
                                style: ElevatedButton.styleFrom(
                                    backgroundColor: AppTheme.errorRed),
                                child: const Text('Hapus',
                                    style:
                                        TextStyle(color: Colors.white)),
                              ),
                            ],
                          ),
                        );
                        if (confirm == true && ctx.mounted) {
                          await ctx
                              .read<FinanceProvider>()
                              .deleteTransaction(
                                  _filteredTransactions[i].id!);
                          await _loadData();
                        }
                      },
                    ),
                  ),
                ),
            ],
          );
        },
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton.small(
            heroTag: 'income_fab',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AddIncomeScreen()),
            ).then((_) => _loadData()),
            backgroundColor: AppTheme.mintGreen,
            child: const Icon(Icons.add, color: Colors.white),
          ),
          const SizedBox(height: 8),
          FloatingActionButton.small(
            heroTag: 'expense_fab',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AddExpenseScreen()),
            ).then((_) => _loadData()),
            backgroundColor: AppTheme.errorRed,
            child: const Icon(Icons.remove, color: Colors.white),
          ),
        ],
      ),
    );
  }
}

class _TransactionCard extends StatelessWidget {
  final TransactionModel transaction;
  final VoidCallback onDelete;

  const _TransactionCard({
    required this.transaction,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isIncome = transaction.type == 'income';
    final color = isIncome ? AppTheme.mintGreen : AppTheme.errorRed;
    final icon = isIncome
        ? Icons.arrow_downward_rounded
        : Icons.arrow_upward_rounded;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction.displayName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: AppTheme.charcoal,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  transaction.categoryName,
                  style: const TextStyle(
                      fontSize: 12, color: AppTheme.darkGrey),
                ),
                if (transaction.type == 'expense' &&
                    transaction.quantity > 1)
                  Text(
                    '${transaction.quantity}x • ${AppUtils.formatCurrency(transaction.amount / transaction.quantity)} /pcs',
                    style: const TextStyle(
                        fontSize: 11, color: AppTheme.darkGrey),
                  ),
                if (transaction.description != null &&
                    transaction.description!.isNotEmpty)
                  Text(
                    transaction.description!,
                    style: const TextStyle(
                        fontSize: 11, color: AppTheme.darkGrey),
                    overflow: TextOverflow.ellipsis,
                  ),
                const SizedBox(height: 2),
                Text(
                  AppUtils.formatDate(transaction.date),
                  style: const TextStyle(
                      fontSize: 11, color: AppTheme.medGrey),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${isIncome ? '+' : '-'}${AppUtils.formatCurrency(transaction.amount)}',
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 6),
              GestureDetector(
                onTap: onDelete,
                child: const Icon(
                  Icons.delete_outline_rounded,
                  color: AppTheme.medGrey,
                  size: 20,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}