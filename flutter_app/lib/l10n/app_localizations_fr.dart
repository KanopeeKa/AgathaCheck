// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appTitle => 'Agatha Track';

  @override
  String get agathaCheckLogo => 'Logo Agatha Track';

  @override
  String get appTagline =>
      'Agatha Track organise la santé de votre animal, pour que vous n\'ayez pas à le faire.';

  @override
  String get appDescription =>
      'Suivez les visites vétérinaires, les médicaments, le poids et les soins quotidiens dans un tableau de bord simple conçu pour les propriétaires d\'animaux occupés.';

  @override
  String get appCta =>
      'Connectez-vous pour reprendre là où vous vous êtes arrêté, ou créez un compte gratuit pour commencer à garder l\'historique de santé de votre animal en sécurité et accessible à tout moment.';

  @override
  String get signIn => 'Se connecter';

  @override
  String get signUp => 'S\'inscrire';

  @override
  String get createAccount => 'Créer un compte';

  @override
  String get signInToAccount => 'Connectez-vous à votre compte';

  @override
  String get createYourAccount => 'Créez votre compte';

  @override
  String get dontHaveAccount => 'Pas encore de compte ?';

  @override
  String get alreadyHaveAccount => 'Déjà un compte ?';

  @override
  String get email => 'E-mail';

  @override
  String get password => 'Mot de passe';

  @override
  String get name => 'Nom';

  @override
  String get confirmPassword => 'Confirmer le mot de passe';

  @override
  String get showPassword => 'Afficher le mot de passe';

  @override
  String get hidePassword => 'Masquer le mot de passe';

  @override
  String get emailRequired => 'L\'e-mail est requis';

  @override
  String get enterValidEmail => 'Entrez un e-mail valide';

  @override
  String get passwordRequired => 'Le mot de passe est requis';

  @override
  String get atLeast6Characters => 'Au moins 6 caractères';

  @override
  String get passwordsDoNotMatch => 'Les mots de passe ne correspondent pas';

  @override
  String get forgotPassword => 'Mot de passe oublié ?';

  @override
  String get logOut => 'Déconnexion';

  @override
  String get resetPassword => 'Réinitialiser le mot de passe';

  @override
  String get forgotPasswordTitle => 'Mot de passe oublié';

  @override
  String get enterResetCode => 'Entrez le code de réinitialisation';

  @override
  String get enterResetCodeInstructions =>
      'Entrez le code à 6 chiffres et votre nouveau mot de passe.';

  @override
  String get forgotPasswordInstructions =>
      'Entrez votre adresse e-mail et nous vous enverrons un code pour réinitialiser votre mot de passe.';

  @override
  String get resetCodeSentMessage =>
      'Si un compte avec cet e-mail existe, un code de réinitialisation a été envoyé. Vérifiez vos e-mails.';

  @override
  String get sendResetCode => 'Envoyer le code';

  @override
  String get resetCode => 'Code de réinitialisation';

  @override
  String get sixDigitCode => 'Code à 6 chiffres';

  @override
  String get codeRequired => 'Le code est requis';

  @override
  String get enterSixDigitCode => 'Entrez le code à 6 chiffres';

  @override
  String get newPassword => 'Nouveau mot de passe';

  @override
  String get useDifferentEmail => 'Utiliser un autre e-mail';

  @override
  String get passwordResetTitle => 'Mot de passe réinitialisé';

  @override
  String get backToSignIn => 'Retour à la connexion';

  @override
  String get myDetails => 'Mon profil';

  @override
  String get notLoggedIn => 'Non connecté';

  @override
  String get editProfile => 'Modifier le profil';

  @override
  String get subscription => 'Abonnement';

  @override
  String get managePlan => 'Gérer votre abonnement';

  @override
  String get changePassword => 'Changer le mot de passe';

  @override
  String get currentPassword => 'Mot de passe actuel';

  @override
  String get showCurrentPassword => 'Afficher le mot de passe actuel';

  @override
  String get hideCurrentPassword => 'Masquer le mot de passe actuel';

  @override
  String get currentPasswordRequired => 'Le mot de passe actuel est requis';

  @override
  String get showNewPassword => 'Afficher le nouveau mot de passe';

  @override
  String get hideNewPassword => 'Masquer le nouveau mot de passe';

  @override
  String get newPasswordRequired => 'Le nouveau mot de passe est requis';

  @override
  String get confirmNewPassword => 'Confirmer le nouveau mot de passe';

  @override
  String get detailsVisibleToShared =>
      'Ces informations sont visibles par les personnes avec qui vous partagez vos animaux';

  @override
  String get profileUpdated => 'Profil mis à jour';

  @override
  String failedToPickPhoto(String error) {
    return 'Échec de la sélection de photo : $error';
  }

  @override
  String failedToSave(String error) {
    return 'Échec de la sauvegarde : $error';
  }

  @override
  String get petGuardian => 'Gardien d\'animal';

  @override
  String get professionalMultiPet => 'Professionnel Multi-Animaux';

  @override
  String categoryLabel(String category) {
    return 'Catégorie : $category';
  }

  @override
  String get firstName => 'Prénom';

  @override
  String get lastName => 'Nom de famille';

  @override
  String get bio => 'Biographie';

  @override
  String get category => 'Catégorie';

  @override
  String get save => 'Enregistrer';

  @override
  String get cancel => 'Annuler';

  @override
  String get delete => 'Supprimer';

  @override
  String get edit => 'Modifier';

  @override
  String get close => 'Fermer';

  @override
  String get retry => 'Réessayer';

  @override
  String get language => 'Langue';

  @override
  String get english => 'English';

  @override
  String get french => 'Français';

  @override
  String get myPets => 'Mes animaux';

  @override
  String get allPets => 'Tous les animaux';

  @override
  String get filterByOrganization => 'Filtrer par organisation';

  @override
  String get notifications => 'Notifications';

  @override
  String get veterinarians => 'Vétérinaires';

  @override
  String get events => 'À faire';

  @override
  String get userMenu => 'Menu utilisateur';

  @override
  String get addPet => 'Ajouter un animal';

  @override
  String get addNewPet => 'Ajouter un nouvel animal';

  @override
  String failedToLoadPets(String error) {
    return 'Échec du chargement des animaux : $error';
  }

  @override
  String get noPetsYet => 'Aucun animal';

  @override
  String get addFirstPet => 'Appuyez sur + pour ajouter votre premier animal';

  @override
  String get petDetails => 'Détails de l\'animal';

  @override
  String get petNotFound => 'Animal introuvable';

  @override
  String errorWithMessage(String error) {
    return 'Erreur : $error';
  }

  @override
  String get goBack => 'Retour';

  @override
  String get editPet => 'Modifier l\'animal';

  @override
  String neuteredSpayed(String date) {
    return 'Stérilisé(e) : $date';
  }

  @override
  String idLabel(String id) {
    return 'ID : $id';
  }

  @override
  String get insuranceDetails => 'Détails de l\'assurance';

  @override
  String get noVetAssigned => 'Aucun vétérinaire assigné';

  @override
  String get addVetFirst => 'Ajouter un vétérinaire. Aucun vétérinaire trouvé.';

  @override
  String get selectVeterinarian => 'Sélectionner un vétérinaire';

  @override
  String get removeVet => 'Retirer le vétérinaire';

  @override
  String get passedAway => 'Décédé(e)';

  @override
  String get weightTracking => 'Suivi du poids';

  @override
  String get addEntry => 'Ajouter un événement santé';

  @override
  String errorLoadingWeightData(String error) {
    return 'Erreur de chargement des données de poids : $error';
  }

  @override
  String get noWeightDataYet => 'Aucune donnée de poids';

  @override
  String get tapAddEntryToStart =>
      'Appuyez sur \"Ajouter une entrée\" pour commencer';

  @override
  String get addWeightEntry => 'Ajouter une entrée de poids';

  @override
  String get selectDate => 'Sélectionner la date pour l\'entrée de poids';

  @override
  String get date => 'Date';

  @override
  String weightWithUnit(String unit) {
    return 'Poids ($unit)';
  }

  @override
  String get notesOptional => 'Notes (facultatif)';

  @override
  String get pleaseEnterValidWeight => 'Veuillez entrer un poids valide';

  @override
  String get deleteWeightEntry => 'Supprimer l\'entrée de poids';

  @override
  String weightChartLabel(int count) {
    return 'Graphique de poids avec $count entrées';
  }

  @override
  String get healthEvents => 'Événements';

  @override
  String get addHealthEntry => 'Ajouter un événement santé';

  @override
  String get noEntriesYet => 'Aucun événement';

  @override
  String noTypeEntriesYet(String type) {
    return 'Aucun événement de type $type';
  }

  @override
  String get tapPlusToAdd => 'Appuyez sur + pour en ajouter';

  @override
  String errorLoadingEntries(String error) {
    return 'Erreur de chargement des événements :\n$error';
  }

  @override
  String get all => 'Tous';

  @override
  String get medications => 'Médicaments';

  @override
  String get preventives => 'Préventifs';

  @override
  String get vetVisits => 'Visites véto';

  @override
  String get other => 'Autre';

  @override
  String get overdue => 'En retard';

  @override
  String get today => 'Aujourd\'hui';

  @override
  String get tomorrow => 'Demain';

  @override
  String get thisWeek => 'Cette semaine';

  @override
  String get later => 'Plus tard';

  @override
  String get completed => 'Terminé';

  @override
  String get groupBy => 'Grouper par';

  @override
  String get byDueDate => 'Par date d\'échéance';

  @override
  String get byPet => 'Par animal';

  @override
  String get bySpecies => 'Par espèce';

  @override
  String get exportPdf => 'Exporter en PDF';

  @override
  String get exportCsv => 'Exporter en CSV';

  @override
  String get csvExport => 'Export CSV';

  @override
  String exportFailed(String error) {
    return 'Échec de l\'export : $error';
  }

  @override
  String pdfExportFailed(String error) {
    return 'Échec de l\'export PDF : $error';
  }

  @override
  String markedAsDone(String name) {
    return '$name marqué comme fait';
  }

  @override
  String snoozedForDays(String name, int days, String dayLabel) {
    return '$name reporté de $days $dayLabel';
  }

  @override
  String get day => 'jour';

  @override
  String get days => 'jours';

  @override
  String get entryName => 'Nom de l\'entrée *';

  @override
  String get entryNameRequired => 'Le nom est requis';

  @override
  String get selectPet => 'Sélectionner un animal *';

  @override
  String get petRequired => 'L\'animal est requis';

  @override
  String get entryType => 'Type *';

  @override
  String get medication => 'Médicament';

  @override
  String get preventive => 'Préventif';

  @override
  String get vetVisit => 'Visite véto';

  @override
  String get procedure => 'Autre';

  @override
  String get dosage => 'Dosage';

  @override
  String get frequency => 'Fréquence';

  @override
  String get doesNotRepeat => 'Ne se répète pas';

  @override
  String get daily => 'Jour';

  @override
  String get weekly => 'Semaine';

  @override
  String get monthly => 'Mois';

  @override
  String get yearly => 'Année';

  @override
  String get custom => 'Personnalisé';

  @override
  String get every => 'Tous les';

  @override
  String everyPeriod(String period) {
    return 'Tous les $period';
  }

  @override
  String everyNPeriods(int n, String periods) {
    return 'Tous les $n $periods';
  }

  @override
  String get repeatEndDate => 'Date de fin de répétition';

  @override
  String get noEndDate => 'Pas de date de fin';

  @override
  String get startDate => 'Date de début';

  @override
  String get nextDueDate => 'Prochaine échéance';

  @override
  String get notes => 'Notes';

  @override
  String get healthIssueOptional => 'Problème de santé (facultatif)';

  @override
  String get none => 'Aucun';

  @override
  String get addHealthEntry2 => 'Ajouter une entrée';

  @override
  String get editEntry => 'Modifier l\'entrée';

  @override
  String get saveEntry => 'Enregistrer';

  @override
  String get deleteEntry => 'Supprimer l\'entrée';

  @override
  String get deleteEntryConfirm =>
      'Êtes-vous sûr de vouloir supprimer cette entrée ?';

  @override
  String get entryCreated => 'Entrée créée';

  @override
  String get entryUpdated => 'Entrée mise à jour';

  @override
  String get entryDeleted => 'Entrée supprimée';

  @override
  String get photos => 'Photos';

  @override
  String get addPhoto => 'Ajouter une photo';

  @override
  String get upTo4Photos => 'jusqu\'à 4 photos, max 2 Mo';

  @override
  String get removePhoto => 'Supprimer la photo';

  @override
  String get failedToPickImage => 'Échec de la sélection d\'image';

  @override
  String get done => 'Fait';

  @override
  String doneOn(String date) {
    return 'Fait le $date';
  }

  @override
  String dueLabel(String date) {
    return 'Échéance $date';
  }

  @override
  String get snooze => 'Reporter';

  @override
  String snoozeEntry(String name) {
    return 'Reporter $name';
  }

  @override
  String snoozeDays(int count, String label) {
    return '$count $label';
  }

  @override
  String get markAsDone => 'Marquer comme fait';

  @override
  String get sharing => 'Partage';

  @override
  String get couldNotLoadSharingInfo =>
      'Impossible de charger les informations de partage';

  @override
  String get sessionExpired => 'Session expirée. Veuillez vous reconnecter.';

  @override
  String get shareLinkTitle => 'Lien de partage';

  @override
  String shareLinkDescription(String petName) {
    return 'Partagez ce lien pour que d\'autres puissent voir le profil de $petName :';
  }

  @override
  String get linkCopied => 'Lien copié dans le presse-papiers';

  @override
  String get copy => 'Copier';

  @override
  String get sharePet => 'Partager l\'animal';

  @override
  String get noOneHasAccess => 'Personne d\'autre n\'a accès pour le moment';

  @override
  String get manageAccess => 'Gérer l\'accès utilisateur';

  @override
  String get removeAccess => 'Retirer l\'accès';

  @override
  String get guardian => 'Gardien';

  @override
  String get viewOnly => 'Lecture seule';

  @override
  String roleLabel(String role) {
    return 'Rôle : $role';
  }

  @override
  String get acceptAndAdd => 'Accepter et ajouter à mes animaux';

  @override
  String get sharedBy => 'Partagé par';

  @override
  String get healthIssues => 'Problèmes de santé';

  @override
  String get addIssue => 'Ajouter un problème';

  @override
  String get editIssue => 'Modifier le problème';

  @override
  String get deleteIssue => 'Supprimer le problème';

  @override
  String get deleteIssueConfirm =>
      'Êtes-vous sûr de vouloir supprimer ce problème de santé ?';

  @override
  String get issueTitle => 'Titre *';

  @override
  String get issueTitleRequired => 'Le titre est requis';

  @override
  String get issueDescription => 'Description';

  @override
  String get create => 'Créer';

  @override
  String get update => 'Mettre à jour';

  @override
  String nEvents(int count) {
    return '$count événement(s)';
  }

  @override
  String get startDateOptional => 'Date de début';

  @override
  String get endDateOptional => 'Date de fin';

  @override
  String get linkedEvents => 'Événements liés';

  @override
  String get noLinkedEvents => 'Aucun événement lié';

  @override
  String get addPetTitle => 'Ajouter un animal';

  @override
  String get editPetTitle => 'Modifier l\'animal';

  @override
  String get petName => 'Nom *';

  @override
  String get petNameRequired => 'Le nom est requis';

  @override
  String get species => 'Espèce *';

  @override
  String get speciesRequired => 'L\'espèce est requise';

  @override
  String get breed => 'Race';

  @override
  String get gender => 'Genre';

  @override
  String get male => 'Mâle';

  @override
  String get female => 'Femelle';

  @override
  String get dateOfBirth => 'Date de naissance';

  @override
  String get weight => 'Poids';

  @override
  String get petBio => 'Biographie';

  @override
  String get insurance => 'Assurance';

  @override
  String get savePet => 'Enregistrer l\'animal';

  @override
  String get deletePet => 'Supprimer l\'animal';

  @override
  String deletePetConfirm(String name) {
    return 'Êtes-vous sûr de vouloir supprimer $name ? Cette action est irréversible.';
  }

  @override
  String petDeleted(String name) {
    return '$name supprimé(e)';
  }

  @override
  String get neuteredSpayedDate => 'Date de stérilisation';

  @override
  String get idMicrochip => 'ID / Puce électronique';

  @override
  String get speciesDog => 'Chien';

  @override
  String get speciesCat => 'Chat';

  @override
  String get speciesBird => 'Oiseau';

  @override
  String get speciesFish => 'Poisson';

  @override
  String get speciesRabbit => 'Lapin';

  @override
  String get speciesHamster => 'Hamster';

  @override
  String get speciesFerret => 'Furet';

  @override
  String get speciesHorsePoney => 'Cheval / Poney';

  @override
  String get speciesOther => 'Autre';

  @override
  String get notificationSettings => 'Paramètres de notification';

  @override
  String get inAppNotifications => 'Notifications dans l\'application';

  @override
  String get overdueAlerts => 'Alertes de retard';

  @override
  String get dueSoonAlerts => 'Alertes d\'échéance proche';

  @override
  String get completedAlerts => 'Alertes de complétion';

  @override
  String get emailReminders => 'Rappels par e-mail';

  @override
  String get emailNotifications => 'Notifications par e-mail';

  @override
  String get reminderDaysBefore => 'Jours de rappel avant';

  @override
  String get mutedPets => 'Animaux en sourdine';

  @override
  String get saveSettings => 'Enregistrer les paramètres';

  @override
  String get settingsSaved => 'Paramètres enregistrés';

  @override
  String get noNotifications => 'Aucune notification';

  @override
  String get markAllRead => 'Tout marquer comme lu';

  @override
  String get notificationSettingsTooltip => 'Paramètres de notification';

  @override
  String get dueSoonAlertsLabel => 'Alertes d\'échéance proche';

  @override
  String get generalLabel => 'Général';

  @override
  String get addVet => 'Ajouter un vétérinaire';

  @override
  String get editVet => 'Modifier le vétérinaire';

  @override
  String get addNewVet => 'Ajouter un nouveau vétérinaire';

  @override
  String get backToVets => 'Retour aux vétérinaires';

  @override
  String get vetName => 'Nom *';

  @override
  String get vetNameRequired => 'Le nom est requis';

  @override
  String get phone => 'Téléphone';

  @override
  String get vetEmail => 'E-mail';

  @override
  String get website => 'Site web';

  @override
  String get address => 'Adresse';

  @override
  String get vetNotes => 'Notes';

  @override
  String get deleteVet => 'Supprimer le vétérinaire';

  @override
  String deleteVetConfirm(String name) {
    return 'Êtes-vous sûr de vouloir supprimer $name ?';
  }

  @override
  String get noVetsYet => 'Aucun vétérinaire';

  @override
  String failedToLoadVets(String error) {
    return 'Échec du chargement des vétérinaires : $error';
  }

  @override
  String failedToLoadVet(String error) {
    return 'Échec du chargement du vétérinaire : $error';
  }

  @override
  String get vetOptions => 'Options du vétérinaire';

  @override
  String get linkedPets => 'Animaux liés';

  @override
  String couldNotLoadPets(String error) {
    return 'Impossible de charger les animaux : $error';
  }

  @override
  String get noPetsAddFirst =>
      'Aucun animal. Ajoutez d\'abord des animaux pour les lier.';

  @override
  String get unlink => 'Délier';

  @override
  String get link => 'Lier';

  @override
  String get availablePets => 'Animaux disponibles :';

  @override
  String get subscriptionTitle => 'Abonnement';

  @override
  String get welcomeUnlimited => 'Bienvenue dans Agatha Track Illimité !';

  @override
  String purchaseFailed(String error) {
    return 'Échec de l\'achat : $error';
  }

  @override
  String get purchasesRestored => 'Achats restaurés avec succès';

  @override
  String couldNotRestore(String error) {
    return 'Impossible de restaurer les achats : $error';
  }

  @override
  String get restorePurchases => 'Restaurer les achats';

  @override
  String get manageSubscription => 'Gérer l\'abonnement';

  @override
  String get subscribe => 'S\'abonner';

  @override
  String get loadPlans => 'Charger les forfaits';

  @override
  String get petReport => 'Rapport de l\'animal';

  @override
  String get chooseSections => 'Choisissez les sections à inclure';

  @override
  String get petProfile => 'Profil de l\'animal';

  @override
  String get basicInfoVet => 'Informations de base, détails du vétérinaire';

  @override
  String get chartAndDataTable => 'Graphique et tableau de données';

  @override
  String get medicationsPreventivesVetVisits =>
      'Médicaments, préventifs, visites véto';

  @override
  String get includeFullLog =>
      'Inclure l\'historique complet pour chaque événement';

  @override
  String get ongoingConditions => 'Pathologies en cours et événements liés';

  @override
  String get sharingSection => 'Partage';

  @override
  String get accessListAndRoles => 'Liste d\'accès et rôles';

  @override
  String get downloadReport => 'Télécharger le rapport';

  @override
  String get downloadPetReport => 'Télécharger le rapport de l\'animal';

  @override
  String get generating => 'Génération...';

  @override
  String get reportGenerated => 'Rapport téléchargé';

  @override
  String reportFailed(String error) {
    return 'Échec du rapport : $error';
  }

  @override
  String get passedAwayConfirmTitle => 'Marquer comme décédé';

  @override
  String passedAwayConfirmMessage(String name) {
    return 'Êtes-vous sûr de vouloir marquer $name comme ayant traversé le pont de l\'arc-en-ciel ?';
  }

  @override
  String passedAwayCondolence(String name) {
    return 'Nous sommes sincèrement désolés pour votre perte. Le profil de $name sera conservé comme un mémorial affectueux.';
  }

  @override
  String get confirm => 'Confirmer';

  @override
  String get ok => 'OK';

  @override
  String get reminderSnooze =>
      'Rappel reporté. Nous vous rappellerons plus tard.';

  @override
  String get dontWantToNeuter => 'Je ne souhaite pas stériliser';

  @override
  String get dontWantToChip => 'Je ne souhaite pas identifier mon animal';

  @override
  String get chipReminderDog =>
      'La puce électronique est recommandée pour les chiens. C\'est une procédure simple qui permet de vous retrouver si votre animal se perd.';

  @override
  String get chipReminderCat =>
      'La puce électronique est recommandée pour les chats. Elle permet d\'identifier votre chat et de le retrouver s\'il s\'éloigne.';

  @override
  String get chipReminderFerret =>
      'La puce électronique est recommandée pour les furets. Elle permet d\'identifier votre animal s\'il s\'échappe.';

  @override
  String get chipReminderRabbit =>
      'La puce électronique est recommandée pour les lapins. Elle fournit une identification permanente.';

  @override
  String get chipReminderHorse =>
      'Un passeport est recommandé pour les chevaux et les poneys. C\'est une obligation légale dans de nombreux pays.';

  @override
  String get chipReminderBird =>
      'Une bague de patte est recommandée pour les oiseaux. Elle permet d\'identifier votre oiseau s\'il s\'envole.';

  @override
  String get chipReminderFish =>
      'Une étiquette d\'aquarium est recommandée pour les poissons. Elle aide à suivre les espèces et les besoins de soins.';

  @override
  String get chipReminderHamster =>
      'Un enregistrement photo d\'identification est recommandé pour les hamsters. Gardez une photo à des fins d\'identification.';

  @override
  String get chipReminderDefault =>
      'Une méthode d\'identification est recommandée pour votre animal.';

  @override
  String get neuterReminderTitle => 'Rappel de stérilisation';

  @override
  String get chipReminderTitle => 'Rappel d\'identification';

  @override
  String get pdfEventsChecklist => 'Liste des événements';

  @override
  String get pdfAllEvents => 'Tous les événements';

  @override
  String pdfGroupedBy(String filter, String group) {
    return '$filter  •  Groupé $group';
  }

  @override
  String get pdfNoEventsToDisplay => 'Aucun événement à afficher.';

  @override
  String pdfGeneratedBy(String date) {
    return 'Généré le $date par Agatha Track';
  }

  @override
  String pdfPageOf(int current, int total) {
    return 'Page $current sur $total';
  }

  @override
  String get pdfPetLabel => 'Animal';

  @override
  String get pdfDueLabel => 'Échéance';

  @override
  String get pdfFreqLabel => 'Fréq';

  @override
  String get pdfNotesLabel => 'Notes';

  @override
  String get pdfIssueLabel => 'Problème';

  @override
  String get pdfOnce => 'Une fois';

  @override
  String get pdfDone => 'Fait';

  @override
  String get pdfReportTitle => 'Rapport Santé Animal';

  @override
  String get pdfAgathaCheck => 'AGATHA CHECK';

  @override
  String get pdfPetProfileSection => 'Profil de l\'animal';

  @override
  String get pdfWeightTrackingSection => 'Suivi du poids';

  @override
  String get pdfHealthEventsSection => 'Événements santé';

  @override
  String get pdfHealthIssuesSection => 'Problèmes de santé';

  @override
  String get pdfSharingSection => 'Partage';

  @override
  String get pdfNoWeightData => 'Aucune donnée de poids enregistrée.';

  @override
  String get pdfNoHealthEvents => 'Aucun événement santé enregistré.';

  @override
  String get pdfNoHealthIssues => 'Aucun problème de santé enregistré.';

  @override
  String get pdfCurrentRecurring => 'Événements en cours et récurrents';

  @override
  String pdfEventsFromTo(String from, String to) {
    return 'Événements du $from au $to';
  }

  @override
  String get pdfNoEventsInPeriod => 'Aucun événement dans cette période.';

  @override
  String get pdfAdminLog => 'Journal d\'administration';

  @override
  String get pdfName => 'Nom';

  @override
  String get pdfSpecies => 'Espèce';

  @override
  String get pdfBreed => 'Race';

  @override
  String get pdfGender => 'Genre';

  @override
  String get pdfAge => 'Âge';

  @override
  String get pdfDateOfBirth => 'Date de naissance';

  @override
  String get pdfCurrentWeight => 'Poids actuel';

  @override
  String get pdfBio => 'Biographie';

  @override
  String get pdfNeuteredSpayed => 'Stérilisé(e)';

  @override
  String get pdfIdMicrochip => 'ID / Puce électronique';

  @override
  String get pdfInsurance => 'Détails de l\'assurance';

  @override
  String get pdfVet => 'Vétérinaire';

  @override
  String get pdfDate => 'Date';

  @override
  String get pdfWeight => 'Poids';

  @override
  String get pdfNotes => 'Notes';

  @override
  String get pdfType => 'Type';

  @override
  String get pdfFrequency => 'Fréquence';

  @override
  String get pdfNextDue => 'Prochaine échéance';

  @override
  String get pdfDosage => 'Dosage';

  @override
  String get pdfStart => 'Début';

  @override
  String get pdfDue => 'Échéance';

  @override
  String get pdfCompleted => 'Terminé';

  @override
  String get pdfNotShared => 'Cet animal n\'est partagé avec personne.';

  @override
  String get pdfRole => 'Rôle';

  @override
  String get pdfSince => 'Depuis';

  @override
  String get pdfGuardian => 'Gardien';

  @override
  String get pdfShared => 'Partagé';

  @override
  String pdfUserNumber(String id) {
    return 'Utilisateur #$id';
  }

  @override
  String pdfNEvent(int count) {
    return '$count événement';
  }

  @override
  String pdfNEvents(int count) {
    return '$count événements';
  }

  @override
  String pdfFrom(String date) {
    return 'Depuis le $date';
  }

  @override
  String pdfUntil(String date) {
    return 'Jusqu\'au $date';
  }

  @override
  String get pdfLinkedEvents => 'Événements liés';

  @override
  String get pdfCustom => 'Personnalisé';

  @override
  String pdfEvery(String period) {
    return 'Tous les $period';
  }

  @override
  String pdfEveryN(int n, String periods) {
    return 'Tous les $n $periods';
  }

  @override
  String get myOrganizations => 'Mes organisations';

  @override
  String get organizations => 'Organisations';

  @override
  String get createOrganization => 'Créer une organisation';

  @override
  String get editOrganization => 'Modifier l\'organisation';

  @override
  String get deleteOrganization => 'Supprimer l\'organisation';

  @override
  String get organizationName => 'Nom de l\'organisation';

  @override
  String get organizationType => 'Type';

  @override
  String get orgTypeProfessional => 'Professionnel';

  @override
  String get orgTypeCharity => 'Association';

  @override
  String get orgEmail => 'E-mail';

  @override
  String get orgPhone => 'Téléphone';

  @override
  String get orgAddress => 'Adresse';

  @override
  String get orgWebsite => 'Site web';

  @override
  String get orgBio => 'Description';

  @override
  String get orgMembers => 'Membres';

  @override
  String get orgPets => 'Animaux';

  @override
  String get orgArchived => 'Animaux archivés';

  @override
  String get orgNoOrganizations => 'Aucune organisation';

  @override
  String get orgCreateFirst =>
      'Créez votre première organisation pour commencer';

  @override
  String get createOrJoinOrganization => 'Créer ou rejoindre une organisation';

  @override
  String get joinOrganization => 'Rejoindre une organisation';

  @override
  String get enterInviteCode =>
      'Entrez le code d\'invitation que vous avez reçu';

  @override
  String get inviteCode => 'Code d\'invitation';

  @override
  String get joinSuccess => 'Organisation rejointe avec succès';

  @override
  String get join => 'Rejoindre';

  @override
  String get orgSuperUser => 'Super utilisateur';

  @override
  String get orgMember => 'Membre';

  @override
  String get orgInviteMember => 'Inviter un membre';

  @override
  String get orgInviteLinkCopied => 'Lien d\'invitation copié';

  @override
  String get orgInviteExpiry => 'Ce lien d\'invitation expire dans 7 jours';

  @override
  String get orgJoinSuccess => 'Organisation rejointe avec succès';

  @override
  String get orgLeave => 'Quitter l\'organisation';

  @override
  String get orgLeaveConfirm =>
      'Êtes-vous sûr de vouloir quitter cette organisation ?';

  @override
  String get orgRemoveMember => 'Retirer le membre';

  @override
  String get orgRemoveMemberConfirm =>
      'Êtes-vous sûr de vouloir retirer ce membre ?';

  @override
  String get orgChangeRole => 'Changer le rôle';

  @override
  String get orgPromoteToSuperUser => 'Promouvoir en super utilisateur';

  @override
  String get orgDemoteToMember => 'Rétrograder en membre';

  @override
  String get orgDeleteConfirm =>
      'Êtes-vous sûr de vouloir supprimer cette organisation ? Cette action est irréversible.';

  @override
  String get orgDeleteRequireNoPets =>
      'Transférez ou retirez tous les animaux avant de supprimer';

  @override
  String get orgNoPets => 'Aucun animal dans cette organisation';

  @override
  String get orgNoMembers => 'Aucun membre';

  @override
  String get orgNoArchived => 'Aucun enregistrement archivé';

  @override
  String get orgAddPet => 'Ajouter un animal';

  @override
  String get transferPet => 'Transférer l\'animal';

  @override
  String get transferToUser => 'Transférer à un utilisateur';

  @override
  String get transferToOrganization => 'Transférer à une organisation';

  @override
  String get transferType => 'Type de transfert';

  @override
  String get transferTypeAdoption => 'Adoption';

  @override
  String get transferTypeTransfer => 'Transfert';

  @override
  String get transferTypeRelease => 'Libération';

  @override
  String get transferTypeOther => 'Autre';

  @override
  String get recipientEmail => 'E-mail du destinataire';

  @override
  String get transferNotes => 'Notes (facultatif)';

  @override
  String get confirmTransfer => 'Confirmer le transfert';

  @override
  String get transferConfirmTitle => 'Confirmer le transfert';

  @override
  String transferConfirmMessage(String petName) {
    return 'Êtes-vous sûr de vouloir transférer $petName ? Cette action est irréversible.';
  }

  @override
  String get transferSuccess => 'Animal transféré avec succès';

  @override
  String get archivedPets => 'Animaux archivés';

  @override
  String archivedOn(String date) {
    return 'Archivé le $date';
  }

  @override
  String get noArchivedPets => 'Aucun animal archivé';

  @override
  String get orgNameRequired => 'Le nom de l\'organisation est requis';

  @override
  String get orgCreated => 'Organisation créée';

  @override
  String get orgUpdated => 'Organisation mise à jour';

  @override
  String get orgDeleted => 'Organisation supprimée';

  @override
  String memberCount(int count) {
    return '$count membres';
  }

  @override
  String petCount(int count) {
    return '$count animaux';
  }

  @override
  String get remindBefore => 'Me rappeler';

  @override
  String get daysBefore => 'jour(s) avant';

  @override
  String get undoComplete => 'Annuler\nTerminé';

  @override
  String undoCompleteDone(String name) {
    return '$name marqué comme non terminé';
  }

  @override
  String get addUser => 'Ajouter un utilisateur';

  @override
  String get inviteByEmail => 'Inviter par e-mail';

  @override
  String get sendInvite => 'Envoyer l\'invitation';

  @override
  String get selectRole => 'Sélectionner le rôle';

  @override
  String get inviteSent => 'Invitation envoyée avec succès';

  @override
  String get pendingInvites => 'Invitations en attente';

  @override
  String inviteToJoinOrg(String orgName) {
    return 'Vous avez été invité(e) à rejoindre $orgName';
  }

  @override
  String inviteAsRole(String role) {
    return 'en tant que $role';
  }

  @override
  String get acceptInvite => 'Accepter';

  @override
  String get declineInvite => 'Refuser';

  @override
  String get userNotFound => 'Aucun utilisateur trouvé avec cet e-mail';

  @override
  String get inviteAccepted => 'Invitation acceptée';

  @override
  String get inviteDeclined => 'Invitation refusée';

  @override
  String get alreadyMember => 'Cet utilisateur est déjà membre';

  @override
  String get enterEmail => 'Entrez l\'adresse e-mail de l\'utilisateur';

  @override
  String invitedBy(String name) {
    return 'Invité(e) par $name';
  }

  @override
  String get people => 'Personnes';

  @override
  String assignedPets(int count) {
    return '$count animaux assignés';
  }

  @override
  String get familyEvents => 'Événements familiaux';

  @override
  String get noFamilyEvents => 'Aucun événement familial';

  @override
  String get addFamilyEvent => 'Ajouter un événement familial';

  @override
  String get editFamilyEvent => 'Modifier l\'événement familial';

  @override
  String get deleteFamilyEventConfirm =>
      'Êtes-vous sûr de vouloir supprimer cet événement familial ?';

  @override
  String get assignedToMember => 'Assigné à';

  @override
  String get unassigned => 'Non assigné';

  @override
  String get fromDateLabel => 'Date de début';

  @override
  String get toDateLabel => 'Date de fin';

  @override
  String get optional => 'optionnel';

  @override
  String get assignTo => 'Attribuer à';

  @override
  String get assignToHint => 'Attribuer un membre à cet animal (optionnel)';

  @override
  String get assignedMember => 'Membre attribué';

  @override
  String get notAssigned => 'Non attribué';

  @override
  String get autoAssignedToYou =>
      'Vous serez automatiquement attribué à cet animal';

  @override
  String get notSet => 'Non défini';

  @override
  String get petOwnership => 'Propriété de l\'animal';

  @override
  String get myPet => 'Mon animal';

  @override
  String get orgPet => 'Animal de l\'organisation';

  @override
  String get pendingShares => 'Partages en attente';

  @override
  String petSharedWithYou(String guardianName, String petName) {
    return '$guardianName souhaite partager $petName avec vous';
  }

  @override
  String get acceptShare => 'Accepter';

  @override
  String get declineShare => 'Refuser';

  @override
  String get shareAccepted => 'Partage accepté';

  @override
  String get acceptShareTo => 'Accepter l\'animal dans…';

  @override
  String get acceptShareToHint =>
      'Choisissez où cet animal partagé doit apparaître.';

  @override
  String get shareDeclined => 'Partage refusé';

  @override
  String get sharedPets => 'Animaux partagés';

  @override
  String get invited => 'Invité(e)';

  @override
  String get pendingInvite => 'En attente';

  @override
  String get hideSharedPet => 'Masquer l\'animal';

  @override
  String get hide => 'Masquer';

  @override
  String get unhide => 'Afficher';

  @override
  String hideSharedPetConfirm(String petName) {
    return 'Masquer $petName ? Vous ne le verrez plus dans votre liste, vos événements ou vos notifications. Vous pourrez le réafficher depuis la page de l\'organisation.';
  }

  @override
  String petHidden(String petName) {
    return '$petName a été masqué';
  }

  @override
  String petUnhidden(String petName) {
    return '$petName est de nouveau visible';
  }

  @override
  String get hiddenSharedPets => 'Animaux partagés masqués';
}
