import 'package:cloud_firestore/cloud_firestore.dart';

class AccountModel {
  final String id;
  final String name;
  final String type; // 'cash', 'bank', 'credit_card', 'loan'
  final double balance;
  final String? note;
  final DateTime createdAt;

  AccountModel({
    required this.id,
    required this.name,
    required this.type,
    required this.balance,
    this.note,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'type': type,
      'balance': balance,
      'note': note,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory AccountModel.fromMap(Map<String, dynamic> map, String id) {
    return AccountModel(
      id: id,
      name: map['name'] ?? '',
      type: map['type'] ?? 'cash',
      balance: (map['balance'] ?? 0).toDouble(),
      note: map['note'],
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  factory AccountModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return AccountModel.fromMap(data, doc.id);
  }

  AccountModel copyWith({
    String? id,
    String? name,
    String? type,
    double? balance,
    String? note,
    DateTime? createdAt,
  }) {
    return AccountModel(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      balance: balance ?? this.balance,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}