/// アプリケーション共通の例外クラス
class AppException implements Exception {
  final String message;
  final String? code;

  const AppException(this.message, {this.code});

  @override
  String toString() => code != null ? '[$code] $message' : message;
}

/// 認証関連の例外
class AuthAppException extends AppException {
  const AuthAppException(super.message, {super.code});
}

/// ネットワーク・データ取得関連の例外
class RepositoryException extends AppException {
  const RepositoryException(super.message, {super.code});
}

/// バリデーション関連の例外
class ValidationException extends AppException {
  const ValidationException(super.message, {super.code});
}
