import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/transfer_model.dart';
import '../models/account_model.dart';
import '../services/transfer_service.dart';
import '../services/account_service.dart';
import 'add_transfer_screen.dart';

class TransfersScreen extends StatefulWidget {
  const TransfersScreen({super.key});

  @override
  State<TransfersScreen> createState() => _TransfersScreenState();
}

class _TransfersScreenState extends State<TransfersScreen> {
  final TransferService _transferService = TransferService();
  final AccountService _accountService = AccountService();
  Map<String, AccountModel> _accountsMap = {};

  @override
  void initState() {
    super.initState();
    _loadAccounts();
  }

  void _loadAccounts() async {
    final accountsStream = _accountService.getAccounts();
    accountsStream.listen((accounts) {
      if (mounted) {
        setState(() {
          _accountsMap = {for (var account in accounts) account.id: account};
        });
      }
    });
  }

  String _getAccountName(String accountId) {
    return _accountsMap[accountId]?.name ?? 'Unknown Account';
  }

  IconData _getAccountIcon(String accountId) {
    final account = _accountsMap[accountId];
    if (account == null) return Icons.account_balance_wallet;

    switch (account.type) {
      case 'cash':
        return Icons.money;
      case 'bank':
        return Icons.account_balance;
      case 'credit_card':
        return Icons.credit_card;
      case 'loan':
        return Icons.request_quote;
      default:
        return Icons.account_balance_wallet;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Transfers'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: StreamBuilder<List<TransferModel>>(
        stream: _transferService.getTransfers(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.swap_horiz, size: 80, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  Text(
                    'No transfers yet',
                    style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tap + to add your first transfer',
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
                  ),
                ],
              ),
            );
          }

          final transfers = snapshot.data!;

          // Group transfers by date
          final groupedTransfers = <String, List<TransferModel>>{};
          for (var transfer in transfers) {
            final dateKey = DateFormat('yyyy-MM-dd').format(transfer.date);
            if (!groupedTransfers.containsKey(dateKey)) {
              groupedTransfers[dateKey] = [];
            }
            groupedTransfers[dateKey]!.add(transfer);
          }

          final sortedDates = groupedTransfers.keys.toList()
            ..sort((a, b) => b.compareTo(a));

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: sortedDates.length,
            itemBuilder: (context, index) {
              final dateKey = sortedDates[index];
              final dateTransfers = groupedTransfers[dateKey]!;
              final date = DateTime.parse(dateKey);

              String dateLabel;
              final now = DateTime.now();
              final today = DateTime(now.year, now.month, now.day);
              final yesterday = today.subtract(const Duration(days: 1));
              final transferDate = DateTime(date.year, date.month, date.day);

              if (transferDate == today) {
                dateLabel = 'Today';
              } else if (transferDate == yesterday) {
                dateLabel = 'Yesterday';
              } else {
                dateLabel = DateFormat('EEEE, dd MMM yyyy').format(date);
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      dateLabel,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                  ),
                  ...dateTransfers.map((transfer) =>
                      _buildTransferTile(transfer)),
                  const SizedBox(height: 8),
                ],
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AddTransferScreen(),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildTransferTile(TransferModel transfer) {
    return Dismissible(
      key: Key(transfer.id),
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      direction: DismissDirection.endToStart,
      confirmDismiss: (direction) async {
        return await showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Confirm Delete'),
              content: const Text('Are you sure you want to delete this transfer?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('Delete', style: TextStyle(color: Colors.red)),
                ),
              ],
            );
          },
        );
      },
      onDismissed: (direction) {
        _transferService.deleteTransfer(transfer.id);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Transfer deleted')),
        );
      },
      child: Card(
        margin: const EdgeInsets.only(bottom: 8),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Icon
              CircleAvatar(
                backgroundColor: Colors.purple.withOpacity(0.1),
                child: const Icon(
                  Icons.swap_horiz,
                  color: Colors.purple,
                ),
              ),
              const SizedBox(width: 12),
              // Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          _getAccountIcon(transfer.fromAccountId),
                          size: 16,
                          color: Colors.grey.shade600,
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            _getAccountName(transfer.fromAccountId),
                            style: const TextStyle(
                              fontWeight: FontWeight.w500,
                              fontSize: 14,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.arrow_downward,
                          size: 12,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          _getAccountIcon(transfer.toAccountId),
                          size: 16,
                          color: Colors.grey.shade600,
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            _getAccountName(transfer.toAccountId),
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade600,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    if (transfer.note != null && transfer.note!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        transfer.note!,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade500,
                          fontStyle: FontStyle.italic,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              // Amount
              Text(
                '₹${transfer.amount.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.purple,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}