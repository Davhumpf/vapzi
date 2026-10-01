import 'package:flutter/material.dart';

import '../data/database_service.dart';
import '../data/notification_service.dart';
import '../models/installment.dart';
import '../widgets/money.dart';

class CreditDetailScreen extends StatefulWidget {
  final CreditSummary summary;
  const CreditDetailScreen({super.key, required this.summary});
  @override
  State<CreditDetailScreen> createState() => _CreditDetailScreenState();
}

class _CreditDetailScreenState extends State<CreditDetailScreen> {
  late CreditSummary s;
  @override
  void initState() {
    super.initState();
    s = widget.summary;
  }

  Future<void> pay(Installment i) async {
    final controller = TextEditingController(
      text: i.balance.toStringAsFixed(0),
    );
    final amount = await showDialog<double>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Registrar pago'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Valor pendiente: ${money(i.balance)}'),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Valor recibido'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(
              context,
              double.tryParse(
                controller.text.replaceAll('.', '').replaceAll(',', '.'),
              ),
            ),
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
    if (amount == null) return;
    final completed = await DatabaseService.instance.registerPayment(
      s,
      i,
      amount,
    );
    if (completed) await NotificationService.instance.cancel(10000 + i.id!);
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Pago registrado')));
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext c) {
    final cr = s.credit;
    return Scaffold(
      appBar: AppBar(title: Text(s.client.name)),
      bottomNavigationBar: s.next == null
          ? null
          : Padding(
              padding: const EdgeInsets.all(20),
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(54),
                ),
                onPressed: () => pay(s.next!),
                icon: const Icon(Icons.payments_rounded),
                label: Text('Registrar pago de ${money(s.next!.amount)}'),
              ),
            ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            cr.product,
            style: Theme.of(c).textTheme.headlineSmall
                ?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Text(s.client.phone, style: const TextStyle(color: Colors.black54)),
          const SizedBox(height: 22),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF5B3DF5),
              borderRadius: BorderRadius.circular(22),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Saldo pendiente',
                  style: TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 4),
                Text(
                  money(s.balance),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 30,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  '${s.paidCount} de ${cr.totalInstallments} cuotas pagadas',
                  style: const TextStyle(color: Colors.white),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Plan de pagos',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 10),
          ...s.installments.map(
            (i) => Card(
              elevation: 0,
              color: Colors.white,
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: i.paid
                      ? Colors.green.shade100
                      : const Color(0xFFE9E5FF),
                  child: Icon(
                    i.paid ? Icons.check_rounded : Icons.calendar_today_rounded,
                    color: i.paid ? Colors.green : const Color(0xFF5B3DF5),
                  ),
                ),
                title: Text(
                  'Cuota ${i.number} · ${money(i.amount)}',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: Text(i.paid ? 'Pagada' : dateLabel(i.dueDate)),
                trailing: i.paid
                    ? const Text(
                        'Pagada',
                        style: TextStyle(color: Colors.green),
                      )
                    : null,
              ),
            ),
          ),
          if (cr.notes.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text('Notas: ${cr.notes}'),
          ],
        ],
      ),
    );
  }
}
