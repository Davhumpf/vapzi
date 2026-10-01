import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../data/database_service.dart';
import '../widgets/money.dart';
import 'credit_detail_screen.dart';

class ActiveCreditsScreen extends StatefulWidget {
  const ActiveCreditsScreen({super.key});
  @override
  State<ActiveCreditsScreen> createState() => _ActiveCreditsScreenState();
}

class _ActiveCreditsScreenState extends State<ActiveCreditsScreen> {
  late Future<List<CreditSummary>> items;
  @override
  void initState() {
    super.initState();
    items = DatabaseService.instance.summaries(completed: false);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Clientes activos')),
    body: FutureBuilder<List<CreditSummary>>(
      future: items,
      builder: (context, snapshot) {
        if (!snapshot.hasData)
          return const Center(child: CircularProgressIndicator());
        if (snapshot.data!.isEmpty)
          return const Center(child: Text('Aún no tienes créditos activos'));
        final today = DateTime.now();
        final collectionsToday = snapshot.data!.where((item) {
          final due = item.next?.dueDate;
          return due != null &&
              due.year == today.year &&
              due.month == today.month &&
              due.day == today.day;
        }).toList();
        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            if (collectionsToday.isNotEmpty) ...[
              Text(
                'Cobros de hoy · ${_weekday(today.weekday)}',
                style: Theme.of(context).textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 10),
              for (final item in collectionsToday)
                _TodayCollection(
                  item: item,
                  onCollect: () => _openWhatsApp(item),
                  onPay: () => _openDetail(item),
                ),
              const SizedBox(height: 22),
              Text(
                'Todos los créditos',
                style: Theme.of(context).textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
            ],
            for (final item in snapshot.data!)
              Card(
                child: ListTile(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CreditDetailScreen(summary: item),
                    ),
                  ),
                  title: Text(
                    item.client.name,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  subtitle: Text(
                    '${item.credit.product}\nSaldo: ${money(item.balance)} · ${item.paidCount}/${item.credit.totalInstallments} cuotas',
                  ),
                  isThreeLine: true,
                  trailing: Text(item.status),
                ),
              ),
          ],
        );
      },
    ),
  );

  Future<void> _openWhatsApp(CreditSummary item) async {
    final installment = item.next;
    if (installment == null) return;
    final phone = item.client.phone.replaceAll(RegExp(r'[^0-9]'), '');
    final normalizedPhone = phone.startsWith('57') ? phone : '57$phone';
    final key = item.credit.paymentMethod == 'Nequi'
        ? ' Llave Bre-B: @NEQUIDAV4433.'
        : '';
    final message =
        'Hola ${item.client.name} 👋 Te recordamos que tienes una cuota pendiente por valor de ${money(installment.balance)} correspondiente a tu compra. Su fecha de pago es ${dateLabel(installment.dueDate)}. Puedes realizar el pago mediante ${item.credit.paymentMethod}.$key ¡Gracias!';
    final uri = Uri.parse(
      'https://wa.me/$normalizedPhone?text=${Uri.encodeComponent(message)}',
    );
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication) &&
        mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No fue posible abrir WhatsApp')),
      );
    }
  }

  Future<void> _openDetail(CreditSummary item) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => CreditDetailScreen(summary: item)),
    );
    if (mounted)
      setState(
        () => items = DatabaseService.instance.summaries(completed: false),
      );
  }
}

String _weekday(int day) => const [
  'Lunes',
  'Martes',
  'Miércoles',
  'Jueves',
  'Viernes',
  'Sábado',
  'Domingo',
][day - 1];

class _TodayCollection extends StatelessWidget {
  final CreditSummary item;
  final VoidCallback onCollect, onPay;
  const _TodayCollection({
    required this.item,
    required this.onCollect,
    required this.onPay,
  });
  @override
  Widget build(BuildContext context) {
    final installment = item.next!;
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              item.client.name,
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
            ),
            Text(
              'Cuota ${installment.number} de ${item.credit.totalInstallments} · ${item.credit.product}',
            ),
            const SizedBox(height: 6),
            Text(
              money(installment.balance),
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
            ),
            Text(
              item.credit.paymentMethod,
              style: const TextStyle(color: Colors.black54),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                TextButton.icon(
                  onPressed: onCollect,
                  icon: const Icon(Icons.chat_outlined),
                  label: const Text('COBRAR'),
                ),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: onPay,
                  child: const Text('REGISTRAR PAGO'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
