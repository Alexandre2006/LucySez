class LucySezError extends Error {
  final String title;
  final String message;
  late final String? details;
  @override
  late final StackTrace? stackTrace;

  LucySezError({
    required this.title,
    required this.message,
    Error? error,
  }) {
    details = error?.toString();
    stackTrace = error?.stackTrace;
  }
}
