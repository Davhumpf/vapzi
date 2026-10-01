import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../models/client.dart';
import '../models/credit.dart';
import '../models/installment.dart';
import '../models/payment.dart';

class CreditSummary {
  final Client client;
  final Credit credit;
  final List<Installment> installments;
  CreditSummary(this.client, this.credit, this.installments);
  double get paid =>
      installments.fold(0.0, (v, x) => v + x.paidAmount) + credit.downPayment;
  double get balance => (credit.total - paid).clamp(0, double.infinity);
  int get paidCount => installments.where((x) => x.paid).length;
  Installment? get next =>
      installments.where((x) => !x.paid).cast<Installment?>().firstOrNull;
  String get status {
    if (credit.completed) return 'Completado';
    final n = next;
    if (n != null &&
        n.dueDate.isBefore(
          DateTime.now().copyWith(
            hour: 0,
            minute: 0,
            second: 0,
            millisecond: 0,
          ),
        ))
      return 'Vencido';
    return n != null && n.dueDate.difference(DateTime.now()).inDays <= 3
        ? 'Pendiente'
        : 'Al día';
  }
}

class CashMovement {
  final int id;
  final double amount;
  final String note;
  final DateTime createdAt;
  CashMovement({
    required this.id,
    required this.amount,
    required this.note,
    required this.createdAt,
  });
  factory CashMovement.fromMap(Map<String, Object?> m) => CashMovement(
    id: m['id'] as int,
    amount: (m['amount'] as num).toDouble(),
    note: m['note'] as String,
    createdAt: DateTime.parse(m['created_at'] as String),
  );
}

class DatabaseService {
  DatabaseService._();
  static final instance = DatabaseService._();
  Database? _db;
  Future<Database> get db async => _db ??= await openDatabase(
    join(await getDatabasesPath(), 'vapzi.db'),
    version: 5,
    onCreate: (d, _) async {
      await d.execute(
        'CREATE TABLE clients(id INTEGER PRIMARY KEY AUTOINCREMENT,name TEXT NOT NULL,phone TEXT NOT NULL)',
      );
      await d.execute(
        'CREATE TABLE credits(id INTEGER PRIMARY KEY AUTOINCREMENT,client_id INTEGER NOT NULL,product TEXT NOT NULL,total REAL NOT NULL,down_payment REAL NOT NULL,total_installments INTEGER NOT NULL,installment_value REAL NOT NULL,frequency TEXT NOT NULL,created_at TEXT NOT NULL,notes TEXT,payment_method TEXT NOT NULL DEFAULT "Nequi",completed INTEGER NOT NULL DEFAULT 0)',
      );
      await d.execute(
        'CREATE TABLE installments(id INTEGER PRIMARY KEY AUTOINCREMENT,credit_id INTEGER NOT NULL,number INTEGER NOT NULL,amount REAL NOT NULL,due_date TEXT NOT NULL,paid INTEGER NOT NULL DEFAULT 0,paid_amount REAL NOT NULL DEFAULT 0)',
      );
      await d.execute(
        'CREATE TABLE payments(id INTEGER PRIMARY KEY AUTOINCREMENT,installment_id INTEGER NOT NULL,amount REAL NOT NULL,paid_at TEXT NOT NULL)',
      );
      await d.execute(
        'CREATE TABLE cash_movements(id INTEGER PRIMARY KEY AUTOINCREMENT,amount REAL NOT NULL,note TEXT NOT NULL,created_at TEXT NOT NULL)',
      );
      await _createIndexes(d);
    },
    onUpgrade: (d, oldVersion, newVersion) async {
      if (oldVersion < 2) {
        await d.execute(
          'ALTER TABLE credits ADD COLUMN payment_method TEXT NOT NULL DEFAULT "Nequi"',
        );
      }
      if (oldVersion < 3)
        await d.execute(
          'ALTER TABLE installments ADD COLUMN paid_amount REAL NOT NULL DEFAULT 0',
        );
      if (oldVersion < 4)
        await d.execute(
          'CREATE TABLE cash_movements(id INTEGER PRIMARY KEY AUTOINCREMENT,amount REAL NOT NULL,note TEXT NOT NULL,created_at TEXT NOT NULL)',
        );
      if (oldVersion < 5) await _createIndexes(d);
    },
  );
  Future<List<CreditSummary>> summaries({required bool completed}) async {
    final d = await db;
    final rows = await d.rawQuery(
      'SELECT c.* , cl.id client_join_id, cl.name client_name, cl.phone client_phone FROM credits c JOIN clients cl ON cl.id=c.client_id WHERE c.completed=? ORDER BY c.created_at DESC',
      [completed ? 1 : 0],
    );
    final list = <CreditSummary>[];
    for (final r in rows) {
      final credit = Credit.fromMap(r);
      final inst = (await d.query(
        'installments',
        where: 'credit_id=?',
        whereArgs: [credit.id],
        orderBy: 'number',
      )).map(Installment.fromMap).toList();
      list.add(
        CreditSummary(
          Client(
            id: r['client_join_id'] as int,
            name: r['client_name'] as String,
            phone: r['client_phone'] as String,
          ),
          credit,
          inst,
        ),
      );
    }
    return list;
  }

