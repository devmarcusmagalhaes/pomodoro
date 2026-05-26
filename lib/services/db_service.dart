import 'package:hive_flutter/hive_flutter.dart';

class DbService {
  static const _boxUsuarios = 'usuarios';
  static const _boxSessoes  = 'sessoes';

  static bool _inicializado = false;
  static Object? _erroInicializacao;

  static bool get inicializado => _inicializado;
  static Object? get erroInicializacao => _erroInicializacao;

  static Future<void> init() async {
    try {
      await Hive.initFlutter();
      await Hive.openBox(_boxUsuarios);
      await Hive.openBox(_boxSessoes);
      _inicializado = true;
      
      // CHAMA A FUNÇÃO DE RAIO-X ASSIM QUE O BANCO LIGAR
      imprimirRaioXDoBanco();

    } catch (e) {
      _erroInicializacao = e;
      _inicializado = false;
    }
  }

  static Box get usuarios => Hive.box(_boxUsuarios);
  static Box get sessoes => Hive.box(_boxSessoes);

  static void imprimirRaioXDoBanco() {
    print('\n');
    print('📦 BANCO DE DADOS HIVE - RAIO-X');
    print('');
    
    print('\n👤 USUÁRIOS CADASTRADOS (${usuarios.length}):');
    if (usuarios.isEmpty) {
      print(' -> Nenhum usuário no banco ainda.');
    } else {
      for (var key in usuarios.keys) {
        print(' -> Chave (Login): $key | Dados: ${usuarios.get(key)}');
      }
    }

    print('\n⏱️ SESSÕES SALVAS (${sessoes.length}):');
    if (sessoes.isEmpty) {
      print(' -> Nenhuma sessão de estudo ainda.');
    } else {
      for (var key in sessoes.keys) {
        print(' -> Dono: $key | Histórico: ${sessoes.get(key)}');
      }
    }
    print('\n');
  }
}