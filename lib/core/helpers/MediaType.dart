import 'package:http_parser/http_parser.dart';

MediaType getAudioMediaType(String path) {
  final extension = path.split('.').last.toLowerCase();

  switch (extension) {
    case 'mp3':
      return MediaType('audio', 'mpeg');
    case 'wav':
      return MediaType('audio', 'wav');
    case 'ogg':
      return MediaType('audio', 'ogg');
    case 'webm':
      return MediaType('audio', 'webm');
    case 'opus':
      return MediaType('audio', 'opus');
    case 'mp4':
      return MediaType('audio', 'mp4');
    case 'm4a':
      return MediaType('audio', 'x-m4a');
    default:
      return MediaType('application', 'octet-stream'); // fallback
  }
}
