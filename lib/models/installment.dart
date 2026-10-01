class Installment {
  final int? id, creditId;
  final int number;
  final double amount;
  final DateTime dueDate;
  final bool paid;
  final double paidAmount;
  const Installment({
    this.id,
    required this.creditId,
    required this.number,
    required this.amount,
    required this.dueDate,
    this.paid = false,
    this.paidAmount = 0,
  });
  double get balance => (amount - paidAmount).clamp(0, double.infinity);
  Map<String, Object?> toMap() => {
    'id': id,
    'credit_id': creditId,
    'number': number,
    'amount': amount,
    'due_date': dueDate.toIso8601String(),
    'paid': paid ? 1 : 0,
    'paid_amount': paidAmount,
  };
  factory Installment.fromMap(Map<String, Object?> m) => Installment(
    id: m['id'] as int?,
    creditId: m['credit_id'] as int,
    number: m['number'] as int,
    amount: (m['amount'] as num).toDouble(),
    dueDate: DateTime.parse(m['due_date'] as String),
    paid: (m['paid'] as int) == 1,
    paidAmount: ((m['paid_amount'] ?? 0) as num).toDouble(),
  );
}
