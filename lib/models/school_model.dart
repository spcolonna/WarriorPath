import 'package:cloud_firestore/cloud_firestore.dart';

class SchoolModel {
  String? id;
  final String name;
  final String ownerId;
  final String? logoUrl;
  final String address;
  final String city;
  final String phone;
  final String description;
  final bool isSubSchool;
  final String? parentSchoolId;
  final String? parentSchoolName;

  SchoolModel({
    this.id,
    required this.name,
    required this.ownerId,
    this.logoUrl,
    this.address = '',
    this.city = '',
    this.phone = '',
    this.description = '',
    this.isSubSchool = false,
    this.parentSchoolId,
    this.parentSchoolName,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'ownerId': ownerId,
      'logoUrl': logoUrl,
      'address': address,
      'city': city,
      'phone': phone,
      'description': description,
      'isSubSchool': isSubSchool,
      'parentSchoolId': parentSchoolId,
      'parentSchoolName': parentSchoolName,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}
