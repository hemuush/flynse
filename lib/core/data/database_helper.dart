import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

/// Manages the underlying SQLite database connection and schema.
/// This class is responsible for opening the database, creating tables,
/// and running migrations. All data-specific queries have been moved
/// to their respective repository classes.
class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;

  // MODIFICATION: Incremented database version to 2 for schema migration.
  static const _dbVersion = 2;
  static const _dbName = 'expenses.db';

  /// Provides access to the database instance, initializing it if necessary.
  Future<Database> get database async {
    if (_database != null && _database!.isOpen) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  /// Gets the path for the database file.
  Future<String> getDbPath() async {
    return kIsWeb ? _dbName : p.join(await getDatabasesPath(), _dbName);
  }

  /// Closes the database connection.
  Future<void> closeDatabase() async {
    if (_database != null && _database!.isOpen) {
      await _database!.close();
      _database = null;
    }
  }

  /// Initializes the database connection and runs creation/upgrade logic.
  Future<Database> _initDatabase() async {
    final path = await getDbPath();
    return openDatabase(
      path,
      version: _dbVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade, // Add the onUpgrade callback
      onConfigure: (db) => db.execute('PRAGMA foreign_keys = ON'),
    );
  }

  /// Deletes the database file and re-initializes it, effectively clearing all data.
  Future<void> resetDatabase() async {
    await closeDatabase();
    final path = await getDbPath();
    await deleteDatabase(path);
    _database = await _initDatabase();
  }

  /// Called when the database is created for the first time.
  Future<void> _onCreate(Database db, int version) async {
    // For new installations, create the latest (V2) schema directly.
    await _createFullSchemaV2(db);
    await _populateDefaultData(db);
  }

  /// Handles database schema upgrades between versions.
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Migration path from V1 to V2
      await _migrateV1toV2(db);
    }
  }

  /// NEW: Migration logic from version 1 to 2.
  Future<void> _migrateV1toV2(Database db) async {
    await db.transaction((txn) async {
      // Step 1: Create the new friend_debts table
      await txn.execute('''
        CREATE TABLE friend_debts (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          principal_amount REAL NOT NULL,
          total_amount REAL NOT NULL,
          amount_paid REAL NOT NULL DEFAULT 0,
          creation_date TEXT NOT NULL,
          is_closed INTEGER NOT NULL DEFAULT 0,
          is_user_debtor INTEGER NOT NULL,
          friend_id INTEGER NOT NULL REFERENCES friends(id) ON DELETE CASCADE
        )
      ''');

      // Step 2: Move friend debts from the old 'debts' table to 'friend_debts'
      final friendDebtsToMigrate = await txn.query('debts', where: 'friend_id IS NOT NULL');
      for (final debt in friendDebtsToMigrate) {
          await txn.insert('friend_debts', {
              'id': debt['id'],
              'name': debt['name'],
              'principal_amount': debt['principal_amount'],
              'total_amount': debt['total_amount'],
              'amount_paid': debt['amount_paid'],
              'creation_date': debt['creation_date'],
              'is_closed': debt['is_closed'],
              'is_user_debtor': debt['is_user_debtor'],
              'friend_id': debt['friend_id'],
          });
      }

      // Step 3: Create a temporary table for personal debts
      await txn.execute('''
        CREATE TABLE personal_debts_temp (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          principal_amount REAL NOT NULL,
          total_amount REAL NOT NULL,
          amount_paid REAL NOT NULL DEFAULT 0,
          creation_date TEXT NOT NULL,
          is_closed INTEGER NOT NULL DEFAULT 0,
          interest_rate REAL,
          loan_term_years INTEGER,
          interest_updates_applied INTEGER NOT NULL DEFAULT 0,
          is_emi_purchase INTEGER NOT NULL DEFAULT 0,
          purchase_description TEXT,
          current_emi REAL,
          current_term_months INTEGER
        )
      ''');

      // Step 4: Copy personal debts into the temporary table
      final personalDebtsToMigrate = await txn.query('debts', where: 'friend_id IS NULL');
       for (final debt in personalDebtsToMigrate) {
          await txn.insert('personal_debts_temp', {
              'id': debt['id'],
              'name': debt['name'],
              'principal_amount': debt['principal_amount'],
              'total_amount': debt['total_amount'],
              'amount_paid': debt['amount_paid'],
              'creation_date': debt['creation_date'],
              'is_closed': debt['is_closed'],
              'interest_rate': debt['interest_rate'],
              'loan_term_years': debt['loan_term_years'],
              'interest_updates_applied': debt['interest_updates_applied'],
              'is_emi_purchase': debt['is_emi_purchase'],
              'purchase_description': debt['purchase_description'],
              'current_emi': debt['current_emi'],
              'current_term_months': debt['current_term_months'],
          });
      }

      // Step 5: Drop the old debts table and rename the temp table
      await txn.execute('DROP TABLE debts');
      await txn.execute('ALTER TABLE personal_debts_temp RENAME TO debts');

      // Step 6: Update transactions table to have separate foreign keys
      await txn.execute('ALTER TABLE transactions ADD COLUMN personal_debt_id INTEGER REFERENCES debts(id) ON DELETE SET NULL');
      await txn.execute('ALTER TABLE transactions ADD COLUMN friend_debt_id INTEGER REFERENCES friend_debts(id) ON DELETE SET NULL');

      // Step 7: Populate the new foreign key columns based on the old debt_id
      final transactionsWithOldDebtId = await txn.query('transactions', where: 'debt_id IS NOT NULL');
      for (var tx in transactionsWithOldDebtId) {
        final oldDebtId = tx['debt_id'];
        final friendDebtCheck = await txn.query('friend_debts', where: 'id = ?', whereArgs: [oldDebtId]);
        if (friendDebtCheck.isNotEmpty) {
          await txn.update('transactions', {'friend_debt_id': oldDebtId}, where: 'id = ?', whereArgs: [tx['id']]);
        } else {
          await txn.update('transactions', {'personal_debt_id': oldDebtId}, where: 'id = ?', whereArgs: [tx['id']]);
        }
      }

      // Step 8: Recreate transactions table to drop the old debt_id column (SQLite limitation)
      await txn.execute('''
        CREATE TABLE transactions_new (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          description TEXT NOT NULL,
          amount REAL NOT NULL,
          type TEXT NOT NULL,
          category TEXT NOT NULL,
          sub_category TEXT,
          transaction_date TEXT NOT NULL,
          pair_id TEXT,
          split_id TEXT,
          friend_id INTEGER,
          prepayment_option TEXT,
          personal_debt_id INTEGER REFERENCES debts(id) ON DELETE SET NULL,
          friend_debt_id INTEGER REFERENCES friend_debts(id) ON DELETE SET NULL
        )
      ''');
      await txn.rawInsert('''
        INSERT INTO transactions_new (id, description, amount, type, category, sub_category, transaction_date, pair_id, split_id, friend_id, prepayment_option, personal_debt_id, friend_debt_id)
        SELECT id, description, amount, type, category, sub_category, transaction_date, pair_id, split_id, friend_id, prepayment_option, personal_debt_id, friend_debt_id
        FROM transactions
      ''');
      await txn.execute('DROP TABLE transactions');
      await txn.execute('ALTER TABLE transactions_new RENAME TO transactions');
    });
  }

  /// NEW: Schema for V2 for fresh installations.
  Future<void> _createFullSchemaV2(Database db) async {
    await db.execute('''
      CREATE TABLE transactions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        description TEXT NOT NULL,
        amount REAL NOT NULL,
        type TEXT NOT NULL,
        category TEXT NOT NULL,
        sub_category TEXT,
        transaction_date TEXT NOT NULL,
        pair_id TEXT,
        split_id TEXT,
        friend_id INTEGER,
        prepayment_option TEXT,
        personal_debt_id INTEGER REFERENCES debts(id) ON DELETE SET NULL,
        friend_debt_id INTEGER REFERENCES friend_debts(id) ON DELETE SET NULL
      )
    ''');
    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_transactions_type_date ON transactions (type, transaction_date)');

    await db.execute('''
      CREATE TABLE categories (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        type TEXT NOT NULL,
        UNIQUE(name, type)
      )
    ''');

    await db.execute('''
      CREATE TABLE sub_categories (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        category_id INTEGER NOT NULL,
        FOREIGN KEY (category_id) REFERENCES categories (id) ON DELETE CASCADE
      )
    ''');
    
    // MODIFICATION: This table is now only for personal debts.
    await db.execute('''
      CREATE TABLE debts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        principal_amount REAL NOT NULL,
        total_amount REAL NOT NULL,
        amount_paid REAL NOT NULL DEFAULT 0,
        creation_date TEXT NOT NULL,
        is_closed INTEGER NOT NULL DEFAULT 0,
        interest_rate REAL,
        loan_term_years INTEGER,
        interest_updates_applied INTEGER NOT NULL DEFAULT 0,
        is_emi_purchase INTEGER NOT NULL DEFAULT 0,
        purchase_description TEXT,
        current_emi REAL,
        current_term_months INTEGER
      )
    ''');

    // NEW: Table specifically for debts with friends.
    await db.execute('''
      CREATE TABLE friend_debts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        principal_amount REAL NOT NULL,
        total_amount REAL NOT NULL,
        amount_paid REAL NOT NULL DEFAULT 0,
        creation_date TEXT NOT NULL,
        is_closed INTEGER NOT NULL DEFAULT 0,
        is_user_debtor INTEGER NOT NULL,
        friend_id INTEGER NOT NULL REFERENCES friends(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE app_settings (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE friends (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL UNIQUE
      )
    ''');

    await db.execute('''
      CREATE TABLE savings_goals (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        target_amount REAL NOT NULL,
        creation_date TEXT NOT NULL,
        is_completed INTEGER NOT NULL DEFAULT 0
      )
    ''');
  }
  
  /// Populates the database with initial default data.
  Future<void> _populateDefaultData(Database db) async {
    await db.transaction((txn) async {
      final categories = {
        'Expense': ['Debt Repayment', 'Others', 'Shopping', 'Friends'],
        'Income': ['Loan', 'Friends', 'Friend Repayment', 'From Savings'],
        'Saving': ['Bank', 'Savings Withdrawal']
      };

      for (final entry in categories.entries) {
        final type = entry.key;
        for (final catName in entry.value) {
          await txn.insert('categories', {'name': catName, 'type': type},
              conflictAlgorithm: ConflictAlgorithm.ignore);
        }
      }
    });
  }
}
