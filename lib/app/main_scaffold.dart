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

    // Si un usuario normal intenta entrar
    // directamente a la rama Admin.
    if (!isAdmin && navigationShell.currentIndex == 5) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        navigationShell.goBranch(0, initialLocation: true);
      });
    }

    const destinations = [
      NavigationDestination(
        icon: Icon(Icons.home_outlined),
        selectedIcon: Icon(Icons.home),
        label: 'Inicio',
      ),
      NavigationDestination(
        icon: Icon(Icons.payments_outlined),
        selectedIcon: Icon(Icons.payments),
        label: 'Gastos',
      ),
      NavigationDestination(
        icon: Icon(Icons.account_balance_wallet_outlined),
        selectedIcon: Icon(Icons.account_balance_wallet),
        label: 'Presupuesto',
      ),
      NavigationDestination(
        icon: Icon(Icons.bar_chart_outlined),
        selectedIcon: Icon(Icons.bar_chart),
        label: 'Estadísticas',
      ),
      NavigationDestination(
        icon: Icon(Icons.calendar_month_outlined),
        selectedIcon: Icon(Icons.calendar_month),
        label: 'Pagos',
      ),
    ];

    final isAdminPage = navigationShell.currentIndex == 5;

    return Scaffold(
      body: navigationShell,

      // Cuando estamos en Administración ocultamos
      // la barra inferior.
      bottomNavigationBar: isAdminPage
          ? null
          : NavigationBar(
              selectedIndex: navigationShell.currentIndex,
              onDestinationSelected: _changeTab,
              labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
              destinations: destinations,
            ),
    );
  }
}
