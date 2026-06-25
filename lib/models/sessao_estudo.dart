// lib/models/sessao_estudo.dart

// MUDANÇAS DA PARTE 3:
//    Campos opcionais de geolocalização (latitude, longitude, local).
//    São opcionais porque a captura de GPS pode falhar ou ser negada, e a
//    sessão deve ser registrada mesmo assim.


class SessaoEstudo {
  final DateTime data;
  final int minutos;

  //Parte 3: geolocalização (podem ser nulos)
  final double? latitude;
  final double? longitude;
  final String? local; // nome legível obtido por geocodificação reversa

  SessaoEstudo({
    required this.data,
    required this.minutos,
    this.latitude,
    this.longitude,
    this.local,
  });

  /// `true` se a sessão possui coordenadas válidas.
  bool get temLocalizacao => latitude != null && longitude != null;

  //Serialização

  Map<String, dynamic> toMap() => {
        'data'   : data.toIso8601String(),
        'minutos': minutos,
        if (latitude != null) 'latitude': latitude,
        if (longitude != null) 'longitude': longitude,
        if (local != null) 'local': local,
      };

  factory SessaoEstudo.fromMap(Map<String, dynamic> map) => SessaoEstudo(
        data     : DateTime.parse(map['data'] as String),
        minutos  : map['minutos'] as int,
        latitude : (map['latitude'] as num?)?.toDouble(),
        longitude: (map['longitude'] as num?)?.toDouble(),
        local    : map['local'] as String?,
      );

  // Lógica de semana atual

  bool get estaSemanAtual {
    final agora = DateTime.now();
    final inicio = agora.subtract(Duration(days: agora.weekday - 1));
    return data.isAfter(DateTime(inicio.year, inicio.month, inicio.day)) &&
        data.isBefore(DateTime(inicio.year, inicio.month, inicio.day + 7));
  }
}
