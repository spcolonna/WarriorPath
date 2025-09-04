import 'package:cloud_firestore/cloud_firestore.dart';

class PaymentPlanModel {
  String? id;
  String title;
  double amount;
  String description;
  String currency;

  PaymentPlanModel({
    this.id,
    required this.title,
    required this.amount,
    this.description = '',
    required this.currency,
  });

  factory PaymentPlanModel.fromModel(PaymentPlanModel another) {
    return PaymentPlanModel(
      id: another.id,
      title: another.title,
      amount: another.amount,
      description: another.description,
      currency: another.currency,
    );
  }

  factory PaymentPlanModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PaymentPlanModel(
      id: doc.id,
      title: data['title'] ?? '',
      amount: (data['amount'] as num?)?.toDouble() ?? 0.0,
      description: data['description'] ?? '',
      currency: data['currency'] ?? 'USD',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'amount': amount,
      'description': description,
      'currency': currency,
    };
  }
}
