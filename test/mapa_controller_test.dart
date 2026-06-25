// test/mapa_controller_test.dart

// Testes de unidade da lógica de agregação de locais de estudo.
// Não dependem de Flutter/UI nem de serviços externos — lógica pura.

import 'package:flutter_test/flutter_test.dart';
import 'package:mini_pomodoro/controllers/mapa_controller.dart';
import 'package:mini_pomodoro/models/sessao_estudo.dart';

void main() {
  late MapaController controller;

  setUp(() => controller = MapaController());

  test('Sessões sem localização são ignoradas', () {
    controller.carregar([
      SessaoEstudo(data: DateTime.now(), minutos: 25),
      SessaoEstudo(data: DateTime.now(), minutos: 15),
    ]);

    expect(controller.locais, isEmpty);
    expect(controller.temLocais, isFalse);
  });

  test('Sessões no mesmo local são somadas', () {
    controller.carregar([
      SessaoEstudo(
        data: DateTime.now(),
        minutos: 25,
        latitude: -27.5954,
        longitude: -48.5480,
        local: 'Biblioteca Central',
      ),
      SessaoEstudo(
        data: DateTime.now(),
        minutos: 45,
        latitude: -27.5954,
        longitude: -48.5480,
        local: 'Biblioteca Central',
      ),
    ]);

    expect(controller.locais.length, 1);
    expect(controller.locais.first.nome, 'Biblioteca Central');
    expect(controller.locais.first.totalMinutos, 70);
    expect(controller.locais.first.totalSessoes, 2);
  });

  test('Locais diferentes geram pontos distintos, ordenados por tempo', () {
    controller.carregar([
      SessaoEstudo(
        data: DateTime.now(),
        minutos: 10,
        latitude: -27.59,
        longitude: -48.54,
        local: 'Casa',
      ),
      SessaoEstudo(
        data: DateTime.now(),
        minutos: 50,
        latitude: -23.55,
        longitude: -46.63,
        local: 'Faculdade',
      ),
    ]);

    expect(controller.locais.length, 2);
    // Ordenação decrescente por minutos: Faculdade (50) antes de Casa (10).
    expect(controller.locais.first.nome, 'Faculdade');
    expect(controller.locais.last.nome, 'Casa');
  });

  test('Sessões sem nome agrupam por coordenada aproximada', () {
    controller.carregar([
      SessaoEstudo(
        data: DateTime.now(),
        minutos: 20,
        latitude: -27.59541,
        longitude: -48.54801,
      ),
      SessaoEstudo(
        data: DateTime.now(),
        minutos: 30,
        latitude: -27.59548, // mesma posição (3 casas decimais)
        longitude: -48.54805,
      ),
    ]);

    expect(controller.locais.length, 1);
    expect(controller.locais.first.totalMinutos, 50);
  });
}
