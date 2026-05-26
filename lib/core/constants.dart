// lib/core/constants.dart
// Constantes globais do app e helpers de formatação.
// Opções padrão exibidas como chips na tela de timer.
const List<int> opcoesPredefinidas = [15, 25, 45];
//Limites aceitáveis para o tempo personalizado.
const int tempoMinimoMin = 1;
const int tempoMaximoMin = 120;
//Tempo Pomodoro clássico — usado como default antes de qualquer escolha.
const int tempoPadraoMin = 25;

//Formata uma duração em minutos como "1h 25min", "45min" ou "2h".
String formatarDuracao(int minutos) {
  final h = minutos ~/ 60;
  final m = minutos % 60;
  if (h == 0) return '${m}min';
  if (m == 0) return '${h}h';
  return '${h}h ${m}min';
}
