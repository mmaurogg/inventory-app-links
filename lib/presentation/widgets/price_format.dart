/// Formatea un valor en centavos como texto, p. ej. `123456` -> `$1,234.56`.
String formatCents(int cents) {
  final negative = cents < 0;
  final abs = cents.abs();
  final whole = (abs ~/ 100).toString();
  final fraction = (abs % 100).toString().padLeft(2, '0');
  final grouped = whole.replaceAllMapped(
    RegExp(r'\B(?=(\d{3})+(?!\d))'),
    (_) => ',',
  );
  return '${negative ? '-' : ''}\$$grouped.$fraction';
}
