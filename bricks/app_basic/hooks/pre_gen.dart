import 'package:mason/mason.dart';

void run(HookContext context) {
  final name = context.vars['name'] as String? ?? '';
  if (!RegExp(r'^[a-z][a-z0-9_]*$').hasMatch(name)) {
    context.logger.err('Nama aplikasi harus snake_case.');
    return;
  }
  final org = context.vars['org'] as String? ?? '';
  if (!org.contains('.')) {
    context.logger.err('Org harus berbentuk seperti com.example.');
  }
}
