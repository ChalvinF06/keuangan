import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/app_utils.dart';
import '../../providers/auth_provider.dart';
import '../../providers/finance_provider.dart';
import '../../models/models.dart';
import '../../core/database/database_helper.dart';
import '../transaction/add_income_screen.dart';
import '../transaction/add_expense_screen.dart';
import '../transaction/transaction_list_screen.dart';
import '../category/category_screen.dart';
import '../report/report_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    _HomeTab(),
    TransactionListScreen(),
    CategoryScreen(),
    ReportScreen(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await context.read<FinanceProvider>().init();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Color(0x15000000),
              blurRadius: 12,
              offset: Offset(0, -2),
            ),
          ],
        ),
        child: NavigationBar(
          selectedIndex: _currentIndex,
          onDestinationSelected: (i) => setState(() => _currentIndex = i),
          backgroundColor: Colors.white,
          indicatorColor: AppTheme.deepBlue.withOpacity(0.1),
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.dashboard_outlined),
              selectedIcon:
                  Icon(Icons.dashboard_rounded, color: AppTheme.deepBlue),
              label: 'Dashboard',
            ),
            NavigationDestination(
              icon: Icon(Icons.receipt_long_outlined),
              selectedIcon:
                  Icon(Icons.receipt_long_rounded, color: AppTheme.deepBlue),
              label: 'Transaksi',
            ),
            NavigationDestination(
              icon: Icon(Icons.category_outlined),
              selectedIcon:
                  Icon(Icons.category_rounded, color: AppTheme.deepBlue),
              label: 'Kategori',
            ),
            NavigationDestination(
              icon: Icon(Icons.bar_chart_outlined),
              selectedIcon:
                  Icon(Icons.bar_chart_rounded, color: AppTheme.deepBlue),
              label: 'Laporan',
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// ALL TIME BALANCE CARD
// ============================================================
class _AllTimeBalanceCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: Future.wait([
        DatabaseHelper().getTotalByType('income'),
        DatabaseHelper().getTotalByType('expense'),
      ]),
      builder: (context, snapshot) {
        final income = (snapshot.data?[0] ?? 0.0) as double;
        final expense = (snapshot.data?[1] ?? 0.0) as double;
        final balance = income - expense;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          decoration: BoxDecoration(
            color: balance >= 0 ? AppTheme.mintGreen : AppTheme.errorRed,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Total Saldo Keseluruhan',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                  Text(
                    AppUtils.formatCurrency(balance),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              const Icon(
                Icons.account_balance_wallet_rounded,
                color: Colors.white54,
                size: 32,
              ),
            ],
          ),
        );
      },
    );
  }
}

// ============================================================
// HOME TAB
// ============================================================
class _HomeTab extends StatelessWidget {
  const _HomeTab();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: RefreshIndicator(
        onRefresh: () => context.read<FinanceProvider>().loadDashboardData(),
        child: CustomScrollView(
          slivers: [
            _buildAppBar(context),
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _AllTimeBalanceCard(),
                  const SizedBox(height: 12),
                  _BalanceCard(),
                  const SizedBox(height: 12),
                  _DateRangeFilter(),
                  const SizedBox(height: 16),
                  _QuickActions(),
                  const SizedBox(height: 20),
                  _ChartsSection(),
                  const SizedBox(height: 20),
                  _FrequencyChartSection(),
                  const SizedBox(height: 20),
                  _RecentTransactions(),
                  const SizedBox(height: 20),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return SliverAppBar(
      expandedHeight: 0,
      floating: true,
      snap: true,
      backgroundColor: AppTheme.deepBlue,
      foregroundColor: Colors.white,
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child:
                const Icon(Icons.account_balance_wallet_rounded, size: 20),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'DompetKu',
                style:
                    TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              ),
              Text(
                'Halo, ${auth.username}!',
                style: const TextStyle(
                    fontSize: 11, fontWeight: FontWeight.w400),
              ),
            ],
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.logout_rounded, size: 22),
          onPressed: () async {
            final confirm = await showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text('Keluar?'),
                content:
                    const Text('Apakah Anda yakin ingin keluar?'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: const Text('Batal'),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    child: const Text('Keluar'),
                  ),
                ],
              ),
            );
            if (confirm == true && context.mounted) {
              await context.read<AuthProvider>().logout();
            }
          },
        ),
      ],
    );
  }
}

