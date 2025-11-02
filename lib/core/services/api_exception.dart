class ApiException implements Exception {
  ApiException(this.statusCode, this.message, {this.path, this.body});

  final int? statusCode;
  final String message;
  final String? body;
  final String? path;

  @override
  String toString() {
    final s = statusCode != null ? '($statusCode) ' : '';
    final p = path != null ? ' at $path' : '';
    return 'ApiException: $s$message$p${body != null ? '\nbody: $body' : ''}';
  }
}
