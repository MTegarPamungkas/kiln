import 'package:mason/mason.dart';

void run(HookContext context) {
  context.logger.info('Kiln app_basic rendered for ${context.vars['name']}.');
}
