import 'package:cloud_firestore/cloud_firestore.dart';

class AccountModel {
  final String id;
  final String name;
  final String type;
  final double balance;
  final String? icon;
  final DateTime createdAt;

  AccountModel({
    required this.id,
    required this.name,
    required this.type,
    required this.balance,
    this.icon,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'type': type,
      'balance': balance,
      'icon': icon,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory AccountModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AccountModel(
      id: doc.id,
      name: data['name'] ?? '',
      type: data['type'] ?? 'cash',
      balance: (data['balance'] ?? 0).toDouble(),
      icon: data['icon'],
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  AccountModel copyWith({
    String? id,
    String? name,
    String? type,
    double? balance,
    String? icon,
    DateTime? createdAt,
  }) {
    return AccountModel(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      balance: balance ?? this.balance,
      icon: icon ?? this.icon,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
