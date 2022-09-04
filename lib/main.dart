import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'model/transaction.dart';
import 'page/transaction_page.dart';

Future main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();

  Hive.registerAdapter(TransactionAdapter());
  await Hive.openBox<Transaction>('transactions');

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: "My Expense",
      theme: ThemeData(primarySwatch: Colors.cyan),
      home: TransactionPage(),
    );
  }
}
