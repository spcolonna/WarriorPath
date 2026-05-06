import 'package:cloud_firestore/cloud_firestore.dart';

class TechniqueModel {
  String? id;
  final int? localId;
  String name;
  String category;
  String description;
  String? videoUrl;
  int complexity;

  TechniqueModel({
    this.id,
    this.localId,
    required this.name,
    required this.category,
    this.description = '',
    this.videoUrl,
    this.complexity = 1,
  });

  factory TechniqueModel.fromModel(TechniqueModel another) {
    return TechniqueModel(
      id: another.id,
      localId: another.localId,
      name: another.name,
      category: another.category,
      description: another.description,
      videoUrl: another.videoUrl,
      complexity: another.complexity,
    );
  }

  factory TechniqueModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return TechniqueModel(
      id: doc.id,
      name: data['name'] ?? 'Sin Nombre',
      category: data['category'] ?? 'Sin Categoría',
      description: data['description'] ?? '',
      videoUrl: data['videoUrl'],
      complexity: (data['complexity'] as num?)?.toInt() ?? 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name.trim(),
      'category': category,
      'description': description.trim(),
      'videoUrl': videoUrl?.trim(),
      'complexity': complexity,
    };
  }
}
