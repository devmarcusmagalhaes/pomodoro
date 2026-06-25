// test/widget_test.dart

// Testes de widget da TelaLogin (formulário baseado em e-mail — Parte 3).

// Montam a TelaLogin diretamente com os providers necessários. Como os
// serviços Firebase são acessados de forma lazy (getters), a construção do
// AuthController não exige o Firebase inicializado — os testes abaixo exercem
// apenas validação de formulário e UI, sem chamadas de rede.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:mini_pomodoro/controllers/auth_controller.dart';
import 'package:mini_pomodoro/controllers/pomodoro_controller.dart';
import 'package:mini_pomodoro/views/tela_login.dart';

Widget _harness() => MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthController()),
        ChangeNotifierProvider(create: (_) => PomodoroController()),
      ],
      child: const MaterialApp(home: TelaLogin()),
    );

void main() {
  testWidgets('Tela de login aparece ao abrir o app', (tester) async {
    await tester.pumpWidget(_harness());

    expect(find.text('Bem-vindo(a) de volta!'), findsOneWidget);
    expect(find.text('Entrar'), findsOneWidget);
  });

  testWidgets('Botão cadastre-se abre tela de cadastro', (tester) async {
    await tester.pumpWidget(_harness());

    await tester.tap(find.text('Cadastre-se'));
    await tester.pump();

    expect(find.text('Criar conta'), findsWidgets);
    expect(find.text('Nome completo'), findsOneWidget);
  });

  testWidgets('Login com campos vazios mostra erros de validação',
      (tester) async {
    await tester.pumpWidget(_harness());

    await tester.tap(find.text('Entrar'));
    await tester.pump();

    expect(find.text('E-mail é obrigatório.'), findsOneWidget);
    expect(find.text('Senha é obrigatória.'), findsOneWidget);
  });

  testWidgets('E-mail inválido é rejeitado na validação', (tester) async {
    await tester.pumpWidget(_harness());

    await tester.enterText(find.byType(TextFormField).at(0), 'email-invalido');
    await tester.tap(find.text('Entrar'));
    await tester.pump();

    expect(find.text('E-mail inválido.'), findsOneWidget);
  });

  testWidgets('Toque no ícone alterna a visibilidade da senha',
      (tester) async {
    await tester.pumpWidget(_harness());

    expect(find.byIcon(Icons.visibility), findsOneWidget);
    await tester.tap(find.byIcon(Icons.visibility));
    await tester.pump();
    expect(find.byIcon(Icons.visibility_off), findsOneWidget);
  });

  testWidgets('Validação de senha rejeita senha sem maiúscula',
      (tester) async {
    await tester.pumpWidget(_harness());

    await tester.tap(find.text('Cadastre-se'));
    await tester.pump();

    // Ordem dos campos no cadastro: nome, e-mail, senha, confirmar.
    await tester.enterText(find.byType(TextFormField).at(0), 'Joao da Silva');
    await tester.enterText(find.byType(TextFormField).at(1), 'joao@email.com');
    await tester.enterText(find.byType(TextFormField).at(2), 'senha1');
    await tester.enterText(find.byType(TextFormField).at(3), 'senha1');

    await tester.tap(find.text('Criar conta').last);
    await tester.pump();

    expect(find.text('Inclua ao menos 1 maiúscula.'), findsOneWidget);
  });
}
