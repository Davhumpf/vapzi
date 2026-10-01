import 'package:flutter/material.dart';

import 'active_credits_screen.dart';
import 'history_screen.dart';
import 'new_credit_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'vapzi',
                style: Theme.of(context).textTheme.headlineLarge
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              const Text(
                'Control de créditos',
                style: TextStyle(color: Colors.black54),
              ),
              const Spacer(),
              _item(
                context,
                Icons.people_alt_outlined,
                'Clientes activos',
                'Créditos y cuotas pendientes',
                const ActiveCreditsScreen(),
              ),
              const Divider(height: 1),
              _item(
                context,
                Icons.history_outlined,
                'Historial',
                'Ventas completadas y capital',
                const HistoryScreen(),
              ),
              const Divider(height: 1),
              _item(
                context,
                Icons.add,
                'Nuevo crédito',
                'Registrar una venta',
                const NewCreditScreen(),
              ),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _item(
    BuildContext context,
    IconData icon,
    String title,
    String detail,
    Widget page,
  ) {
    return InkWell(
      onTap: () =>
          Navigator.push(context, MaterialPageRoute(builder: (_) => page)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 22),
        child: Row(
          children: [
            Icon(icon, size: 22),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(detail, style: const TextStyle(color: Colors.black54)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right),
          ],
        ),
      ),
    );
  }
}
