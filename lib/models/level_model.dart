import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class LevelModel {
  final String? id;
  String name;
  Color color;
  int order;

  LevelModel({
    this.id,
    required this.name,
    required this.color,
    this.order = 0,
  });

  factory LevelModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return LevelModel(
      id: doc.id,
      name: data['name'] ?? '',
      color: data.containsKey('colorValue') ? Color(data['colorValue']) : Colors.grey,
      order: data['order'] ?? 0,
    );
  }

  factory LevelModel.fromModel(LevelModel another) {
    return LevelModel(
      id: another.id,
      name: another.name,
      color: another.color,
      order: another.order,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'colorValue': color.value,
      'order': order,
    };
  }
}
