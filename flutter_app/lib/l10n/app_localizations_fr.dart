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
      'Agatha Track organise la santé de vos animaux — que vous soyez un particulier, un refuge ou une organisation professionnelle.';

  @override
  String get appDescription =>
      'Suivez les visites vétérinaires, les médicaments, le poids et les soins quotidiens dans un tableau de bord simple. Créez des organisations pour collaborer avec votre équipe, partager des animaux et coordonner les soins sur tout votre réseau.';

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
  String get pdfAgathaCheck => 'AGATHA TRACK';

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
  String get pdfFamilyEventsSection => 'Événements familiaux';

  @override
  String get pdfNoFamilyEvents =>
      'Aucun événement familial enregistré pour cet animal.';

  @override
  String get pdfAssignedTo => 'Assigné à';

  @override
  String get pdfFromDate => 'Du';

  @override
  String get pdfToDate => 'Au';

  @override
  String get pdfOngoing => 'En cours';

  @override
  String get pdfNotificationsSection => 'Notifications';

  @override
  String get pdfNoNotifications =>
      'Aucune notification récente pour cet animal.';

  @override
  String get pdfNotificationType => 'Type';

  @override
  String get pdfNotificationMessage => 'Message';

  @override
  String get familyEventsSection => 'Événements familiaux';

  @override
  String get familyEventsDesc =>
      'Affectations de soins et séjours en famille d\'accueil';

  @override
  String get notificationsSection => 'Notifications';

  @override
  String get notificationsDesc => 'Alertes et rappels récents';

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

  @override
  String get help => 'Aide';

  @override
  String get helpTitle => 'Aide & FAQ';

  @override
  String get helpSubtitle =>
      'Trouvez les réponses à vos questions sur toutes les fonctionnalités d\'Agatha Track.';

  @override
  String get faqAccountTitle => 'Compte & Authentification';

  @override
  String get faqAccountQ1 => 'Comment créer un compte ?';

  @override
  String get faqAccountA1 =>
      'Appuyez sur « S\'inscrire » sur la page d\'accueil. Saisissez votre adresse e-mail, choisissez un mot de passe et indiquez votre prénom et nom. Vous serez connecté automatiquement après l\'inscription.';

  @override
  String get faqAccountQ2 => 'Comment me connecter ?';

  @override
  String get faqAccountA2 =>
      'Appuyez sur « Se connecter » sur la page d\'accueil et entrez votre e-mail et mot de passe. Votre session reste active jusqu\'à la déconnexion.';

  @override
  String get faqAccountQ3 =>
      'J\'ai oublié mon mot de passe — comment le réinitialiser ?';

  @override
  String get faqAccountA3 =>
      'Sur l\'écran de connexion, appuyez sur « Mot de passe oublié ? ». Entrez l\'adresse e-mail associée à votre compte et suivez les instructions pour définir un nouveau mot de passe.';

  @override
  String get faqAccountQ4 => 'Comment modifier mon profil ?';

  @override
  String get faqAccountA4 =>
      'Allez dans le menu utilisateur (votre avatar en haut à droite), puis appuyez sur « Mes informations ». Vous pouvez modifier votre nom, bio, photo de profil et changer votre mot de passe.';

  @override
  String get faqAccountQ5 => 'Comment me déconnecter ?';

  @override
  String get faqAccountA5 =>
      'Ouvrez le menu utilisateur (icône avatar en haut à droite) et appuyez sur « Déconnexion ». Vous serez redirigé vers la page d\'accueil.';

  @override
  String get faqPetProfileTitle => 'Profils des animaux';

  @override
  String get faqPetProfileQ1 => 'Comment ajouter un nouvel animal ?';

  @override
  String get faqPetProfileA1 =>
      'Appuyez sur le bouton « + » sur l\'écran de la liste des animaux. Renseignez le nom, l\'espèce, la race, la date de naissance et les détails optionnels comme le numéro de puce et la photo. Chaque animal reçoit une couleur unique pour l\'identifier facilement.';

  @override
  String get faqPetProfileQ2 => 'Comment modifier ou supprimer un animal ?';

  @override
  String get faqPetProfileA2 =>
      'Appuyez sur la carte de l\'animal pour ouvrir sa page de détail. Utilisez l\'icône de modification en haut à droite pour mettre à jour les informations. Pour supprimer un animal, utilisez l\'option de suppression — notez que cela supprime définitivement toutes les entrées de santé, les relevés de poids et les autres données associées.';

  @override
  String get faqPetProfileQ3 => 'Que signifie le rappel d\'identification ?';

  @override
  String get faqPetProfileA3 =>
      'Si votre animal n\'a pas de numéro d\'identification (puce ou tatouage) enregistré, un rappel spécifique à l\'espèce apparaîtra sur la carte de l\'animal. Vous pouvez ignorer ce rappel ou ajouter l\'identifiant dans le formulaire de modification.';

  @override
  String get faqPetProfileQ4 => 'Comment marquer un animal comme décédé ?';

  @override
  String get faqPetProfileA4 =>
      'Ouvrez le formulaire de modification de l\'animal et activez l\'option « Décédé ». Cela change la couleur de l\'animal en blanc, ajoute une icône de mémorial sur la photo et envoie une notification. L\'animal reste dans votre liste en tant que mémorial.';

  @override
  String get faqPetProfileQ5 => 'Quel est le système de couleurs des animaux ?';

  @override
  String get faqPetProfileA5 =>
      'Chaque animal se voit attribuer une couleur unique parmi une palette de 15 couleurs lors de sa création. Cette couleur apparaît sur les cartes, les graphiques et dans toute l\'application pour identifier rapidement chaque animal.';

  @override
  String get faqPetProfileQ6 => 'Comment l\'âge de mon animal est-il calculé ?';

  @override
  String get faqPetProfileA6 =>
      'L\'âge est calculé automatiquement à partir de la date de naissance saisie. Il se met à jour dynamiquement et s\'affiche sur la page de détail et les cartes de profil.';

  @override
  String get faqHealthTitle => 'Suivi de santé';

  @override
  String get faqHealthQ1 => 'Quels types d\'entrées de santé puis-je suivre ?';

  @override
  String get faqHealthA1 =>
      'Vous pouvez suivre les médicaments, les traitements préventifs (vaccins, vermifuges, antiparasitaires), les visites vétérinaires et les procédures médicales. Chaque type a sa propre icône et couleur dans le tableau de bord.';

  @override
  String get faqHealthQ2 => 'Comment ajouter une entrée de santé ?';

  @override
  String get faqHealthA2 =>
      'Vous pouvez ajouter des entrées depuis deux endroits : la page de détail de l\'animal (spécifique à cet animal) ou le Tableau de bord santé global (accessible depuis l\'icône médicale dans la barre du haut). Renseignez le type, le nom, la date et les détails optionnels.';

  @override
  String get faqHealthQ3 => 'Qu\'est-ce que le Tableau de bord santé ?';

  @override
  String get faqHealthA3 =>
      'Le Tableau de bord santé est une vue globale de tous les événements de santé de tous vos animaux. Il est organisé en onglets par type et affiche les entrées à venir, dues et en retard. Vous pouvez filtrer par organisation.';

  @override
  String get faqHealthQ4 =>
      'Comment fonctionnent les entrées de santé récurrentes ?';

  @override
  String get faqHealthA4 =>
      'Lors de la création d\'une entrée de santé, vous pouvez définir une fréquence (quotidienne, hebdomadaire, mensuelle, annuelle ou un nombre de jours personnalisé). L\'application planifiera automatiquement la prochaine occurrence et vous notifiera.';

  @override
  String get faqHealthQ5 => 'Que sont les Problèmes de santé ?';

  @override
  String get faqHealthA5 =>
      'Les Problèmes de santé permettent de suivre les affections médicales en cours (allergies, maladies chroniques). Chaque problème peut avoir une date de début, une date de fin optionnelle et être lié à des entrées de santé pour un historique médical complet.';

  @override
  String get faqHealthQ6 => 'Puis-je joindre des photos aux entrées de santé ?';

  @override
  String get faqHealthA6 =>
      'Oui. Lors de la création ou de la modification d\'une entrée de santé, vous pouvez joindre une photo — par exemple une ordonnance, des résultats d\'analyse ou une photo de blessure. La photo est stockée avec l\'entrée.';

  @override
  String get faqWeightTitle => 'Suivi du poids';

  @override
  String get faqWeightQ1 => 'Comment enregistrer le poids de mon animal ?';

  @override
  String get faqWeightA1 =>
      'Ouvrez la page de détail de l\'animal et faites défiler jusqu\'à la section Poids. Appuyez sur le bouton d\'ajout pour saisir un nouveau relevé de poids. Vous pouvez choisir entre kilogrammes (kg) et livres (lb).';

  @override
  String get faqWeightQ2 =>
      'Comment les données de poids sont-elles affichées ?';

  @override
  String get faqWeightA2 =>
      'L\'historique de poids est affiché sous forme de graphique linéaire interactif sur la page de détail de l\'animal. Vous pouvez voir les tendances et appuyer sur les points pour les détails. Le graphique utilise la couleur unique de votre animal.';

  @override
  String get faqWeightQ3 => 'Puis-je basculer entre kg et lb ?';

  @override
  String get faqWeightA3 =>
      'Oui. Utilisez le bouton de changement d\'unité dans la section poids pour basculer entre kilogrammes et livres. La conversion est appliquée à toutes les valeurs affichées.';

  @override
  String get faqVetTitle => 'Gestion des vétérinaires';

  @override
  String get faqVetQ1 => 'Comment ajouter un vétérinaire ?';

  @override
  String get faqVetA1 =>
      'Allez dans la section Vétérinaires (accessible depuis l\'icône stéthoscope dans la barre du haut). Appuyez sur le bouton « + » et renseignez le nom de la clinique, le nom du vétérinaire, le téléphone, l\'e-mail, l\'adresse et le site web.';

  @override
  String get faqVetQ2 => 'Comment associer un vétérinaire à mon animal ?';

  @override
  String get faqVetA2 =>
      'Lors de la modification du profil d\'un animal, vous pouvez sélectionner un vétérinaire dans votre liste enregistrée. Cela lie le vétérinaire à l\'animal pour un accès rapide à ses coordonnées depuis la page de détail.';

  @override
  String get faqVetQ3 => 'Puis-je modifier ou supprimer un vétérinaire ?';

  @override
  String get faqVetA3 =>
      'Oui. Depuis la liste des vétérinaires, appuyez sur un vétérinaire pour voir ses détails, puis utilisez les options de modification ou de suppression. La suppression d\'un vétérinaire retire le lien avec les animaux associés mais ne supprime pas les animaux.';

  @override
  String get faqSharingTitle => 'Partage d\'animaux';

  @override
  String get faqSharingQ1 => 'Comment partager un animal avec quelqu\'un ?';

  @override
  String get faqSharingA1 =>
      'Ouvrez la page de détail de l\'animal et utilisez l\'option de partage pour générer un lien. Envoyez ce lien à la personne souhaitée. Lorsqu\'elle l\'accepte, elle verra l\'animal dans sa liste.';

  @override
  String get faqSharingQ2 =>
      'Que se passe-t-il quand quelqu\'un accepte un partage ?';

  @override
  String get faqSharingA2 =>
      'Le destinataire reçoit une notification avec le partage en attente. Il peut choisir de placer l\'animal partagé dans sa liste personnelle ou dans une organisation à laquelle il appartient. L\'animal apparaît avec un badge « partagé ».';

  @override
  String get faqSharingQ3 => 'Puis-je masquer un animal partagé ?';

  @override
  String get faqSharingA3 =>
      'Oui. Faites glisser vers la gauche sur la carte d\'un animal partagé pour le masquer. Les animaux masqués n\'apparaîtront pas dans votre liste, votre tableau de bord santé, et ne généreront pas de notifications. Vous pouvez les réafficher depuis la page de détail de l\'organisation.';

  @override
  String get faqSharingQ4 =>
      'Quelle est la différence entre partager et transférer ?';

  @override
  String get faqSharingA4 =>
      'Le partage donne un accès en lecture à un animal — le propriétaire d\'origine garde le contrôle total. Le transfert (disponible pour les animaux d\'organisation) transfère la propriété de l\'animal à un autre utilisateur ou organisation.';

  @override
  String get faqOrgTitle => 'Organisations';

  @override
  String get faqOrgQ1 => 'À quoi servent les organisations ?';

  @override
  String get faqOrgA1 =>
      'Les organisations permettent à plusieurs personnes de collaborer sur les soins des animaux. Elles sont idéales pour les cliniques vétérinaires, les refuges, les associations et les réseaux de familles d\'accueil. Vous pouvez créer des organisations Professionnelles ou Caritatives.';

  @override
  String get faqOrgQ2 => 'Comment créer une organisation ?';

  @override
  String get faqOrgA2 =>
      'Allez sur la page Organisations (accessible depuis l\'icône entreprise dans la barre du haut ou depuis Mes informations). Appuyez sur « Créer » et choisissez Professionnelle ou Caritative, puis renseignez le nom et les détails. Vous devenez automatiquement super utilisateur.';

  @override
  String get faqOrgQ3 =>
      'Comment inviter des personnes dans mon organisation ?';

  @override
  String get faqOrgA3 =>
      'Depuis la page de détail de l\'organisation, appuyez sur « Ajouter un utilisateur ». Entrez l\'adresse e-mail de la personne et choisissez son rôle — « Membre » ou « Super utilisateur ». Elle recevra une invitation en attente qu\'elle peut accepter ou refuser.';

  @override
  String get faqOrgQ4 =>
      'Quelle est la différence entre Membre et Super utilisateur ?';

  @override
  String get faqOrgA4 =>
      'Les membres peuvent voir et gérer les animaux de l\'organisation. Les super utilisateurs ont des permissions supplémentaires : inviter ou retirer des membres, modifier les détails de l\'organisation, transférer des animaux et gérer les archives.';

  @override
  String get faqOrgQ5 =>
      'Comment archiver ou restaurer un animal dans une organisation ?';

  @override
  String get faqOrgA5 =>
      'Les super utilisateurs peuvent archiver un animal depuis la liste des animaux de l\'organisation (par exemple après une adoption). Les animaux archivés sont masqués de la liste active mais conservés. Ils peuvent être restaurés à tout moment depuis la section Animaux archivés.';

  @override
  String get faqFamilyEventsTitle => 'Événements familiaux';

  @override
  String get faqFamilyEventsQ1 => 'Que sont les événements familiaux ?';

  @override
  String get faqFamilyEventsA1 =>
      'Les événements familiaux sont des affectations de soins pour les animaux d\'organisation. Ils enregistrent qui est responsable d\'un animal pendant une période donnée — comme un séjour en famille d\'accueil. Chaque événement a un membre assigné, une plage de dates et des notes optionnelles.';

  @override
  String get faqFamilyEventsQ2 => 'Comment créer un événement familial ?';

  @override
  String get faqFamilyEventsA2 =>
      'Ouvrez la page de détail d\'un animal d\'organisation et faites défiler jusqu\'à la section Événements familiaux. Appuyez sur le bouton d\'ajout, choisissez le membre assigné, définissez les dates et ajoutez des notes. Tous les membres de l\'organisation seront notifiés.';

  @override
  String get faqFamilyEventsQ3 =>
      'Les événements familiaux apparaissent-ils dans le tableau de bord santé ?';

  @override
  String get faqFamilyEventsA3 =>
      'Oui. Les événements familiaux ont leur propre onglet dédié dans le tableau de bord santé. Ils déclenchent également des rappels lorsque la date de fin approche.';

  @override
  String get faqNotificationsTitle => 'Notifications';

  @override
  String get faqNotificationsQ1 => 'Quelles notifications vais-je recevoir ?';

  @override
  String get faqNotificationsA1 =>
      'Vous recevrez des notifications dans l\'application pour : les entrées de santé dues ou en retard, les rappels de médicaments, les invitations d\'organisation, les demandes de partage, les mémoriaux et les rappels d\'événements familiaux.';

  @override
  String get faqNotificationsQ2 =>
      'Comment gérer mes préférences de notification ?';

  @override
  String get faqNotificationsA2 =>
      'Allez sur l\'écran Notifications (icône cloche dans la barre du haut) et appuyez sur l\'icône paramètres. Vous pouvez personnaliser les types de notifications que vous souhaitez recevoir.';

  @override
  String get faqNotificationsQ3 =>
      'Puis-je désactiver les notifications pour un animal spécifique ?';

  @override
  String get faqNotificationsA3 =>
      'Oui. Chaque animal a une option de mise en sourdine dans ses paramètres de notification. Les animaux mis en sourdine ne généreront aucune notification de santé tant qu\'ils ne seront pas réactivés.';

  @override
  String get faqNotificationsQ4 => 'Puis-je reporter une notification ?';

  @override
  String get faqNotificationsA4 =>
      'Oui. Vous pouvez reporter des notifications individuelles pour être rappelé après un nombre de jours choisi. Le rappel reporté réapparaîtra en comptant à partir d\'aujourd\'hui, pas de la date d\'échéance d\'origine.';

  @override
  String get faqReportsTitle => 'Rapports';

  @override
  String get faqReportsQ1 => 'Comment générer un rapport pour un animal ?';

  @override
  String get faqReportsA1 =>
      'Ouvrez la page de détail d\'un animal et appuyez sur l\'icône rapport/PDF. Vous pouvez personnaliser le contenu — informations de profil, historique de poids, événements de santé, problèmes de santé, événements familiaux, notifications et détails de partage. Le rapport est généré en PDF téléchargeable.';

  @override
  String get faqReportsQ2 =>
      'Quelles informations sont incluses dans un rapport ?';

  @override
  String get faqReportsA2 =>
      'Les rapports peuvent inclure : les détails du profil (nom, race, âge, ID), un graphique de poids et tableau d\'historique, une liste de toutes les entrées de santé par type, les problèmes de santé enregistrés, les affectations et séjours en famille d\'accueil (pour les animaux d\'organisation), les notifications et alertes récentes, et les détails de partage. Vous choisissez les sections à inclure.';

  @override
  String get faqSubscriptionTitle => 'Abonnement';

  @override
  String get faqSubscriptionQ1 => 'Agatha Track est-il gratuit ?';

  @override
  String get faqSubscriptionA1 =>
      'Agatha Track propose un niveau gratuit avec les fonctionnalités essentielles. Un abonnement premium optionnel débloque des fonctionnalités supplémentaires. Visitez la page Abonnement depuis Mes informations pour en savoir plus.';

  @override
  String get faqSubscriptionQ2 => 'Comment m\'abonner ?';

  @override
  String get faqSubscriptionA2 =>
      'Allez dans Mes informations et appuyez sur « Abonnement ». Choisissez un forfait et finalisez l\'achat via le système de paiement de votre plateforme. Votre abonnement est géré de manière sécurisée via RevenueCat.';

  @override
  String get faqSubscriptionQ3 => 'Comment annuler mon abonnement ?';

  @override
  String get faqSubscriptionA3 =>
      'Les abonnements peuvent être gérés ou annulés via les paramètres du magasin d\'applications de votre appareil (App Store ou Google Play). Les modifications prennent effet à la fin de la période de facturation en cours.';

  @override
  String get faqLanguageTitle => 'Langue & Accessibilité';

  @override
  String get faqLanguageQ1 => 'Comment changer la langue de l\'application ?';

  @override
  String get faqLanguageA1 =>
      'Allez dans Mes informations et utilisez le menu déroulant de langue pour basculer entre l\'anglais et le français. Le changement prend effet immédiatement dans toute l\'application et est enregistré dans votre profil.';

  @override
  String get faqLanguageQ2 => 'L\'application est-elle accessible ?';

  @override
  String get faqLanguageA2 =>
      'Oui. Agatha Track inclut des fonctionnalités d\'accessibilité : étiquettes sémantiques pour les lecteurs d\'écran, infobulles sur tous les éléments interactifs, étiquetage approprié des champs de formulaire et support de la navigation au clavier.';

  @override
  String get consentBannerTitle => 'Votre vie privée compte';

  @override
  String get consentBannerMessage =>
      'Nous utilisons des cookies et services essentiels pour faire fonctionner Agatha Track. Nous aimerions également définir des cookies optionnels pour l\'analyse et le marketing afin d\'améliorer votre expérience. Vous pouvez gérer vos préférences à tout moment.';

  @override
  String get consentAcceptAll => 'Tout accepter';

  @override
  String get consentManagePreferences => 'Gérer les préférences';

  @override
  String get consentSettings => 'Préférences de confidentialité';

  @override
  String get consentPreferencesDescription =>
      'Choisissez les types de traitement de données auxquels vous consentez. Les services essentiels sont toujours actifs car ils sont nécessaires au fonctionnement de l\'application.';

  @override
  String get consentEssential => 'Essentiel';

  @override
  String get consentEssentialDescription =>
      'Requis pour l\'authentification, le stockage des données et les fonctionnalités principales de l\'application. Ne peut pas être désactivé.';

  @override
  String get consentAnalytics => 'Analyse';

  @override
  String get consentAnalyticsDescription =>
      'Nous aide à comprendre comment vous utilisez l\'application afin de l\'améliorer. Aucune donnée personnelle n\'est partagée avec des tiers.';

  @override
  String get consentMarketing => 'Marketing';

  @override
  String get consentMarketingDescription =>
      'Nous permet de vous envoyer des mises à jour et offres pertinentes concernant les fonctionnalités et services d\'Agatha Track.';

  @override
  String get consentSavePreferences => 'Enregistrer les préférences';

  @override
  String get consentPreferencesSaved =>
      'Préférences de confidentialité enregistrées';

  @override
  String consentLastUpdated(String timestamp) {
    return 'Dernière mise à jour : $timestamp';
  }

  @override
  String get aboutUs => 'À propos';

  @override
  String get aboutIntro =>
      'Agatha Track aide les gardiens d\'animaux et les organisations à organiser la santé de leurs animaux. Suivez les visites vétérinaires, les médicaments, le poids et les soins quotidiens — que vous gériez un seul animal ou coordonniez toute une équipe.';

  @override
  String get privacyPolicy => 'Politique de confidentialité';

  @override
  String get termsOfService => 'Conditions d\'utilisation';

  @override
  String get appVersion => 'Version 1.0.0';

  @override
  String get version => 'Version';

  @override
  String get ppDataController => 'Responsable du traitement';

  @override
  String get ppDataControllerDesc =>
      'Le responsable du traitement est chargé du traitement de vos données personnelles conformément au Règlement (UE) 2016/679 (Règlement général sur la protection des données, « RGPD »). Contactez-nous pour les coordonnées du responsable du traitement.';

  @override
  String get ppScope => 'Champ d\'application';

  @override
  String get ppScopeDesc =>
      'Cette Politique de confidentialité s\'applique à l\'application Agatha Track, une plateforme de gestion d\'animaux disponible en tant qu\'application web, et décrit comment nous collectons, utilisons, stockons et protégeons vos données personnelles.';

  @override
  String get ppDataCollected => 'Données collectées';

  @override
  String get ppDataCollectedDesc =>
      'Nous collectons les catégories de données suivantes :\n\n• Données de compte : adresse e-mail, mot de passe (haché), prénom, nom, nom d\'affichage, catégorie, bio, photo de profil, préférence de langue.\n• Données animaux : nom, espèce, race, date de naissance, sexe, numéro de puce/identification, assurance, photo, statut décédé.\n• Données de suivi santé : entrées de santé (médicaments, préventifs, visites véto), photos/pièces jointes, problèmes de santé, historique d\'administration.\n• Données de suivi du poids : entrées de poids (valeur, date, unité).\n• Données vétérinaires : nom, clinique, téléphone, e-mail, adresse.\n• Données d\'organisation : nom, type, description, adhésion, rôles, événements familiaux.\n• Données de partage : enregistrements d\'accès, liens de partage, invitations en attente.\n• Données de notification : notifications in-app, préférences de notification.\n• Données techniques : jetons d\'authentification JWT, préférences locales.';

  @override
  String get ppLegalBasis => 'Base juridique du traitement';

  @override
  String get ppLegalBasisDesc =>
      'Nous traitons vos données personnelles sur les bases juridiques suivantes selon l\'article 6 du RGPD :\n\n• Consentement (Art. 6(1)(a)) : Pour les données facultatives telles que photos de profil, photos d\'animaux et bio.\n• Nécessité contractuelle (Art. 6(1)(b)) : Pour les données nécessaires à la fourniture du service.\n• Intérêt légitime (Art. 6(1)(f)) : Pour les mesures de sécurité et l\'amélioration du service.\n• Obligation légale (Art. 6(1)(c)) : Lorsque la loi applicable l\'exige.';

  @override
  String get ppHowWeUse => 'Comment nous utilisons vos données';

  @override
  String get ppHowWeUseDesc =>
      'Nous utilisons vos données personnelles pour :\n\n• Fournir le Service : gérer votre compte, profils d\'animaux, dossiers de santé et toutes les fonctionnalités associées.\n• Générer des rapports : créer des rapports PDF pour les animaux.\n• Envoyer des notifications : délivrer des rappels et alertes in-app.\n• Gérer les abonnements : traiter les droits d\'abonnement via RevenueCat.\n• Assurer la sécurité : authentifier les utilisateurs, prévenir la fraude et maintenir l\'intégrité du service.';

  @override
  String get ppDataSharing => 'Partage de données et sous-traitants';

  @override
  String get ppDataSharingDesc =>
      'Nous utilisons RevenueCat pour la gestion des abonnements (identifiant utilisateur, statut d\'abonnement). Nous ne vendons, ne louons ni n\'échangeons vos données personnelles avec des tiers. Nous pouvons divulguer vos données si la loi l\'exige.';

  @override
  String get ppInternationalTransfers => 'Transferts internationaux de données';

  @override
  String get ppInternationalTransfersDesc =>
      'Lorsque des données sont transférées en dehors de l\'Espace économique européen (EEE), nous veillons à ce que des garanties adéquates soient en place, y compris les clauses contractuelles types de l\'UE (CCT) et les décisions d\'adéquation de la Commission européenne.';

  @override
  String get ppDataRetention => 'Conservation des données';

  @override
  String get ppDataRetentionDesc =>
      'Les données de compte sont conservées pendant la durée de votre compte plus 30 jours après la suppression. Les profils d\'animaux, entrées de santé, entrées de poids et contacts vétérinaires sont conservés jusqu\'à suppression individuelle ou suppression du compte. Les notifications sont automatiquement purgées après 90 jours. Lorsque vous supprimez votre compte, toutes les données associées sont définitivement supprimées sous 30 jours.';

  @override
  String get ppYourRights => 'Vos droits (RGPD Art. 15–22)';

  @override
  String get ppYourRightsDesc =>
      'En vertu du RGPD, vous avez le droit de :\n\n• Accéder à vos données personnelles (Art. 15)\n• Rectifier les données inexactes (Art. 16)\n• Effacer vos données — « Droit à l\'oubli » (Art. 17)\n• Limiter le traitement (Art. 18)\n• Portabilité des données dans un format lisible par machine (Art. 20)\n• S\'opposer au traitement (Art. 21)\n• Retirer votre consentement à tout moment (Art. 7(3))\n• Déposer une plainte auprès de votre autorité de protection des données (Art. 77)\n\nVous pouvez exercer ces droits via l\'écran Mon profil de l\'application ou en nous contactant directement. Nous répondrons sous 30 jours.';

  @override
  String get ppCookies => 'Cookies et stockage local';

  @override
  String get ppCookiesDesc =>
      'L\'application utilise le stockage local (SharedPreferences) pour stocker les jetons d\'authentification, les préférences de langue, l\'état du consentement et les données de cache. Nous n\'utilisons pas de cookies de suivi tiers.';

  @override
  String get ppChildrensData => 'Données des enfants';

  @override
  String get ppChildrensDataDesc =>
      'L\'application ne s\'adresse pas aux enfants de moins de 16 ans. Nous ne collectons pas sciemment de données personnelles d\'enfants de moins de 16 ans (RGPD Art. 8).';

  @override
  String get ppSecurity => 'Sécurité des données';

  @override
  String get ppSecurityDesc =>
      'Nous mettons en œuvre des mesures techniques et organisationnelles appropriées pour protéger vos données, notamment le chiffrement en transit (TLS/HTTPS), le hachage des mots de passe (bcrypt), l\'authentification JWT, le contrôle d\'accès basé sur les rôles et les requêtes paramétrées en base de données.';

  @override
  String get ppChanges => 'Modifications de cette politique';

  @override
  String get ppChangesDesc =>
      'Nous pouvons mettre à jour cette Politique de confidentialité de temps à autre. Nous vous informerons des changements importants par notification in-app ou en mettant à jour la date de dernière modification.';

  @override
  String get ppContact => 'Nous contacter';

  @override
  String get ppContactDesc =>
      'Pour toute question, demande ou préoccupation concernant cette Politique de confidentialité ou nos pratiques de traitement des données, veuillez nous contacter via l\'application ou par e-mail.';

  @override
  String get tosAcceptance => 'Introduction et acceptation';

  @override
  String get tosAcceptanceDesc =>
      'Ces Conditions d\'utilisation régissent votre accès et votre utilisation de l\'application Agatha Track. En créant un compte ou en utilisant l\'application, vous acceptez d\'être lié par ces Conditions. Si vous n\'êtes pas d\'accord, vous ne devez pas utiliser l\'application.';

  @override
  String get tosEligibility => 'Éligibilité';

  @override
  String get tosEligibilityDesc =>
      'Vous devez avoir au moins 16 ans pour utiliser l\'application, conformément à l\'article 8 du RGPD. En créant un compte, vous déclarez remplir la condition d\'âge et avoir la capacité juridique d\'accepter ces Conditions.';

  @override
  String get tosAccountSecurity => 'Inscription et sécurité du compte';

  @override
  String get tosAccountSecurityDesc =>
      'Pour utiliser l\'application, vous devez vous inscrire avec une adresse e-mail valide et un mot de passe. Vous êtes responsable de la confidentialité de vos identifiants de connexion et de toutes les activités effectuées sous votre compte.';

  @override
  String get tosServiceDescription => 'Description du service';

  @override
  String get tosServiceDescriptionDesc =>
      'L\'application fournit la gestion de profils d\'animaux, le suivi de santé, le suivi du poids, les contacts vétérinaires, la gestion d\'organisations, le partage d\'animaux, les événements familiaux, les rapports d\'animaux, les notifications et la gestion d\'abonnements.';

  @override
  String get tosUserContent => 'Contenu utilisateur et responsabilités';

  @override
  String get tosUserContentDesc =>
      'Vous conservez la propriété de tout contenu que vous téléchargez. En téléchargeant du contenu, vous nous accordez une licence limitée pour le stocker, le traiter et l\'afficher uniquement pour fournir le Service. Vous acceptez de ne pas télécharger de contenu illégal, nuisible ou contrefait. L\'application ne remplace pas les conseils vétérinaires professionnels.';

  @override
  String get tosProhibitedUses => 'Utilisations interdites';

  @override
  String get tosProhibitedUsesDesc =>
      'Vous acceptez de ne pas utiliser l\'application à des fins illégales, de ne pas tenter d\'obtenir un accès non autorisé, d\'interférer avec l\'infrastructure, d\'utiliser des outils automatisés sans consentement, de désassembler toute partie de l\'application, ou de partager, vendre ou transférer votre compte sans notre consentement.';

  @override
  String get tosSubscriptions => 'Abonnements et paiements';

  @override
  String get tosSubscriptionsDesc =>
      'Certaines fonctionnalités nécessitent un abonnement payant géré via RevenueCat. Les abonnements se renouvellent automatiquement sauf annulation avant la fin de la période de facturation en cours. Les remboursements sont régis par les politiques du magasin d\'applications concerné.';

  @override
  String get tosIntellectualProperty => 'Propriété intellectuelle';

  @override
  String get tosIntellectualPropertyDesc =>
      'L\'application, y compris son design, son code, ses graphiques, logos et sa documentation, est protégée par le droit d\'auteur, les marques et autres lois sur la propriété intellectuelle. Nous vous accordons une licence limitée, non exclusive, non transférable et révocable pour utiliser l\'application conformément à ces Conditions.';

  @override
  String get tosLiability => 'Limitation de responsabilité';

  @override
  String get tosLiabilityDesc =>
      'L\'application est fournie « en l\'état » sans garantie. Nous ne serons pas responsables des dommages indirects, accessoires, spéciaux ou consécutifs. Notre responsabilité totale ne dépassera pas le montant que vous avez payé au cours des douze mois précédant la réclamation. Pour les consommateurs de l\'UE, rien ne limite notre responsabilité en cas de décès, de blessure, de fraude ou de non-conformité en vertu de la Directive (UE) 2019/770.';

  @override
  String get tosTermination => 'Résiliation';

  @override
  String get tosTerminationDesc =>
      'Vous pouvez résilier votre compte à tout moment via la fonction Supprimer le compte. Nous pouvons suspendre ou résilier votre accès si vous violez ces Conditions ou si la loi l\'exige. Avant la résiliation, vous pouvez exporter vos données via la fonction Exporter mes données (RGPD Art. 20).';

  @override
  String get tosGoverningLaw => 'Droit applicable et résolution des litiges';

  @override
  String get tosGoverningLawDesc =>
      'Ces Conditions sont régies par le droit de l\'Union européenne et le droit national applicable. Pour les consommateurs de l\'UE, vous bénéficiez des lois impératives de protection des consommateurs de votre pays de résidence. Vous pouvez utiliser la plateforme de règlement en ligne des litiges (RLL) de la Commission européenne pour résoudre les litiges en ligne.';

  @override
  String get tosContact => 'Coordonnées';

  @override
  String get tosContactDesc =>
      'Pour toute question concernant ces Conditions, veuillez nous contacter via l\'application ou par e-mail.';

  @override
  String get exportMyData => 'Exporter mes données';

  @override
  String get exportMyDataSubtitle =>
      'Télécharger toutes vos données au format JSON';

  @override
  String get dataExported => 'Vos données ont été exportées';

  @override
  String get consentPreferences => 'Préférences de confidentialité';

  @override
  String get consentReset =>
      'Préférences de consentement réinitialisées. La bannière de consentement apparaîtra au prochain lancement.';

  @override
  String get deleteAccount => 'Supprimer le compte';

  @override
  String get deleteAccountSubtitle =>
      'Supprimer définitivement votre compte et toutes vos données';

  @override
  String get deleteAccountWarning =>
      'Cette action est irréversible. Tous vos animaux, entrées de santé, relevés de poids, notifications et adhésions aux organisations seront définitivement supprimés. Entrez votre mot de passe pour confirmer.';

  @override
  String get error => 'Erreur';
}
