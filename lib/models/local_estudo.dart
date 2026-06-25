// lib/models/local_estudo.dart  ← NOVO na Parte 3

// Representa um local de estudo agregado: agrupa todas as sessões que
// ocorreram aproximadamente nas mesmas coordenadas, somando o tempo total.
// Usado pela Tela Mapa de Estudos.

class LocalEstudo {
  final String nome;
  final double latitude;
  final double longitude;
  final int totalMinutos;
  final int totalSessoes;

  const LocalEstudo({
    required this.nome,
    required this.latitude,
    required this.longitude,
    required this.totalMinutos,
    required this.totalSessoes,
  });
}
