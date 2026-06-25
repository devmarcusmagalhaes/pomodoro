// lib/views/tela_debug.dart

// Inspetor de dados — usado para demonstrar a persistência durante a
// apresentação do projeto.

// MUDANÇA DA PARTE 3: a autenticação e a fonte da verdade das sessões agora
// estão no Firebase (Auth + Firestore). Esta tela mostra:
//   - O usuário autenticado no Firebase (uid, nome, e-mail).
//   - O cache local Hive das sessões (espelho offline do Firestore).
//   - A preferência leve em SharedPreferences (último tempo escolhido).

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../controllers/auth_controller.dart';
import '../services/db_service.dart';
import '../services/preferencias_service.dart';

class TelaDebug extends StatefulWidget {
  const TelaDebug({super.key});

  @override
  State<TelaDebug> createState() => _TelaDebugState();
}

class _TelaDebugState extends State<TelaDebug> {
  Map<String, dynamic> _sessoesCache = {};
  int? _tempoPadrao;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    final tempoPadrao = await PreferenciasService().lerTempoPadrao();

    // Lê o cache local Hive (box "sessoes": chave = uid → List<Map>).
    final sessoes = <String, dynamic>{};
    for (final key in DbService.sessoes.keys) {
      sessoes[key.toString()] = DbService.sessoes.get(key);
    }

    if (!mounted) return;
    setState(() {
      _tempoPadrao = tempoPadrao;
      _sessoesCache = sessoes;
    });
  }

  /// Converte valores do Hive para tipos JSON-safe (chaves como String).
  dynamic _sanitize(dynamic v) {
    if (v is Map) {
      return v.map<String, dynamic>(
        (k, val) => MapEntry(k.toString(), _sanitize(val)),
      );
    }
    if (v is List) return v.map(_sanitize).toList();
    if (v is DateTime) return v.toIso8601String();
    return v;
  }

  String _prettify(dynamic value) =>
      const JsonEncoder.withIndent('  ').convert(_sanitize(value));

  Future<void> _copiar(String texto) async {
    await Clipboard.setData(ClipboardData(text: texto));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('JSON copiado para a área de transferência'),
        duration: Duration(seconds: 1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final usuario = context.watch<AuthController>().usuario;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Inspetor de Dados'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Atualizar',
            onPressed: _carregar,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Padding(
            padding: EdgeInsets.only(bottom: 8),
            child: Text(
              'Auth e fonte da verdade na nuvem (Firebase). O Hive é o cache '
              'local offline das sessões.',
              style: TextStyle(fontSize: 13, color: Colors.black54),
            ),
          ),
          _Section(
            titulo: 'Firebase Auth — usuário logado',
            subtitulo: 'Identidade gerenciada pelo Firebase',
            conteudo: _prettify({
              'uid'  : usuario?.uid,
              'nome' : usuario?.nome,
              'email': usuario?.email,
            }),
            onCopiar: _copiar,
          ),
          _Section(
            titulo: 'Hive — cache local de sessões',
            subtitulo:
                '${_sessoesCache.length} usuário(s) em cache — chave = uid',
            conteudo:
                _sessoesCache.isEmpty ? '{}' : _prettify(_sessoesCache),
            onCopiar: _copiar,
          ),
          _Section(
            titulo: 'SharedPreferences',
            subtitulo: 'Preferência leve (último tempo escolhido)',
            conteudo: _prettify({'tempo_padrao_min': _tempoPadrao}),
            onCopiar: _copiar,
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String titulo;
  final String subtitulo;
  final String conteudo;
  final Future<void> Function(String) onCopiar;

  const _Section({
    required this.titulo,
    required this.subtitulo,
    required this.conteudo,
    required this.onCopiar,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        titulo,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        subtitulo,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.copy, size: 18),
                  tooltip: 'Copiar JSON',
                  onPressed: () => onCopiar(conteudo),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade900,
                borderRadius: BorderRadius.circular(8),
              ),
              child: SelectableText(
                conteudo,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 12,
                  color: Colors.greenAccent,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
