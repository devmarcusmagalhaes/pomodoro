import 'package:flutter/material.dart';
import '../controllers/pomodoro_controller.dart';

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
    return Stack(
      alignment: Alignment.center,
      children: [
        SizedBox(
          width: 220,
          height: 220,
          child: CircularProgressIndicator(
            value: progresso,
            strokeWidth: 10,
            backgroundColor: Colors.grey.shade200,
            valueColor: AlwaysStoppedAnimation(
              estado == EstadoTimer.rodando
                  ? Colors.deepOrange
                  : Colors.deepOrange.shade200,
            ),
          ),
        ),
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              tempo,
              style: const TextStyle(fontSize: 56, fontWeight: FontWeight.w200),
            ),
            Text(
              switch (estado) {
                EstadoTimer.rodando => 'Focando...',
                EstadoTimer.pausado => 'Pausado',
                EstadoTimer.aguardando => '$minutosEscolhidos min',
              },
              style: TextStyle(color: Colors.grey.shade500),
            ),
          ],
        ),
      ],
    );
  }
}
