import 'package:flutter/material.dart';
import '../core/constants.dart';

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
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          SizedBox(
            width: 32,
            child: Text(
              dia,
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: proporcao,
                minHeight: 22,
                backgroundColor: Colors.grey.shade100,
                valueColor: AlwaysStoppedAnimation(
                  minutos > 0 ? Colors.deepOrange : Colors.transparent,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 68,
            child: Text(
              minutos > 0 ? formatarDuracao(minutos) : '—',
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 12,
                fontWeight:
                    minutos > 0 ? FontWeight.w600 : FontWeight.normal,
                color:
                    minutos > 0 ? Colors.black87 : Colors.grey.shade400,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
