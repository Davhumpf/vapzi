class Credit {
  final int? id;
  final int clientId, totalInstallments;
  final String product, frequency, notes, paymentMethod;
  final double total, downPayment, installmentValue;
  final DateTime createdAt;
  final bool completed;
  const Credit({
    this.id,
    required this.clientId,
    required this.product,
    required this.total,
    required this.downPayment,
    required this.totalInstallments,
    required this.installmentValue,
    required this.frequency,
    required this.createdAt,
    this.notes = '',
    this.completed = false,
    this.paymentMethod = 'Nequi',
  });
  double get financed => total - downPayment;
  Map<String, Object?> toMap() => {
    'id': id,
    'client_id': clientId,
    'product': product,
    'total': total,
    'down_payment': downPayment,
    'total_installments': totalInstallments,
    'installment_value': installmentValue,
    'frequency': frequency,
    'created_at': createdAt.toIso8601String(),
    'notes': notes,
    'completed': completed ? 1 : 0,
    'payment_method': paymentMethod,
  };
  factory Credit.fromMap(Map<String, Object?> m) => Credit(
    id: m['id'] as int?,
    clientId: m['client_id'] as int,
    product: m['product'] as String,
    total: (m['total'] as num).toDouble(),
    downPayment: (m['down_payment'] as num).toDouble(),
    totalInstallments: m['total_installments'] as int,
    installmentValue: (m['installment_value'] as num).toDouble(),
    frequency: m['frequency'] as String,
    createdAt: DateTime.parse(m['created_at'] as String),
    notes: (m['notes'] ?? '') as String,
    completed: (m['completed'] as int) == 1,
    paymentMethod: (m['payment_method'] ?? 'Nequi') as String,
  );
}
