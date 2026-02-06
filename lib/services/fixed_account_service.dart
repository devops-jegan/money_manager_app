import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/account_model.dart';

class AccountService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'accounts';

  // Get all accounts as Stream<List<AccountModel>>
  Stream<List<AccountModel>> getAccounts() {
    return _firestore
        .collection(_collection)
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => AccountModel.fromFirestore(doc))
            .toList());
  }

  // Get all accounts as Future<List<AccountModel>>
  Future<List<AccountModel>> getAccountsList() async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .orderBy('createdAt', descending: false)
          .get();

      return snapshot.docs
          .map((doc) => AccountModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Error getting accounts list: $e');
      return [];
    }
  }

  // Get single account by ID
  Future<AccountModel?> getAccountById(String id) async {
    try {
      final doc = await _firestore.collection(_collection).doc(id).get();
      return doc.exists ? AccountModel.fromFirestore(doc) : null;
    } catch (e) {
      print('Error getting account: $e');
      return null;
    }
  }

  // Add new account
  Future<String> addAccount(AccountModel account) async {
    try {
      final docRef = await _firestore.collection(_collection).add(account.toMap());
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to add account: $e');
    }
  }

  // Update account
  Future<void> updateAccount(String id, AccountModel account) async {
    try {
      await _firestore.collection(_collection).doc(id).update(account.toMap());
    } catch (e) {
      throw Exception('Failed to update account: $e');
    }
  }

  // Update account balance
  Future<void> updateAccountBalance(String id, double newBalance) async {
    try {
      await _firestore.collection(_collection).doc(id).update({
        'balance': newBalance,
      });
    } catch (e) {
      throw Exception('Failed to update balance: $e');
    }
  }

  // Delete account
  Future<void> deleteAccount(String id) async {
    try {
      await _firestore.collection(_collection).doc(id).delete();
    } catch (e) {
      throw Exception('Failed to delete account: $e');
    }
  }

  // Get total balance across all accounts
  Future<double> getTotalBalance() async {
    try {
      final accounts = await getAccountsList();
      return accounts.fold(0.0, (sum, account) => sum + account.balance);
    } catch (e) {
      print('Error calculating total balance: $e');
      return 0.0;
    }
  }

  // Get accounts by type
  Stream<List<AccountModel>> getAccountsByType(String type) {
    return _firestore
        .collection(_collection)
        .where('type', isEqualTo: type)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => AccountModel.fromFirestore(doc))
            .toList());
  }
}