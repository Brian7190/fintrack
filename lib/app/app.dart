import 'package:flutter/material.dart';

import 'router.dart';
import 'theme.dart';

class FinTrackApp extends StatelessWidget {
  const FinTrackApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'FinTrack',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      routerConfig: appRouter,

      // Evita que las pantallas se estiren
      // cuando el usuario intenta desplazarse
      // más allá del inicio o del final.
      scrollBehavior: const FinTrackScrollBehavior(),
    );
  }
}

class FinTrackScrollBehavior extends MaterialScrollBehavior {
  const FinTrackScrollBehavior();

  @override
  Widget buildOverscrollIndicator(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) {
    return child;
  }

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) {
    return const ClampingScrollPhysics();
  }
}
