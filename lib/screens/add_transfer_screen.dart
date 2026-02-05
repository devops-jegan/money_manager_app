import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/transfer_model.dart';
import '../models/account_model.dart';
import '../services/transfer_service.dart';
import '../services/account_service.dart';

class AddTransferScreen extends StatefulWidget {
  const AddTransferScreen({super.key});

  @override
  State<AddTransferScreen> createState() => _AddTransferScreenState();
}

class _AddTransferScreenState extends State<AddTransferScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  final TransferService _transferService = TransferService();
  final AccountService _accountService = AccountService();

  List<AccountModel> _accounts = [];
  String? _fromAccountId;
  String? _toAccountId;
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;

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
          _accounts = accounts;
        });
      }
    });
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _saveTransfer() async {
    if (_formKey.currentState!.validate()) {
      if (_fromAccountId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a source account')),
        );
        return;
      }
      if (_toAccountId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a destination account')),
        );
        return;
      }
      if (_fromAccountId == _toAccountId) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Source and destination accounts must be different')),
        );
        return;
      }

      setState(() => _isLoading = true);

      try {
        final transfer = TransferModel(
          id: '',
          fromAccountId: _fromAccountId!,
          toAccountId: _toAccountId!,
          amount: double.parse(_amountController.text),
          date: _selectedDate,
          note: _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
        );

        await _transferService.addTransfer(transfer);

        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Transfer added successfully')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e')),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  String _getAccountName(String accountId) {
    try {
      final account = _accounts.firstWhere((a) => a.id == accountId);
      return account.name;
    } catch (e) {
      return 'Unknown Account';
    }
  }

  IconData _getAccountIcon(String accountId) {
    try {
      final account = _accounts.firstWhere((a) => a.id == accountId);
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
    } catch (e) {
      return Icons.account_balance_wallet;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Transfer'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: _accounts.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.account_balance_wallet, size: 80, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'No accounts available',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Please add at least 2 accounts to make transfers',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          : _accounts.length < 2
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.account_balance_wallet, size: 80, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        'Need at least 2 accounts',
                        style: TextStyle(fontSize: 18, color: Colors.grey),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Please add one more account to make transfers',
                        style: TextStyle(fontSize: 14, color: Colors.grey),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // From Account
                        const Text(
                          'From Account',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          value: _fromAccountId,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.account_balance_wallet),
                            hintText: 'Select source account',
                          ),
                          items: _accounts.map((account) {
                            return DropdownMenuItem<String>(
                              value: account.id,
                              child: Row(
                                children: [
                                  Icon(_getAccountIcon(account.id), size: 20),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      account.name,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Text(
                                    '₹${account.balance.toStringAsFixed(2)}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              _fromAccountId = value;
                            });
                          },
                          validator: (value) {
                            if (value == null) {
                              return 'Please select source account';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 24),

                        // Transfer Icon
                        Center(
                          child: Icon(
                            Icons.arrow_downward,
                            size: 32,
                            color: Theme.of(context).primaryColor,
                          ),
                        ),
                        const SizedBox(height: 24),

                        // To Account
                        const Text(
                          'To Account',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          value: _toAccountId,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.account_balance_wallet),
                            hintText: 'Select destination account',
                          ),
                          items: _accounts.map((account) {
                            return DropdownMenuItem<String>(
                              value: account.id,
                              child: Row(
                                children: [
                                  Icon(_getAccountIcon(account.id), size: 20),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      account.name,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Text(
                                    '₹${account.balance.toStringAsFixed(2)}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              _toAccountId = value;
                            });
                          },
                          validator: (value) {
                            if (value == null) {
                              return 'Please select destination account';
                            }
                            if (value == _fromAccountId) {
                              return 'Cannot transfer to same account';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 24),

                        // Amount
                        TextFormField(
                          controller: _amountController,
                          decoration: const InputDecoration(
                            labelText: 'Amount',
                            hintText: '0.00',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.currency_rupee),
                          ),
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter amount';
                            }
                            if (double.tryParse(value) == null) {
                              return 'Please enter a valid number';
                            }
                            final amount = double.parse(value);
                            if (amount <= 0) {
                              return 'Amount must be greater than 0';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // Date
                        ListTile(
                          title: Text('Date: ${DateFormat('dd/MM/yyyy').format(_selectedDate)}'),
                          leading: const Icon(Icons.calendar_today),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                            side: BorderSide(color: Colors.grey.shade400),
                          ),
                          onTap: () => _selectDate(context),
                        ),
                        const SizedBox(height: 16),

                        // Note
                        TextFormField(
                          controller: _noteController,
                          decoration: const InputDecoration(
                            labelText: 'Note (Optional)',
                            hintText: 'Add transfer details',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.note),
                          ),
                          maxLines: 3,
                        ),
                        const SizedBox(height: 24),

                        // Save Button
                        ElevatedButton(
                          onPressed: _isLoading ? null : _saveTransfer,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.all(16),
                            backgroundColor: Colors.purple,
                            foregroundColor: Colors.white,
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text(
                                  'Transfer Money',
                                  style: TextStyle(fontSize: 16),
                                ),
                        ),
                      ],
                    ),
                  ),
                ),
    );
  }
}