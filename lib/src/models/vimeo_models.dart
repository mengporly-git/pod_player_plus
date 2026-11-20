class VideoQalityUrls {
  int quality;
  String url;
  String? audioUrl;

  new({required this.quality, required this.url, this.audioUrl});

  @override
  String toString() =>
      'VideoQalityUrls(quality: $quality, url: $url, '
      'hasSeparateAudio: ${audioUrl != null})';
}

class VimeoApiException implements Exception {
  const new({required this.message, this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() {
    final status = statusCode == null ? '' : ' (HTTP $statusCode)';
    return 'VimeoApiException$status: $message';
  }
}
