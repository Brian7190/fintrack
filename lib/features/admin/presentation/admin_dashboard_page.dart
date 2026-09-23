import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../app/theme.dart';
import '../../auth/presentation/auth_provider.dart';
import '../domain/admin_user_summary.dart';
import 'admin_provider.dart';

class AdminDashboardPage extends ConsumerWidget {
  const AdminDashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // ==================================================
    // VALIDAR QUE SEA ADMINISTRADOR
    // ==================================================

    final isAdmin = ref.watch(isAdminProvider);

    if (!isAdmin) {
      return const _AccessDenied();
    }

    // ==================================================
    // DATOS DEL PANEL
    // ==================================================

    final usersState = ref.watch(adminUsersProvider);

    final totalUsers = ref.watch(totalRegisteredUsersProvider);

    final totalLogins = ref.watch(totalLoginCountProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Administración')),
      body: SafeArea(
        child: usersState.when(
          // ==============================================
          // CARGANDO
          // ==============================================
          loading: () {
            return const Center(child: CircularProgressIndicator());
          },

          // ==============================================
          // ERROR
          // ==============================================
          error: (error, stackTrace) {
            return _AdminError(error: error);
          },

          // ==============================================
          // DATOS
          // ==============================================
          data: (users) {
            final normalUsers = users.where((user) => !user.isAdmin).toList();

            return RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(adminUsersProvider);

                await ref.read(adminUsersProvider.future);
              },
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 100),
                children: [
                  // ======================================
                  // ENCABEZADO
                  // ======================================
                  const _AdminHeader(),

                  const SizedBox(height: 22),

                  // ======================================
                  // MÉTRICAS
                  // ======================================
                  Row(
                    children: [
                      Expanded(
                        child: _MetricCard(
                          icon: Icons.people_outline,
                          title: 'Usuarios registrados',
                          value: '$totalUsers',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _MetricCard(
                          icon: Icons.login_outlined,
                          title: 'Inicios de sesión',
                          value: '$totalLogins',
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 30),

                  // ======================================
                  // USUARIOS
                  // ======================================
                  const Text(
                    'Usuarios',
                    style: TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),

                  const SizedBox(height: 5),

                  const Text(
                    'Selecciona un usuario para consultar su información y presupuesto actual.',
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.4,
                      color: AppColors.textSecondary,
                    ),
                  ),

                  const SizedBox(height: 16),

                  if (normalUsers.isEmpty)
                    const _NoUsers()
                  else
                    for (final user in normalUsers)
                      _UserCard(
                        user: user,
                        onTap: () {
                          context.push('/admin/user/${user.uid}');
                        },
                      ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

// ====================================================
// ENCABEZADO
// ====================================================

class _AdminHeader extends StatelessWidget {
  const _AdminHeader();

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
            color: AppColors.primaryDark.withValues(alpha: 0.17),
            blurRadius: 18,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.admin_panel_settings_outlined,
              size: 30,
              color: Colors.white,
            ),
          ),

          const SizedBox(width: 16),

          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Panel administrativo',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),

                SizedBox(height: 6),

                Text(
                  'Consulta los usuarios registrados y su actividad dentro de FinTrack.',
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.4,
                    color: Colors.white70,
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
// MÉTRICAS
// ====================================================

class _MetricCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const _MetricCard({
    required this.icon,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primarySoft,
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icon, color: AppColors.primaryDark, size: 21),
          ),

          const SizedBox(height: 14),

          Text(
            value,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),

          const SizedBox(height: 3),

          Text(
            title,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

// ====================================================
// TARJETA DEL USUARIO
// ====================================================

class _UserCard extends StatelessWidget {
  final AdminUserSummary user;
  final VoidCallback onTap;

  const _UserCard({required this.user, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy · HH:mm');

    final lastLogin = user.lastLogin == null
        ? 'Sin accesos'
        : dateFormat.format(user.lastLogin!);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(17),
          child: Ink(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(17),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // ======================================
                // ICONO
                // ======================================
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.primarySoft,
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: const Icon(
                    Icons.person_outline,
                    color: AppColors.primaryDark,
                    size: 25,
                  ),
                ),

                const SizedBox(width: 14),

                // ======================================
                // INFORMACIÓN
                // ======================================
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.name.isEmpty ? 'Sin nombre' : user.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),

                      const SizedBox(height: 3),

                      Text(
                        user.email,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),

                      const SizedBox(height: 9),

                      Row(
                        children: [
                          const Icon(
                            Icons.schedule_outlined,
                            size: 14,
                            color: AppColors.textSecondary,
                          ),

                          const SizedBox(width: 5),

                          Expanded(
                            child: Text(
                              lastLogin,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 10),

                // ======================================
                // ACCESOS
                // ======================================
                Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceAlt,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        children: [
                          Text(
                            '${user.loginCount}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppColors.primaryDark,
                            ),
                          ),
                          const Text(
                            'accesos',
                            style: TextStyle(
                              fontSize: 9,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 8),

                    const Icon(
                      Icons.chevron_right,
                      size: 20,
                      color: AppColors.textSecondary,
                    ),
                  ],
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
// SIN USUARIOS
// ====================================================

class _NoUsers extends StatelessWidget {
  const _NoUsers();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(26),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: const Column(
        children: [
          Icon(Icons.people_outline, size: 40, color: AppColors.primaryDark),

          SizedBox(height: 12),

          Text(
            'No hay usuarios registrados',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),

          SizedBox(height: 5),

          Text(
            'Las cuentas registradas aparecerán en esta sección.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
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
// ERROR
// ====================================================

class _AdminError extends StatelessWidget {
  final Object error;

  const _AdminError({required this.error});

  @override
  Widget build(BuildContext context) {
    final permissionDenied = error.toString().contains('permission-denied');

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppColors.error),

            const SizedBox(height: 14),

            const Text(
              'No fue posible cargar la información',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              permissionDenied
                  ? 'La cuenta administradora no tiene los permisos necesarios en Firestore.'
                  : 'Inténtalo nuevamente.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
