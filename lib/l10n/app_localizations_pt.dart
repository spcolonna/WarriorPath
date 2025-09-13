// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Portuguese (`pt`).
class AppLocalizationsPt extends AppLocalizations {
  AppLocalizationsPt([String locale = 'pt']) : super(locale);

  @override
  String get appName => 'Warrior Path';

  @override
  String get appSlogan => 'Seja um guerreiro, crie seu caminho';

  @override
  String get emailLabel => 'E-mail';

  @override
  String get loginButton => 'Entrar';

  @override
  String get createAccountButton => 'Criar Conta';

  @override
  String get forgotPasswordLink => 'Esqueceu sua senha?';

  @override
  String get profileErrorTitle => 'Erro de Perfil';

  @override
  String get profileErrorContent =>
      'Não foi possível carregar seu perfil. Tente novamente.';

  @override
  String get accessDeniedTitle => 'Acesso Negado';

  @override
  String get accessDeniedContent =>
      'Você não possui um papel ativo em nenhuma escola.';

  @override
  String get loginErrorTitle => 'Erro de Login';

  @override
  String get loginErrorUserNotFound =>
      'Nenhum usuário encontrado para este e-mail.';

  @override
  String get loginErrorWrongPassword =>
      'Senha incorreta fornecida para este usuário.';

  @override
  String get loginErrorInvalidCredential =>
      'As credenciais fornecidas estão incorretas.';

  @override
  String get unexpectedError => 'Ocorreu um erro inesperado.';

  @override
  String get registrationErrorTitle => 'Erro de Registro';

  @override
  String get registrationErrorContent =>
      'Não foi possível concluir o registro. O e-mail já pode estar em uso ou a senha é muito fraca.';

  @override
  String get errorTitle => 'Erro';

  @override
  String genericErrorContent(String errorDetails) {
    return 'Ocorreu um erro: $errorDetails';
  }

  @override
  String get language => 'Idioma';

  @override
  String get ok => 'Ok';

  @override
  String welcomeTitle(String userName) {
    return 'Bem-vindo, $userName!';
  }

  @override
  String get teacher => 'Mestre';

  @override
  String get sessionError => 'Erro: Sessão inválida.';

  @override
  String get noSchedulerClass => 'Não há aulas agendadas para hoje.';

  @override
  String get choseClass => 'Selecionar Turma';

  @override
  String get todayClass => 'Aulas de Hoje';

  @override
  String get takeAssistance => 'Marcar Presença';

  @override
  String get loading => 'Carregando...';

  @override
  String get activeStudents => 'Alunos Ativos';

  @override
  String get pendingApplication => 'Solicitações Pendentes';
}
