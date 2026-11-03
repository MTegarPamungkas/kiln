import '../command_context.dart';
import '../infra/exit_codes.dart';

/// Prints a shell completion script.
final class CompletionCommand extends KilnCommand {
  CompletionCommand(super.context);

  static const _commands =
      'create add remove upgrade rollback list info graph doctor config '
      'cache store completion ext version';

  @override
  String get name => 'completion';

  @override
  String get description => 'Print a shell completion script.';

  @override
  String get invocation => 'kiln completion <bash|zsh|fish>';

  @override
  Future<int> run() async {
    final rest = argResults!.rest;
    if (rest.isEmpty) {
      usageException('Choose a shell: bash, zsh, or fish.');
    }
    final shell = rest.first;
    if (shell != 'bash' && shell != 'zsh' && shell != 'fish') {
      usageException('Unknown shell: $shell');
    }
    final script = switch (shell) {
      'bash' =>
        '''
_kiln_complete() {
  local commands="$_commands"
  COMPREPLY=( \$(compgen -W "\$commands" -- "\${COMP_WORDS[COMP_CWORD]}") )
}
complete -F _kiln_complete kiln
''',
      'zsh' =>
        '''
#compdef kiln
_kiln() {
  local -a commands
  commands=($_commands)
  _describe 'command' commands
}
compdef _kiln kiln
''',
      'fish' => 'complete -c kiln -f -a "$_commands"\n',
      _ => '',
    };
    logger.info(script.trimRight());
    return ExitCodes.success;
  }
}
