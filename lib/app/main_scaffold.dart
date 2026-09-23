import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/presentation/auth_provider.dart';

class MainScaffold extends ConsumerWidget {
  final StatefulNavigationShell navigationShell;

  const MainScaffold({super.key, required this.navigationShell});

  void _changeTab(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAdmin = ref.watch(isAdminProvider);

    // ==================================================
    // PROTECCIÓN DE ADMIN
    // ==================================================

    if (!isAdmin && navigationShell.currentIndex == 5) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        navigationShell.goBranch(0, initialLocation: true);
      });
    }

    // ==================================================
    // DESTINOS
    // ==================================================

    final destinations = <NavigationDestination>[
      const NavigationDestination(
        icon: Icon(Icons.home_outlined),
        selectedIcon: Icon(Icons.home),
        label: 'Inicio',
      ),

      const NavigationDestination(
        icon: Icon(Icons.payments_outlined),
        selectedIcon: Icon(Icons.payments),
        label: 'Gastos',
      ),

      const NavigationDestination(
        icon: Icon(Icons.account_balance_wallet_outlined),
        selectedIcon: Icon(Icons.account_balance_wallet),
        label: 'Presupuesto',
      ),

      const NavigationDestination(
        icon: Icon(Icons.bar_chart_outlined),
        selectedIcon: Icon(Icons.bar_chart),
        label: 'Estadísticas',
      ),

      const NavigationDestination(
        icon: Icon(Icons.calendar_month_outlined),
        selectedIcon: Icon(Icons.calendar_month),
        label: 'Pagos',
      ),
    ];

    if (isAdmin) {
      destinations.add(
        const NavigationDestination(
          icon: Icon(Icons.admin_panel_settings_outlined),
          selectedIcon: Icon(Icons.admin_panel_settings),
          label: 'Admin',
        ),
      );
    }

    final selectedIndex = navigationShell.currentIndex < destinations.length
        ? navigationShell.currentIndex
        : 0;

    // ==================================================
    // NAVEGACIÓN
    // ==================================================

    return Scaffold(
      body: navigationShell,

      bottomNavigationBar: NavigationBarTheme(
        data: NavigationBarThemeData(
          height: isAdmin ? 72 : 70,

          // Cuando existen 6 opciones reducimos
          // ligeramente el tamaño del texto.
          labelTextStyle: WidgetStateProperty.resolveWith((states) {
            final selected = states.contains(WidgetState.selected);

            return TextStyle(
              fontSize: isAdmin ? 9.5 : 11,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
            );
          }),

          iconTheme: WidgetStateProperty.resolveWith((states) {
            final selected = states.contains(WidgetState.selected);

            return IconThemeData(size: selected ? 24 : 22);
          }),
        ),
        child: NavigationBar(
          selectedIndex: selectedIndex,

          onDestinationSelected: _changeTab,

          // Todos los nombres siempre visibles.
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,

          destinations: destinations,
        ),
      ),
    );
  }
}
