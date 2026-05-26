// Inicialização principal do app - Parte 2
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'controllers/auth_controller.dart';
import 'controllers/pomodoro_controller.dart';
import 'core/theme.dart';
import 'services/db_service.dart';
import 'views/tela_splash.dart';

Future<void> main() async {
  //Garante que o Flutter esteja pronto para chamadas assíncronas antes do runApp
  WidgetsFlutterBinding.ensureInitialized();

  //Inicializa o banco de dados local (Hive) antes de carregar as telas
  await DbService.init();

  runApp(const AppPomodoro());
}

class AppPomodoro extends StatelessWidget {
  const AppPomodoro({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => AuthController()),
        ChangeNotifierProvider(create: (context) => PomodoroController()),
      ],
      child: MaterialApp(
        title: 'Pomodoro Semanal',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        home: const TelaSplash(), // Começa pela tela de splash para decidir a rota
      ),
    );
  }
}