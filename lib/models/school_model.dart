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
  final double? latitude;
  final double? longitude;

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
    this.latitude,
    this.longitude,
  });

  factory SchoolModel.fromJson(Map<String, dynamic> json, String id) {
    return SchoolModel(
      id: id,
      name: json['name'] ?? '',
      ownerId: json['ownerId'] ?? '',
      logoUrl: json['logoUrl'],
      address: json['address'] ?? '',
      city: json['city'] ?? '',
      phone: json['phone'] ?? '',
      description: json['description'] ?? '',
      isSubSchool: json['isSubSchool'] ?? false,
      parentSchoolId: json['parentSchoolId'],
      parentSchoolName: json['parentSchoolName'],
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
    );
  }

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
      'latitude': latitude,
      'longitude': longitude,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}
