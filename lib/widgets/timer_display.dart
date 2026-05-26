import 'package:flutter/material.dart';
import '../controllers/pomodoro_controller.dart';

// Componente visual do cronômetro (o círculo com o tempo no meio)
class TimerDisplay extends StatelessWidget {
  final String tempo;
  final double progresso;
  final EstadoTimer estado;
  final int minutosEscolhidos;

  const TimerDisplay({
    super.key,
    required this.tempo,
    required this.progresso,
    required this.estado,
    required this.minutosEscolhidos,
  });

  @override
  Widget build(BuildContext context) {
    // 1. Lógica de cor extraída para facilitar a leitura
    Color corDoCirculo = estado == EstadoTimer.rodando
        ? Colors.deepOrange
        : Colors.deepOrange.shade200;

    // 2. Lógica de texto extraída usando if/else tradicional
    String textoDoEstado = '';
    if (estado == EstadoTimer.rodando) {
      textoDoEstado = 'Focando...';
    } else if (estado == EstadoTimer.pausado) {
      textoDoEstado = 'Pausado';
    } else {
      textoDoEstado = '$minutosEscolhidos min';
    }

    return Stack(
      alignment: Alignment.center,
      children: [
        // O anel de progresso que fica girando/diminuindo em volta
        SizedBox(
          width: 220,
          height: 220,
          child: CircularProgressIndicator(
            value: progresso,
            strokeWidth: 10,
            backgroundColor: Colors.grey.shade200,
            valueColor: AlwaysStoppedAnimation(corDoCirculo),
          ),
        ),
        
        // Os textos que ficam exatamente no centro do anel
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              tempo, // Ex: "25:00"
              style: const TextStyle(fontSize: 56, fontWeight: FontWeight.w200),
            ),
            Text(
              textoDoEstado, // Ex: "Focando..." ou "Pausado"
              style: TextStyle(color: Colors.grey.shade500),
            ),
          ],
        ),
      ],
    );
  }
}