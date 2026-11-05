import '../../command_context.dart';
import '../../infra/exit_codes.dart';
import 'ext_new_command.dart';
import 'ext_pack_command.dart';
import 'ext_publish_command.dart';
import 'ext_test_command.dart';
import 'ext_validate_command.dart';

/// Namespace for extension authoring tools.
final class ExtCommand extends KilnCommand {
  ExtCommand(super.context) {
    addSubcommand(ExtNewCommand(context));
    addSubcommand(ExtValidateCommand(context));
    addSubcommand(ExtTestCommand(context));
    addSubcommand(ExtPackCommand(context));
    addSubcommand(ExtPublishCommand(context));
  }

  @override
  String get name => 'ext';

  @override
  String get description => 'Tools for extension authors.';

  @override
  Future<int> run() async {
    printUsage();
    return ExitCodes.usage;
  }
}
