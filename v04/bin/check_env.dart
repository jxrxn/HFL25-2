// v04/bin/check_env.dart
import 'package:v04/env.dart';

void main() {
  // Ladda .env lokalt; i CI ignoreras filen och OS-miljö används.
  Env.load();

  final token = Env.superheroToken;
  if (token == null || token.isEmpty) {
    print('TOKEN_STATUS=missing');
    return;
  }

  // Skriv ALDRIG ut hela token. Visa bara maskad info.
  final masked = token.length <= 6
      ? '***'
      : '${token.substring(0, 3)}•••${token.substring(token.length - 3)}';

  print('TOKEN_STATUS=present');
  print('TOKEN_MASKED=$masked');
  print('TOKEN_LENGTH=${token.length}');
}