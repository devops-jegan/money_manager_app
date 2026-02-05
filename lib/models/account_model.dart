import 'package:cloud_firestore/cloud_firestore.dart';

class AccountModel {
  final String id;
  final String name;
  final String type;
  final double balance;
  final String? icon;
  final String? note;
  final DateTime createdAt;

  AccountModel({
    required this.id,
    required this.name,
    required this.type,
    required this.balance,
    this.icon,
    this.note,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  // Helper getters
  String get typeDisplayName {
    switch (type.toLowerCase()) {
      case 'bank':
        return 'Bank Account';
      case 'cash':
        return 'Cash';
      case 'credit card':
      case 'card':
        return 'Credit Card';
      case 'wallet':
        return 'Digital Wallet';
      case 'loan':
        return 'Loan';
      default:
        return type;
    }
  }

  bool get isDebt {
    return type.toLowerCase() == 'loan' || type.toLowerCase() == 'credit card';
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'type': type,
      'balance': balance,
      'icon': icon,
      'note': note,
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
      note: data['note'],
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
    String? note,
    DateTime? createdAt,
  }) {
    return AccountModel(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      balance: balance ?? this.balance,
      icon: icon ?? this.icon,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
