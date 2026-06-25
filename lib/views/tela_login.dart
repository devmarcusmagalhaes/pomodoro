// lib/views/tela_login.dart

// MUDANÇAS DA PARTE 3:
//   - Autenticação por E-MAIL/senha (Firebase Auth) no lugar de "login".
//   - entrar/cadastrar retornam Result: tratamos Ok/Falha com a mensagem
//     já traduzida pelo AuthRepository.
//   - Após autenticar: carrega as sessões pelo `uid` antes de navegar.


import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/auth_controller.dart';
import '../controllers/pomodoro_controller.dart';
import '../core/result.dart';
import '../models/usuario.dart';
import 'tela_pomodoro.dart';

class TelaLogin extends StatefulWidget {
  const TelaLogin({super.key});

  @override
  State<TelaLogin> createState() => _TelaLoginState();
}

class _TelaLoginState extends State<TelaLogin> {
  final _formKey = GlobalKey<FormState>();
  final _nomeCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _senhaCtrl = TextEditingController();
  final _confirmarCtrl = TextEditingController();

  bool _senhaVisivel = false;
  bool _modoLogin = true;
  bool _carregando = false;

  @override
  void dispose() {
    _nomeCtrl.dispose();
    _emailCtrl.dispose();
    _senhaCtrl.dispose();
    _confirmarCtrl.dispose();
    super.dispose();
  }

  Future<void> _submeter() async {
    if (!_formKey.currentState!.validate()) return;
    if (_carregando) return;

    setState(() => _carregando = true);

    final auth  = context.read<AuthController>();
    final pomoc = context.read<PomodoroController>();
    final email = _emailCtrl.text.trim();
    final senha = _senhaCtrl.text;

    try {
      final Result<Usuario> resultado = _modoLogin
          ? await auth.entrar(email, senha)
          : await auth.cadastrar(_nomeCtrl.text.trim(), email, senha);

      switch (resultado) {
        case Falha(:final mensagem):
          _snack(mensagem, Colors.red.shade700);
        case Ok(:final value):
          await pomoc.carregarSessoes(value.uid);
          if (!mounted) return;
          if (_modoLogin) {
            _irParaPomodoro();
          } else {
            _snack(
              'Bem-vindo(a), ${value.nome.split(' ').first}!',
              Colors.green.shade700,
              aoFechar: _irParaPomodoro,
            );
          }
      }
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  void _irParaPomodoro() => Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const TelaPomodoro()),
      );

  void _snack(String msg, Color cor, {VoidCallback? aoFechar}) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(
          content: Text(msg),
          backgroundColor: cor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10)),
        ))
        .closed
        .then((_) => aoFechar?.call());
  }

  void _alternarModo() {
    setState(() {
      _modoLogin = !_modoLogin;
      _formKey.currentState?.reset();
      for (final c in [_nomeCtrl, _emailCtrl, _senhaCtrl, _confirmarCtrl]) {
        c.clear();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthController>();

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 16),
                  Center(
                    child: Semantics(
                      label: 'Logotipo Pomodoro',
                      child: Container(
                        width: 72,
                        height: 72,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: Colors.deepOrange.shade50,
                          shape: BoxShape.circle,
                        ),
                        child:
                            const Text('🍅', style: TextStyle(fontSize: 36)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    _modoLogin ? 'Bem-vindo(a) de volta!' : 'Criar conta',
                    style: const TextStyle(
                        fontSize: 26, fontWeight: FontWeight.w700),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        if (!_modoLogin) ...[
                          TextFormField(
                            controller: _nomeCtrl,
                            validator: auth.validarNome,
                            textCapitalization: TextCapitalization.words,
                            decoration: const InputDecoration(
                              labelText: 'Nome completo',
                              prefixIcon: Icon(Icons.person_outline),
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                        TextFormField(
                          controller: _emailCtrl,
                          validator: auth.validarEmail,
                          autocorrect: false,
                          keyboardType: TextInputType.emailAddress,
                          decoration: const InputDecoration(
                            labelText: 'E-mail',
                            prefixIcon: Icon(Icons.alternate_email),
                            helperText: 'ex.: voce@email.com',
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _senhaCtrl,
                          validator: auth.validarSenha,
                          obscureText: !_senhaVisivel,
                          decoration: InputDecoration(
                            labelText: 'Senha',
                            prefixIcon: const Icon(Icons.lock_outline),
                            helperText: _modoLogin
                                ? null
                                : 'Mín. 6 chars · 1 maiúscula · 1 número',
                            suffixIcon: IconButton(
                              icon: Icon(_senhaVisivel
                                  ? Icons.visibility_off
                                  : Icons.visibility),
                              tooltip: _senhaVisivel
                                  ? 'Ocultar senha'
                                  : 'Mostrar senha',
                              onPressed: () => setState(
                                  () => _senhaVisivel = !_senhaVisivel),
                            ),
                          ),
                        ),
                        if (!_modoLogin) ...[
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _confirmarCtrl,
                            validator: (v) =>
                                auth.validarConfirmar(v, _senhaCtrl.text),
                            obscureText: true,
                            decoration: const InputDecoration(
                              labelText: 'Confirmar senha',
                              prefixIcon: Icon(Icons.lock_reset),
                            ),
                          ),
                        ],
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: FilledButton(
                            onPressed: _carregando ? null : _submeter,
                            style: FilledButton.styleFrom(
                              backgroundColor: Colors.deepOrange,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                            child: _carregando
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : Text(
                                    _modoLogin ? 'Entrar' : 'Criar conta',
                                    style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _modoLogin ? 'Não tem conta? ' : 'Já tem conta? ',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                      GestureDetector(
                        onTap: _alternarModo,
                        child: Text(
                          _modoLogin ? 'Cadastre-se' : 'Faça login',
                          style: const TextStyle(
                            color: Colors.deepOrange,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
