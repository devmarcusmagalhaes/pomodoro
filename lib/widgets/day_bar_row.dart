import 'package:flutter/material.dart';
import '../core/constants.dart';

// Componente que desenha a barrinha de progresso de cada dia na tela de estatísticas
class DayBarRow extends StatelessWidget {
  final String dia;
  final int minutos;
  final double proporcao;

  const DayBarRow({
    super.key,
    required this.dia,
    required this.minutos,
    required this.proporcao,
  });

  @override
  Widget build(BuildContext context) {
    // Variáveis auxiliares criadas para evitar repetir "minutos > 0" no meio do layout
    bool teveFoco = minutos > 0;
    Color corDaBarra = teveFoco ? Colors.deepOrange : Colors.transparent;
    Color corDoTexto = teveFoco ? Colors.black87 : Colors.grey.shade400;
    FontWeight pesoDoTexto = teveFoco ? FontWeight.w600 : FontWeight.normal;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          // Nome do dia (Ex: Seg, Ter)
          SizedBox(
            width: 32,
            child: Text(
              dia,
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
            ),
          ),
          const SizedBox(width: 8),
          
          // Barra de progresso (Expanded faz ela esticar e ocupar o meio da tela)
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: proporcao,
                minHeight: 22,
                backgroundColor: Colors.grey.shade100,
                valueColor: AlwaysStoppedAnimation(corDaBarra),
              ),
            ),
          ),
          const SizedBox(width: 10),
          
          // Tempo formatado ou traço caso seja zero
          SizedBox(
            width: 68,
            child: Text(
              teveFoco ? formatarDuracao(minutos) : '—',
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 12,
                fontWeight: pesoDoTexto,
                color: corDoTexto,
              ),
            ),
          ),
        ],
      ),
    );
  }
}