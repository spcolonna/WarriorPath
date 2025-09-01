import 'package:flutter/material.dart';

class LevelModel {
  String name;
  Color color;
  int order;

  LevelModel({required this.name, required this.color, this.order = 0});

  // Método para convertir el objeto a un mapa para Firestore
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      // Guardamos el color como un entero (formato ARGB)
      'colorValue': color.value,
      'order': order,
    };
  }
}
