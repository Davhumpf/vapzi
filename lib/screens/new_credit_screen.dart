import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/database_service.dart';
import '../data/notification_service.dart';
import '../models/client.dart';
import '../models/credit.dart';
import '../widgets/money.dart';

class NewCreditScreen extends StatefulWidget {
  const NewCreditScreen({super.key});
  @override
  State<NewCreditScreen> createState() => _NewCreditScreenState();
}

class _NewCreditScreenState extends State<NewCreditScreen> {
  final form = GlobalKey<FormState>();
  final name = TextEditingController(),
      phone = TextEditingController(),
      product = TextEditingController(),
      price = TextEditingController(),
      initial = TextEditingController(text: '0'),
      count = TextEditingController(text: '1'),
      value = TextEditingController(),
      notes = TextEditingController();
  String frequency = 'Semanal';
  String paymentMethod = 'Nequi';
  String paymentMode = 'Pago a cuotas';
  DateTime first = DateTime.now().add(const Duration(days: 7));
  double n(TextEditingController c) =>
      double.tryParse(c.text.replaceAll('.', '').replaceAll(',', '.')) ?? 0;
  void recalc() {
    final p = n(price), down = n(initial), q = int.tryParse(count.text) ?? 1;
    if (p >= down && q > 0) value.text = ((p - down) / q).round().toString();
    setState(() {});
  }

