class FinanceLimits {
  FinanceLimits._();

  /// Límite razonable para entradas monetarias en una app de finanzas
  /// personales. Evita desbordamientos visuales y cálculos poco útiles.
  static const double maxAmount = 99999999.99;
}

class InputValidators {
  InputValidators._();

  static final RegExp _personNameRegex = RegExp(
    r"^[A-Za-zÁÉÍÓÚÜÑáéíóúüñ' -]+$",
  );

  static final RegExp _emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  static String? personName(String? value) {
    final name = value?.trim() ?? '';

    if (name.isEmpty) {
      return 'Ingresa tu nombre';
    }

    if (name.length < 3) {
      return 'Ingresa un nombre válido';
    }

    if (name.length > 80) {
      return 'El nombre es demasiado largo';
    }

    if (!_personNameRegex.hasMatch(name)) {
      return 'El nombre solo puede contener letras, espacios, guiones o apóstrofes';
    }

    return null;
  }

  static String? email(String? value) {
    final email = value?.trim() ?? '';

    if (email.isEmpty) {
      return 'Ingresa tu correo';
    }

    if (!_emailRegex.hasMatch(email)) {
      return 'Ingresa un correo válido';
    }

    return null;
  }

  static String? newPassword(String? value) {
    final password = value ?? '';

    if (password.isEmpty) {
      return 'Ingresa una contraseña';
    }

    if (password.length < 8) {
      return 'La contraseña debe tener al menos 8 caracteres';
    }

    if (!RegExp(r'[A-Za-z]').hasMatch(password) ||
        !RegExp(r'\d').hasMatch(password)) {
      return 'Usa al menos una letra y un número';
    }

    return null;
  }

  static double? parseAmount(String? value) {
    final normalized = (value ?? '').trim().replaceAll(',', '.');
    return double.tryParse(normalized);
  }

  static String? moneyAmount(
    String? value, {
    String emptyMessage = 'Ingresa el monto',
  }) {
    final normalized = (value ?? '').trim().replaceAll(',', '.');

    if (normalized.isEmpty) {
      return emptyMessage;
    }

    final amount = double.tryParse(normalized);

    if (amount == null || amount <= 0 || !amount.isFinite) {
      return 'Ingresa un monto válido';
    }

    if (amount > FinanceLimits.maxAmount) {
      return 'El monto máximo permitido es 99,999,999.99';
    }

    return null;
  }
}
