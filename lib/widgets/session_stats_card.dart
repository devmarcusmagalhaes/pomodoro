import 'package:flutter/material.dart';

// Cartão de resumo de estatísticas (aquele painel no topo da tela de perfil/stats)
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
      // Caixinha com fundo levemente laranja e bordas arredondadas
      decoration: BoxDecoration(
        color: Colors.deepOrange.shade50,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        // Distribui os itens com espaços iguais ao redor deles
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _StatItem(valor: '$sessoesSemana', label: 'Sessões\nesta semana'),
          
          // Divisória vertical (uma linha fina)
          Container(height: 40, width: 1, color: Colors.deepOrange.shade200),
          
          _StatItem(valor: totalFormatado, label: 'Total\nestudado'),
          
          // Divisória vertical
          Container(height: 40, width: 1, color: Colors.deepOrange.shade200),
          
          _StatItem(valor: '$totalSessoes', label: 'Sessões\nno total'),
        ],
      ),
    );
  }
}

// Sub-widget privado (só pode ser usado dentro deste arquivo)
// Serve para montar o par "Número grande em cima, texto pequeno embaixo"
class _StatItem extends StatelessWidget {
  final String valor;
  final String label;

  const _StatItem({required this.valor, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min, // Ocupa apenas o espaço necessário
      children: [
        Text(
          valor,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 2), // Espacinho entre o número e o texto
        Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
        ),
      ],
    );
  }
}