  Future<void> save() async {
    if (!form.currentState!.validate()) return;
    final total = n(price),
        down = n(initial),
        q = int.parse(count.text),
        each = n(value);
    if (paymentMode == 'Pago a cuotas' &&
        ((frequency == 'Diario' && q > 5) ||
            (frequency == 'Semanal' && q > 3))) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Diario permite máximo 5 cuotas y semanal máximo 3'),
        ),
      );
      return;
    }
    if (down > total) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('La cuota inicial no puede superar el precio'),
        ),
      );
      return;
    }
    final creditId = await DatabaseService.instance.createCredit(
      client: Client(name: name.text.trim(), phone: phone.text.trim()),
      credit: Credit(
        clientId: 0,
        product: product.text.trim(),
        total: total,
        downPayment: paymentMode == 'Pago directo' ? total : down,
        totalInstallments: paymentMode == 'Pago directo' ? 0 : q,
        installmentValue: paymentMode == 'Pago directo' ? 0 : each,
        frequency: frequency,
        createdAt: DateTime.now(),
        notes: notes.text.trim(),
        paymentMethod: paymentMethod,
      ),
      firstDueDate: first,
      completed: paymentMode == 'Pago directo',
    );
    final summary = (await DatabaseService.instance.summaries(completed: false))
        .where((x) => x.credit.id == creditId)
        .firstOrNull;
    if (summary != null)
      for (final installment in summary.installments) {
        await NotificationService.instance.schedule(
          10000 + installment.id!,
          installment.dueDate,
          '${summary.client.name} tiene una cuota de ${money(installment.amount)} pendiente para hoy.',
        );
      }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Crédito creado correctamente')),
      );
      Navigator.pop(context);
    }
  }

  @override
  void dispose() {
    for (final c in [name, phone, product, price, initial, count, value, notes])
      c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext c) {
    final due = price.text.isNotEmpty ? n(price) - n(initial) : 0;
    return Scaffold(
      appBar: AppBar(title: const Text('Nuevo crédito')),
      body: Form(
        key: form,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Text(
              'Datos de la venta',
              style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 14),
            field(name, 'Nombre del cliente', Icons.person_outline),
            const SizedBox(height: 12),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(
                  value: 'Pago directo',
                  label: Text('Pago directo'),
                ),
                ButtonSegment(value: 'Pago a cuotas', label: Text('A cuotas')),
              ],
              selected: {paymentMode},
              onSelectionChanged: (x) => setState(() => paymentMode = x.first),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: paymentMethod,
              decoration: const InputDecoration(labelText: 'Método de pago'),
              items: const [
                DropdownMenuItem(value: 'Nequi', child: Text('Nequi')),
                DropdownMenuItem(value: 'Efectivo', child: Text('Efectivo')),
              ],
              onChanged: (method) => setState(() => paymentMethod = method!),
            ),
            if (paymentMode == 'Pago a cuotas') const SizedBox(height: 12),
            if (paymentMode == 'Pago a cuotas')
              field(
                phone,
                'Número de celular',
                Icons.phone_outlined,
                type: TextInputType.phone,
              ),
            const SizedBox(height: 12),
            field(product, 'Producto', Icons.shopping_bag_outlined),
            const SizedBox(height: 24),
            const Text(
              'Plan de pago',
              style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 14),
            field(
              price,
              'Precio del producto',
              Icons.attach_money,
              onChanged: (_) => recalc(),
            ),
            if (paymentMode == 'Pago a cuotas') const SizedBox(height: 12),
            if (paymentMode == 'Pago a cuotas')
              field(
                initial,
                'Cuota inicial',
                Icons.payments_outlined,
                onChanged: (_) => recalc(),
              ),
            if (paymentMode == 'Pago a cuotas') const SizedBox(height: 12),
            if (paymentMode == 'Pago a cuotas')
              field(
                count,
                'Número de cuotas',
                Icons.format_list_numbered,
                type: TextInputType.number,
                onChanged: (_) => recalc(),
              ),
            const SizedBox(height: 12),
            field(
              value,
              'Valor de cada cuota',
              Icons.calculate_outlined,
              onChanged: (_) => setState(() {}),
            ),
            if (paymentMode == 'Pago a cuotas' && price.text.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Text(
                  'Saldo a financiar: ${money(due.clamp(0, double.infinity))}',
                  style: TextStyle(
                    color: Theme.of(c).colorScheme.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            const SizedBox(height: 12),
            if (paymentMode == 'Pago a cuotas')
              DropdownButtonFormField(
                value: frequency,
                items: ['Semanal', 'Diario']
                    .map((x) => DropdownMenuItem(value: x, child: Text(x)))
                    .toList(),
                onChanged: (x) => setState(() => frequency = x!),
                decoration: const InputDecoration(
                  labelText: 'Frecuencia de pago',
                ),
              ),
            if (paymentMode == 'Pago a cuotas') const SizedBox(height: 12),
            if (paymentMode == 'Pago a cuotas')
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                tileColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                leading: const Icon(Icons.event_outlined),
                title: const Text('Fecha del primer pago'),
                subtitle: Text(dateLabel(first)),
                trailing: const Icon(Icons.chevron_right),
                onTap: () async {
                  final x = await showDatePicker(
                    context: c,
                    initialDate: first,
                    firstDate: DateTime.now().subtract(const Duration(days: 1)),
                    lastDate: DateTime.now().add(const Duration(days: 3650)),
                  );
                  if (x != null) setState(() => first = x);
                },
              ),
            if (paymentMode == 'Pago directo' && paymentMethod == 'Nequi') ...[
              const SizedBox(height: 16),
              Center(
                child: InkWell(
                  onTap: () => showDialog(
                    context: c,
                    builder: (_) => Dialog(
                      child: InteractiveViewer(
                        child: Image.asset('qr.jpeg', fit: BoxFit.contain),
                      ),
                    ),
                  ),
                  borderRadius: BorderRadius.circular(16),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.asset(
                      'qr.jpeg',
                      width: 210,
                      height: 210,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
              const Center(
                child: Text(
                  'Toca el QR para ampliarlo',
                  style: TextStyle(color: Colors.black54, fontSize: 12),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Llave Bre-B: @NEQUIDAV4433'),
                  IconButton(
                    onPressed: () => Clipboard.setData(
                      const ClipboardData(text: '@NEQUIDAV4433'),
                    ),
                    icon: const Icon(Icons.copy_rounded),
                  ),
                ],
              ),
              Text(
                'Valor a pagar: ${money(n(price))}',
                textAlign: TextAlign.center,
              ),
            ],
            const SizedBox(height: 12),
            TextFormField(
              controller: notes,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Notas (opcional)',
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 28),
            FilledButton(
              onPressed: save,
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(54),
              ),
              child: Text(
                paymentMode == 'Pago directo'
                    ? 'Confirmar pago'
                    : 'Crear crédito',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget field(
    TextEditingController controller,
    String label,
    IconData icon, {
    TextInputType type = TextInputType.text,
    ValueChanged<String>? onChanged,
  }) => TextFormField(
    controller: controller,
    keyboardType: type,
    onChanged: onChanged,
    validator: (x) => controller == notes || label.contains('Cuota inicial')
        ? null
        : (x == null || x.trim().isEmpty ? 'Este campo es obligatorio' : null),
    decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon)),
  );
}
