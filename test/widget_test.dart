// Testes da tela de login. Pulando a Splash para evitar erro de inicialização do Hive.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:mini_pomodoro/controllers/auth_controller.dart';
import 'package:mini_pomodoro/controllers/pomodoro_controller.dart';
import 'package:mini_pomodoro/views/tela_login.dart';

// Cria um app fake para conseguirmos testar a tela com os Providers injetados
Widget _montarTelaBase() {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (context) => AuthController()),
      ChangeNotifierProvider(create: (context) => PomodoroController()),
    ],
    child: const MaterialApp(home: TelaLogin()),
  );
}

void main() {
  testWidgets('Tela de login aparece ao abrir o app', (tester) async {
    await tester.pumpWidget(_montarTelaBase());

    expect(find.text('Bem-vindo(a) de volta!'), findsOneWidget);
    expect(find.text('Entrar'), findsOneWidget);
  });

  testWidgets('Botão cadastre-se abre tela de cadastro', (tester) async {
    await tester.pumpWidget(_montarTelaBase());

    await tester.tap(find.text('Cadastre-se'));
    await tester.pump();

    expect(find.text('Criar conta'), findsWidgets);
    expect(find.text('Nome completo'), findsOneWidget);
  });

  testWidgets('Login com campos vazios mostra erros de validação', (tester) async {
    await tester.pumpWidget(_montarTelaBase());

    await tester.tap(find.text('Entrar'));
    await tester.pump();

    expect(find.text('Login é obrigatório.'), findsOneWidget);
    expect(find.text('Senha é obrigatória.'), findsOneWidget);
  });

  testWidgets('Toque no ícone alterna a visibilidade da senha', (tester) async {
    await tester.pumpWidget(_montarTelaBase());

    expect(find.byIcon(Icons.visibility), findsOneWidget);
    await tester.tap(find.byIcon(Icons.visibility));
    await tester.pump();
    
    expect(find.byIcon(Icons.visibility_off), findsOneWidget);
  });

  testWidgets('Validação de senha rejeita senha sem maiúscula', (tester) async {
    await tester.pumpWidget(_montarTelaBase());

    await tester.tap(find.text('Cadastre-se'));
    await tester.pump();

    // Preenchendo os campos pelos índices para testar o formulário
    await tester.enterText(find.byType(TextFormField).at(0), 'Joao da Silva');
    await tester.enterText(find.byType(TextFormField).at(1), 'joao_silva');
    await tester.enterText(find.byType(TextFormField).at(2), 'senha1');
    await tester.enterText(find.byType(TextFormField).at(3), 'senha1');

    await tester.tap(find.text('Criar conta').last);
    await tester.pump();

    expect(find.text('Inclua ao menos 1 maiúscula.'), findsOneWidget);
  });
}