// lib/services/localizacao_service.dart  ← NOVO na Parte 3

// Recurso nativo: acesso ao GPS do dispositivo via pacote 'geolocator'.

// Responsabilidades:
//   - Verificar se o serviço de localização está ativo.
//   - Solicitar permissão ao usuário (runtime permission).
//   - Obter a coordenada atual.

// Toda falha é convertida em 'Falha' (Result) — nada de exceção vazando.


import 'package:geolocator/geolocator.dart';

import '../core/result.dart';

/// Par de coordenadas geográficas simples (desacopla a UI do pacote geolocator).
class Coordenada {
  final double latitude;
  final double longitude;
  const Coordenada(this.latitude, this.longitude);
}

class LocalizacaoService {
  /// Obtém a localização atual do dispositivo.

  /// Fluxo: serviço ativo? → permissão concedida? → lê posição.
  Future<Result<Coordenada>> obterLocalizacaoAtual() async {
    try {
      final servicoAtivo = await Geolocator.isLocationServiceEnabled();
      if (!servicoAtivo) {
        return const Falha('Serviço de localização desativado no aparelho.');
      }

      var permissao = await Geolocator.checkPermission();
      if (permissao == LocationPermission.denied) {
        permissao = await Geolocator.requestPermission();
      }
      if (permissao == LocationPermission.denied) {
        return const Falha('Permissão de localização negada.');
      }
      if (permissao == LocationPermission.deniedForever) {
        return const Falha(
          'Permissão de localização negada permanentemente. '
          'Habilite nas configurações do aparelho.',
        );
      }

      final posicao = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      return Ok(Coordenada(posicao.latitude, posicao.longitude));
    } catch (e) {
      return Falha('Erro ao obter localização.', e);
    }
  }
}
