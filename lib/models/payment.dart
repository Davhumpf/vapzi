class Payment {
  final int? id, installmentId;
  final double amount;
  final DateTime paidAt;
  const Payment({
    this.id,
    required this.installmentId,
    required this.amount,
    required this.paidAt,
  });
  Map<String, Object?> toMap() => {
    'id': id,
    'installment_id': installmentId,
    'amount': amount,
    'paid_at': paidAt.toIso8601String(),
  };
  factory Payment.fromMap(Map<String, Object?> m) => Payment(
    id: m['id'] as int?,
    installmentId: m['installment_id'] as int,
    amount: (m['amount'] as num).toDouble(),
    paidAt: DateTime.parse(m['paid_at'] as String),
  );
}
