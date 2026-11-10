import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Botón para usar como `leading` de un `AppBar`.
///
/// Si hay historial hace `pop()`; si no, navega a Home (`/`).
class BackOrHomeButton extends StatelessWidget {
  const BackOrHomeButton({super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      tooltip: 'Volver',
      onPressed: () {
        if (context.canPop()) {
          context.pop();
        } else {
          context.go('/');
        }
      },
    );
  }
}
