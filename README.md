# 🍅 Pomodoro Semanal — Parte 2

Aplicativo Flutter de Pomodoro com **estatísticas semanais**, **autenticação
de usuários** e **persistência local** (banco de dados Hive + SharedPreferences).
Desenvolvido como entrega da disciplina de Desenvolvimento Mobile.

---

---

## 🎯 Objetivo da Parte 2

A Parte 2 estende o projeto da Parte 1 com:

1. **Banco de dados local** (Hive) para persistir usuários e sessões.
2. **Sistema de autenticação** com cadastro, login, logout e auto-login.
3. **Melhorias de UX e qualidade de código** sobre a Parte 1.

---

## 🏗️ Arquitetura

O projeto segue um padrão em camadas (MVC-like) com `Provider` para
gerenciamento de estado:

```
lib/
├── main.dart                          ← inicializa Hive e sobe a UI
│
├── core/
│   ├── constants.dart                 ← opções, limites e helpers
│   └── theme.dart                     ← tema visual do app
│
├── models/
│   ├── usuario.dart                   ← Usuario (com senhaHash)
│   └── sessao_estudo.dart             ← SessaoEstudo (com toMap/fromMap)
│
├── services/                          ← camada de dados
│   ├── db_service.dart                ← inicialização do Hive
│   ├── auth_service.dart              ← validações + autenticação
│   ├── sessao_service.dart            ← CRUD de sessões
│   └── preferencias_service.dart      ← SharedPreferences (login + tempo)
│
├── controllers/                       ← lógica + estado (ChangeNotifier)
│   ├── auth_controller.dart
│   └── pomodoro_controller.dart
│
├── views/                             ← telas
│   ├── tela_splash.dart               ← decide rota inicial
│   ├── tela_login.dart                ← login / cadastro
│   ├── tela_pomodoro.dart             ← timer + estatísticas semanais
│   └── tela_perfil.dart               ← perfil + excluir conta
│
└── widgets/                           ← componentes reutilizáveis
    ├── timer_display.dart
    ├── session_stats_card.dart
    └── day_bar_row.dart
```

---

## 🗃️ Banco de dados (Hive)

O **Hive** é um banco NoSQL chave-valor, persistido localmente. Foi escolhido
por:

- **Não é uma API** (atendendo à restrição explícita do enunciado).
- Não exige configuração de servidor (Firebase exigiria projeto + chaves).
- Funciona **offline** e é rápido para os volumes típicos do app.

### Estrutura das "boxes" (tabelas)

```
Box "usuarios"
  chave: "joao_silva"  →  { nome: "João Silva", login: "joao_silva", senhaHash: "3b4c..." }
  chave: "maria99"     →  { nome: "Maria ...",  login: "maria99",    senhaHash: "a1b2..." }

Box "sessoes"
  chave: "joao_silva"  →  [ {data: "2026-05-20T10:00:00", minutos: 25}, ... ]
  chave: "maria99"     →  [ {data: "2026-05-21T09:00:00", minutos: 15}, ... ]
```

Cada usuário tem seus dados **isolados pela chave = login**.

### Por que combinamos Hive com SharedPreferences?

- **Hive** guarda dados estruturados (usuários, sessões).
- **SharedPreferences** guarda apenas valores leves: o login da sessão ativa
  (para auto-login) e o último tempo escolhido pelo usuário (para UX).

---

## 🔐 Autenticação

### Hash de senha

```
Parte 1:  senha = "Abc123"          ← texto puro no objeto Usuario ❌
Parte 2:  senha = sha256("Abc123")  ← hash irreversível no banco   ✅
          → "6ca13d52ca70c883e0f0bb101e425a89e8624de51db2d2392593af6a84118090"
```

O hash é calculado em `AuthService._hashSenha()` antes de salvar ou comparar.
**Nunca armazenamos a senha original.**

> **Nota acadêmica:** SHA-256 sem salt é o mínimo aceitável. Em produção real
> usaríamos `bcrypt` ou `argon2` com salt aleatório por usuário, para resistir
> a tabelas pré-computadas (rainbow tables).

### Fluxo de auto-login

```
Abrir app
    ↓
main() → DbService.init() → runApp()
    ↓
TelaSplash
    ↓
auth.carregarSessaoAtiva()
    ↓ SharedPreferences tem login salvo?
   Sim → Hive[usuarios][login] existe?
           Sim → carrega sessões → TelaPomodoro
           Não → limpa lixo do SharedPreferences → TelaLogin
   Não → TelaLogin
```

### Fluxo de login normal

```
TelaLogin._submeter()
    ↓
auth.entrar(login, senha)   [async]
    ↓
AuthService.entrar()
  → busca Hive[usuarios][login]
  → compara sha256(senha) com senhaHash salvo
  → grava login em SharedPreferences
    ↓
pomodoro.carregarSessoes(login)
  → lê Hive[sessoes][login]
  → restaura tempo padrão das preferências
    ↓
TelaPomodoro
```

---

## ✨ Melhorias da Parte 1

Além dos requisitos obrigatórios (banco + auth), foram implementadas as
seguintes melhorias sobre a versão anterior:

