import 'package:flutter/material.dart';

void main() => runApp(const ExampleApp());

class ExampleApp extends StatelessWidget {
  const ExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Infobip Huawei Plugin',
      home: Scaffold(
        appBar: AppBar(title: const Text('Infobip Huawei Plugin')),
        body: const Center(
          child: Text('Plugin infrastructure is ready.'),
        ),
      ),
    );
  }
}
