import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../app/theme.dart';
import '../../auth/presentation/auth_provider.dart';
import '../domain/admin_user_budget.dart';
import '../domain/admin_user_summary.dart';
import 'admin_provider.dart';

final NumberFormat _moneyFormat = NumberFormat.currency(
  locale: 'es_MX',
  symbol: '\$',
  decimalDigits: 2,
);

final DateFormat _dateFormat = DateFormat('dd/MM/yyyy · HH:mm');

class AdminUserDetailPage extends ConsumerWidget {
  final String userId;

  const AdminUserDetailPage({super.key, required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAdmin = ref.watch(isAdminProvider);

    if (!isAdmin) {
      return const _AccessDenied();
    }

    final usersAsync = ref.watch(adminUsersProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Detalle del usuario')),
      body: SafeArea(
        child: usersAsync.when(
          loading: () {
            return const Center(child: CircularProgressIndicator());
          },
          error: (error, stackTrace) {
            return const _GeneralError(
              message: 'No fue posible cargar la información del usuario.',
            );
          },
          data: (users) {
            AdminUserSummary? selectedUser;

            for (final user in users) {
              if (user.uid == userId) {
                selectedUser = user;
                break;
              }
            }

            if (selectedUser == null) {
              return const _GeneralError(
                message: 'No se encontró el usuario seleccionado.',
              );
            }

            return _UserDetailContent(user: selectedUser);
          },
        ),
      ),
    );
  }
}

// ====================================================
// CONTENIDO PRINCIPAL
// ====================================================

class _UserDetailContent extends ConsumerWidget {
  final AdminUserSummary user;

  const _UserDetailContent({required this.user});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ==================================================
          // PERFIL
          // ==================================================
          _UserHeader(user: user),

          const SizedBox(height: 28),

          // ==================================================
          // INFORMACIÓN FINANCIERA
          // ==================================================
          const _SectionHeader(
            title: 'Información financiera',
            subtitle: 'Resumen del presupuesto y gastos del mes actual.',
          ),

          const SizedBox(height: 14),

          _FinancialSummary(userId: user.uid),

          const SizedBox(height: 30),

          // ==================================================
          // ACTIVIDAD
          // ==================================================
          const _SectionHeader(
            title: 'Actividad',
            subtitle: 'Información relacionada con el uso de FinTrack.',
          ),

          const SizedBox(height: 14),

          _ActivityCard(user: user),
        ],
      ),
    );
  }
}

// ====================================================
// ENCABEZADO DEL USUARIO
// ====================================================

class _UserHeader extends StatelessWidget {
  final AdminUserSummary user;

  const _UserHeader({required this.user});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.primaryDark,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryDark.withValues(alpha: 0.16),
            blurRadius: 18,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.person_outline,
              size: 30,
              color: Colors.white,
            ),
          ),

          const SizedBox(width: 16),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.name.trim().isEmpty ? 'Sin nombre' : user.name,
                  style: const TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),

                const SizedBox(height: 5),

                Text(
                  user.email,
                  style: const TextStyle(fontSize: 13, color: Colors.white70),
                ),

                const SizedBox(height: 12),

                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    user.isAdmin ? 'Administrador' : 'Usuario',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ====================================================
// ENCABEZADO DE SECCIÓN
// ====================================================

class _SectionHeader extends StatelessWidget {
  final String title;
  final String subtitle;

  const _SectionHeader({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),

        const SizedBox(height: 5),

        Text(
          subtitle,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 13,
            height: 1.4,
          ),
        ),
      ],
    );
  }
}

// ====================================================
// RESUMEN FINANCIERO EN TIEMPO REAL
// ====================================================

class _FinancialSummary extends ConsumerWidget {
  final String userId;