| Melhoria | Onde está | Por que melhora |
|----------|-----------|-----------------|
| **Tela de Perfil** | `views/tela_perfil.dart` | Centraliza informações do usuário, estatísticas agregadas e histórico das últimas 5 sessões. |
| **Excluir conta** | `tela_perfil.dart` + `AuthService.excluirConta` | Direito do usuário sobre os próprios dados; vem com confirmação dupla. |
| **Confirmação de logout** | `tela_pomodoro.dart` | Evita logout acidental (UX comum em apps reais). |
| **Lembrar último tempo escolhido** | `PreferenciasService.gravarTempoPadrao` | Usuário não precisa re-selecionar 25min toda vez que abre. |
| **Feedback tátil ao trocar tempo** | `PomodoroController.selecionarMinutos` | Resposta sensorial imediata (Material Design guideline). |
| **Tela de erro na splash** | `views/tela_splash.dart` | Em vez de tela branca em caso de falha do Hive, mostra mensagem e detalhes. |
| **Loading state no botão de login** | `tela_login.dart` | Evita duplo-clique enquanto a operação async roda. |
| **Tooltips e Semantics** | login, pomodoro, perfil | Acessibilidade (leitores de tela e usuários novos). |
| **Defesa contra race condition no cadastro** | `AuthService.cadastrar` | Lança `StateError` se o login for tomado entre check e write. |
| **Tratamento de erro de persistência** | `PomodoroController._tick` | Falha de I/O não derruba a sessão em memória. |

---

## 🚀 Instalação e execução

### Requisitos

- **Flutter SDK**: 3.16.0 ou superior (compatível com Dart 3.0+)
- **Android Studio** ou **VS Code** com plugins Flutter/Dart
- **Emulador Android** (API 21+) ou dispositivo físico
- Conexão à internet apenas para baixar dependências (o app em si roda offline)

### Passo a passo

1. **Clonar o repositório**

   ```bash
   git clone https://github.com/<usuario>/<repositorio>.git
   cd <repositorio>
   ```

2. **Instalar as dependências**

   ```bash
   flutter pub get
   ```

3. **Verificar o ambiente** (opcional)

   ```bash
   flutter doctor
   ```

4. **Executar o app**

   ```bash
   flutter run
   ```

   Ou abra o projeto no Android Studio/VS Code e clique em ▶️ Run.

### Dependências principais

```yaml
dependencies:
  flutter: sdk: flutter
  provider: ^6.1.2          # gerenciamento de estado
  hive_flutter: ^1.1.0      # banco de dados local NoSQL
  crypto: ^3.0.3            # hash SHA-256 para senhas
  shared_preferences: ^2.3.2 # sessão ativa e preferências leves
```

---

## 🧪 Testes

### Testes automatizados

```bash
flutter test
```

Os testes em `test/widget_test.dart` validam o comportamento da `TelaLogin`
(presença de campos, validações, alternância de modo). Testes que exigem
`Hive` (login bem-sucedido, cadastro, persistência de sessão) são feitos
manualmente — ver abaixo.

### Testes manuais (checklist)

1. **Cadastro:** abrir app → "Cadastre-se" → preencher → "Criar conta" →
   deve abrir TelaPomodoro com saudação personalizada.
2. **Persistência:** fechar e reabrir o app → deve fazer **auto-login**
   direto na TelaPomodoro (sem passar pela TelaLogin).
3. **Sessões persistidas:** iniciar timer de 1 minuto → aguardar conclusão →
   fechar e reabrir → a sessão deve aparecer no histórico do perfil.
4. **Isolamento por usuário:** logout → cadastrar segundo usuário → não deve
   ver sessões do primeiro.
5. **Logout:** ícone de sair → confirmar → deve voltar para TelaLogin.
6. **Senha incorreta:** sair → tentar login com senha errada → mensagem de
   erro deve aparecer e não autenticar.
7. **Login duplicado:** tentar cadastrar com login já existente → mensagem
   "Login já em uso".
8. **Excluir conta:** perfil → Excluir conta → confirmar → usuário e sessões
   apagados; tentar login novamente deve falhar.

---

## ⚠️ Limitações conhecidas

- **Sem sincronização na nuvem** — os dados ficam apenas no dispositivo. Se
  o app for desinstalado, tudo é perdido. Por design: usamos banco local
  conforme o enunciado.
- **Sem salt no hash de senha** — SHA-256 puro. Aceitável para escopo
  acadêmico local; insuficiente para produção.
- **Sem limite de tentativas de login** — não há proteção contra brute-force,
  pois o app é single-user local.
- **Sem recuperação de senha** — se o usuário esquecer, precisa criar nova
  conta (não há e-mail/SMS implementados).

---

## 📂 Estrutura de versionamento

Recomenda-se trabalhar com branches separadas durante o desenvolvimento e
manter a branch `main` sempre estável (entregável). O histórico de commits
deve evidenciar a contribuição de cada integrante.

```bash
git checkout -b feature/<nome>
# … desenvolver …
git commit -m "descrição clara"
git push origin feature/<nome>
# Pull Request → main
```

---

## 📜 Licença e propósito

Trabalho acadêmico — não destinado a uso em produção.
