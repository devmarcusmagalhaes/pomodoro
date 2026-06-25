// test/validadores_test.dart

// Testes de unidade das validações puras (sem UI, sem Firebase).

import 'package:flutter_test/flutter_test.dart';
import 'package:mini_pomodoro/core/validadores.dart';

void main() {
  group('Validadores.email', () {
    test('aceita e-mails válidos', () {
      expect(Validadores.email('voce@email.com'), isNull);
      expect(Validadores.email('a.b-c@sub.dominio.org'), isNull);
    });

    test('rejeita e-mails inválidos', () {
      expect(Validadores.email(''), isNotNull);
      expect(Validadores.email('sem-arroba'), isNotNull);
      expect(Validadores.email('falta@dominio'), isNotNull);
    });
  });

  group('Validadores.senha', () {
    test('aceita senha forte', () {
      expect(Validadores.senha('Abc123'), isNull);
    });

    test('rejeita senha curta, sem número ou sem maiúscula', () {
      expect(Validadores.senha('Ab1'), isNotNull);     // curta
      expect(Validadores.senha('abcdef'), isNotNull);  // sem número/maiúscula
      expect(Validadores.senha('abc123'), isNotNull);  // sem maiúscula
    });
  });

  group('Validadores.confirmar', () {
    test('aceita quando coincide', () {
      expect(Validadores.confirmar('Abc123', 'Abc123'), isNull);
    });

    test('rejeita quando difere', () {
      expect(Validadores.confirmar('Abc123', 'Outra1'), isNotNull);
    });
  });
}
