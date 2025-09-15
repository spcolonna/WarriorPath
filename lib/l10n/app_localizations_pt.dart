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
  String get teacherLower => 'mestre';

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

  @override
  String get password => 'Senha';

  @override
  String get home => 'Início';

  @override
  String get student => 'Aluno';

  @override
  String get studentLower => 'aluno';

  @override
  String get managment => 'Gestão';

  @override
  String get profile => 'Perfil';

  @override
  String get actives => 'Ativos';

  @override
  String get pending => 'Pendentes';

  @override
  String get inactives => 'Inativos';

  @override
  String get general => 'Geral';

  @override
  String get assistance => 'Presença';

  @override
  String get payments => 'Pagamentos';

  @override
  String get payment => 'Pagamento';

  @override
  String get progress => 'Progresso';

  @override
  String get technics => 'Técnicas';

  @override
  String get facturation => 'Faturamento';

  @override
  String get changeAssignedPlan => 'Alterar Plano Designado';

  @override
  String get personalData => 'Dados Pessoais';

  @override
  String get birdthDate => 'Data de Nascimento';

  @override
  String get gender => 'Sexo';

  @override
  String get years => 'anos';

  @override
  String get phone => 'Telefone';

  @override
  String get emergencyInfo => 'Informações de Emergência';

  @override
  String get contact => 'Contato';

  @override
  String get medService => 'Serviço Médico';

  @override
  String get medInfo => 'Informações Médicas';

  @override
  String get noSpecify => 'Não especificado';

  @override
  String get changeRol => 'Mudar Papel';

  @override
  String get noPayment => 'Não há pagamentos registrados para este aluno.';

  @override
  String get errorLoadHistory => 'Erro ao carregar o histórico.';

  @override
  String get noRegisterAssitance =>
      'Não há registros de presença para este aluno.';

  @override
  String get classRoom => 'Aula';

  @override
  String get removeAssistance => 'Remover esta presença';

  @override
  String get confirm => 'Confirmar';

  @override
  String get removeAssistanceCOnfirmation =>
      'Tem certeza de que deseja remover esta presença do registro do aluno?';

  @override
  String get cancel => 'Cancelar';

  @override
  String get eliminate => 'Excluir';

  @override
  String get assistanceDelete => 'Presença excluída.';

  @override
  String deleteError(String e) {
    return 'Erro ao excluir: $e';
  }

  @override
  String get loadProgressError => 'Erro ao carregar o progresso.';

  @override
  String get noHistPromotion => 'Este aluno não tem histórico de promoções.';

  @override
  String rolUpdatedTo(String rol) {
    return 'Papel atualizado para $rol';
  }

  @override
  String get invalidRegisterPromotion => 'Registro de promoção inválido';

  @override
  String get deleteLevel => 'Nível Excluído';

  @override
  String promotionTo(String level) {
    return 'Promovido para $level';
  }

  @override
  String get notes => 'Notas';

  @override
  String notesWith(Object notesWith) {
    return 'Notes: $notesWith';
  }

  @override
  String notesValue(String notes) {
    return 'Notas: $notes';
  }

  @override
  String get revertPromotion => 'Reverter Promoção';

  @override
  String get revertThisPromotion => 'Reverter esta promoção';

  @override
  String get confirmReverPromotion =>
      'Tem certeza de que deseja excluir este registro de promoção? \n\nIsso reverterá o nível atual do aluno para o nível anterior.';

  @override
  String get yesRevert => 'Sim, Reverter';

  @override
  String get maleGender => 'Masculino';

  @override
  String get femaleGender => 'Feminino';

  @override
  String get otherGender => 'Outro';

  @override
  String get noSpecifyGender => 'Prefere não dizer';

  @override
  String get noClassForTHisDay =>
      'Não havia aulas agendadas para o dia selecionado.';

  @override
  String classFor(String day) {
    return 'Aulas de $day';
  }

  @override
  String get successAssistance => 'Presença registrada com sucesso.';

  @override
  String saveError(String e) {
    return 'Erro ao salvar: $e';
  }

  @override
  String get successRevertPromotion => 'Promoção revertida com sucesso.';

  @override
  String errorToRevert(String e) {
    return 'Erro ao reverter: $e';
  }

  @override
  String get registerPayment => 'Registrar Pagamento';

  @override
  String get payPlan => 'Pagamento do Plano';

  @override
  String get paySpecial => 'Pagamento Especial';

  @override
  String get selectPlan => 'Selecione um plano';

  @override
  String get concept => 'Conceito';

  @override
  String get amount => 'Valor';

  @override
  String get savePayment => 'Salvar Pagamento';

  @override
  String get promotionOrChangeLevel => 'Promover ou Corrigir Nível';

  @override
  String get choseNewLevel => 'Selecione o novo nível';

  @override
  String get optional => 'opcional';

  @override
  String get studentSuccessPromotion => 'Aluno promovido com sucesso!';

  @override
  String promotionError(String e) {
    return 'Erro ao promover: $e';
  }

  @override
  String get changeRolMember => 'Mudar Papel do Membro';

  @override
  String get instructor => 'instructor';

  @override
  String get save => 'Salvar';

  @override
  String get updateRolSuccess => 'Papel atualizado com sucesso.';

  @override
  String updateRolError(String e) {
    return 'Erro ao mudar o papel: $e';
  }

  @override
  String get successPayment => 'Pagamento registrado com sucesso.';

  @override
  String paymentError(String e) {
    return 'Erro ao registrar o pagamento: $e';
  }

  @override
  String get assignPlan => 'Designar Plano de Pagamento';

  @override
  String get removeAssignedPlan => 'Remover plano designado';

  @override
  String get withPutLevel => 'Sem Nível';

  @override
  String get registerPausedAssistance => 'Registrar Presença Passada';

  @override
  String get errorLevelLoad =>
      'Não foi possível carregar o nível atual do aluno.';

  @override
  String get levelPromotion => 'Promover Nível';

  @override
  String get assignTechnic => 'Designar Técnicas';

  @override
  String get studentNotAssignedTechnics =>
      'Este aluno não possui técnicas designadas.';

  @override
  String get notassignedPaymentPlan => 'Nenhum plano de pagamento designado.';

  @override
  String paymentPlanNotFoud(String assignedPlanId) {
    return 'Plano designado (ID: $assignedPlanId) não encontrado.';
  }

  @override
  String get contactData => 'Dados de Contato';

  @override
  String get saveAndContinue => 'Salvar e Continuar';
}
