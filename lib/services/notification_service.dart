/// Service singleton gérant les notifications locales (VERSION DÉSACTIVÉE).
///
/// Version temporaire sans dépendance flutter_local_notifications
/// pour permettre la compilation de l'application.
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() {
    return _instance;
  }

  NotificationService._internal();

  /// Initialise le service de notifications.
  Future<void> initialize() async {
    print('[NotificationService] Mode désactivé - initialisation ignorée');
  }

  /// Demande les permissions de notification.
  Future<bool> requestPermissions() async {
    print('[NotificationService] Mode désactivé - permissions ignorées');
    return true;
  }

  /// Affiche ou met à jour la notification de session en cours.
  Future<void> showTimerNotification(Duration duration) async {
    // Ne fait rien en mode désactivé
  }

  /// Masque la notification du timer.
  Future<void> hideTimerNotification() async {
    // Ne fait rien en mode désactivé
  }

  /// Annule toutes les notifications.
  Future<void> cancelAll() async {
    // Ne fait rien en mode désactivé
  }
}
