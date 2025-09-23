import 'package:cloud_firestore/cloud_firestore.dart';

class DisciplineModel {
  String? id;
  String name;
  Map<String, dynamic> theme;
  bool isActive;

  DisciplineModel({
    this.id,
    required this.name,
    required this.theme,
    this.isActive = true,
  });

  factory DisciplineModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return DisciplineModel(
      id: doc.id,
      name: data['name'] ?? '',
      theme: data['theme'] as Map<String, dynamic>? ?? {},
      isActive: data['isActive'] ?? true,
    );
  }

  factory DisciplineModel.fromModel(DisciplineModel another) {
    return DisciplineModel(
        id: another.id,
        name: another.name,
        theme: Map<String, dynamic>.from(another.theme),
        isActive: another.isActive
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'theme': theme,
      'isActive': isActive,
    };
  }
}
