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

  @override
  String get subscriptionExpired => 'Assinatura Expirada';

  @override
  String get subscriptionExpiredMessage =>
      'Seu acesso às ferramentas de professor foi pausado. Para renovar sua assinatura e reativar sua conta, por favor, entre em contato com o administrador.';

  @override
  String get contactAdmin => 'Contatar Administrador';

  @override
  String get renewalSubject => 'Renovação de Assinatura - Warrior Path';

  @override
  String get mailError => 'Não foi possível abrir o aplicativo de e-mail.';

  @override
  String mailLaunchError(String e) {
    return 'Erro ao tentar abrir o e-mail: $e';
  }

  @override
  String get nameAndMartialArtRequired =>
      'Nome e Arte Marcial são obrigatórios.';

  @override
  String get needSelectSubSchool =>
      'Se for uma sub-escola, você deve selecionar a escola principal.';

  @override
  String get notAuthenticatedUser => 'Usuário não autenticado.';

  @override
  String createSchoolError(String e) {
    return 'Erro ao criar a escola: $e';
  }

  @override
  String get crateSchoolStep2 => 'Crie Sua Escola (Passo 2)';

  @override
  String get isSubSchool => 'É uma sub-escola?';

  @override
  String get pickAColor => 'Escolha uma cor';

  @override
  String get select => 'Selecionar';

  @override
  String get configureLevelsStep3 => 'Configurar Níveis (Passo 3)';

  @override
  String get addYourFirstLevel => 'Adicione seu primeiro nível abaixo.';

  @override
  String get addLevel => 'Adicionar Nível';

  @override
  String get schoolManagement => 'Gestão da Escola';

  @override
  String get noActiveSchoolError => 'Erro: Nenhuma escola ativa na sessão.';

  @override
  String get myProfileAndActions => 'Meu Perfil e Ações';

  @override
  String get logOut => 'Sair';

  @override
  String get editMyProfile => 'Editar Meu Perfil';

  @override
  String get updateProfileInfo => 'Atualize seu nome, foto ou senha.';

  @override
  String get switchProfileSchool => 'Mudar de Perfil/Escola';

  @override
  String get accessOtherRoles => 'Acesse seus outros papéis ou escolas.';

  @override
  String get enrollInAnotherSchool => 'Inscrever-se em outra Escola';

  @override
  String get joinAnotherCommunity => 'Junte-se a outra comunidade como aluno.';

  @override
  String get createNewSchool => 'Criar uma Nova Escola';

  @override
  String get expandYourLegacy => 'Expanda seu legado ou abra uma nova filial.';

  @override
  String get students => 'Alunos';

  @override
  String get reject => 'Rejeitar';

  @override
  String get accept => 'Aceitar';

  @override
  String get selectProfile => 'Selecionar Perfil';

  @override
  String get addSchedule => 'Adicionar Horário';

  @override
  String get saveSchedule => 'Salvar Horário';

  @override
  String get confirmDeletion => 'Confirmar Exclusão';

  @override
  String get confirmDeleteSchedule =>
      'Tem certeza que deseja excluir este horário?';

  @override
  String get manageSchedules => 'Gerenciar Horários';

  @override
  String get confirmDeleteEvent =>
      'Tem certeza que deseja excluir este evento permanentemente? Esta ação não pode ser desfeita.';

  @override
  String get eventDeleted => 'Evento excluído.';

  @override
  String get eventNoLongerExists => 'Este evento não existe mais.';

  @override
  String get attendees => 'Participantes';

  @override
  String get manageGuests => 'Gerenciar Convidados';

  @override
  String get noStudentsInvitedYet => 'Você ainda não convidou nenhum aluno.';

  @override
  String get endTime => 'Hora de Fim';

  @override
  String get startTime => 'Hora de Início';

  @override
  String get daysOfTheWeek => 'Dias da semana';

  @override
  String get classTitle => 'Título da Turma';

  @override
  String get classTitleExample => 'Ex: Crianças, Adultos, Chutes';

  @override
  String get scheduleSavedSuccess => 'Horário salvo com sucesso.';

  @override
  String get endTimeAfterStartTimeError =>
      'A hora de fim deve ser posterior à hora de início.';

  @override
  String get pleaseFillAllFields =>
      'Por favor, preencha todos os campos obrigatórios.';

  @override
  String get unknownSchool => 'Escola Desconhecida';

  @override
  String get noActiveProfilesFound => 'Nenhum perfil ativo encontrado.';

  @override
  String enterAs(String e) {
    return 'Entrar como $e';
  }

  @override
  String inSchool(String message) {
    return 'em $message';
  }

  @override
  String yourAnswer(String message) {
    return 'Sua Resposta: $message';
  }

  @override
  String get cost => 'Custo';

  @override
  String get time => 'Hora';

  @override
  String get date => 'Data';

  @override
  String get location => 'Localização';

  @override
  String get invited => 'Convidado';

  @override
  String get eventDetails => 'Detalhes do Evento';

  @override
  String errorSendingResponse(String e) {
    return 'Erro ao enviar resposta: $e';
  }

  @override
  String responseSent(String message) {
    return 'Resposta enviada: $message';
  }

  @override
  String get manageEvents => 'Gerenciar Eventos';

  @override
  String get manageEventsDescription => 'Crie exames, torneios e seminários.';

  @override
  String get manageSchedulesDescription =>
      'Defina os turnos e dias de suas aulas.';

  @override
  String get manageLevels => 'Gerenciar Níveis';

  @override
  String get manageLevelsDescription =>
      'Edite os nomes, cores e ordem das faixas/cintos.';

  @override
  String get manageTechniques => 'Gerenciar Técnicas';

  @override
  String get manageTechniquesDescription =>
      'Adicione ou modifique o currículo da sua escola.';

  @override
  String get manageFinances => 'Gerenciar Finanças';

  @override
  String get manageFinancesDescription =>
      'Ajuste os preços e planos de pagamento.';

  @override
  String get editSchoolData => 'Editar Dados da Escola';

  @override
  String get editSchoolDataDescription =>
      'Modifique o endereço, telefone, descrição, etc.';

  @override
  String get upcoming => 'Próximos';

  @override
  String get past => 'Passados';

  @override
  String get noUpcomingEvents => 'Não há eventos futuros.';

  @override
  String get noPastEvents => 'Não há eventos passados.';

  @override
  String get errorNoActiveSession => 'Erro: Nenhuma sessão ativa.';

  @override
  String get profileLoadedError => 'Não foi possível carregar o perfil.';

  @override
  String get fullName => 'Nome e Sobrenome';

  @override
  String get saveChanges => 'Salvar Alterações';

  @override
  String get emergencyInfoNotice =>
      'Esta informação será visível apenas para os professores da sua escola, se necessário.';

  @override
  String get emergencyContactName => 'Nome do Contato de Emergência';

  @override
  String get emergencyContactPhone => 'Telefone do Contato de Emergência';

  @override
  String get medicalEmergencyService => 'Serviço de Emergência Médica';

  @override
  String get medicalServiceExample => 'Ex: SAMU, Unimed, etc.';

  @override
  String get relevantMedicalInfo => 'Informações Médicas Relevantes';

  @override
  String get medicalInfoExample => 'Ex: Alergias, asma, medicação, etc.';

  @override
  String get accountActions => 'Ações da Conta';

  @override
  String get becomeATeacher => 'Torne-se um mestre e inicie seu caminho.';

  @override
  String get myData => 'Meus Dados';

  @override
  String get myProfile => 'Meu Perfil';

  @override
  String profileUpdateError(String message) {
    return 'Erro ao atualizar o perfil: $message';
  }

  @override
  String noStudentsWithStatus(String state) {
    return 'Não há alunos com o status $state';
  }

  @override
  String get noName => 'Sem Nome';

  @override
  String applicationDate(String message) {
    return 'Data da solicitação: $message';
  }

  @override
  String get noLevelsConfiguredError =>
      'Sua escola não tem níveis configurados. Vá para Gestão -> Níveis para adicioná-los.';

  @override
  String get studentAcceptedSuccess => 'Aluno aceito com sucesso.';

  @override
  String get applicationRejected => 'Solicitação rejeitada.';

  @override
  String get monday => 'Segunda-feira';

  @override
  String get tuesday => 'Terça-feira';

  @override
  String get wednesday => 'Quarta-feira';

  @override
  String get thursday => 'Quinta-feira';

  @override
  String get friday => 'Sexta-feira';

  @override
  String get saturday => 'Sábado';

  @override
  String get sunday => 'Domingo';

  @override
  String get noSchedulesDefined =>
      'Não há horários definidos.\nPressione (+) para adicionar o primeiro.';

  @override
  String get schoolCommunity => 'Comunidade da Escola';

  @override
  String get errorLoadingLevels => 'Erro ao carregar os níveis da escola.';

  @override
  String get errorLoadingMembers => 'Erro ao carregar os membros.';

  @override
  String get noActiveMembersYet => 'Ainda não há membros ativos na escola.';

  @override
  String get instructors => 'Instrutores';

  @override
  String get myPayments => 'Meus Pagamentos';

  @override
  String get errorLoadingPaymentHistory =>
      'Erro ao carregar seu histórico de pagamentos.';

  @override
  String get noPaymentsRegisteredYet =>
      'Você ainda não tem pagamentos registrados.';

  @override
  String paymentDetails(String concept, String date) {
    return '$concept\nPago em $date';
  }

  @override
  String get myProgress => 'Meu Progresso';

  @override
  String get couldNotLoadProgress => 'Não foi possível carregar seu progresso.';

  @override
  String get yourPath => 'Seu Caminho';

  @override
  String get promotionHistory => 'Histórico de Promoções';

  @override
  String get assignedTechniques => 'Técnicas Designadas';

  @override
  String get myAttendanceHistory => 'Meu Histórico de Presença';

  @override
  String get noLevelAssignedYet => 'Você ainda não tem um nível designado.';

  @override
  String get yourCurrentLevel => 'Seu Nível Atual';

  @override
  String get progressionSystemNotDefined =>
      'O sistema de progressão não foi definido.';

  @override
  String get teacherHasNotAssignedTechniques =>
      'Seu mestre ainda não lhe designou técnicas.';

  @override
  String get noPromotionsRegisteredYet =>
      'Você ainda não tem promoções registradas.';

  @override
  String couldNotOpenVideo(String link) {
    return 'Não foi possível abrir o vídeo: $link';
  }

  @override
  String get noDescriptionAvailable => 'Nenhuma descrição disponível.';

  @override
  String get watchTechniqueVideo => 'Assistir Vídeo da Técnica';

  @override
  String get close => 'Fechar';

  @override
  String get mySchool => 'Minha Escola';

  @override
  String get couldNotLoadSchoolInfo =>
      'Não foi possível carregar as informações da escola.';

  @override
  String get schoolName => 'Nome da Escola';

  @override
  String get martialArt => 'Arte Marcial';

  @override
  String get address => 'Endereço';

  @override
  String get upcomingEvents => 'Próximos Eventos';

  @override
  String get classSchedule => 'Horário de Aulas';

  @override
  String get scheduleNotDefinedYet => 'O horário ainda não foi definido.';

  @override
  String get updateProfileSuccess => 'Perfil atualizado com sucesso.';
}
