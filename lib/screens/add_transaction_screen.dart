import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../models/transaction_model.dart';
import '../models/account_model.dart';
import '../services/transaction_service.dart';
import '../services/account_service.dart';
import '../utils/categories.dart';

class AddTransactionScreen extends StatefulWidget {
  final TransactionModel? transaction;

  const AddTransactionScreen({super.key, this.transaction});

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  
  final TransactionService _transactionService = TransactionService();
  final AccountService _accountService = AccountService();

  String _type = 'income';
  String? _selectedCategory;
  String? _selectedSubcategory;
  String? _paymentMethod;
  String? _fromAccount;
  String? _toAccount;
  DateTime _selectedDate = DateTime.now();
  bool _isRecurring = false;
  String _selectedFrequency = 'monthly';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.transaction != null) {
      _loadTransaction();
    } else {
      _selectedCategory = Categories.getMainCategories(_type)[0];
    }
  }

  void _loadTransaction() {
    final t = widget.transaction!;
    _type = t.type;
    _amountController.text = t.amount.toString();
    _selectedCategory = t.category;
    _selectedSubcategory = t.subcategory;
    _paymentMethod = t.paymentMethod;
    _fromAccount = t.fromAccount;
    _toAccount = t.toAccount;
    _selectedDate = t.date;
    _noteController.text = t.note ?? '';
    _isRecurring = t.isRecurring;
    _selectedFrequency = t.recurringFrequency ?? 'monthly';
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
      lastDate: DateTime(2030),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _saveTransaction() async {
    if (_formKey.currentState!.validate()) {
      if (_type == 'transfer') {
        if (_fromAccount == null || _toAccount == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please select both accounts for transfer')),
          );
          return;
        }
        if (_fromAccount == _toAccount) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('From and To accounts must be different')),
          );
          return;
        }
      }

      setState(() {
        _isLoading = true;
      });

      try {
        final transaction = TransactionModel(
          id: widget.transaction?.id ?? '',
          type: _type,
          amount: double.parse(_amountController.text),
          category: _type == 'transfer' ? 'Transfer' : _selectedCategory!,
          subcategory: _selectedSubcategory,
          paymentMethod: _type == 'expense' ? _paymentMethod : null,
          date: _selectedDate,
          note: _noteController.text.isEmpty ? null : _noteController.text,
          fromAccount: _type == 'transfer' 
              ? _fromAccount 
              : (_type == 'expense' ? _fromAccount : null),
          toAccount: _type == 'transfer' 
              ? _toAccount 
              : (_type == 'income' ? _fromAccount : null),
          isRecurring: _isRecurring,
          recurringFrequency: _isRecurring ? _selectedFrequency : null,
        );

        if (widget.transaction != null) {
          await _transactionService.updateTransaction(transaction.id, transaction);
        } else {
          await _transactionService.addTransaction(transaction);
        }

        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(widget.transaction != null
                  ? 'Transaction updated!'
                  : 'Transaction added!'),
              backgroundColor: Colors.green,
            ),
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
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  IconData _getAccountIcon(String type) {
    switch (type.toLowerCase()) {
      case 'bank':
        return Icons.account_balance;
      case 'cash':
        return Icons.money;
      case 'credit card':
      case 'card':
        return Icons.credit_card;
      case 'wallet':
        return Icons.account_balance_wallet;
      case 'loan':
        return Icons.trending_down;
      default:
        return Icons.account_circle;
    }
  }

  @override
  Widget build(BuildContext context) {
    final categories = Categories.getMainCategories(_type);
    
    if (!categories.contains(_selectedCategory)) {
      _selectedCategory = categories[0];
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.transaction != null ? 'Edit Transaction' : 'Add Transaction'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ListTile(
                title: Text('Date: ${DateFormat('dd MMM yyyy').format(_selectedDate)}'),
                leading: const Icon(Icons.calendar_today),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                  side: BorderSide(color: Colors.grey.shade400),
                ),
                onTap: () => _selectDate(context),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: RadioListTile<String>(
                      title: const Text('Income', style: TextStyle(fontSize: 14)),
                      value: 'income',
                      groupValue: _type,
                      onChanged: (value) {
                        setState(() {
                          _type = value!;
                          _selectedCategory = Categories.getMainCategories(_type)[0];
                          _selectedSubcategory = null;
                        });
                      },
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  Expanded(
                    child: RadioListTile<String>(
                      title: const Text('Expense', style: TextStyle(fontSize: 14)),
                      value: 'expense',
                      groupValue: _type,
                      onChanged: (value) {
                        setState(() {
                          _type = value!;
                          _selectedCategory = Categories.getMainCategories(_type)[0];
                          _selectedSubcategory = null;
                        });
                      },
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  Expanded(
                    child: RadioListTile<String>(
                      title: const Text('Transfer', style: TextStyle(fontSize: 14)),
                      value: 'transfer',
                      groupValue: _type,
                      onChanged: (value) {
                        setState(() {
                          _type = value!;
                        });
                      },
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _amountController,
                decoration: const InputDecoration(
                  labelText: 'Amount',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.currency_rupee),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter an amount';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Please enter a valid number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              if (_type != 'transfer')
                DropdownButtonFormField<String>(
                  value: _selectedCategory,
                  decoration: const InputDecoration(
                    labelText: 'Category',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.category),
                  ),
                  items: categories.map((String category) {
                    return DropdownMenuItem<String>(
                      value: category,
                      child: Text(category),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      _selectedCategory = newValue!;
                      _selectedSubcategory = null;
                    });
                  },
                ),
              if (_type != 'transfer') const SizedBox(height: 16),
              if (_type != 'transfer' && _selectedCategory != null)
                Builder(
                  builder: (context) {
                    final subcategories = Categories.getSubcategories(_type, _selectedCategory!);
                    if (subcategories.isEmpty) return const SizedBox.shrink();
                    
                    return Column(
                      children: [
                        DropdownButtonFormField<String>(
                          value: _selectedSubcategory,
                          decoration: const InputDecoration(
                            labelText: 'Subcategory (Optional)',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.subdirectory_arrow_right),
                          ),
                          items: [
                            const DropdownMenuItem<String>(
                              value: null,
                              child: Text('None'),
                            ),
                            ...subcategories.map((String subcat) {
                              return DropdownMenuItem<String>(
                                value: subcat,
                                child: Text(subcat),
                              );
                            }).toList(),
                          ],
                          onChanged: (String? newValue) {
                            setState(() {
                              _selectedSubcategory = newValue;
                            });
                          },
                        ),
                        const SizedBox(height: 16),
                      ],
                    );
                  },
                ),
              if (_type == 'transfer') ...[
                StreamBuilder<List<AccountModel>>(
                  stream: _accountService.getAccounts(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const CircularProgressIndicator();
                    }
                    final accounts = snapshot.data!;
                    return Column(
                      children: [
                        DropdownButtonFormField<String>(
                          value: _fromAccount,
                          decoration: const InputDecoration(
                            labelText: 'From Account',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.account_balance_wallet),
                          ),
                          items: accounts.map((account) {
                            return DropdownMenuItem<String>(
                              value: account.id,
                              child: Row(
                                children: [
                                  Icon(_getAccountIcon(account.type), size: 20),
                                  const SizedBox(width: 8),
                                  Text(account.name),
                                ],
                              ),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              _fromAccount = value;
                            });
                          },
                          validator: (value) {
                            if (_type == 'transfer' && value == null) {
                              return 'Please select from account';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          value: _toAccount,
                          decoration: const InputDecoration(
                            labelText: 'To Account',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.account_balance_wallet),
                          ),
                          items: accounts.map((account) {
                            return DropdownMenuItem<String>(
                              value: account.id,
                              child: Row(
                                children: [
                                  Icon(_getAccountIcon(account.type), size: 20),
                                  const SizedBox(width: 8),
                                  Text(account.name),
                                ],
                              ),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              _toAccount = value;
                            });
                          },
                          validator: (value) {
                            if (_type == 'transfer' && value == null) {
                              return 'Please select to account';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                      ],
                    );
                  },
                ),
              ],
              if (_type != 'transfer')
                StreamBuilder<List<AccountModel>>(
                  stream: _accountService.getAccounts(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const SizedBox.shrink();
                    }
                    final accounts = snapshot.data!;
                    return Column(
                      children: [
                        DropdownButtonFormField<String>(
                          value: _fromAccount,
                          decoration: InputDecoration(
                            labelText: _type == 'income' ? 'To Account (Optional)' : 'From Account (Optional)',
                            border: const OutlineInputBorder(),
                            prefixIcon: const Icon(Icons.account_balance_wallet),
                          ),
                          items: [
                            const DropdownMenuItem<String>(
                              value: null,
                              child: Text('No account selected'),
                            ),
                            ...accounts.map((account) {
                              return DropdownMenuItem<String>(
                                value: account.id,
                                child: Row(
                                  children: [
                                    Icon(_getAccountIcon(account.type), size: 20),
                                    const SizedBox(width: 8),
                                    Text(account.name),
                                  ],
                                ),
                              );
                            }).toList(),
                          ],
                          onChanged: (value) {
                            setState(() {
                              _fromAccount = value;
                            });
                          },
                        ),
                        const SizedBox(height: 16),
                      ],
                    );
                  },
                ),
              if (_type == 'expense')
                DropdownButtonFormField<String>(
                  value: _paymentMethod,
                  decoration: const InputDecoration(
                    labelText: 'Payment Method (Optional)',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.payment),
                  ),
                  items: const [
                    DropdownMenuItem(value: null, child: Text('Not specified')),
                    DropdownMenuItem(value: 'Cash', child: Text('Cash')),
                    DropdownMenuItem(value: 'Debit Card', child: Text('Debit Card')),
                    DropdownMenuItem(value: 'Credit Card', child: Text('Credit Card')),
                    DropdownMenuItem(value: 'UPI', child: Text('UPI')),
                    DropdownMenuItem(value: 'Net Banking', child: Text('Net Banking')),
                    DropdownMenuItem(value: 'Wallet', child: Text('Digital Wallet')),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _paymentMethod = value;
                    });
                  },
                ),
              if (_type == 'expense') const SizedBox(height: 16),
              TextFormField(
                controller: _noteController,
                decoration: const InputDecoration(
                  labelText: 'Notes (Optional)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.note),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                title: const Text('Recurring Transaction'),
                subtitle: Text(_isRecurring ? 'Repeats $_selectedFrequency' : 'One-time'),
                value: _isRecurring,
                onChanged: (value) {
                  setState(() {
                    _isRecurring = value;
                  });
                },
              ),
              if (_isRecurring) ...[
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _selectedFrequency,
                  decoration: const InputDecoration(
                    labelText: 'Repeat Frequency',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.repeat),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'daily', child: Text('Daily')),
                    DropdownMenuItem(value: 'weekly', child: Text('Weekly')),
                    DropdownMenuItem(value: 'monthly', child: Text('Monthly')),
                    DropdownMenuItem(value: 'yearly', child: Text('Yearly')),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedFrequency = value!;
                    });
                  },
                ),
              ],
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : _saveTransaction,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                  backgroundColor: _type == 'income'
                      ? Colors.green
                      : _type == 'expense'
                          ? Colors.red
                          : Colors.blue,
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
                    : Text(
                        widget.transaction != null
                            ? 'Update Transaction'
                            : 'Add Transaction',
                        style: const TextStyle(fontSize: 16),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
