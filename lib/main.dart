// lib/main.dart

// MUDANÇAS DA PARTE 3:
//  Inicializa o Firebase (Auth + Firestore) antes do runApp.
// Habilita a persistência offline do Firestore (offline-first).

// MUDANÇAS DA PARTE 2 (mantidas):
// 'DbService.init()' abre o Hive (cache local das sessões).
// 'home' é a 'TelaSplash', que decide a rota inicial.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'controllers/auth_controller.dart';
import 'controllers/mapa_controller.dart';
import 'controllers/pomodoro_controller.dart';
import 'core/theme.dart';
import 'firebase_options.dart';
import 'services/db_service.dart';
import 'views/tela_splash.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Parte 3: inicializa o Firebase com as opções geradas pelo flutterfire.
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Parte 3: persistência offline do Firestore — leituras/escritas funcionam
  // sem internet e sincronizam automaticamente ao reconectar.
  FirebaseFirestore.instance.settings =
      const Settings(persistenceEnabled: true);

  // Inicializa o cache local (Hive). Falhas são capturadas internamente e a
  // TelaSplash exibirá uma mensagem de erro amigável se necessário.
  await DbService.init();

  runApp(const AppPomodoro());
}

class AppPomodoro extends StatelessWidget {
  const AppPomodoro({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthController()),
        ChangeNotifierProvider(create: (_) => PomodoroController()),
        ChangeNotifierProvider(create: (_) => MapaController()),
      ],
      child: MaterialApp(
        title: 'Pomodoro Semanal',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        home: const TelaSplash(),
      ),
    );
  }
}
