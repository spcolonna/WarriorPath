import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String email;
  String? displayName;
  String? phoneNumber;
  String? photoUrl;
  String? role;
  int wizardStep; // El campo clave para nuestro wizard

  UserModel({
    required this.uid,
    required this.email,
    this.displayName,
    this.phoneNumber,
    this.photoUrl,
    this.role,
    required this.wizardStep,
  });

  // Convertir un objeto UserModel a un Map para Firestore
  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'phoneNumber': phoneNumber,
      'photoUrl': photoUrl,
      'role': role,
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
      wizardStep: data['wizardStep'] ?? 0,
    );
  }
}