// ============================================================
// DATE RANGE FILTER
// DIPERBAIKI: hapus locale: const Locale('id', 'ID') — penyebab crash
// ============================================================
class _DateRangeFilter extends StatelessWidget {
  Future<void> _pickDateRange(BuildContext context) async {
    final fp = context.read<FinanceProvider>();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(
        start: fp.startDate,
        end: fp.endDate,
      ),
      // DIPERBAIKI: locale dihapus agar tidak crash di HP tanpa locale id_ID
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: AppTheme.deepBlue,
            onPrimary: Colors.white,
            surface: Colors.white,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      fp.setDateRange(picked.start, picked.end);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<FinanceProvider>(
      builder: (context, fp, _) {
        return GestureDetector(
          onTap: () => _pickDateRange(context),
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppTheme.medGrey),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 6,
                ),
              ],
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.date_range_rounded,
                  color: AppTheme.deepBlue,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Periode',
                        style: TextStyle(
                          fontSize: 10,
                          color: AppTheme.darkGrey,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        AppUtils.filterLabel(fp.startDate, fp.endDate),
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.deepBlue,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: AppTheme.darkGrey,
                  size: 20,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ============================================================
// BALANCE CARD
// ============================================================
class _BalanceCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<FinanceProvider>(
      builder: (context, fp, _) {
        return Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppTheme.deepBlue, AppTheme.mediumBlue],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: AppTheme.deepBlue.withOpacity(0.35),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'Saldo ${AppUtils.filterLabel(fp.startDate, fp.endDate)}',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'IDR',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              fp.isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : Text(
                      AppUtils.formatCurrency(fp.balance),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 30,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                      ),
                    ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: _MiniStatCard(
                      label: 'Pemasukan',
                      amount: fp.totalIncome,
                      icon: Icons.arrow_downward_rounded,
                      color: AppTheme.mintGreen,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _MiniStatCard(
                      label: 'Pengeluaran',
                      amount: fp.totalExpense,
                      icon: Icons.arrow_upward_rounded,
                      color: AppTheme.errorRed,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _MiniStatCard extends StatelessWidget {
  final String label;
  final double amount;
  final IconData icon;
  final Color color;

  const _MiniStatCard({
    required this.label,
    required this.amount,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.25),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 14),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                      color: Colors.white60, fontSize: 11),
                ),
                Text(
                  AppUtils.formatCurrency(amount),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// QUICK ACTIONS
// ============================================================
class _QuickActions extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _ActionButton(
            label: 'Tambah Pemasukan',
            icon: Icons.add_circle_outline_rounded,
            color: AppTheme.mintGreen,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AddIncomeScreen()),
            ).then(
                (_) => context.read<FinanceProvider>().loadDashboardData()),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _ActionButton(
            label: 'Tambah Pengeluaran',
            icon: Icons.remove_circle_outline_rounded,
            color: AppTheme.errorRed,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AddExpenseScreen()),
            ).then(
                (_) => context.read<FinanceProvider>().loadDashboardData()),
          ),
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.25)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// PIE CHARTS SECTION
// ============================================================
class _ChartsSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<FinanceProvider>(
      builder: (context, fp, _) {
        if (fp.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Grafik Keuangan',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppTheme.deepBlue,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _PieChartCard(
                    title: 'Pengeluaran',
                    data: fp.expenseTotals,
                    color: AppTheme.errorRed,
                    total: fp.totalExpense,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _PieChartCard(
                    title: 'Pemasukan',
                    data: fp.incomeTotals,
                    color: AppTheme.mintGreen,
                    total: fp.totalIncome,
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _PieChartCard extends StatefulWidget {
  final String title;
  final List<CategoryTotal> data;
  final Color color;
  final double total;

  const _PieChartCard({
    required this.title,
    required this.data,
    required this.color,
    required this.total,
  });

  @override
  State<_PieChartCard> createState() => _PieChartCardState();
}

class _PieChartCardState extends State<_PieChartCard> {
  int _touchedIndex = -1;
  bool _showAmount = false;

  @override
  Widget build(BuildContext context) {
    final isEmpty = widget.data.isEmpty || widget.total == 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            widget.title,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 13,
              color: AppTheme.deepBlue,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            AppUtils.formatCurrency(widget.total),
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 12,
              color: widget.color,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 110,
            child: isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.pie_chart_outline_rounded,
                            color: AppTheme.medGrey, size: 32),
                        const SizedBox(height: 4),
                        const Text(
                          'Tidak ada data',
                          style: TextStyle(
                              fontSize: 11, color: AppTheme.darkGrey),
                        ),
                      ],
                    ),
                  )
                : PieChart(
                    PieChartData(
                      sections: _buildSections(),
                      pieTouchData: PieTouchData(
                        touchCallback: (event, response) {
                          setState(() {
                            final tapped = response
                                    ?.touchedSection
                                    ?.touchedSectionIndex ??
                                -1;
                            if (event is FlTapUpEvent) {
                              if (_touchedIndex == tapped && tapped != -1) {
                                _showAmount = !_showAmount;
                              } else {
                                _touchedIndex = tapped;
                                _showAmount = tapped != -1;
                              }
                            } else if (event is FlPointerExitEvent) {
                              // biarkan tetap tampil
                            } else if (tapped == -1) {
                              _touchedIndex = -1;
                              _showAmount = false;
                            } else {
                              _touchedIndex = tapped;
                            }
                          });
                        },
                      ),
                      centerSpaceRadius: 28,
                      sectionsSpace: 2,
                    ),
                  ),
          ),

          // Tooltip saat ada slice yang di-tap
          if (_touchedIndex != -1 && _touchedIndex < widget.data.length) ...[
            const SizedBox(height: 6),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(
                  horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme
                    .chartColors[
                        _touchedIndex % AppTheme.chartColors.length]
                    .withOpacity(0.12),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppTheme
                      .chartColors[
                          _touchedIndex % AppTheme.chartColors.length]
                      .withOpacity(0.4),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Text(
                      widget.data[_touchedIndex].categoryName,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.chartColors[
                            _touchedIndex % AppTheme.chartColors.length],
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    AppUtils.formatCurrency(
                        widget.data[_touchedIndex].total),
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.charcoal,
                    ),
                  ),
                ],
              ),
            ),
          ],

          if (!isEmpty) ...[
            const SizedBox(height: 8),
            ...widget.data.take(3).toList().asMap().entries.map(
                  (e) => _LegendItem(
                    color: AppTheme.chartColors[
                        e.key % AppTheme.chartColors.length],
                    label: e.value.categoryName,
                    percent: widget.total > 0
                        ? (e.value.total / widget.total * 100)
                        : 0,
                  ),
                ),
            if (widget.data.length > 3)
              Text(
                '+${widget.data.length - 3} lainnya',
                style: const TextStyle(
                    fontSize: 10, color: AppTheme.darkGrey),
              ),
          ],
        ],
      ),
    );
  }

  List<PieChartSectionData> _buildSections() {
    return widget.data.asMap().entries.map((e) {
      final isTouched = e.key == _touchedIndex;
      final color =
          AppTheme.chartColors[e.key % AppTheme.chartColors.length];
      final pct =
          widget.total > 0 ? (e.value.total / widget.total * 100) : 0;
      return PieChartSectionData(
        value: e.value.total,
        color: color,
        radius: isTouched ? 38 : 30,
        title: (isTouched && _showAmount)
            ? AppUtils.formatCurrency(e.value.total)
                .replaceAll('Rp ', 'Rp\n')
            : '${pct.toStringAsFixed(0)}%',
        titleStyle: TextStyle(
          fontSize: (isTouched && _showAmount) ? 8 : (isTouched ? 11 : 9),
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      );
    }).toList();
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  final double percent;

  const _LegendItem({
    required this.color,
    required this.label,
    required this.percent,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
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
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                  fontSize: 10, color: AppTheme.charcoal),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            '${percent.toStringAsFixed(0)}%',
            style: const TextStyle(
              fontSize: 10,
              color: AppTheme.darkGrey,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// FREQUENCY CHART SECTION
// ============================================================
class _FrequencyChartSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<FinanceProvider>(
      builder: (context, fp, _) {
        final data = fp.frequencyData;
        final isExpense = fp.frequencyType == 'expense';
        final color = isExpense ? AppTheme.errorRed : AppTheme.mintGreen;
        final label = isExpense ? 'Pengeluaran' : 'Pemasukan';

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header + Toggle
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Frekuensi Transaksi',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.deepBlue,
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: AppTheme.softGrey,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _ToggleBtn(
                          label: 'Pengeluaran',
                          isActive: isExpense,
                          activeColor: AppTheme.errorRed,
                          onTap: () =>
                              fp.toggleFrequencyType('expense'),
                        ),
                        _ToggleBtn(
                          label: 'Pemasukan',
                          isActive: !isExpense,
                          activeColor: AppTheme.mintGreen,
                          onTap: () =>
                              fp.toggleFrequencyType('income'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Total $label pada periode ini',
                style: const TextStyle(
                  fontSize: 11,
                  color: AppTheme.darkGrey,
                ),
              ),
              const SizedBox(height: 16),

              // Chart
              if (data.isEmpty)
                SizedBox(
                  height: 100,
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.bar_chart_outlined,
                            color: AppTheme.medGrey, size: 36),
                        const SizedBox(height: 6),
                        Text(
                          'Tidak ada data $label',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.darkGrey,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                SizedBox(
                  height: 160,
                  child: BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      maxY: _getMaxY(data),
                      barTouchData: BarTouchData(
                        enabled: true,
                        touchTooltipData: BarTouchTooltipData(
                          getTooltipColor: (_) =>
                              AppTheme.deepBlue.withOpacity(0.9),
                          getTooltipItem: (group, groupIndex, rod, rodIndex) {
                            final item = data[groupIndex];
                            final date = item['date'] as String;
                            final total =
                                (item['total'] as num).toDouble();
                            final count = item['count'] as int;
                            return BarTooltipItem(
                              '${AppUtils.formatDate(date)}\n',
                              const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 11,
                              ),
                              children: [
                                TextSpan(
                                  text:
                                      '${AppUtils.formatCurrency(total)}\n$count transaksi',
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontWeight: FontWeight.w500,
                                    fontSize: 10,
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                      titlesData: FlTitlesData(
                        show: true,
                        topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 44,
                            getTitlesWidget: (value, meta) {
                              if (value == 0) return const SizedBox();
                              return Text(
                                _formatYLabel(value),
                                style: const TextStyle(
                                  fontSize: 9,
                                  color: AppTheme.darkGrey,
                                ),
                              );
                            },
                          ),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 28,
                            getTitlesWidget: (value, meta) {
                              final idx = value.toInt();
                              if (idx < 0 || idx >= data.length) {
                                return const SizedBox();
                              }
                              if (data.length > 10 && idx % 3 != 0) {
                                return const SizedBox();
                              }
                              final dateStr =
                                  data[idx]['date'] as String;
                              try {
                                final dt = DateTime.parse(dateStr);
                                return Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text(
                                    DateFormat('dd/MM').format(dt),
                                    style: const TextStyle(
                                      fontSize: 9,
                                      color: AppTheme.darkGrey,
                                    ),
                                  ),
                                );
                              } catch (_) {
                                return const SizedBox();
                              }
                            },
                          ),
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        getDrawingHorizontalLine: (value) => FlLine(
                          color: AppTheme.softGrey,
                          strokeWidth: 1,
                        ),
                      ),
                      barGroups: data.asMap().entries.map((e) {
                        final total =
                            (e.value['total'] as num).toDouble();
                        return BarChartGroupData(
                          x: e.key,
                          barRods: [
                            BarChartRodData(
                              toY: total,
                              color: color,
                              width: data.length > 15 ? 6 : 14,
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(4),
                                topRight: Radius.circular(4),
                              ),
                              backDrawRodData: BackgroundBarChartRodData(
                                show: true,
                                toY: _getMaxY(data),
                                color: color.withOpacity(0.05),
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  double _getMaxY(List<Map<String, dynamic>> data) {
    if (data.isEmpty) return 100;
    final max = data
        .map((e) => (e['total'] as num).toDouble())
        .reduce((a, b) => a > b ? a : b);
    return max * 1.2;
  }

  String _formatYLabel(double value) {
    if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(1)}jt';
    } else if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(0)}rb';
    }
    return value.toStringAsFixed(0);
  }
}

class _ToggleBtn extends StatelessWidget {
  final String label;
  final bool isActive;
  final Color activeColor;
  final VoidCallback onTap;

  const _ToggleBtn({
    required this.label,
    required this.isActive,
    required this.activeColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? activeColor : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: isActive ? Colors.white : AppTheme.darkGrey,
          ),
        ),
      ),
    );
  }
}

// ============================================================
// RECENT TRANSACTIONS
// ============================================================
class _RecentTransactions extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<FinanceProvider>(
      builder: (context, fp, _) {
        final recent = fp.transactions.take(5).toList();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Transaksi Terbaru',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.deepBlue,
                  ),
                ),
                if (fp.transactions.isNotEmpty)
                  TextButton(
                    onPressed: () {
                      context
                          .findAncestorStateOfType<_DashboardScreenState>()
                          ?.setState(() {
                        context
                            .findAncestorStateOfType<
                                _DashboardScreenState>()
                            ?._currentIndex = 1;
                      });
                    },
                    child: const Text(
                      'Lihat Semua',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            if (recent.isEmpty)
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Center(
                  child: Column(
                    children: [
                      Icon(Icons.receipt_long_outlined,
                          color: AppTheme.medGrey, size: 40),
                      SizedBox(height: 8),
                      Text(
                        'Belum ada transaksi',
                        style: TextStyle(
                            color: AppTheme.darkGrey, fontSize: 14),
                      ),
                    ],
                  ),
                ),
              )
            else
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: recent.length,
                  separatorBuilder: (_, __) =>
                      const Divider(height: 1, indent: 60),
                  itemBuilder: (_, i) =>
                      _TransactionTile(transaction: recent[i]),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _TransactionTile extends StatelessWidget {
  final TransactionModel transaction;

  const _TransactionTile({required this.transaction});

  @override
  Widget build(BuildContext context) {
    final isIncome = transaction.type == 'income';
    final color = isIncome ? AppTheme.mintGreen : AppTheme.errorRed;
    final icon = isIncome
        ? Icons.arrow_downward_rounded
        : Icons.arrow_upward_rounded;

    return ListTile(
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(
        transaction.displayName,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppTheme.charcoal,
        ),
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        '${transaction.categoryName} • ${AppUtils.formatDate(transaction.date)}',
        style: const TextStyle(fontSize: 11, color: AppTheme.darkGrey),
      ),
      trailing: Text(
        '${isIncome ? '+' : '-'}${AppUtils.formatCurrency(transaction.amount)}',
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}