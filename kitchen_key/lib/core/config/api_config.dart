/// Backend connection settings.
///
/// Point [baseUrl] at your running Django server. Pick the option that matches
/// how your phone reaches the PC:
///
/// - Physical phone on the same Wi‑Fi  →  `http://YOUR-PC-LAN-IP:8000`
/// - ngrok (works on any network)       →  `https://YOUR-DOMAIN.ngrok-free.dev`
/// - Android emulator                   →  `http://10.0.2.2:8000`
///
/// Run the backend with:  python manage.py runserver 0.0.0.0:8000
class ApiConfig {
  ApiConfig._();

  /// CHANGE THIS to your machine's address.
  /// - Flutter web / desktop on this PC  →  http://127.0.0.1:8000
  /// - Physical Android phone            →  `http://PC-LAN-IP:8000`  (run server with 0.0.0.0)
  static const String baseUrl = 'http://127.0.0.1:8000';

  static const String apiPrefix = '/api/v1';

  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 20);
}