  Future<int> createCredit({
    required Client client,
    required Credit credit,
    required DateTime firstDueDate,
    bool completed = false,
  }) async {
    final d = await db;
    return d.transaction((txn) async {
      final clientId = await txn.insert(
        'clients',
        client.toMap()..remove('id'),
      );
      final creditId = await txn.insert(
        'credits',
        Credit(
          clientId: clientId,
          product: credit.product,
          total: credit.total,
          downPayment: credit.downPayment,
          totalInstallments: credit.totalInstallments,
          installmentValue: credit.installmentValue,
          frequency: credit.frequency,
          createdAt: credit.createdAt,
          notes: credit.notes,
          paymentMethod: credit.paymentMethod,
          completed: completed,
        ).toMap()..remove('id'),
      );
      for (var i = 0; i < credit.totalInstallments; i++) {
        final date = _addPeriod(firstDueDate, credit.frequency, i);
        final amount = i == credit.totalInstallments - 1
            ? credit.financed -
                  (credit.installmentValue * (credit.totalInstallments - 1))
            : credit.installmentValue;
        await txn.insert(
          'installments',
          Installment(
            creditId: creditId,
            number: i + 1,
            amount: amount,
            dueDate: date,
          ).toMap()..remove('id'),
        );
      }
      return creditId;
    });
  }

  DateTime _addPeriod(DateTime date, String frequency, int n) =>
      switch (frequency) {
        'Diario' => date.add(Duration(days: n)),
        'Semanal' => date.add(Duration(days: 7 * n)),
        'Quincenal' => date.add(Duration(days: 15 * n)),
        _ => DateTime(date.year, date.month + n, date.day),
      };
  Future<bool> registerPayment(
    CreditSummary summary,
    Installment installment,
    double amount,
  ) async {
    final d = await db;
    return d.transaction((t) async {
      final totalPaid = installment.paidAmount + amount;
      if (amount <= 0 || totalPaid > installment.amount + .001)
        throw ArgumentError('Monto inválido');
      await t.insert(
        'payments',
        Payment(
          installmentId: installment.id!,
          amount: amount,
          paidAt: DateTime.now(),
        ).toMap()..remove('id'),
      );
      final isPaid = totalPaid >= installment.amount - .001;
      await t.update(
        'installments',
        {'paid': isPaid ? 1 : 0, 'paid_amount': totalPaid},
        where: 'id=?',
        whereArgs: [installment.id],
      );
      final count = Sqflite.firstIntValue(
        await t.rawQuery(
          'SELECT COUNT(*) FROM installments WHERE credit_id=? AND paid=0',
          [summary.credit.id],
        ),
      );
      if (isPaid && count == 0)
        await t.update(
          'credits',
          {'completed': 1},
          where: 'id=?',
          whereArgs: [summary.credit.id],
        );
      return isPaid;
    });
  }

  Future<double> completedRevenue() async {
    final d = await db;
    return ((Sqflite.firstIntValue(
              await d.rawQuery(
                'SELECT CAST(COALESCE(SUM(total),0) AS INTEGER) FROM credits WHERE completed=1',
              ),
            ) ??
            0)
        .toDouble());
  }

  Future<List<CashMovement>> cashMovements() async {
    final d = await db;
    return (await d.query(
      'cash_movements',
      orderBy: 'created_at DESC',
    )).map(CashMovement.fromMap).toList();
  }

  Future<void> withdraw(double amount, String note) async {
    if (amount <= 0) throw ArgumentError('Monto inválido');
    final available = await availableCash();
    if (amount > available) throw ArgumentError('No hay saldo suficiente');
    final d = await db;
    await d.insert('cash_movements', {
      'amount': amount,
      'note': note,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  Future<double> availableCash() async {
    final income = await completedRevenue();
    final moves = await cashMovements();
    return income - moves.fold(0.0, (sum, m) => sum + m.amount);
  }

  Future<void> _createIndexes(DatabaseExecutor d) async {
    await d.execute(
      'CREATE INDEX IF NOT EXISTS idx_credits_completed ON credits(completed, created_at)',
    );
    await d.execute(
      'CREATE INDEX IF NOT EXISTS idx_installments_credit_due ON installments(credit_id, due_date)',
    );
    await d.execute(
      'CREATE INDEX IF NOT EXISTS idx_payments_installment ON payments(installment_id)',
    );
  }
}
