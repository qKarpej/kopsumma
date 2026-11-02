/// Bāzes adrese no vides: flutter run --dart-define-from-file=config/mock.json
const apiBaseUrl = String.fromEnvironment('API_BASE_URL', defaultValue: 'http://localhost:8080');
