// lib/models/sessao_estudo.dart
//MUDANÇAS DA PARTE 2:
//Métodos `toMap` / `fromMap` para serialização no Hive.
class SessaoEstudo {
  final DateTime data;
  final int minutos;

  SessaoEstudo({required this.data, required this.minutos});

  //Serializa para Map (data em ISO-8601 para compatibilidade com JSON/Hive).
  Map<String, dynamic> toMap() => {
        'data'   : data.toIso8601String(),
        'minutos': minutos,
      };

  factory SessaoEstudo.fromMap(Map<String, dynamic> map) => SessaoEstudo(
        data   : DateTime.parse(map['data'] as String),
        minutos: map['minutos'] as int,
      );

  //Indica se esta sessão pertence à semana corrente (segunda → domingo).
  bool get estaSemanAtual {
    final agora = DateTime.now();
    final inicio = agora.subtract(Duration(days: agora.weekday - 1));
    return data.isAfter(DateTime(inicio.year, inicio.month, inicio.day)) &&
        data.isBefore(DateTime(inicio.year, inicio.month, inicio.day + 7));
  }
}
