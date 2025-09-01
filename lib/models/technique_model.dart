class TechniqueModel {
  String name;
  String category;
  String description;
  String? videoUrl;

  // Usamos un ID local para manejar la lista en la UI
  final int localId;

  TechniqueModel({
    required this.name,
    required this.category,
    this.description = '',
    this.videoUrl,
    required this.localId,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name.trim(),
      'category': category,
      'description': description.trim(),
      'videoUrl': videoUrl?.trim(),
    };
  }
}
