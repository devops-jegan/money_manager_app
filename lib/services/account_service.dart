import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/account_model.dart';

class AccountService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'accounts';

  Stream<List<AccountModel>> getAccounts() {
    return _firestore
        .collection(_collection)
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => AccountModel.fromFirestore(doc))
            .toList());
  }

  Future<void> addAccount(AccountModel account) async {
    await _firestore.collection(_collection).add(account.toMap());
  }

  Future<void> updateAccount(String id, AccountModel account) async {
    await _firestore.collection(_collection).doc(id).update(account.toMap());
  }

  Future<void> updateAccountBalance(String id, double newBalance) async {
    await _firestore.collection(_collection).doc(id).update({'balance': newBalance});
  }

  Future<void> deleteAccount(String id) async {
    await _firestore.collection(_collection).doc(id).delete();
  }

  Future<AccountModel?> getAccountById(String id) async {
    final doc = await _firestore.collection(_collection).doc(id).get();
    return doc.exists ? AccountModel.fromFirestore(doc) : null;
  }
}
