import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class EventModel {
  String? id;
  String title;
  String description;
  DateTime date;
  TimeOfDay startTime;
  TimeOfDay endTime;
  String location;
  double cost;
  String currency;
  String createdBy;
  List<String> invitedStudentIds;
  Map<String, String> attendeeStatus;
  List<String> disciplineIds;

  EventModel({
    this.id,
    required this.title,
    this.description = '',
    required this.date,
    required this.startTime,
    required this.endTime,
    this.location = '',
    this.cost = 0.0,
    this.currency = 'UYU',
    required this.createdBy,
    this.invitedStudentIds = const [],
    this.attendeeStatus = const {},
    required this.disciplineIds,
  });

  factory EventModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final date = (data['eventDate'] as Timestamp).toDate();

    return EventModel(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      date: date,
      startTime: TimeOfDay(hour: int.parse(data['startTime'].split(':')[0]), minute: int.parse(data['startTime'].split(':')[1])),
      endTime: TimeOfDay(hour: int.parse(data['endTime'].split(':')[0]), minute: int.parse(data['endTime'].split(':')[1])),
      location: data['location'] ?? '',
      cost: (data['cost'] as num?)?.toDouble() ?? 0.0,
      currency: data['currency'] ?? 'UYU',
      createdBy: data['createdBy'] ?? '',
      invitedStudentIds: List<String>.from(data['invitedStudentIds'] ?? []),
      attendeeStatus: Map<String, String>.from(data['attendeeStatus'] ?? {}),
      disciplineIds: List<String>.from(data['disciplineIds'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'eventDate': Timestamp.fromDate(date),
      'startTime': '${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')}',
      'endTime': '${endTime.hour.toString().padLeft(2, '0')}:${endTime.minute.toString().padLeft(2, '0')}',
      'location': location,
      'cost': cost,
      'currency': currency,
      'createdBy': createdBy,
      'createdAt': FieldValue.serverTimestamp(),
      'invitedStudentIds': invitedStudentIds,
      'attendeeStatus': attendeeStatus,
      'disciplineIds': disciplineIds,
    };
  }
}
