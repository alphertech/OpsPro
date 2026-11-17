import 'dart:io';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'storage_service.dart';
import '../services/crypto_service.dart';

class SqliteStorageService implements StorageService {
  static final SqliteStorageService _instance = SqliteStorageService._internal();
  factory SqliteStorageService() => _instance;
  SqliteStorageService._internal();

  static Database? _database;
  static const int _version = 9;
  static const String _dbName = 'agristock.db';
  bool _initialized = false;
  final CryptoService _crypto = CryptoService();

  static void initFfi() {
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }
  }

  @override
  String hashPassword(String password) {
    final salt = _crypto.generateSalt();
    return _crypto.hashPassword(password, salt);
  }

  @override
  bool verifyPassword(String password, String salt, String hash) {
    if (salt.isEmpty || hash.isEmpty) return false;
    return _crypto.verifyPassword(password, salt, hash);
  }

  @override
  Future<void> init() async {
    if (_initialized && _database != null && _database!.isOpen) return;
    final Directory documentsDirectory = await getApplicationDocumentsDirectory();
    final String path = join(documentsDirectory.path, _dbName);

    Future<Database> openDb() => openDatabase(
          path,
          version: _version,
          onCreate: _createDatabase,
          onUpgrade: _upgradeDatabase,
          onOpen: (db) async {
            await db.execute('PRAGMA foreign_keys = ON');
            await db.execute('PRAGMA journal_mode = WAL');
            final av = await db.rawQuery('PRAGMA auto_vacuum');
            final mode = av.isNotEmpty ? (av.first['auto_vacuum'] as int? ?? 0) : 0;
            if (mode == 1) {
              await db.execute('PRAGMA auto_vacuum = NONE');
            }
      await db.execute('PRAGMA synchronous = NORMAL');
      // Ensure required columns/tables exist even for databases whose
      // reported user_version prevented the version-gated migration from
      // running (e.g. a DB stamped v9 by an older build). Without this,
      // every list query (`WHERE is_deleted = 0`) fails and screens render
      // empty even though the data is saved.
      await _ensureSchema(db);
      _initialized = true;
    },
        );

    try {
      _database = await openDb();
    } catch (e) {
      // Recover from a corrupt/stale WAL or SHM side file (common after a crash
      // or forced close) by removing them and retrying.
      for (final suffix in ['-wal', '-shm']) {
        final side = File('$path$suffix');
        if (await side.exists()) {
          try {
            await side.delete();
          } catch (_) {}
        }
      }
      try {
        _database = await openDb();
      } catch (e2) {
        // Last resort: the main database file is corrupt. Recreate it from
        // scratch (existing data is already unrecoverable in this state).
        final main = File(path);
        if (await main.exists()) {
          try {
            await main.delete();
          } catch (_) {}
        }
        _database = await openDb();
      }
    }
  }

  Future<Database> get _db async {
    if (_database == null || !_database!.isOpen) {
      await init();
    }
    if (_database == null) {
      throw StateError('Database is not initialized');
    }
    return _database!;
  }

  Future<void> _createDatabase(Database db, int version) async {
    await db.execute('''
      CREATE TABLE products (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        sku TEXT UNIQUE NOT NULL,
        barcode TEXT,
        category_id INTEGER,
        category_name TEXT,
        purchase_price REAL NOT NULL,
        average_cost REAL NOT NULL,
        selling_price REAL NOT NULL,
        wholesale_price REAL DEFAULT 0,
        vip_price REAL,
        current_stock REAL NOT NULL,
        minimum_stock REAL NOT NULL,
        maximum_stock REAL DEFAULT 999999,
        base_unit TEXT NOT NULL,
        selling_unit TEXT,
        conversion_factor REAL DEFAULT 1,
        weight_per_unit REAL,
        volume_per_unit REAL,
        location TEXT,
        batch_number TEXT,
        manufacturing_date TEXT,
        expiry_date TEXT,
        supplier_id INTEGER,
        supplier_name TEXT,
        is_active INTEGER DEFAULT 1,
        is_deleted INTEGER DEFAULT 0,
        image_path TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE customers (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        phone TEXT,
        email TEXT,
        address TEXT,
        id_number TEXT,
        credit_limit REAL DEFAULT 0,
        current_balance REAL DEFAULT 0,
        notes TEXT,
        is_active INTEGER DEFAULT 1,
        is_deleted INTEGER DEFAULT 0,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE suppliers (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        contact_person TEXT,
        phone TEXT,
        email TEXT,
        address TEXT,
        tax_clearance TEXT,
        notes TEXT,
        is_active INTEGER DEFAULT 1,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        username TEXT UNIQUE NOT NULL,
        password_hash TEXT NOT NULL,
        password_salt TEXT,
        pin_hash TEXT,
        pin_salt TEXT,
        display_name TEXT NOT NULL,
        email TEXT,
        role TEXT NOT NULL,
        is_active INTEGER DEFAULT 1,
        last_login TEXT,
        pattern_hash TEXT,
        pattern_salt TEXT,
        failed_attempts INTEGER DEFAULT 0,
        locked_until TEXT,
        security_question_id INTEGER,
        security_answer_hash TEXT,
        security_answer_salt TEXT,
        setup_completed INTEGER DEFAULT 0,
        lock_type TEXT,
        lockout_level INTEGER DEFAULT 0,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE sales (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        invoice_number TEXT UNIQUE NOT NULL,
        sale_date TEXT NOT NULL,
        customer_id INTEGER,
        customer_name TEXT,
        user_id INTEGER,
        user_name TEXT,
        subtotal REAL NOT NULL,
        discount_amount REAL DEFAULT 0,
        tax_amount REAL DEFAULT 0,
        total_amount REAL NOT NULL,
        amount_paid REAL NOT NULL,
        balance_due REAL DEFAULT 0,
        payment_method TEXT NOT NULL,
        payment_reference TEXT,
        status TEXT NOT NULL,
        notes TEXT,
        is_credit INTEGER DEFAULT 0,
        due_date TEXT,
        is_deleted INTEGER DEFAULT 0,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (customer_id) REFERENCES customers (id),
        FOREIGN KEY (user_id) REFERENCES users (id)
      )
    ''');
    await db.execute('''
      CREATE TABLE sale_items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        sale_id INTEGER NOT NULL,
        product_id INTEGER NOT NULL,
        product_name TEXT NOT NULL,
        product_sku TEXT,
        quantity REAL NOT NULL,
        unit TEXT NOT NULL,
        unit_price REAL NOT NULL,
        purchase_cost REAL NOT NULL,
        discount_amount REAL DEFAULT 0,
        tax_amount REAL DEFAULT 0,
        total_amount REAL NOT NULL,
        batch_number TEXT,
        weight REAL,
        FOREIGN KEY (sale_id) REFERENCES sales (id) ON DELETE CASCADE,
        FOREIGN KEY (product_id) REFERENCES products (id)
      )
    ''');
    await db.execute('''
      CREATE TABLE expenses (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        category TEXT NOT NULL,
        description TEXT,
        amount REAL NOT NULL,
        expense_date TEXT NOT NULL,
        payment_method TEXT,
        reference TEXT,
        receipt_path TEXT,
        notes TEXT,
        is_active INTEGER DEFAULT 1,
        is_deleted INTEGER DEFAULT 0,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE backups (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        file_path TEXT NOT NULL,
        file_size INTEGER,
        backup_date TEXT NOT NULL,
        description TEXT,
        created_at TEXT NOT NULL
      )
    ''');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_products_sku ON products (sku)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_products_name ON products (name)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_sales_date ON sales (sale_date)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_sale_items_sale ON sale_items (sale_id)');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS security_questions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        question_text TEXT NOT NULL,
        is_default INTEGER DEFAULT 0,
        created_at TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS security_events (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER,
        event_type TEXT NOT NULL,
        details TEXT,
        ip_address TEXT,
        created_at TEXT NOT NULL,
        FOREIGN KEY (user_id) REFERENCES users (id)
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS security_config (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        max_failed_attempts INTEGER DEFAULT 5,
        lockout_duration_minutes INTEGER DEFAULT 15,
        require_security_question INTEGER DEFAULT 1,
        allow_pattern INTEGER DEFAULT 1,
        allow_pin INTEGER DEFAULT 1,
        allow_password INTEGER DEFAULT 1,
        session_timeout_minutes INTEGER DEFAULT 15,
        enable_f5_lock INTEGER DEFAULT 1,
        updated_at TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS accounts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        code TEXT UNIQUE NOT NULL,
        name TEXT NOT NULL,
        type TEXT NOT NULL,
        sub_type TEXT,
        balance REAL DEFAULT 0,
        parent_id INTEGER,
        is_active INTEGER DEFAULT 1,
        description TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS journal_entries (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        entry_number TEXT UNIQUE NOT NULL,
        entry_date TEXT NOT NULL,
        description TEXT NOT NULL,
        amount REAL NOT NULL,
        debit_account_id INTEGER NOT NULL,
        credit_account_id INTEGER NOT NULL,
        reference TEXT,
        notes TEXT,
        user_id INTEGER,
        created_at TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS bank_reconciliations (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        bank_account_id INTEGER NOT NULL,
        statement_date TEXT NOT NULL,
        statement_balance REAL NOT NULL,
        book_balance REAL NOT NULL,
        adjusted_balance REAL DEFAULT 0,
        is_reconciled INTEGER DEFAULT 0,
        reconciled_at TEXT,
        notes TEXT,
        created_at TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS petty_cash_transactions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        transaction_date TEXT NOT NULL,
        description TEXT NOT NULL,
        amount REAL NOT NULL,
        type TEXT NOT NULL,
        paid_to TEXT,
        received_from TEXT,
        receipt_number TEXT,
        user_id INTEGER,
        created_at TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS employees (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        employee_id TEXT UNIQUE NOT NULL,
        first_name TEXT NOT NULL,
        last_name TEXT NOT NULL,
        email TEXT,
        phone TEXT,
        address TEXT,
        id_number TEXT,
        tax_id TEXT,
        emergency_contact_name TEXT,
        emergency_contact_phone TEXT,
        job_title TEXT NOT NULL,
        department TEXT DEFAULT '',
        hire_date TEXT NOT NULL,
        salary REAL DEFAULT 0,
        employment_type TEXT DEFAULT 'Full-time',
        status TEXT DEFAULT 'Active',
        termination_date TEXT,
        bank_name TEXT,
        bank_account_number TEXT,
        notes TEXT,
        is_active INTEGER DEFAULT 1,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS leave_requests (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        employee_id INTEGER NOT NULL,
        employee_name TEXT NOT NULL,
        leave_type TEXT NOT NULL,
        start_date TEXT NOT NULL,
        end_date TEXT NOT NULL,
        days REAL NOT NULL,
        reason TEXT NOT NULL,
        status TEXT DEFAULT 'Pending',
        approved_by INTEGER,
        approver_name TEXT,
        approved_at TEXT,
        comments TEXT,
        created_at TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS shifts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        employee_id INTEGER NOT NULL,
        employee_name TEXT NOT NULL,
        shift_date TEXT NOT NULL,
        start_time TEXT NOT NULL,
        end_time TEXT NOT NULL,
        break_duration TEXT,
        shift_type TEXT DEFAULT 'Regular',
        notes TEXT,
        created_at TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS expense_reimbursements (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        employee_id INTEGER NOT NULL,
        employee_name TEXT NOT NULL,
        expense_date TEXT NOT NULL,
        category TEXT NOT NULL,
        amount REAL NOT NULL,
        description TEXT NOT NULL,
        receipt_path TEXT,
        status TEXT DEFAULT 'Pending',
        approved_by INTEGER,
        approver_name TEXT,
        approved_at TEXT,
        notes TEXT,
        created_at TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS purchase_orders (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        po_number TEXT UNIQUE NOT NULL,
        supplier_id INTEGER NOT NULL,
        supplier_name TEXT NOT NULL,
        order_date TEXT NOT NULL,
        expected_date TEXT,
        status TEXT DEFAULT 'Draft',
        subtotal REAL DEFAULT 0,
        tax_amount REAL DEFAULT 0,
        shipping_cost REAL DEFAULT 0,
        insurance_cost REAL DEFAULT 0,
        customs_fee REAL DEFAULT 0,
        other_costs REAL DEFAULT 0,
        total_amount REAL DEFAULT 0,
        amount_paid REAL DEFAULT 0,
        notes TEXT,
        created_by INTEGER,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS purchase_order_items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        po_id INTEGER NOT NULL,
        product_id INTEGER NOT NULL,
        product_name TEXT NOT NULL,
        product_sku TEXT,
        quantity REAL NOT NULL,
        unit TEXT NOT NULL,
        unit_price REAL NOT NULL,
        received_quantity REAL DEFAULT 0,
        total_price REAL DEFAULT 0,
        landed_cost_per_unit REAL DEFAULT 0,
        FOREIGN KEY (po_id) REFERENCES purchase_orders (id) ON DELETE CASCADE
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS projects (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        description TEXT,
        customer_id INTEGER,
        customer_name TEXT,
        start_date TEXT NOT NULL,
        end_date TEXT,
        status TEXT DEFAULT 'Planning',
        budget REAL DEFAULT 0,
        actual_cost REAL DEFAULT 0,
        manager_id INTEGER,
        manager_name TEXT,
        priority TEXT DEFAULT 'Medium',
        progress INTEGER DEFAULT 0,
        notes TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS project_tasks (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        project_id INTEGER NOT NULL,
        project_name TEXT DEFAULT '',
        title TEXT NOT NULL,
        description TEXT,
        status TEXT DEFAULT 'Not Started',
        priority TEXT DEFAULT 'Medium',
        start_date TEXT,
        due_date TEXT,
        completed_date TEXT,
        assigned_to INTEGER,
        assignee_name TEXT,
        predecessor_id INTEGER,
        estimated_hours REAL DEFAULT 0,
        actual_hours REAL DEFAULT 0,
        progress INTEGER DEFAULT 0,
        notes TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (project_id) REFERENCES projects (id) ON DELETE CASCADE
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS time_entries (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        project_id INTEGER,
        task_id INTEGER,
        employee_id INTEGER,
        employee_name TEXT,
        entry_date TEXT NOT NULL,
        hours REAL NOT NULL,
        description TEXT,
        is_billable INTEGER DEFAULT 0,
        hourly_rate REAL,
        created_at TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS project_attachments (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        project_id INTEGER NOT NULL,
        file_name TEXT NOT NULL,
        file_path TEXT NOT NULL,
        file_size REAL DEFAULT 0,
        description TEXT,
        created_at TEXT NOT NULL,
        FOREIGN KEY (project_id) REFERENCES projects (id) ON DELETE CASCADE
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS audit_logs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        table_name TEXT NOT NULL,
        record_id INTEGER,
        action TEXT NOT NULL,
        old_values TEXT,
        new_values TEXT,
        user_id INTEGER,
        user_name TEXT,
        created_at TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS currencies (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        code TEXT UNIQUE NOT NULL,
        name TEXT NOT NULL,
        symbol TEXT NOT NULL,
        exchange_rate REAL DEFAULT 1,
        is_default INTEGER DEFAULT 0,
        is_active INTEGER DEFAULT 1,
        updated_at TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS tax_rates (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        rate REAL DEFAULT 0,
        description TEXT,
        is_default INTEGER DEFAULT 0,
        is_active INTEGER DEFAULT 1,
        created_at TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS recurring_invoices (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        customer_id INTEGER,
        customer_name TEXT,
        frequency TEXT DEFAULT 'Monthly',
        start_date TEXT NOT NULL,
        end_date TEXT,
        last_generated TEXT,
        next_due TEXT NOT NULL,
        amount REAL DEFAULT 0,
        tax_amount REAL DEFAULT 0,
        total_amount REAL DEFAULT 0,
        notes TEXT,
        status TEXT DEFAULT 'Active',
        created_at TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS credit_memos (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        memo_number TEXT UNIQUE NOT NULL,
        sale_id INTEGER NOT NULL,
        invoice_number TEXT NOT NULL,
        customer_id INTEGER,
        customer_name TEXT,
        memo_date TEXT NOT NULL,
        amount REAL DEFAULT 0,
        tax_amount REAL DEFAULT 0,
        total_amount REAL DEFAULT 0,
        reason TEXT NOT NULL,
        status TEXT DEFAULT 'Issued',
        created_at TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS warehouses (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        code TEXT,
        address TEXT,
        manager TEXT,
        is_default INTEGER DEFAULT 0,
        is_active INTEGER DEFAULT 1,
        created_at TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS stock_transfers (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        transfer_number TEXT UNIQUE NOT NULL,
        from_warehouse_id INTEGER NOT NULL,
        to_warehouse_id INTEGER NOT NULL,
        from_warehouse_name TEXT NOT NULL,
        to_warehouse_name TEXT NOT NULL,
        transfer_date TEXT NOT NULL,
        status TEXT DEFAULT 'Pending',
        notes TEXT,
        created_by INTEGER,
        created_at TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS email_queue (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        recipient TEXT NOT NULL,
        subject TEXT NOT NULL,
        body TEXT NOT NULL,
        attachment_path TEXT,
        created_at TEXT NOT NULL,
        sent_at TEXT,
        status TEXT DEFAULT 'Pending'
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS internal_memos (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        content TEXT NOT NULL,
        created_by INTEGER NOT NULL,
        created_by_name TEXT NOT NULL,
        priority TEXT DEFAULT 'Normal',
        created_at TEXT NOT NULL,
        expires_at TEXT,
        is_pinned INTEGER DEFAULT 0
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS warehouses_stock (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        warehouse_id INTEGER NOT NULL,
        product_id INTEGER NOT NULL,
        quantity REAL DEFAULT 0,
        FOREIGN KEY (warehouse_id) REFERENCES warehouses (id),
        FOREIGN KEY (product_id) REFERENCES products (id),
        UNIQUE(warehouse_id, product_id)
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS app_preferences (
        id INTEGER PRIMARY KEY CHECK (id = 1),
        currency_symbol TEXT DEFAULT 'UGX',
        currency_position TEXT DEFAULT 'Left',
        decimal_places INTEGER DEFAULT 0,
        date_format TEXT DEFAULT 'dd/MM/yyyy',
        invoice_prefix TEXT DEFAULT 'INV-',
        next_invoice_number INTEGER DEFAULT 1001,
        default_tax_rate REAL DEFAULT 0.0,
        tax_inclusive INTEGER DEFAULT 0,
        allow_negative_stock INTEGER DEFAULT 0,
        require_customer INTEGER DEFAULT 0,
        enable_f5_lock INTEGER DEFAULT 1,
        auto_backup INTEGER DEFAULT 1,
        backup_interval_hours INTEGER DEFAULT 2,
        dark_mode INTEGER DEFAULT 0,
        updated_at TEXT NOT NULL
      )
    ''');
    await _insertDefaultData(db);
  }

  Future<void> _upgradeDatabase(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS security_questions (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          question_text TEXT NOT NULL,
          is_default INTEGER DEFAULT 0,
          created_at TEXT NOT NULL
        )
      ''');
      await db.execute('''
        CREATE TABLE IF NOT EXISTS security_events (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          user_id INTEGER,
          event_type TEXT NOT NULL,
          details TEXT,
          ip_address TEXT,
          created_at TEXT NOT NULL,
          FOREIGN KEY (user_id) REFERENCES users (id)
        )
      ''');
    }
    if (oldVersion < 3) {
      try {
        await db.execute('ALTER TABLE users ADD COLUMN lock_type TEXT');
      } catch (_) {}
    }
    if (oldVersion < 4) {
      try {
        await db.execute('ALTER TABLE users ADD COLUMN lockout_level INTEGER DEFAULT 0');
      } catch (_) {}
    }
    if (oldVersion < 5) {
      try {
        await db.execute('ALTER TABLE products ADD COLUMN image_path TEXT');
      } catch (_) {}
    }
    if (oldVersion < 6) {
      final columns = <String, String>{
        'password_salt': 'TEXT',
        'pin_hash': 'TEXT',
        'pin_salt': 'TEXT',
        'pattern_salt': 'TEXT',
        'security_answer_salt': 'TEXT',
      };
      for (final entry in columns.entries) {
        try {
          await db.execute('ALTER TABLE users ADD COLUMN ${entry.key} ${entry.value}');
        } catch (_) {}
      }
      await db.execute('''
        CREATE TABLE IF NOT EXISTS security_config (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          max_failed_attempts INTEGER DEFAULT 5,
          lockout_duration_minutes INTEGER DEFAULT 15,
          require_security_question INTEGER DEFAULT 1,
          allow_pattern INTEGER DEFAULT 1,
          allow_pin INTEGER DEFAULT 1,
          allow_password INTEGER DEFAULT 1,
          session_timeout_minutes INTEGER DEFAULT 15,
          enable_f5_lock INTEGER DEFAULT 1,
          updated_at TEXT NOT NULL
        )
      ''');
    }
    if (oldVersion < 7) {
      await _createNewTables(db);
    }
    if (oldVersion < 8) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS app_preferences (
          id INTEGER PRIMARY KEY CHECK (id = 1),
          currency_symbol TEXT DEFAULT 'UGX',
          currency_position TEXT DEFAULT 'Left',
          decimal_places INTEGER DEFAULT 0,
          date_format TEXT DEFAULT 'dd/MM/yyyy',
          invoice_prefix TEXT DEFAULT 'INV-',
          next_invoice_number INTEGER DEFAULT 1001,
        default_tax_rate REAL DEFAULT 0.0,
          tax_inclusive INTEGER DEFAULT 0,
          allow_negative_stock INTEGER DEFAULT 0,
          require_customer INTEGER DEFAULT 0,
          enable_f5_lock INTEGER DEFAULT 1,
          auto_backup INTEGER DEFAULT 1,
          backup_interval_hours INTEGER DEFAULT 2,
          dark_mode INTEGER DEFAULT 0,
          updated_at TEXT NOT NULL
        )
      ''');
    }
    if (oldVersion < 9) {
      try {
        await db.execute('ALTER TABLE products ADD COLUMN is_deleted INTEGER DEFAULT 0');
      } catch (_) {}
      try {
        await db.execute('ALTER TABLE customers ADD COLUMN is_deleted INTEGER DEFAULT 0');
      } catch (_) {}
      try {
        await db.execute('ALTER TABLE suppliers ADD COLUMN is_deleted INTEGER DEFAULT 0');
      } catch (_) {}
      try {
        await db.execute('ALTER TABLE sales ADD COLUMN is_deleted INTEGER DEFAULT 0');
      } catch (_) {}
      try {
        await db.execute('ALTER TABLE expenses ADD COLUMN is_deleted INTEGER DEFAULT 0');
      } catch (_) {}
      await db.execute('''
        CREATE VIRTUAL TABLE IF NOT EXISTS products_fts USING fts5(
          name,
          sku,
          barcode,
          category_name,
          content='products',
          content_rowid='id'
        )
      ''');
      await db.execute('''
        CREATE TABLE IF NOT EXISTS transaction_log (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          table_name TEXT NOT NULL,
          record_id INTEGER NOT NULL,
          action TEXT NOT NULL,
          old_values TEXT,
          new_values TEXT,
          user_id INTEGER,
          user_name TEXT,
          created_at TEXT NOT NULL
        )
      ''');
      await db.execute('''
        CREATE TABLE IF NOT EXISTS cash_movements (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          movement_type TEXT NOT NULL,
          amount REAL NOT NULL,
          payment_method TEXT NOT NULL,
          sale_id INTEGER,
          reference TEXT,
          notes TEXT,
          user_id INTEGER,
          user_name TEXT,
          created_at TEXT NOT NULL
        )
      ''');
      await db.execute('''
        CREATE TABLE IF NOT EXISTS daily_closing (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          closing_date TEXT NOT NULL,
          cash_expected REAL NOT NULL,
          cash_counted REAL NOT NULL,
          cash_variance REAL NOT NULL,
          total_sales REAL NOT NULL,
          total_cash REAL NOT NULL,
          total_credit REAL NOT NULL,
          total_mobile REAL NOT NULL,
          total_bank REAL NOT NULL,
          transaction_count INTEGER NOT NULL,
          snapshot_json TEXT NOT NULL,
          user_id INTEGER,
          user_name TEXT,
          created_at TEXT NOT NULL
        )
      ''');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_transaction_log_table_record ON transaction_log (table_name, record_id)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_cash_movements_sale ON cash_movements (sale_id)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_daily_closing_date ON daily_closing (closing_date)');
    }
    await _insertDefaultData(db);
  }

  /// Idempotently ensures the schema contains all columns and tables expected
  /// by the current code, regardless of the database's reported user_version.
  ///
  /// This is the safety net for databases that were stamped with version 9 by
  /// an older build whose create/migrate logic omitted these objects. Because
  /// [onUpgrade] only runs when oldVersion < newVersion, such databases would
  /// otherwise never receive the `is_deleted` columns (used by every list
  /// query) and the v9 support tables, leaving all list screens empty.
  Future<void> _ensureSchema(Database db) async {
    try {
      const deletedTables = {
        'products': 'INTEGER DEFAULT 0',
        'customers': 'INTEGER DEFAULT 0',
        'suppliers': 'INTEGER DEFAULT 0',
        'sales': 'INTEGER DEFAULT 0',
        'expenses': 'INTEGER DEFAULT 0',
      };
      for (final entry in deletedTables.entries) {
        if (!await _columnExists(db, entry.key, 'is_deleted')) {
          try {
            await db.execute(
              'ALTER TABLE ${entry.key} ADD COLUMN is_deleted ${entry.value}',
            );
          } catch (_) {
            // Best effort; ignore if the column already exists or cannot be added.
          }
        }
      }

      // Ensure v9 support tables exist (transaction logging, cash movement
      // tracking, daily closing and full-text product search).
      await _ensureTable(db, '''
        CREATE TABLE IF NOT EXISTS transaction_log (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          table_name TEXT NOT NULL,
          record_id INTEGER NOT NULL,
          action TEXT NOT NULL,
          old_values TEXT,
          new_values TEXT,
          user_id INTEGER,
          user_name TEXT,
          created_at TEXT NOT NULL
        )
      ''');
      await _ensureTable(db, '''
        CREATE TABLE IF NOT EXISTS cash_movements (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          movement_type TEXT NOT NULL,
          amount REAL NOT NULL,
          payment_method TEXT NOT NULL,
          sale_id INTEGER,
          reference TEXT,
          notes TEXT,
          user_id INTEGER,
          user_name TEXT,
          created_at TEXT NOT NULL
        )
      ''');
      await _ensureTable(db, '''
        CREATE TABLE IF NOT EXISTS daily_closing (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          closing_date TEXT NOT NULL,
          cash_expected REAL NOT NULL,
          cash_counted REAL NOT NULL,
          cash_variance REAL NOT NULL,
          total_sales REAL NOT NULL,
          total_cash REAL NOT NULL,
          total_credit REAL NOT NULL,
          total_mobile REAL NOT NULL,
          total_bank REAL NOT NULL,
          transaction_count INTEGER NOT NULL,
          snapshot_json TEXT NOT NULL,
          user_id INTEGER,
          user_name TEXT,
          created_at TEXT NOT NULL
        )
      ''');
      try {
        final fts = await db.rawQuery(
          "SELECT name FROM sqlite_master WHERE type='table' AND name='products_fts'",
        );
        if (fts.isEmpty) {
          await db.execute('''
            CREATE VIRTUAL TABLE IF NOT EXISTS products_fts USING fts5(
              name,
              sku,
              barcode,
              category_name,
              content='products',
              content_rowid='id'
            )
          ''');
        }
      } catch (_) {
        // FTS5 may be unavailable in some SQLite builds; ignore.
      }
    } catch (_) {
      // Never let schema reconciliation break opening the database.
    }
  }

  Future<bool> _columnExists(Database db, String table, String column) async {
    final info = await db.rawQuery('PRAGMA table_info($table)');
    return info.any((r) => r['name'] == column);
  }

  Future<void> _ensureTable(Database db, String createSql) async {
    try {
      await db.execute(createSql);
    } catch (_) {
      // Best effort; ignore if creation fails (e.g. concurrent access).
    }
  }

  Future<void> _createNewTables(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS accounts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        code TEXT UNIQUE NOT NULL,
        name TEXT NOT NULL,
        type TEXT NOT NULL,
        sub_type TEXT,
        balance REAL DEFAULT 0,
        parent_id INTEGER,
        is_active INTEGER DEFAULT 1,
        description TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS journal_entries (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        entry_number TEXT UNIQUE NOT NULL,
        entry_date TEXT NOT NULL,
        description TEXT NOT NULL,
        amount REAL NOT NULL,
        debit_account_id INTEGER NOT NULL,
        credit_account_id INTEGER NOT NULL,
        reference TEXT,
        notes TEXT,
        user_id INTEGER,
        created_at TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS bank_reconciliations (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        bank_account_id INTEGER NOT NULL,
        statement_date TEXT NOT NULL,
        statement_balance REAL NOT NULL,
        book_balance REAL NOT NULL,
        adjusted_balance REAL DEFAULT 0,
        is_reconciled INTEGER DEFAULT 0,
        reconciled_at TEXT,
        notes TEXT,
        created_at TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS petty_cash_transactions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        transaction_date TEXT NOT NULL,
        description TEXT NOT NULL,
        amount REAL NOT NULL,
        type TEXT NOT NULL,
        paid_to TEXT,
        received_from TEXT,
        receipt_number TEXT,
        user_id INTEGER,
        created_at TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS employees (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        employee_id TEXT UNIQUE NOT NULL,
        first_name TEXT NOT NULL,
        last_name TEXT NOT NULL,
        email TEXT,
        phone TEXT,
        address TEXT,
        id_number TEXT,
        tax_id TEXT,
        emergency_contact_name TEXT,
        emergency_contact_phone TEXT,
        job_title TEXT NOT NULL,
        department TEXT DEFAULT '',
        hire_date TEXT NOT NULL,
        salary REAL DEFAULT 0,
        employment_type TEXT DEFAULT 'Full-time',
        status TEXT DEFAULT 'Active',
        termination_date TEXT,
        bank_name TEXT,
        bank_account_number TEXT,
        notes TEXT,
        is_active INTEGER DEFAULT 1,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS leave_requests (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        employee_id INTEGER NOT NULL,
        employee_name TEXT NOT NULL,
        leave_type TEXT NOT NULL,
        start_date TEXT NOT NULL,
        end_date TEXT NOT NULL,
        days REAL NOT NULL,
        reason TEXT NOT NULL,
        status TEXT DEFAULT 'Pending',
        approved_by INTEGER,
        approver_name TEXT,
        approved_at TEXT,
        comments TEXT,
        created_at TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS shifts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        employee_id INTEGER NOT NULL,
        employee_name TEXT NOT NULL,
        shift_date TEXT NOT NULL,
        start_time TEXT NOT NULL,
        end_time TEXT NOT NULL,
        break_duration TEXT,
        shift_type TEXT DEFAULT 'Regular',
        notes TEXT,
        created_at TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS expense_reimbursements (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        employee_id INTEGER NOT NULL,
        employee_name TEXT NOT NULL,
        expense_date TEXT NOT NULL,
        category TEXT NOT NULL,
        amount REAL NOT NULL,
        description TEXT NOT NULL,
        receipt_path TEXT,
        status TEXT DEFAULT 'Pending',
        approved_by INTEGER,
        approver_name TEXT,
        approved_at TEXT,
        notes TEXT,
        created_at TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS purchase_orders (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        po_number TEXT UNIQUE NOT NULL,
        supplier_id INTEGER NOT NULL,
        supplier_name TEXT NOT NULL,
        order_date TEXT NOT NULL,
        expected_date TEXT,
        status TEXT DEFAULT 'Draft',
        subtotal REAL DEFAULT 0,
        tax_amount REAL DEFAULT 0,
        shipping_cost REAL DEFAULT 0,
        insurance_cost REAL DEFAULT 0,
        customs_fee REAL DEFAULT 0,
        other_costs REAL DEFAULT 0,
        total_amount REAL DEFAULT 0,
        amount_paid REAL DEFAULT 0,
        notes TEXT,
        created_by INTEGER,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS purchase_order_items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        po_id INTEGER NOT NULL,
        product_id INTEGER NOT NULL,
        product_name TEXT NOT NULL,
        product_sku TEXT,
        quantity REAL NOT NULL,
        unit TEXT NOT NULL,
        unit_price REAL NOT NULL,
        received_quantity REAL DEFAULT 0,
        total_price REAL DEFAULT 0,
        landed_cost_per_unit REAL DEFAULT 0,
        FOREIGN KEY (po_id) REFERENCES purchase_orders (id) ON DELETE CASCADE
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS projects (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        description TEXT,
        customer_id INTEGER,
        customer_name TEXT,
        start_date TEXT NOT NULL,
        end_date TEXT,
        status TEXT DEFAULT 'Planning',
        budget REAL DEFAULT 0,
        actual_cost REAL DEFAULT 0,
        manager_id INTEGER,
        manager_name TEXT,
        priority TEXT DEFAULT 'Medium',
        progress INTEGER DEFAULT 0,
        notes TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS project_tasks (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        project_id INTEGER NOT NULL,
        project_name TEXT DEFAULT '',
        title TEXT NOT NULL,
        description TEXT,
        status TEXT DEFAULT 'Not Started',
        priority TEXT DEFAULT 'Medium',
        start_date TEXT,
        due_date TEXT,
        completed_date TEXT,
        assigned_to INTEGER,
        assignee_name TEXT,
        predecessor_id INTEGER,
        estimated_hours REAL DEFAULT 0,
        actual_hours REAL DEFAULT 0,
        progress INTEGER DEFAULT 0,
        notes TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (project_id) REFERENCES projects (id) ON DELETE CASCADE
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS time_entries (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        project_id INTEGER,
        task_id INTEGER,
        employee_id INTEGER,
        employee_name TEXT,
        entry_date TEXT NOT NULL,
        hours REAL NOT NULL,
        description TEXT,
        is_billable INTEGER DEFAULT 0,
        hourly_rate REAL,
        created_at TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS project_attachments (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        project_id INTEGER NOT NULL,
        file_name TEXT NOT NULL,
        file_path TEXT NOT NULL,
        file_size REAL DEFAULT 0,
        description TEXT,
        created_at TEXT NOT NULL,
        FOREIGN KEY (project_id) REFERENCES projects (id) ON DELETE CASCADE
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS audit_logs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        table_name TEXT NOT NULL,
        record_id INTEGER,
        action TEXT NOT NULL,
        old_values TEXT,
        new_values TEXT,
        user_id INTEGER,
        user_name TEXT,
        created_at TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS currencies (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        code TEXT UNIQUE NOT NULL,
        name TEXT NOT NULL,
        symbol TEXT NOT NULL,
        exchange_rate REAL DEFAULT 1,
        is_default INTEGER DEFAULT 0,
        is_active INTEGER DEFAULT 1,
        updated_at TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS tax_rates (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        rate REAL DEFAULT 0,
        description TEXT,
        is_default INTEGER DEFAULT 0,
        is_active INTEGER DEFAULT 1,
        created_at TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS recurring_invoices (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        customer_id INTEGER,
        customer_name TEXT,
        frequency TEXT DEFAULT 'Monthly',
        start_date TEXT NOT NULL,
        end_date TEXT,
        last_generated TEXT,
        next_due TEXT NOT NULL,
        amount REAL DEFAULT 0,
        tax_amount REAL DEFAULT 0,
        total_amount REAL DEFAULT 0,
        notes TEXT,
        status TEXT DEFAULT 'Active',
        created_at TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS credit_memos (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        memo_number TEXT UNIQUE NOT NULL,
        sale_id INTEGER NOT NULL,
        invoice_number TEXT NOT NULL,
        customer_id INTEGER,
        customer_name TEXT,
        memo_date TEXT NOT NULL,
        amount REAL DEFAULT 0,
        tax_amount REAL DEFAULT 0,
        total_amount REAL DEFAULT 0,
        reason TEXT NOT NULL,
        status TEXT DEFAULT 'Issued',
        created_at TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS warehouses (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        code TEXT,
        address TEXT,
        manager TEXT,
        is_default INTEGER DEFAULT 0,
        is_active INTEGER DEFAULT 1,
        created_at TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS stock_transfers (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        transfer_number TEXT UNIQUE NOT NULL,
        from_warehouse_id INTEGER NOT NULL,
        to_warehouse_id INTEGER NOT NULL,
        from_warehouse_name TEXT NOT NULL,
        to_warehouse_name TEXT NOT NULL,
        transfer_date TEXT NOT NULL,
        status TEXT DEFAULT 'Pending',
        notes TEXT,
        created_by INTEGER,
        created_at TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS email_queue (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        recipient TEXT NOT NULL,
        subject TEXT NOT NULL,
        body TEXT NOT NULL,
        attachment_path TEXT,
        created_at TEXT NOT NULL,
        sent_at TEXT,
        status TEXT DEFAULT 'Pending'
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS internal_memos (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        content TEXT NOT NULL,
        created_by INTEGER NOT NULL,
        created_by_name TEXT NOT NULL,
        priority TEXT DEFAULT 'Normal',
        created_at TEXT NOT NULL,
        expires_at TEXT,
        is_pinned INTEGER DEFAULT 0
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS warehouses_stock (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        warehouse_id INTEGER NOT NULL,
        product_id INTEGER NOT NULL,
        quantity REAL DEFAULT 0,
        is_deleted INTEGER DEFAULT 0,
        FOREIGN KEY (warehouse_id) REFERENCES warehouses (id),
        FOREIGN KEY (product_id) REFERENCES products (id),
        UNIQUE(warehouse_id, product_id)
      )
    ''');
    await db.execute('''
      CREATE VIRTUAL TABLE products_fts USING fts5(
        name,
        sku,
        barcode,
        category_name,
        content='products',
        content_rowid='id'
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS transaction_log (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        table_name TEXT NOT NULL,
        record_id INTEGER NOT NULL,
        action TEXT NOT NULL,
        old_values TEXT,
        new_values TEXT,
        user_id INTEGER,
        user_name TEXT,
        created_at TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS cash_movements (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        movement_type TEXT NOT NULL,
        amount REAL NOT NULL,
        payment_method TEXT NOT NULL,
        sale_id INTEGER,
        reference TEXT,
        notes TEXT,
        user_id INTEGER,
        user_name TEXT,
        created_at TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS daily_closing (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        closing_date TEXT NOT NULL,
        cash_expected REAL NOT NULL,
        cash_counted REAL NOT NULL,
        cash_variance REAL NOT NULL,
        total_sales REAL NOT NULL,
        total_cash REAL NOT NULL,
        total_credit REAL NOT NULL,
        total_mobile REAL NOT NULL,
        total_bank REAL NOT NULL,
        transaction_count INTEGER NOT NULL,
        snapshot_json TEXT NOT NULL,
        user_id INTEGER,
        user_name TEXT,
        created_at TEXT NOT NULL
      )
    ''');
    final columns = <String, String>{
      'password_salt': 'TEXT',
      'pin_hash': 'TEXT',
      'pin_salt': 'TEXT',
      'pattern_hash': 'TEXT',
      'pattern_salt': 'TEXT',
      'failed_attempts': 'INTEGER DEFAULT 0',
      'locked_until': 'TEXT',
      'security_question_id': 'INTEGER',
      'security_answer_hash': 'TEXT',
      'security_answer_salt': 'TEXT',
      'setup_completed': 'INTEGER DEFAULT 0',
      'lock_type': 'TEXT',
      'lockout_level': 'INTEGER DEFAULT 0',
      'image_path': 'TEXT',
    };

    for (final entry in columns.entries) {
      try {
        await db.execute('ALTER TABLE users ADD COLUMN ${entry.key} ${entry.value}');
      } catch (_) {}
    }
  }

  Future<void> _insertDefaultData(Database db) async {
    final questionCount = await db.query('security_questions');
    if (questionCount.isEmpty) {
      final questions = [
        'What is your mother\'s maiden name?',
        'What was your first pet\'s name?',
        'What is the name of your first school?',
        'What is your favorite color?',
        'What city were you born in?',
        'What is your favorite food?',
        'What is your father\'s first name?',
        'What was your childhood nickname?',
      ];
      for (final q in questions) {
        await db.insert('security_questions', {
          'question_text': q,
          'is_default': 1,
          'created_at': DateTime.now().toIso8601String(),
        });
      }
    }

    final configCount = await db.query('security_config');
    if (configCount.isEmpty) {
      await db.insert('security_config', {
        'max_failed_attempts': 5,
        'lockout_duration_minutes': 15,
        'require_security_question': 1,
        'allow_pattern': 1,
        'allow_pin': 1,
        'allow_password': 1,
        'session_timeout_minutes': 15,
        'enable_f5_lock': 1,
        'updated_at': DateTime.now().toIso8601String(),
      });
    }

    final currencyCount = await db.query('currencies');
    if (currencyCount.isEmpty) {
      await db.insert('currencies', {
        'code': 'UGX',
        'name': 'Ugandan Shilling',
        'symbol': 'USh',
        'exchange_rate': 1,
        'is_default': 1,
        'is_active': 1,
        'updated_at': DateTime.now().toIso8601String(),
      });
      await db.insert('currencies', {
        'code': 'USD',
        'name': 'US Dollar',
        'symbol': '\$',
        'exchange_rate': 3700,
        'is_default': 0,
        'is_active': 1,
        'updated_at': DateTime.now().toIso8601String(),
      });
      await db.insert('currencies', {
        'code': 'KES',
        'name': 'Kenyan Shilling',
        'symbol': 'KSh',
        'exchange_rate': 28,
        'is_default': 0,
        'is_active': 1,
        'updated_at': DateTime.now().toIso8601String(),
      });
      await db.insert('currencies', {
        'code': 'EUR',
        'name': 'Euro',
        'symbol': '€',
        'exchange_rate': 4000,
        'is_default': 0,
        'is_active': 1,
        'updated_at': DateTime.now().toIso8601String(),
      });
      await db.insert('currencies', {
        'code': 'TZS',
        'name': 'Tanzanian Shilling',
        'symbol': 'TSh',
        'exchange_rate': 1.5,
        'is_default': 0,
        'is_active': 1,
        'updated_at': DateTime.now().toIso8601String(),
      });
      await db.insert('currencies', {
        'code': 'RWF',
        'name': 'Rwandan Franc',
        'symbol': 'FRw',
        'exchange_rate': 3,
        'is_default': 0,
        'is_active': 1,
        'updated_at': DateTime.now().toIso8601String(),
      });
    }

    final taxCount = await db.query('tax_rates');
    if (taxCount.isEmpty) {
      await db.insert('tax_rates', {
        'name': 'No Tax',
        'rate': 0,
        'description': '0% Tax Rate',
        'is_default': 1,
        'is_active': 1,
        'created_at': DateTime.now().toIso8601String(),
      });
      await db.insert('tax_rates', {
        'name': 'VAT',
        'rate': 18,
        'description': '18% Value Added Tax (Standard Uganda rate)',
        'is_default': 0,
        'is_active': 1,
        'created_at': DateTime.now().toIso8601String(),
      });
      await db.insert('tax_rates', {
        'name': 'WHT',
        'rate': 6,
        'description': '6% Withholding Tax',
        'is_default': 0,
        'is_active': 1,
        'created_at': DateTime.now().toIso8601String(),
      });
      await db.insert('tax_rates', {
        'name': 'VAT Zero',
        'rate': 0,
        'description': 'Zero-rated VAT (e.g. exports)',
        'is_default': 0,
        'is_active': 1,
        'created_at': DateTime.now().toIso8601String(),
      });
    }

    final accountCount = await db.query('accounts');
    if (accountCount.isEmpty) {
      final accounts = [
        {'code': '1000', 'name': 'Assets', 'type': 'Asset', 'sub_type': null},
        {'code': '1100', 'name': 'Cash on Hand', 'type': 'Asset', 'sub_type': 'Current Asset'},
        {'code': '1200', 'name': 'Bank Account', 'type': 'Asset', 'sub_type': 'Current Asset'},
        {'code': '1300', 'name': 'Accounts Receivable', 'type': 'Asset', 'sub_type': 'Current Asset'},
        {'code': '1400', 'name': 'Inventory', 'type': 'Asset', 'sub_type': 'Current Asset'},
        {'code': '2000', 'name': 'Liabilities', 'type': 'Liability', 'sub_type': null},
        {'code': '2100', 'name': 'Accounts Payable', 'type': 'Liability', 'sub_type': 'Current Liability'},
        {'code': '2200', 'name': 'Tax Payable', 'type': 'Liability', 'sub_type': 'Current Liability'},
        {'code': '3000', 'name': 'Equity', 'type': 'Equity', 'sub_type': null},
        {'code': '3100', 'name': 'Owner\'s Equity', 'type': 'Equity', 'sub_type': 'Owner Equity'},
        {'code': '3200', 'name': 'Retained Earnings', 'type': 'Equity', 'sub_type': 'Retained Earnings'},
        {'code': '4000', 'name': 'Revenue', 'type': 'Revenue', 'sub_type': null},
        {'code': '4100', 'name': 'Sales Revenue', 'type': 'Revenue', 'sub_type': 'Sales'},
        {'code': '4200', 'name': 'Other Income', 'type': 'Revenue', 'sub_type': 'Other'},
        {'code': '5000', 'name': 'Expenses', 'type': 'Expense', 'sub_type': null},
        {'code': '5100', 'name': 'Cost of Goods Sold', 'type': 'Expense', 'sub_type': 'COGS'},
        {'code': '5200', 'name': 'Rent Expense', 'type': 'Expense', 'sub_type': 'Operating'},
        {'code': '5300', 'name': 'Utilities Expense', 'type': 'Expense', 'sub_type': 'Operating'},
        {'code': '5400', 'name': 'Salaries & Wages', 'type': 'Expense', 'sub_type': 'Operating'},
        {'code': '5500', 'name': 'Transport Expense', 'type': 'Expense', 'sub_type': 'Operating'},
      ];
      for (final acc in accounts) {
        await db.insert('accounts', {
          'code': acc['code'],
          'name': acc['name'],
          'type': acc['type'],
          'sub_type': acc['subType'],
          'balance': 0,
          'is_active': 1,
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        });
      }
    }

    final warehouseCount = await db.query('warehouses');
    if (warehouseCount.isEmpty) {
      await db.insert('warehouses', {
        'name': 'Main Warehouse',
        'code': 'MAIN',
        'address': '',
        'manager': '',
        'is_default': 1,
        'is_active': 1,
        'created_at': DateTime.now().toIso8601String(),
      });
    }
  }

  @override
  Future<int> insert(String table, Map<String, dynamic> data) async {
    final db = await _db;
    return await db.insert(table, data, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  @override
  Future<int> update(String table, Map<String, dynamic> data, {required int id}) async {
    final db = await _db;
    return await db.update(table, data, where: 'id = ?', whereArgs: [id]);
  }

  @override
  Future<int> delete(String table, {required int id}) async {
    final db = await _db;
    return await db.delete(table, where: 'id = ?', whereArgs: [id]);
  }

  @override
  Future<int> softDelete(String table, {required int id}) async {
    final db = await _db;
    return await db.update(table, {'is_deleted': 1}, where: 'id = ?', whereArgs: [id]);
  }

  @override
  Future<List<Map<String, dynamic>>> query(String table, {String? where, List<dynamic>? whereArgs, String? orderBy, int? limit}) async {
    final db = await _db;
    return await db.query(table, where: where, whereArgs: whereArgs, orderBy: orderBy, limit: limit);
  }

  @override
  Future<Map<String, dynamic>?> queryOne(String table, {required int id}) async {
    final results = await query(table, where: 'id = ?', whereArgs: [id]);
    return results.isNotEmpty ? results.first : null;
  }

  @override
  Future<T> transaction<T>(Future<T> Function(dynamic database) action) async {
    final db = await _db;
    return await db.transaction((txn) => action(txn));
  }

  @override
  Future<void> backupDatabase(String backupPath) async {
    final dbPath = await getDatabasePath();
    await File(dbPath).copy(backupPath);
  }

  @override
  Future<String> getDatabasePath() async {
    final Directory documentsDirectory = await getApplicationDocumentsDirectory();
    return join(documentsDirectory.path, _dbName);
  }

  /// Closes the open database and deletes the database files so the app can
  /// be re-initialized from a clean first-run state (e.g. "Reset app").
  Future<void> deleteDatabaseFile() async {
    if (_database != null && _database!.isOpen) {
      await _database!.close();
    }
    _database = null;
    _initialized = false;
    final Directory documentsDirectory = await getApplicationDocumentsDirectory();
    final base = join(documentsDirectory.path, _dbName);
    for (final suffix in ['', '-wal', '-shm']) {
      final file = File('$base$suffix');
      if (await file.exists()) {
        try {
          await file.delete();
        } catch (_) {
          // Best effort; ignore if the file is locked.
        }
      }
    }
  }

  @override
  Future<String> exportDatabaseAsSql() async {
    final db = await _db;
    final Directory documentsDirectory = await getApplicationDocumentsDirectory();
    final String exportPath = join(documentsDirectory.path, 'plexus_export_${DateTime.now().millisecondsSinceEpoch}.sql');

    final buffer = StringBuffer();
    buffer.writeln('-- Plexus Database Export');
    buffer.writeln('-- Generated: ${DateTime.now().toIso8601String()}');
    buffer.writeln('-- App Version: 3.2.0');
    buffer.writeln('');

    final tables = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%' ORDER BY name",
    );

    for (final table in tables) {
      final tableName = table['name'] as String;
      final rows = await db.query(tableName);
      if (rows.isEmpty) continue;

      buffer.writeln('-- Table: $tableName');
      final columns = rows.first.keys.toList();

      for (final row in rows) {
        final values = columns.map((col) {
          final val = row[col];
          if (val == null) return 'NULL';
          if (val is String) return "'${val.replaceAll("'", "''")}'";
          if (val is double) return val.toString();
          if (val is int) return val.toString();
          if (val is DateTime) return "'${val.toIso8601String()}'";
          return "'${val.toString().replaceAll("'", "''")}'";
        }).join(', ');

        buffer.writeln("INSERT INTO $tableName (${columns.join(', ')}) VALUES ($values);");
      }
      buffer.writeln('');
    }

    final file = File(exportPath);
    await file.writeAsString(buffer.toString());
    return exportPath;
  }
}
