import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';

import '../boxes.dart';
import '../model/transaction.dart';
import '../widget/transaction_dialog.dart';

class TransactionPage extends StatefulWidget {
  @override
  _TransactionPageState createState() => _TransactionPageState();
}

class _TransactionPageState extends State<TransactionPage> {
  bool _isVisible = true;
  @override
  void dispose() {
    Hive.close();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            'My Expense',
            style: TextStyle(color: Colors.white),
          ),
          // centerTitle: true,
        ),
        body: ValueListenableBuilder<Box<Transaction>>(
          valueListenable: Boxes.getTransactions().listenable(),
          builder: (context, box, _) {
            final transactions = box.values.toList().cast<Transaction>();

            return buildContent(transactions);
          },
        ),
        floatingActionButton: AnimatedSlide(
          duration: Duration(milliseconds: 300),
          offset: _isVisible ? Offset.zero : Offset(0, 2),
          child: AnimatedOpacity(
            duration: Duration(milliseconds: 300),
            opacity: _isVisible ? 1 : 0,
            child: FloatingActionButton(
              onPressed: () => showDialog(
                context: context,
                builder: (context) => TransactionDialog(
                  onClickedDone: addTransaction,
                ),
              ),
              child: Icon(
                Icons.add,
                color: Colors.white,
                size: 30.0,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget buildContent(List<Transaction> transactions) {
    if (transactions.isEmpty) {
      return Center(
        child: Text(
          'No expenses yet!',
          style: TextStyle(fontSize: 24, color: Colors.black38),
        ),
      );
    } else {
      final netExpense = transactions.fold<double>(
        0,
        (previousValue, transaction) => transaction.isExpense
            ? previousValue - transaction.amount
            : previousValue + transaction.amount,
      );
      final newExpenseString = '\৳ ${netExpense.toStringAsFixed(2)}';
      final color = netExpense > 0 ? Colors.green : Colors.red;

      return Column(
        children: [
          SizedBox(height: 24),
          Card(
            elevation: 8.0,
            color: Colors.white,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
              child: Text(
                'Expense: $newExpenseString',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                  color: color,
                ),
              ),
            ),
          ),
          SizedBox(height: 16),
          Divider(
            thickness: 1.0,
            color: Colors.black26,
          ),
          Expanded(
            child: NotificationListener<UserScrollNotification>(
              onNotification: (notification) {
                if (notification.direction == ScrollDirection.forward) {
                  if (!_isVisible) setState(() => _isVisible = true);
                } else if (notification.direction == ScrollDirection.reverse) {
                  if (_isVisible) setState(() => _isVisible = false);
                }
                return true;
              },
              child: ListView.builder(
                padding: EdgeInsets.all(8),
                itemCount: transactions.length,
                itemBuilder: (BuildContext context, int index) {
                  final transaction = transactions[index];

                  return buildTransaction(context, transaction);
                },
              ),
            ),
          ),
        ],
      );
    }
  }

  Widget buildTransaction(
    BuildContext context,
    Transaction transaction,
  ) {
    final color = transaction.isExpense ? Colors.red : Colors.green;
    final date = DateFormat.yMMMd().format(transaction.createdDate);
    final amount = '\$' + transaction.amount.toStringAsFixed(2);

    return Card(
      color: Colors.white,
      elevation: 5.0,
      child: ExpansionTile(
        tilePadding: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        title: Text(
          transaction.name,
          maxLines: 2,
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        subtitle: Text(date),
        trailing: Text(
          amount,
          style: TextStyle(
              color: color, fontWeight: FontWeight.bold, fontSize: 16),
        ),
        children: [
          Divider(),
          buildButtons(context, transaction),
        ],
      ),
    );
  }

  Widget buildButtons(BuildContext context, Transaction transaction) => Row(
        children: [
          Expanded(
            child: TextButton.icon(
              label: Text(
                'Edit',
                style: TextStyle(color: Colors.amber),
              ),
              icon: Icon(
                Icons.edit,
                color: Colors.amber,
              ),
              onPressed: () {
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (context) => TransactionDialog(
                    onClickedDone: (name, amount, isExpense) =>
                        editTransaction(transaction, name, amount, isExpense),
                  ),
                );
              },
            ),
          ),
          Expanded(
            child: TextButton.icon(
              label: Text(
                'Delete',
                style: TextStyle(color: Colors.red),
              ),
              icon: Icon(
                Icons.delete,
                color: Colors.red,
              ),
              onPressed: () {
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (context) {
                    return AlertDialog(
                      backgroundColor: Colors.green[50],
                      title: Text('Confimation Delete'),
                      content:
                          Text('Are you sure you want to delete this item?'),
                      actions: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            MaterialButton(
                              onPressed: () {
                                Navigator.of(context).pop();
                              },
                              child: Text(
                                "Cancel",
                                style: TextStyle(color: Colors.white),
                              ),
                              color: Colors.green,
                            ),
                            MaterialButton(
                              onPressed: () {
                                Navigator.of(context).pop(true);
                                deleteTransaction(transaction);
                              },
                              child: Text(
                                "Delete",
                                style: TextStyle(color: Colors.white),
                              ),
                              color: Colors.red,
                            ),
                          ],
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          )
        ],
      );

  Future addTransaction(String name, double amount, bool isExpense) async {
    final transaction = Transaction()
      ..name = name
      ..createdDate = DateTime.now()
      ..amount = amount
      ..isExpense = isExpense;

    final box = Boxes.getTransactions();
    box.add(transaction);
  }

  void editTransaction(
    Transaction transaction,
    String name,
    double amount,
    bool isExpense,
  ) {
    transaction.name = name;
    transaction.amount = amount;
    transaction.isExpense = isExpense;

    transaction.save();
  }

  void deleteTransaction(Transaction transaction) {
    transaction.delete();
  }
}