  const _FinancialSummary({required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final budgetAsync = ref.watch(adminUserBudgetProvider(userId));

    final spentAsync = ref.watch(adminUserSpentProvider(userId));

    if (budgetAsync.isLoading || spentAsync.isLoading) {
      return const _FinancialLoading();
    }

    if (budgetAsync.hasError) {
      return _FinancialError(error: budgetAsync.error);
    }

    if (spentAsync.hasError) {
      return _FinancialError(error: spentAsync.error);
    }

    final budget = budgetAsync.asData?.value;

    final spent = spentAsync.asData?.value ?? 0;

    // ==================================================
    // SIN PRESUPUESTO
    // ==================================================

    if (budget == null) {
      return _NoBudgetCard(spent: spent);
    }

    // ==================================================
    // CÁLCULOS
    // ==================================================

    final available = budget.amount - spent;

    final isOverBudget = available < 0;

    final percentageUsed = budget.amount <= 0
        ? 0.0
        : (spent / budget.amount) * 100;

    final progress = budget.amount <= 0
        ? 0.0
        : (spent / budget.amount).clamp(0.0, 1.0).toDouble();

    return _FinancialCard(
      budget: budget,
      spent: spent,
      available: available,
      percentageUsed: percentageUsed,
      progress: progress,
      isOverBudget: isOverBudget,
    );
  }
}

// ====================================================
// TARJETA FINANCIERA
// ====================================================

class _FinancialCard extends StatelessWidget {
  final AdminUserBudget budget;
  final double spent;
  final double available;
  final double percentageUsed;
  final double progress;
  final bool isOverBudget;

  const _FinancialCard({
    required this.budget,
    required this.spent,
    required this.available,
    required this.percentageUsed,
    required this.progress,
    required this.isOverBudget,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ==================================================
          // MES
          // ==================================================
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: const Icon(
                  Icons.account_balance_wallet_outlined,
                  color: AppColors.primaryDark,
                ),
              ),

              const SizedBox(width: 14),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Estado financiero actual',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),

                    const SizedBox(height: 3),

                    Text(
                      budget.periodLabel,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // ==================================================
          // ALERTA
          // ==================================================
          if (isOverBudget) ...[
            const SizedBox(height: 18),

            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.errorSoft,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    size: 17,
                    color: AppColors.error,
                  ),
                  SizedBox(width: 6),
                  Text(
                    'PRESUPUESTO EXCEDIDO',
                    style: TextStyle(
                      color: AppColors.error,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 22),

          // ==================================================
          // DISPONIBLE / SALDO
          // ==================================================
          Text(
            isOverBudget ? 'Saldo' : 'Disponible',
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),

          const SizedBox(height: 5),

          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              _moneyFormat.format(available),
              style: TextStyle(
                fontSize: 34,
                height: 1,
                fontWeight: FontWeight.bold,
                color: isOverBudget ? AppColors.error : AppColors.primaryDark,
              ),
            ),
          ),

          const SizedBox(height: 22),

          // ==================================================
          // BARRA
          // ==================================================
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: AppColors.border,
              color: AppColors.primary,
            ),
          ),

