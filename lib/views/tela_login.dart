// Tela de Login e Cadastro (Responsável por autenticação e validações)
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/auth_controller.dart';
import '../controllers/pomodoro_controller.dart';
import 'tela_pomodoro.dart';

class TelaLogin extends StatefulWidget {
  const TelaLogin({super.key});

  @override
  State<TelaLogin> createState() => _TelaLoginState();
}

class _TelaLoginState extends State<TelaLogin> {
  // Chave global para podermos disparar a validação do formulário inteiro
  final _formKey = GlobalKey<FormState>();
  
  // Controladores para capturar o que o usuário digita nos campos
  final _nomeCtrl = TextEditingController();
  final _loginCtrl = TextEditingController();
  final _senhaCtrl = TextEditingController();
  final _confirmarCtrl = TextEditingController();

  // Estados da tela
  bool _senhaVisivel = false;
  bool _modoLogin = true; // true = Tela de Entrar / false = Tela de Cadastrar
  bool _carregando = false; // Evita que o usuário clique duas vezes no botão

  @override
  void dispose() {
    // Liberando a memória quando a tela for destruída
    _nomeCtrl.dispose();
    _loginCtrl.dispose();
    _senhaCtrl.dispose();
    _confirmarCtrl.dispose();
    super.dispose();
  }

  // Função principal chamada ao clicar em "Entrar" ou "Criar Conta"
  Future<void> _submeter() async {
    // Dispara as validações dos TextFormFields. Se alguma falhar, interrompe aqui.
    if (!_formKey.currentState!.validate()) return;
    
    // Se já estiver processando, não faz nada (evita duplo clique)
    if (_carregando) return;

    setState(() => _carregando = true);

    final auth = context.read<AuthController>();
    final pomoc = context.read<PomodoroController>();
    final login = _loginCtrl.text.trim();
    final senha = _senhaCtrl.text;

    try {
      if (_modoLogin) {
        // FLUXO DE LOGIN
        final usuario = await auth.entrar(login, senha);
        if (usuario == null) {
          _mostrarMensagem('Login ou senha incorretos.', Colors.red.shade700);
          return;
        }
        
        // Se logou com sucesso, carrega o histórico dele antes de mudar de tela
        await pomoc.carregarSessoes(usuario.login);
        if (mounted) _irParaPomodoro();
      } else {
        // FLUXO DE CADASTRO
        if (auth.loginEmUso(login)) {
          _mostrarMensagem('Poxa, esse login já está em uso.', Colors.red.shade700);
          return;
        }
        
        final novoUsuario = await auth.cadastrar(_nomeCtrl.text.trim(), login, senha);
        await pomoc.carregarSessoes(novoUsuario.login);
        
        _mostrarMensagem(
          'Bem-vindo(a), ${novoUsuario.nome.split(' ').first}!',
          Colors.green.shade700,
          aoFechar: _irParaPomodoro,
        );
      }
    } on StateError catch (e) {
      _mostrarMensagem(e.message, Colors.red.shade700);
    } catch (e) {
      _mostrarMensagem('Ops, erro inesperado: $e', Colors.red.shade700);
    } finally {
      // Sempre tira o estado de carregando no final, dando erro ou não
      if (mounted) setState(() => _carregando = false);
    }
  }

  void _irParaPomodoro() {
    // pushReplacement destrói a tela de login para o usuário não voltar pra ela pelo botão de voltar do celular
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const TelaPomodoro()),
    );
  }

  // Função auxiliar para exibir as "torradas" (pop-ups) de erro ou sucesso
  void _mostrarMensagem(String msg, Color cor, {VoidCallback? aoFechar}) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(
          content: Text(msg),
          backgroundColor: cor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ))
        .closed
        .then((_) => aoFechar?.call());
  }

  // Troca entre tela de Login e tela de Cadastro limpando os campos
  void _alternarModo() {
    setState(() {
      _modoLogin = !_modoLogin;
      _formKey.currentState?.reset();
      _nomeCtrl.clear();
      _loginCtrl.clear();
      _senhaCtrl.clear();
      _confirmarCtrl.clear();
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
                  
                  // LOGO
                  Center(
                    child: Container(
                      width: 72,
                      height: 72,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Colors.deepOrange.shade50,
                        shape: BoxShape.circle,
                      ),
                      child: const Text('🍅', style: TextStyle(fontSize: 36)),
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  // TÍTULO DINÂMICO
                  Text(
                    _modoLogin ? 'Bem-vindo(a) de volta!' : 'Criar conta',
                    style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w700),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  
                  // FORMULÁRIO
                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        // Campo de Nome (Só aparece se for Cadastro)
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
                        
                        // Campo de Login
                        TextFormField(
                          controller: _loginCtrl,
                          validator: auth.validarLogin,
                          autocorrect: false,
                          decoration: const InputDecoration(
                            labelText: 'Login',
                            prefixIcon: Icon(Icons.alternate_email),
                            helperText: 'Letras, números e _  •  mín. 4 caracteres',
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        // Campo de Senha
                        TextFormField(
                          controller: _senhaCtrl,
                          validator: auth.validarSenha,
                          obscureText: !_senhaVisivel,
                          decoration: InputDecoration(
                            labelText: 'Senha',
                            prefixIcon: const Icon(Icons.lock_outline),
                            helperText: _modoLogin ? null : 'Mín. 6 chars · 1 maiúscula · 1 número',
                            suffixIcon: IconButton(
                              icon: Icon(_senhaVisivel ? Icons.visibility_off : Icons.visibility),
                              onPressed: () => setState(() => _senhaVisivel = !_senhaVisivel),
                            ),
                          ),
                        ),
                        
                        // Campo Confirmar Senha (Só aparece se for Cadastro)
                        if (!_modoLogin) ...[
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _confirmarCtrl,
                            validator: (v) => auth.validarConfirmar(v, _senhaCtrl.text),
                            obscureText: true,
                            decoration: const InputDecoration(
                              labelText: 'Confirmar senha',
                              prefixIcon: Icon(Icons.lock_reset),
                            ),
                          ),
                        ],
                        
                        const SizedBox(height: 24),
                        
                        // BOTÃO DE SUBMETER
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: FilledButton(
                            onPressed: _carregando ? null : _submeter,
                            style: FilledButton.styleFrom(
                              backgroundColor: Colors.deepOrange,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: _carregando
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                  )
                                : Text(
                                    _modoLogin ? 'Entrar' : 'Criar conta',
                                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // BOTÃO DE ALTERNAR MODO (Login <-> Cadastro)
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
                          style: const TextStyle(color: Colors.deepOrange, fontWeight: FontWeight.w600),
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