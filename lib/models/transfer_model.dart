import 'package:cloud_firestore/cloud_firestore.dart';

class TransferModel {
  final String id;
  final String fromAccountId;
  final String toAccountId;
  final double amount;
  final DateTime date;
  final String? note;

  TransferModel({
    required this.id,
    required this.fromAccountId,
    required this.toAccountId,
    required this.amount,
    required this.date,
    this.note,
  });

  Map<String, dynamic> toMap() {
    return {
      'fromAccountId': fromAccountId,
      'toAccountId': toAccountId,
      'amount': amount,
      'date': Timestamp.fromDate(date),
      'note': note,
    };
  }

  factory TransferModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return TransferModel(
      id: doc.id,
      fromAccountId: data['fromAccountId'] ?? '',
      toAccountId: data['toAccountId'] ?? '',
      amount: (data['amount'] ?? 0).toDouble(),
      date: (data['date'] as Timestamp).toDate(),
      note: data['note'],
    );
  }
}