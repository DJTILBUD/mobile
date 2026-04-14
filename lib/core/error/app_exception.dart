sealed class AppException implements Exception {
  const AppException(this.message);
  final String message;
}

class NetworkException extends AppException {
  const NetworkException(super.message);
}

class AuthException extends AppException {
  const AuthException(super.message);
}

class NoMusicianProfileException extends AppException {
  const NoMusicianProfileException()
      : super('Denne konto har ingen musikerprofil. Kontakt support.');
}

class NeedsProfileSetupException extends AppException {
  const NeedsProfileSetupException() : super('');
}

class DatabaseException extends AppException {
  const DatabaseException(super.message);
}

class AgentException extends AppException {
  const AgentException(super.message);
}
