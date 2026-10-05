import 'package:url_launcher/url_launcher.dart';

import '../payments/domain/payment.dart';

class CalendarService {
  CalendarService._();

  static String _twoDigits(int value) {
    return value.toString().padLeft(2, '0');
  }

  static String _formatDate(DateTime date) {
    return '${date.year}'
        '${_twoDigits(date.month)}'
        '${_twoDigits(date.day)}';
  }

  static Future<bool> addPaymentToGoogleCalendar(Payment payment) async {
    final startDate = DateTime(
      payment.dueDate.year,
      payment.dueDate.month,
      payment.dueDate.day,
    );

    final endDate = startDate.add(const Duration(days: 1));

    final uri = Uri.https('calendar.google.com', '/calendar/render', {
      'action': 'TEMPLATE',
      'text': 'Pago: ${payment.name}',
      'dates': '${_formatDate(startDate)}/${_formatDate(endDate)}',
      'details':
          'Pago registrado en FinTrack.\n'
          'Monto: \$${payment.amount.toStringAsFixed(2)} MXN.',
    });

    return launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}
