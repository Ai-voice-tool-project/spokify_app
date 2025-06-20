class Transcription {
  final String id;
  final String transcription;
  final String? enhanced;
  final String? summary;
  final List<dynamic>? topics;
  final List<dynamic>? tasks;
  final String? audioUrl;
  final String? filename;
  final String? userName;
  final String? uploadDate;

  Transcription({
    required this.id,
    required this.transcription,
    this.enhanced,
    this.summary,
    this.topics,
    this.tasks,
    this.audioUrl,
    this.filename,
    this.userName,
    this.uploadDate,
  });

  factory Transcription.fromJson(Map<String, dynamic> json) {
    return Transcription(
      id: json['id'],
      transcription: json['transcription'],
      enhanced: json['enhanced'],
      summary: json['summary'],
      topics: json['topics'],
      tasks: json['tasks'],
      audioUrl: json['audio']?['downloadUrl'],
      filename: json['audio']?['filename'],
      userName: json['userName'],
      uploadDate: json['upload_date'],
    );
  }
}
