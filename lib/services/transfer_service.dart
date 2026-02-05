import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/transfer_model.dart';
import '../models/account_model.dart';
import 'account_service.dart';

class TransferService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final AccountService _accountService = AccountService();

  Future<void> addTransfer(TransferModel transfer) async {
    try {
      // Start a batch write
      final batch = _db.batch();

      // Add transfer document
      final transferRef = _db.collection('transfers').doc();
      batch.set(transferRef, transfer.toMap());

      // Update account balances
      final fromAccountRef = _db.collection('accounts').doc(transfer.fromAccountId);
      final toAccountRef = _db.collection('accounts').doc(transfer.toAccountId);

      // Get current balances
      final fromAccountDoc = await fromAccountRef.get();
      final toAccountDoc = await toAccountRef.get();

      if (!fromAccountDoc.exists || !toAccountDoc.exists) {
        throw Exception('One or both accounts not found');
      }

      final fromBalance = (fromAccountDoc.data()?['balance'] ?? 0).toDouble();
      final toBalance = (toAccountDoc.data()?['balance'] ?? 0).toDouble();

      // Update balances
      batch.update(fromAccountRef, {'balance': fromBalance - transfer.amount});
      batch.update(toAccountRef, {'balance': toBalance + transfer.amount});

      // Commit the batch
      await batch.commit();
    } catch (e) {
      throw Exception('Failed to add transfer: $e');
    }
  }

  Stream<List<TransferModel>> getTransfers() {
    return _db
        .collection('transfers')
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => TransferModel.fromFirestore(doc))
            .toList());
  }

  Future<void> deleteTransfer(String id) async {
    try {
      // Get the transfer first
      final transferDoc = await _db.collection('transfers').doc(id).get();
      
      if (!transferDoc.exists) {
        throw Exception('Transfer not found');
      }

      final transfer = TransferModel.fromFirestore(transferDoc);

      // Start a batch write
      final batch = _db.batch();

      // Delete transfer document
      batch.delete(_db.collection('transfers').doc(id));

      // Reverse the account balance changes
      final fromAccountRef = _db.collection('accounts').doc(transfer.fromAccountId);
      final toAccountRef = _db.collection('accounts').doc(transfer.toAccountId);

      // Get current balances
      final fromAccountDoc = await fromAccountRef.get();
      final toAccountDoc = await toAccountRef.get();

      if (fromAccountDoc.exists && toAccountDoc.exists) {
        final fromBalance = (fromAccountDoc.data()?['balance'] ?? 0).toDouble();
        final toBalance = (toAccountDoc.data()?['balance'] ?? 0).toDouble();

        // Reverse the transfer
        batch.update(fromAccountRef, {'balance': fromBalance + transfer.amount});
        batch.update(toAccountRef, {'balance': toBalance - transfer.amount});
      }

      // Commit the batch
      await batch.commit();
    } catch (e) {
      throw Exception('Failed to delete transfer: $e');
    }
  }
}