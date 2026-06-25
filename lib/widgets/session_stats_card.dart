import 'package:flutter/material.dart';

class SessionStatsCard extends StatelessWidget {
  final int sessoesSemana;
  final String totalFormatado;
  final int totalSessoes;

  const SessionStatsCard({
    super.key,
    required this.sessoesSemana,
    required this.totalFormatado,
    required this.totalSessoes,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.deepOrange.shade50,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _StatItem(valor: '$sessoesSemana', label: 'Sessões\nesta semana'),
          Container(height: 40, width: 1, color: Colors.deepOrange.shade200),
          _StatItem(valor: totalFormatado, label: 'Total\nestudado'),
          Container(height: 40, width: 1, color: Colors.deepOrange.shade200),
          _StatItem(valor: '$totalSessoes', label: 'Sessões\nno total'),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String valor;
  final String label;

  const _StatItem({required this.valor, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(valor,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
        const SizedBox(height: 2),
        Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
        ),
      ],
    );
  }
}
