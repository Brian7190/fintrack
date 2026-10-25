import 'package:flutter_test/flutter_test.dart';
import 'package:fintrack/core/input_validators.dart';

void main() {
  group('InputValidators.personName', () {
    test('acepta nombres con acentos y espacios', () {
      expect(InputValidators.personName('José Ángel Hernández'), isNull);
    });

    test('rechaza números y símbolos no permitidos', () {
      expect(InputValidators.personName('Brian123'), isNotNull);
      expect(InputValidators.personName('Brian@'), isNotNull);
    });
  });

  group('InputValidators.newPassword', () {
    test('rechaza una contraseña formada solo por números', () {
      expect(InputValidators.newPassword('12345678'), isNotNull);
    });

    test('acepta una contraseña con letras y números', () {
      expect(InputValidators.newPassword('FinTrack2026'), isNull);
    });
  });

  group('InputValidators.moneyAmount', () {
    test('rechaza cantidades negativas o cero', () {
      expect(InputValidators.moneyAmount('0'), isNotNull);
      expect(InputValidators.moneyAmount('-10'), isNotNull);
    });

    test('rechaza cantidades fuera del límite', () {
      expect(InputValidators.moneyAmount('50000000000000000000'), isNotNull);
    });

    test('acepta una cantidad válida con dos decimales', () {
      expect(InputValidators.moneyAmount('1250.50'), isNull);
    });
  });
}
