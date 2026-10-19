import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import '../core/database/database_helper.dart';
import '../models/models.dart';

class FinanceProvider extends ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper();

  // ============================================================
  // STATE VARIABLES
  // ============================================================

  List<CategoryModel> _incomeCategories = [];
  List<CategoryModel> _expenseCategories = [];
  List<TransactionModel> _transactions = [];
  double _totalIncome = 0;
  double _totalExpense = 0;
  List<CategoryTotal> _expenseTotals = [];
  List<CategoryTotal> _incomeTotals = [];

  // Date range — default: bulan ini
  DateTime _startDate = DateTime(DateTime.now().year, DateTime.now().month, 1);
  DateTime _endDate = DateTime.now();

  bool _isLoading = false;

  // Frequency chart
  List<Map<String, dynamic>> _frequencyData = [];
  String _frequencyType = 'expense';

  // ============================================================
  // GETTERS
  // ============================================================

  List<CategoryModel> get incomeCategories => _incomeCategories;
  List<CategoryModel> get expenseCategories => _expenseCategories;
  List<TransactionModel> get transactions => _transactions;
  double get totalIncome => _totalIncome;
  double get totalExpense => _totalExpense;
  double get balance => _totalIncome - _totalExpense;
  List<CategoryTotal> get expenseTotals => _expenseTotals;
  List<CategoryTotal> get incomeTotals => _incomeTotals;
  DateTime get startDate => _startDate;
  DateTime get endDate => _endDate;
  bool get isLoading => _isLoading;
  List<Map<String, dynamic>> get frequencyData => _frequencyData;
  String get frequencyType => _frequencyType;

  // ============================================================
  // INIT
  // ============================================================

  Future<void> init() async {
    await loadCategories();
    await loadDashboardData();
  }

  // ============================================================
  // CATEGORIES
  // ============================================================

  Future<void> loadCategories() async {
    final incList = await _db.getCategoriesByType('income');
    final expList = await _db.getCategoriesByType('expense');
    _incomeCategories = incList.map(CategoryModel.fromMap).toList();
    _expenseCategories = expList.map(CategoryModel.fromMap).toList();
    notifyListeners();
  }

  Future<bool> addCategory(String name, String type) async {
    if (name.trim().isEmpty) return false;
    final now = DateTime.now().toIso8601String();
    await _db.insertCategory({
      'name': name.trim(),
      'type': type,
      'created_at': now,
    });
    await loadCategories();
    return true;
  }

  // DIPERBAIKI: hapus pengecekan Admin — semua kategori bisa dihapus
  Future<bool> deleteCategory(int id, String type) async {
    await _db.deleteCategory(id);
    await loadCategories();
    return true;
  }

  // ============================================================
  // DASHBOARD DATA
  // ============================================================

  Future<void> loadDashboardData() async {
    _isLoading = true;
    notifyListeners();

    final start = DateFormat('yyyy-MM-dd').format(_startDate);
    final end = DateFormat('yyyy-MM-dd').format(_endDate);

    _transactions =
        (await _db.getTransactions(startDate: start, endDate: end))
            .map(TransactionModel.fromMap)
            .toList();

    _totalIncome =
        await _db.getTotalByType('income', startDate: start, endDate: end);
    _totalExpense =
        await _db.getTotalByType('expense', startDate: start, endDate: end);

    final expTotals = await _db.getCategoryTotals(
      'expense',
      startDate: start,
      endDate: end,
    );
    final incTotals = await _db.getCategoryTotals(
      'income',
      startDate: start,
      endDate: end,
    );

    _expenseTotals = expTotals.map(CategoryTotal.fromMap).toList();
    _incomeTotals = incTotals.map(CategoryTotal.fromMap).toList();

    // Load frequency data sekalian
    await _loadFrequencyData(start, end);

    _isLoading = false;
    notifyListeners();
  }

  // ============================================================
  // TRANSACTIONS — REPORT
  // ============================================================

  Future<List<TransactionModel>> loadTransactionsForReport(
    DateTime startDate,
    DateTime endDate, {
    String? categoryName,
  }) async {
    final start = DateFormat('yyyy-MM-dd').format(startDate);
    final end = DateFormat('yyyy-MM-dd').format(endDate);
    final list = await _db.getTransactions(
      startDate: start,
      endDate: end,
      categoryName: categoryName,
    );
    return list.map(TransactionModel.fromMap).toList();
  }

  Future<Map<String, dynamic>> loadSummaryForReport(
    DateTime startDate,
    DateTime endDate,
  ) async {
    final start = DateFormat('yyyy-MM-dd').format(startDate);
    final end = DateFormat('yyyy-MM-dd').format(endDate);

    final income =
        await _db.getTotalByType('income', startDate: start, endDate: end);
    final expense =
        await _db.getTotalByType('expense', startDate: start, endDate: end);
    final expTotals =
        (await _db.getCategoryTotals('expense', startDate: start, endDate: end))
            .map(CategoryTotal.fromMap)
            .toList();
    final incTotals =
        (await _db.getCategoryTotals('income', startDate: start, endDate: end))
            .map(CategoryTotal.fromMap)
            .toList();

    return {
      'income': income,
      'expense': expense,
      'balance': income - expense,
      'expenseTotals': expTotals,
      'incomeTotals': incTotals,
    };
  }

  // ============================================================
  // DATE RANGE
  // ============================================================

  void setDateRange(DateTime start, DateTime end) {
    _startDate = start;
    _endDate = end;
    loadDashboardData();
  }

  // ============================================================
  // FREQUENCY CHART
  // ============================================================

  Future<void> _loadFrequencyData(String start, String end) async {
    _frequencyData = await _db.getTransactionFrequency(
      _frequencyType,
      start,
      end,
    );
  }

  Future<void> toggleFrequencyType(String type) async {
    _frequencyType = type;
    final start = DateFormat('yyyy-MM-dd').format(_startDate);
    final end = DateFormat('yyyy-MM-dd').format(_endDate);
    _frequencyData = await _db.getTransactionFrequency(type, start, end);
    notifyListeners();
  }

  // ============================================================
  // ADD TRANSACTIONS
  // ============================================================

  Future<bool> addIncomeTransaction({
    required double amount,
    required int categoryId,
    required String categoryName,
    required String date,
    String? description,
  }) async {
    await _db.insertTransaction({
      'type': 'income',
      'amount': amount,
      'category_id': categoryId,
      'category_name': categoryName,
      'description': description,
      'item_name': null,
      'quantity': 1,
      'date': date,
      'created_at': DateTime.now().toIso8601String(),
    });
    await loadDashboardData();
    return true;
  }

  Future<bool> addExpenseTransaction({
    required String itemName,
    required double amount,
    required int categoryId,
    required String categoryName,
    required int quantity,
    required String date,
    String? description,
  }) async {
    await _db.insertTransaction({
      'type': 'expense',
      'amount': amount,
      'category_id': categoryId,
      'category_name': categoryName,
      'item_name': itemName,
      'quantity': quantity,
      'description': description,
      'date': date,
      'created_at': DateTime.now().toIso8601String(),
    });
    await loadDashboardData();
    return true;
  }

  Future<void> deleteTransaction(int id) async {
    await _db.deleteTransaction(id);
    await loadDashboardData();
  }
}