import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';
import '../../core/constants/symbols.dart';

/// SQLite Database Manager for Kestrel.
///
/// Encapsulates schema creation, foreign key enforcement, and connection lifecycle.
class AppDatabase {
  static const String _dbName = 'kestrel.db';
  static const int _dbVersion = 2;

  Database? _db;

  AppDatabase([Database? db]) : _db = db;

  /// Returns the open database instance, initializing it if necessary.
  Future<Database> get database async {
    if (_db != null && _db!.isOpen) {
      return _db!;
    }
    _db = await _initDatabase();
    return _db!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, _dbName);

    return await openDatabase(
      path,
      version: _dbVersion,
      onConfigure: _onConfigure,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  /// Enable foreign keys on SQLite connections
  static Future<void> _onConfigure(Database db) async {
    await db.execute('PRAGMA foreign_keys = ON;');
  }

  /// Create tables on first run
  static Future<void> _onCreate(Database db, int version) async {
    final batch = db.batch();

    // 1. Watchlists table
    batch.execute('''
      CREATE TABLE watchlists (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        position INTEGER NOT NULL DEFAULT 0,
        created_at INTEGER NOT NULL
      );
    ''');

    // 2. Watchlist stocks table (with cascade delete)
    batch.execute('''
      CREATE TABLE watchlist_stocks (
        watchlist_id INTEGER NOT NULL,
        symbol TEXT NOT NULL,
        position INTEGER NOT NULL DEFAULT 0,
        PRIMARY KEY (watchlist_id, symbol),
        FOREIGN KEY (watchlist_id) REFERENCES watchlists (id) ON DELETE CASCADE
      );
    ''');

    // 3. Wallet table (single row with ID = 1)
    batch.execute('''
      CREATE TABLE wallet (
        id INTEGER PRIMARY KEY CHECK (id = 1),
        balance_paise INTEGER NOT NULL,
        locked_paise INTEGER NOT NULL DEFAULT 0
      );
    ''');

    // Seed initial wallet balance (₹1,00,000.00 = 10,000,000 paise)
    batch.rawInsert('''
      INSERT INTO wallet (id, balance_paise, locked_paise)
      VALUES (1, ?, 0)
    ''', [Universe.initialWalletBalance.paise]);

    // 4. Orders table (history & pending orders)
    batch.execute('''
      CREATE TABLE orders (
        id TEXT PRIMARY KEY,
        symbol TEXT NOT NULL,
        side TEXT NOT NULL,
        type TEXT NOT NULL DEFAULT 'MARKET',
        status TEXT NOT NULL DEFAULT 'EXECUTED',
        quantity INTEGER NOT NULL,
        price_paise INTEGER NOT NULL,
        trigger_price_paise INTEGER,
        value_paise INTEGER NOT NULL,
        realized_pnl_paise INTEGER DEFAULT 0,
        timestamp INTEGER NOT NULL,
        executed_at INTEGER
      );
    ''');

    // 5. Holdings table (portfolio)
    batch.execute('''
      CREATE TABLE holdings (
        symbol TEXT PRIMARY KEY,
        quantity INTEGER NOT NULL,
        avg_cost_paise INTEGER NOT NULL,
        updated_at INTEGER NOT NULL
      );
    ''');

    await batch.commit(noResult: true);
  }

  /// Schema migration handler
  static Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Add locked_paise to wallet
      await db.execute(
        'ALTER TABLE wallet ADD COLUMN locked_paise INTEGER NOT NULL DEFAULT 0;',
      );

      // Add v2 columns to orders
      await db.execute(
        "ALTER TABLE orders ADD COLUMN type TEXT NOT NULL DEFAULT 'MARKET';",
      );
      await db.execute(
        "ALTER TABLE orders ADD COLUMN status TEXT NOT NULL DEFAULT 'EXECUTED';",
      );
      await db.execute(
        'ALTER TABLE orders ADD COLUMN trigger_price_paise INTEGER;',
      );
      await db.execute(
        'ALTER TABLE orders ADD COLUMN realized_pnl_paise INTEGER DEFAULT 0;',
      );
      await db.execute(
        'ALTER TABLE orders ADD COLUMN executed_at INTEGER;',
      );
    }
  }

  /// Close the database.
  Future<void> close() async {
    if (_db != null && _db!.isOpen) {
      await _db!.close();
      _db = null;
    }
  }
}

/// Riverpod provider for singleton AppDatabase
final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(() => db.close());
  return db;
});
