
import 'package:cloud_firestore/cloud_firestore.dart';

class SchoolModel {
  final String? id;
  final String name;
  final String martialArt;
  final String ownerId;
  final String? logoUrl;
  final String address;
  final String city;
  final String phone;
  final String description;
  final bool isSubSchool;
  final String? parentSchoolId;
  final String? parentSchoolName;
  final Map<String, String> theme;

  SchoolModel({
    this.id,
    required this.name,
    required this.martialArt,
    required this.ownerId,
    this.logoUrl,
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
      'logoUrl': logoUrl,
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
