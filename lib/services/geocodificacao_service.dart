// lib/services/geocodificacao_service.dart  ← NOVO na Parte 3

// API Web (HTTP): geocodificação reversa via Nominatim (OpenStreetMap).
// Converte coordenadas (lat, lon) em um nome de local legível.

// Endpoint: https://nominatim.openstreetmap.org/reverse
//   - Gratuito, sem chave de API.
//   - Política de uso exige header User-Agent identificando o app e
//     limita a 1 requisição por segundo (respeitado: chamamos 1x por sessão).

import 'dart:convert';

import 'package:http/http.dart' as http;

import '../core/result.dart';

class GeocodificacaoService {
  static const _baseUrl = 'https://nominatim.openstreetmap.org';

  /// Retorna o nome legível do local correspondente às coordenadas.
  Future<Result<String>> nomeDoLocal(double latitude, double longitude) async {
    final uri = Uri.parse(
      '$_baseUrl/reverse'
      '?format=jsonv2&lat=$latitude&lon=$longitude'
      '&zoom=16&addressdetails=1',
    );

    try {
      final resposta = await http.get(
        uri,
        headers: {
          // Exigido pela política do Nominatim.
          'User-Agent': 'PomodoroSemanal/3.0 (trabalho-academico)',
          'Accept-Language': 'pt-BR',
        },
      ).timeout(const Duration(seconds: 10));

      if (resposta.statusCode != 200) {
        return Falha('Falha na geocodificação (HTTP ${resposta.statusCode}).');
      }

      final json = jsonDecode(resposta.body) as Map<String, dynamic>;
      return Ok(_extrairNome(json));
    } catch (e) {
      return Falha('Erro ao consultar o serviço de mapas.', e);
    }
  }

  /// Monta um nome curto e legível a partir do endereço detalhado do Nominatim.
  /// Ex.: "Biblioteca Central, Centro, Florianópolis".
  String _extrairNome(Map<String, dynamic> json) {
    final endereco = json['address'] as Map<String, dynamic>?;

    if (endereco != null) {
      final partes = <String?>[
        endereco['amenity'] ?? endereco['building'] ?? endereco['road'],
        endereco['suburb'] ?? endereco['neighbourhood'],
        endereco['city'] ?? endereco['town'] ?? endereco['village'],
      ].whereType<String>().toList();

      if (partes.isNotEmpty) return partes.join(', ');
    }

    return json['display_name'] as String? ?? 'Local desconhecido';
  }
}
