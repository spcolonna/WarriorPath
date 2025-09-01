
import 'package:cloud_firestore/cloud_firestore.dart';

class SchoolModel {
  final String? id; // El ID del documento, será nulo al crear
  final String name;
  final String martialArt;
  final String ownerId;
  final String address;
  final String city;
  final String phone;
  final String description;
  final bool isSubSchool;
  final String? parentSchoolId;
  final String? parentSchoolName;
  final Map<String, String> theme; // Para guardar los colores

  SchoolModel({
    this.id,
    required this.name,
    required this.martialArt,
    required this.ownerId,
    required this.address,
    required this.city,
    required this.phone,
    required this.description,
    required this.isSubSchool,
    this.parentSchoolId,
    this.parentSchoolName,
    required this.theme,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'martialArt': martialArt,
      'ownerId': ownerId,
      'address': address,
      'city': city,
      'phone': phone,
      'description': description,
      'isSubSchool': isSubSchool,
      'parentSchoolId': parentSchoolId,
      'parentSchoolName': parentSchoolName,
      'theme': theme,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}
