import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../domain/cart_controller.dart';
import '../widgets/back_or_home_button.dart';
import '../widgets/price_format.dart';

/// Carrito: líneas, botón eliminar y total.
class CartScreen extends StatelessWidget {
  const CartScreen({required this.cart, super.key});

  final CartController cart;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const BackOrHomeButton(),
        title: const Text('Carrito'),
      ),
      body: ListenableBuilder(
        listenable: cart,
        builder: (context, _) {
          if (cart.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Tu carrito está vacío'),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () => context.go('/'),
                    child: const Text('Ir al inicio'),
                  ),
                ],
              ),
            );
          }
          return Column(
            children: [
              Expanded(
                child: ListView(
                  children: [
                    for (final line in cart.lines)
                      ListTile(
                        title: Text(line.product.name),
                        subtitle: Text(
                          '${line.quantity} x '
                          '${formatCents(line.product.effectivePriceCents)}'
                          ' = ${formatCents(line.subtotalCents)}',
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete),
                          tooltip: 'Eliminar ${line.product.name}',
                          onPressed: () => cart.remove(line.product.id),
                        ),
                      ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Total: ${formatCents(cart.totalCents)}',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
