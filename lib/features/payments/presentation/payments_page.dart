import 'package:flutter/material.dart';

import '../../../app/theme.dart';

class PaymentsPage extends StatelessWidget {
  const PaymentsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Próximos pagos',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: const SafeArea(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Center(
            child: Text(
              'Aquí administraremos tus próximos pagos.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18, color: AppColors.textSecondary),
            ),
          ),
        ),
      ),
    );
  }
}
