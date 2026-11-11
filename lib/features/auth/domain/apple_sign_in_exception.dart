class AppleSignInException implements Exception {
  const AppleSignInException({required this.code, required this.message});

  final String code;
  final String message;

  @override
  String toString() => 'AppleSignInException($code)';
}
