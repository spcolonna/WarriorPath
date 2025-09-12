import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String email;
  String? displayName;
  String? phoneNumber;
  String? photoUrl;
  String? role;
  String? gender;
  DateTime? dateOfBirth;
  int wizardStep;

  UserModel({
    required this.uid,
    required this.email,
    this.displayName,
    this.phoneNumber,
    this.photoUrl,
    this.role,
    this.gender,
    this.dateOfBirth,
    required this.wizardStep,
  });

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'phoneNumber': phoneNumber,
      'photoUrl': photoUrl,
      'role': role,
      'gender': gender,
      'dateOfBirth': dateOfBirth != null ? Timestamp.fromDate(dateOfBirth!) : null,
      'wizardStep': wizardStep,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }

  // Crear un UserModel desde un DocumentSnapshot de Firestore
  factory UserModel.fromSnap(DocumentSnapshot snap) {
    var data = snap.data() as Map<String, dynamic>;
    return UserModel(
      uid: data['uid'],
      email: data['email'],
      displayName: data['displayName'],
      phoneNumber: data['phoneNumber'],
      photoUrl: data['photoUrl'],
      role: data['role'],
      gender: data['gender'],
      dateOfBirth: (data['dateOfBirth'] as Timestamp?)?.toDate(),
      wizardStep: data['wizardStep'] ?? 0,
    );
  }
}
