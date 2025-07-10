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

  // MODIFICATION: Reverted database version to 1.
  static const _dbVersion = 1;
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
      onUpgrade: _onUpgrade,
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
    // MODIFICATION: Using the full schema creation method for the fresh start.
    await _createFullSchemaV1(db);
    await _populateDefaultData(db);
  }

  /// Handles database schema upgrades between versions.
  // MODIFICATION: Emptied the upgrade path as we are starting fresh from V1.
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // No upgrade paths needed for a fresh V1 database.
  }

  /// The schema for Version 1 of the database, containing all tables and columns.
  Future<void> _createFullSchemaV1(Database db) async {
    await db.execute('''
      CREATE TABLE transactions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        description TEXT NOT NULL,
        amount REAL NOT NULL,
        type TEXT NOT NULL,
        category TEXT NOT NULL,
        sub_category TEXT,
        transaction_date TEXT NOT NULL,
        debt_id INTEGER,
        pair_id TEXT,
        split_id TEXT,
        friend_id INTEGER,
        prepayment_option TEXT
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
        is_user_debtor INTEGER NOT NULL DEFAULT 1,
        friend_id INTEGER REFERENCES friends(id) ON DELETE SET NULL,
        is_emi_purchase INTEGER NOT NULL DEFAULT 0,
        purchase_description TEXT,
        current_emi REAL,
        current_term_months INTEGER
      )
    ''');

    await db.execute('''
      CREATE TABLE app_settings (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');

    // ---FIX: Removed the 'avatar' column---
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