enum AuthResultType {
  loginSuccess,
  signupRequired,
  failure,
}

class AuthResult {
  final AuthResultType type;
  final String? accessToken;
  final String? refreshToken;
  final String? signupToken; // Token for completing signup
  final String? errorMessage;

  AuthResult({
    required this.type,
    this.accessToken,
    this.refreshToken,
    this.signupToken,
    this.errorMessage,
  });
}