          const SizedBox(height: 9),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${percentageUsed.toStringAsFixed(1)}% utilizado',
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
              ),

              if (isOverBudget)
                Text(
                  'Exceso: ${_moneyFormat.format(spent - budget.amount)}',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.error,
                  ),
                ),
            ],
          ),

          const SizedBox(height: 22),

          // ==================================================
          // PRESUPUESTO + GASTADO
          // ==================================================
          Row(
            children: [
              Expanded(
                child: _FinancialMetric(
                  label: 'Presupuesto',
                  value: _moneyFormat.format(budget.amount),
                  icon: Icons.account_balance_wallet_outlined,
                ),
              ),

              const SizedBox(width: 10),

              Expanded(
                child: _FinancialMetric(
                  label: 'Gastado',
                  value: _moneyFormat.format(spent),
                  icon: Icons.payments_outlined,
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          // ==================================================
          // SOLO LECTURA
          // ==================================================
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(
              color: AppColors.surfaceAlt,
              borderRadius: BorderRadius.circular(13),
            ),
            child: const Row(
              children: [
                Icon(
                  Icons.visibility_outlined,
                  size: 19,
                  color: AppColors.primaryDark,
                ),
                SizedBox(width: 9),
                Expanded(
                  child: Text(
                    'Información actualizada en tiempo real y disponible únicamente para consulta.',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),

          if (budget.updatedAt != null) ...[
            const SizedBox(height: 12),

            Text(
              'Presupuesto actualizado: '
              '${_dateFormat.format(budget.updatedAt!)}',
              style: const TextStyle(
                fontSize: 10,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ====================================================
// MÉTRICA FINANCIERA
// ====================================================

class _FinancialMetric extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _FinancialMetric({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: AppColors.primaryDark),

          const SizedBox(height: 10),

          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
          ),

          const SizedBox(height: 4),

          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ====================================================
// SIN PRESUPUESTO
// ====================================================

class _NoBudgetCard extends StatelessWidget {
  final double spent;

  const _NoBudgetCard({required this.spent});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.account_balance_wallet_outlined,
            size: 38,
            color: AppColors.primaryDark,
          ),

          const SizedBox(height: 12),

          const Text(
            'Sin presupuesto configurado',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),

          const SizedBox(height: 5),

          const Text(
            'Este usuario todavía no ha establecido un presupuesto para el mes actual.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),

          if (spent > 0) ...[
            const SizedBox(height: 18),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(13),
              ),
              child: Column(
                children: [
                  const Text(
                    'Gastos registrados este mes',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),

                  const SizedBox(height: 5),

                  Text(
                    _moneyFormat.format(spent),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ====================================================
// CARGANDO FINANZAS
// ====================================================

class _FinancialLoading extends StatelessWidget {
  const _FinancialLoading();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 210,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: const Center(child: CircularProgressIndicator()),
    );
  }
}

// ====================================================
// ERROR FINANCIERO
// ====================================================

class _FinancialError extends StatelessWidget {
  final Object? error;

  const _FinancialError({required this.error});

  @override
  Widget build(BuildContext context) {
    final permissionDenied =
        error?.toString().contains('permission-denied') ?? false;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.errorSoft,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppColors.error),

          const SizedBox(width: 12),

          Expanded(
            child: Text(
              permissionDenied
                  ? 'La cuenta administradora no tiene permiso para consultar esta información.'
                  : 'No fue posible cargar la información financiera.',
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}

// ====================================================
// ACTIVIDAD
// ====================================================

class _ActivityCard extends StatelessWidget {
  final AdminUserSummary user;

  const _ActivityCard({required this.user});

  @override
  Widget build(BuildContext context) {
    final lastLogin = user.lastLogin == null
        ? 'Sin accesos registrados'
        : _dateFormat.format(user.lastLogin!);

    final createdAt = user.createdAt == null
        ? 'No disponible'
        : _dateFormat.format(user.createdAt!);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          _ActivityRow(
            icon: Icons.login_outlined,
            title: 'Inicios de sesión',
            value: '${user.loginCount}',
          ),

          const Divider(height: 1),

          _ActivityRow(
            icon: Icons.schedule_outlined,
            title: 'Último acceso',
            value: lastLogin,
          ),

          const Divider(height: 1),

          _ActivityRow(
            icon: Icons.person_add_alt_outlined,
            title: 'Cuenta creada',
            value: createdAt,
          ),
        ],
      ),
    );
  }
}

class _ActivityRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const _ActivityRow({
    required this.icon,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primarySoft,
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icon, size: 20, color: AppColors.primaryDark),
          ),

          const SizedBox(width: 13),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),

                const SizedBox(height: 3),

                Text(
                  value,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ====================================================
// ACCESO DENEGADO
// ====================================================

class _AccessDenied extends StatelessWidget {
  const _AccessDenied();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.lock_outline, size: 56, color: AppColors.error),

                SizedBox(height: 16),

                Text(
                  'Acceso restringido',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),

                SizedBox(height: 8),

                Text(
                  'Esta sección está disponible únicamente para administradores.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ====================================================
// ERROR GENERAL
// ====================================================

class _GeneralError extends StatelessWidget {
  final String message;

  const _GeneralError({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppColors.error),

            const SizedBox(height: 14),

            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
