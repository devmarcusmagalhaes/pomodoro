// lib/services/frase_service.dart  ← NOVO na Parte 3
//
// API Web (HTTP): frases motivacionais via ZenQuotes.
// Endpoint: https://zenquotes.io/api/random  (gratuito, sem chave)
//
// Resiliência: se a API falhar (offline, timeout, rate limit), caímos em uma
// lista local de frases — assim o app nunca quebra a experiência de conclusão.


import 'dart:convert';
import 'dart:math';

import 'package:http/http.dart' as http;

/// Frase motivacional com autor.
class Frase {
  final String texto;
  final String autor;
  const Frase(this.texto, this.autor);
}

class FraseService {
  static const _url = 'https://zenquotes.io/api/random';

  /// Frases de reserva (usadas quando a API não responde).
  static const _reserva = <Frase>[
    Frase('A persistência é o caminho do êxito.', 'Charles Chaplin'),
    Frase('Foco no progresso, não na perfeição.', 'Anônimo'),
    Frase('Comece onde você está. Use o que tem. Faça o que pode.',
        'Arthur Ashe'),
    Frase('A disciplina é a ponte entre metas e realizações.', 'Jim Rohn'),
    Frase('Pequenos progressos diários levam a grandes resultados.',
        'Anônimo'),
  ];

  /// Busca uma frase aleatória na API; em caso de falha retorna uma reserva.
  Future<Frase> fraseAleatoria() async {
    try {
      final resposta = await http
          .get(Uri.parse(_url))
          .timeout(const Duration(seconds: 8));

      if (resposta.statusCode == 200) {
        final lista = jsonDecode(resposta.body) as List;
        if (lista.isNotEmpty) {
          final item = lista.first as Map<String, dynamic>;
          return Frase(item['q'] as String, item['a'] as String);
        }
      }
    } catch (_) {
      // Silenciado de propósito: caímos na lista de reserva abaixo.
    }
    return _reserva[Random().nextInt(_reserva.length)];
  }
}
