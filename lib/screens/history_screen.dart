import 'package:flutter/material.dart';

import '../data/database_service.dart';
import '../widgets/money.dart';
import 'credit_detail_screen.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});
  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  late Future<_Data> data;
  final _search = TextEditingController();
  bool _recentFirst = true;
  @override
  void initState() {
    super.initState();
    reload();
  }

  void reload() => data = _load();
  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<_Data> _load() async => _Data(
    await DatabaseService.instance.summaries(completed: true),
    await DatabaseService.instance.completedRevenue(),
    await DatabaseService.instance.availableCash(),
    await DatabaseService.instance.cashMovements(),
  );
  Future<void> take() async {
    final c = TextEditingController();
    final result = await showDialog<bool>(
      context: context,
      builder: (x) => AlertDialog(
        title: const Text('Retirar / reinvertir'),
        content: TextField(
          controller: c,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Monto'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(x),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(x, true),
            child: const Text('Registrar'),
          ),
        ],
      ),
    );
    if (result == true) {
      try {
        await DatabaseService.instance.withdraw(
          double.parse(c.text.replaceAll('.', '').replaceAll(',', '.')),
          'Reinversión',
        );
        setState(reload);
      } catch (e) {
        if (mounted)
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  @override
  Widget build(BuildContext c) => Scaffold(
    appBar: AppBar(title: const Text('Historial')),
    body: FutureBuilder<_Data>(
      future: data,
      builder: (c, s) {
        if (!s.hasData) return const Center(child: CircularProgressIndicator());
        final d = s.data!;
        final needle = _search.text.trim().toLowerCase();
        final credits =
            d.credits
                .where(
                  (item) =>
                      needle.isEmpty ||
                      item.client.name.toLowerCase().contains(needle) ||
                      item.client.phone
                          .replaceAll(RegExp(r'[^0-9]'), '')
                          .contains(needle.replaceAll(RegExp(r'[^0-9]'), '')),
                )
                .toList()
              ..sort(
                (a, b) => _recentFirst
                    ? b.credit.createdAt.compareTo(a.credit.createdAt)
                    : a.credit.createdAt.compareTo(b.credit.createdAt),
              );
        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
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
                    'Capital disponible',
                    style: TextStyle(color: Colors.white70),
                  ),
                  Text(
                    money(d.available),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 30,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    'Ventas completadas: ${money(d.revenue)}',
                    style: const TextStyle(color: Colors.white70),
                  ),
                  OutlinedButton(
                    onPressed: take,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Retirar / reinvertir'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Registro de movimientos',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
            ),
            for (final m in d.moves)
              ListTile(
                leading: const Icon(Icons.south_west, color: Colors.orange),
                title: Text(m.note),
                trailing: Text('-${money(m.amount)}'),
              ),
            const SizedBox(height: 12),
            const Text(
              'Créditos finalizados',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _search,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                labelText: 'Buscar por nombre o número',
                prefixIcon: Icon(Icons.search),
              ),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<bool>(
              initialValue: _recentFirst,
              decoration: const InputDecoration(labelText: 'Ordenar por fecha'),
              items: const [
                DropdownMenuItem(
                  value: true,
                  child: Text('Más recientes primero'),
                ),
                DropdownMenuItem(
                  value: false,
                  child: Text('Más antiguos primero'),
                ),
              ],
              onChanged: (value) => setState(() => _recentFirst = value!),
            ),
            const SizedBox(height: 12),
            if (credits.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Text('No se encontraron créditos finalizados'),
              ),
            for (final item in credits)
              Card(
                child: ListTile(
                  onTap: () => Navigator.push(
                    c,
                    MaterialPageRoute(
                      builder: (_) => CreditDetailScreen(summary: item),
                    ),
                  ),
                  leading: const Icon(Icons.check_circle, color: Colors.green),
                  title: Text(item.client.name),
                  subtitle: Text(
                    '${item.credit.product} · ${dateLabel(item.credit.createdAt)}',
                  ),
                  trailing: Text(money(item.credit.total)),
                ),
              ),
          ],
        );
      },
    ),
  );
}

class _Data {
  final List<CreditSummary> credits;
  final double revenue, available;
  final List<CashMovement> moves;
  _Data(this.credits, this.revenue, this.available, this.moves);
}
