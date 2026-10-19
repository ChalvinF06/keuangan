import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static const String _dbName = 'dompetku.db';
  static const int _dbVersion = 1;

  // Table names
  static const String tableCategory = 'categories';
  static const String tableTransaction = 'transactions';

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _dbName);
    return await openDatabase(
      path,
      version: _dbVersion,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // === TABEL KATEGORI ===
    await db.execute('''
      CREATE TABLE $tableCategory (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        type TEXT NOT NULL CHECK(type IN ('income', 'expense')),
        created_at TEXT NOT NULL
      )
    ''');

    // === TABEL TRANSAKSI ===
    await db.execute('''
      CREATE TABLE $tableTransaction (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        type TEXT NOT NULL CHECK(type IN ('income', 'expense')),
        amount REAL NOT NULL,
        category_id INTEGER NOT NULL,
        category_name TEXT NOT NULL,
        description TEXT,
        item_name TEXT,
        quantity INTEGER DEFAULT 1,
        date TEXT NOT NULL,
        created_at TEXT NOT NULL,
        FOREIGN KEY (category_id) REFERENCES $tableCategory(id)
      )
    ''');

    // === DATA DEFAULT: Kategori Pengeluaran "Admin" ===
    final now = DateTime.now().toIso8601String();
    await db.insert(tableCategory, {
      'name': 'Admin',
      'type': 'expense',
      'created_at': now,
    });

    // === DATA DEFAULT: Beberapa kategori awal yang berguna ===
    final defaultIncomeCategories = ['Gaji', 'Freelance', 'Bonus', 'Lainnya'];
    for (final cat in defaultIncomeCategories) {
      await db.insert(tableCategory, {
        'name': cat,
        'type': 'income',
        'created_at': now,
      });
    }

    final defaultExpenseCategories = [
      'Makanan & Minuman',
      'Transportasi',
      'Belanja',
      'Kesehatan',
      'Hiburan',
      'Tagihan',
      'Pendidikan',
    ];
    for (final cat in defaultExpenseCategories) {
      await db.insert(tableCategory, {
        'name': cat,
        'type': 'expense',
        'created_at': now,
      });
    }
  }

  // ============================================================
  // CATEGORY METHODS
  // ============================================================

  Future<int> insertCategory(Map<String, dynamic> data) async {
    final db = await database;
    return db.insert(tableCategory, data);
  }

  Future<List<Map<String, dynamic>>> getCategoriesByType(String type) async {
    final db = await database;
    return db.query(
      tableCategory,
      where: 'type = ?',
      whereArgs: [type],
      orderBy: 'name ASC',
    );
  }

  Future<int> deleteCategory(int id) async {
    final db = await database;
    return db.delete(tableCategory, where: 'id = ?', whereArgs: [id]);
  }

  // ============================================================
  // TRANSACTION METHODS
  // ============================================================

  Future<int> insertTransaction(Map<String, dynamic> data) async {
    final db = await database;
    return db.insert(tableTransaction, data);
  }

  Future<int> deleteTransaction(int id) async {
    final db = await database;
    return db.delete(tableTransaction, where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Map<String, dynamic>>> getTransactions({
    String? startDate,
    String? endDate,
    String? type,
    String? categoryName,
  }) async {
    final db = await database;
    final conditions = <String>[];
    final args = <dynamic>[];

    if (startDate != null) {
      conditions.add('date >= ?');
      args.add(startDate);
    }
    if (endDate != null) {
      conditions.add('date <= ?');
      args.add(endDate);
    }
    if (type != null) {
      conditions.add('type = ?');
      args.add(type);
    }
    if (categoryName != null) {
      conditions.add('category_name = ?');
      args.add(categoryName);
    }

    final where = conditions.isEmpty ? null : conditions.join(' AND ');
    return db.query(
      tableTransaction,
      where: where,
      whereArgs: args.isEmpty ? null : args,
      orderBy: 'date DESC, created_at DESC',
    );
  }

  Future<double> getTotalByType(
    String type, {
    String? startDate,
    String? endDate,
  }) async {
    final db = await database;
    final conditions = ['type = ?'];
    final args = <dynamic>[type];

    if (startDate != null) {
      conditions.add('date >= ?');
      args.add(startDate);
    }
    if (endDate != null) {
      conditions.add('date <= ?');
      args.add(endDate);
    }

    final result = await db.rawQuery(
      'SELECT SUM(amount) as total FROM $tableTransaction WHERE ${conditions.join(' AND ')}',
      args,
    );
    return (result.first['total'] as num?)?.toDouble() ?? 0.0;
  }

  Future<List<Map<String, dynamic>>> getCategoryTotals(
    String type, {
    String? startDate,
    String? endDate,
  }) async {
    final db = await database;
    final conditions = ['type = ?'];
    final args = <dynamic>[type];

    if (startDate != null) {
      conditions.add('date >= ?');
      args.add(startDate);
    }
    if (endDate != null) {
      conditions.add('date <= ?');
      args.add(endDate);
    }

    return db.rawQuery(
      '''SELECT category_name, SUM(amount) as total
         FROM $tableTransaction
         WHERE ${conditions.join(' AND ')}
         GROUP BY category_name
         ORDER BY total DESC''',
      args,
    );
  }

  // ============================================================
  // FREQUENCY METHOD — DIPERBAIKI: sekarang di dalam class
  // ============================================================

  Future<List<Map<String, dynamic>>> getTransactionFrequency(
    String type,
    String startDate,
    String endDate,
  ) async {
    final db = await database;
    return db.rawQuery(
      '''SELECT date, COUNT(*) as count, SUM(amount) as total
         FROM $tableTransaction
         WHERE type = ? AND date >= ? AND date <= ?
         GROUP BY date
         ORDER BY date ASC''',
      [type, startDate, endDate],
    );
  }
}