import 'package:flutter/material.dart';

class LevelModel {
  String? id;
  String name;
  Color color;
  int order;

  LevelModel({this.id, required this.name, required this.color, this.order = 0});

  factory LevelModel.fromModel(LevelModel another) {
    return LevelModel(id: another.id, name: another.name, color: another.color, order: another.order);
  }

  factory LevelModel.fromFirestore(String id, Map<String, dynamic> data) {
    return LevelModel(
      id: id,
      name: data['name'],
      color: Color(data['colorValue']),
      order: data['order'],
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
