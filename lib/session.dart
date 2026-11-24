import 'dart:convert';

/// Garde en mémoire l'utilisateur connecté pour les appels API
class Session {
  static String email = '';
  static String _password = '';
  static List<String> roles = [];

  static void set(String e, String p, List<String> r) {
    email = e;
    _password = p;
    roles = r;
  }

  static void clear() {
    email = '';
    _password = '';
    roles = [];
  }

  static bool get isAdmin => roles.contains('ADMIN');

  static Map<String, String> get authHeader => {
    'Authorization':
    'Basic ${base64Encode(utf8.encode('$email:$_password'))}',
  };
}