import 'package:args/command_runner.dart';
import 'package:kiln_core/kiln_core.dart';
import 'package:kiln_extension_sdk/kiln_extension_sdk.dart';
import 'package:kiln_store/kiln_store.dart';

import 'exit_codes.dart';
import 'kiln_logger.dart';

/// Converts known errors into a message and a stable exit code.
final class ErrorPresenter {
  const ErrorPresenter(this.logger);

  final KilnLogger logger;

  int present(Object error, [StackTrace? stackTrace]) {
    if (error is ResolutionException) {
      logger.error('Extensions cannot be installed together:');
      for (final conflict in error.conflicts) {
        logger.error('  ${conflict.message}');
        final suggestion = conflict.suggestion;
        if (suggestion != null) {
          logger.info('    hint: $suggestion');
        }
      }
      return ExitCodes.conflict;
    }
    if (error is KilnStoreException) {
      logger.error(error.message);
      final suggestion = error.suggestion;
      if (suggestion != null) {
        logger.info('Hint: $suggestion');
      }
      return _codeFor(error.code);
    }
    if (error is KilnException) {
      logger.error(error.message);
      final suggestion = error.suggestion;
      if (suggestion != null) {
        logger.info('Hint: $suggestion');
      }
      for (final entry in error.details.entries) {
        if (entry.key == 'stdout' || entry.key == 'stderr') {
          final text = '${entry.value}'.trim();
          if (text.isNotEmpty) {
            logger.info(text);
          }
        }
      }
      return _codeFor(error.code);
    }
    if (error is Failure) {
      logger.error('${error.code.value}: ${error.message}');
      return error.kind == FailureKind.network
          ? ExitCodes.network
          : ExitCodes.project;
    }
    if (error is UsageException) {
      logger.error(error.message);
      logger.info(error.usage);
      return ExitCodes.usage;
    }
    logger.error('Unexpected error: $error');
    if (stackTrace != null) {
      logger.detail(stackTrace.toString());
    }
    return ExitCodes.internal;
  }

  int _codeFor(String code) {
    if (code == 'hooks.untrusted' ||
        code == 'remove.dependents' ||
        code == 'install.conflict' ||
        code == 'store.untrusted' ||
        code == 'store.checksum_mismatch') {
      return ExitCodes.conflict;
    }
    if (code == 'store.fetch_failed' ||
        code == 'store.offline_missing' ||
        code.startsWith('network.')) {
      return ExitCodes.network;
    }
    if (code.startsWith('manifest.') ||
        code.startsWith('prompt.') ||
        code.startsWith('catalog.') ||
        code.startsWith('create.') ||
        code.startsWith('store.') ||
        code == 'project.not_found' ||
        code == 'remove.not_installed' ||
        code == 'ext.exists' ||
        code == 'ext.not_found') {
      return ExitCodes.project;
    }
    if (code.startsWith('verification.')) {
      return ExitCodes.verification;
    }
    return ExitCodes.internal;
  }
}
