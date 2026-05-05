class Note {
  final String? id;
  final String title;
  final String description;
  final String? imageBase64;
  final DateTime createdAt;
  double? latitude;
  double? longitude;

  Note({
    this.id,
    required this.title,
    required this.description,
    this.imageBase64,
    required this.createdAt,
    this.latitude,
    this.longitude,
  });

  factory Note.fromMap(String id, Map<String, dynamic> map) {
    return Note(
      id: id,
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      imageBase64: map['imageBase64'],
      createdAt: DateTime.tryParse(map['createdAt'] ?? '') ?? DateTime.now(),
      latitude: (map['latitude'] as num?)?.toDouble(),
      longitude: (map['longitude'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'imageBase64': imageBase64,
      'createdAt': createdAt.toIso8601String(),
      'latitude': latitude,
      'longitude': longitude,
    };
  }
}