class FailedToDecodeImageFileException implements Exception {
  final String message;
  final String? details;

  FailedToDecodeImageFileException({
    required this.message,
    this.details,
  });
}
