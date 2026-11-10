import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kiln_core/kiln_core.dart';
import 'package:full_stack/extensions/l10n/failure_messages.dart';
import 'package:full_stack/l10n/generated/app_localizations.dart';

void main() {
  group('L10nFailureMessages', () {
    const messages = L10nFailureMessages();

    test('has a friendly Indonesian message for every known code', () {
      final fallback = lookupAppLocalizations(const Locale('id'))
          .failureUnexpected;
      for (final code in FailureCode.known) {
        final text = messages.messageFor(
          Failure(code: code, message: 'raw technical message'),
        );

        expect(text, isNotEmpty, reason: code.value);
        expect(text, isNot('raw technical message'), reason: code.value);
        if (code != FailureCode.unexpected) {
          expect(text, isNot(fallback), reason: '${code.value} used fallback');
        }
      }
    });

    test('uses the unexpected fallback for unknown codes', () {
      final text = messages.messageFor(
        const Failure(
          code: FailureCode('feature.unknown'),
          message: 'raw technical message',
        ),
      );

      expect(
        text,
        lookupAppLocalizations(const Locale('id')).failureUnexpected,
      );
    });

    test('returns English copy when the locale resolver says en', () {
      final english = L10nFailureMessages(
        resolveLocale: () => const Locale('en'),
      );
      final text = english.messageFor(
        const Failure(code: FailureCode.networkOffline, message: 'offline'),
      );

      expect(
        text,
        lookupAppLocalizations(const Locale('en')).failureNetworkOffline,
      );
      expect(
        text,
        isNot(lookupAppLocalizations(const Locale('id')).failureNetworkOffline),
      );
    });

    test('follows a live locale resolver', () {
      var locale = const Locale('id');
      final live = L10nFailureMessages(resolveLocale: () => locale);
      const failure = Failure(
        code: FailureCode.storageWriteFailed,
        message: 'write failed',
      );

      expect(
        live.messageFor(failure),
        lookupAppLocalizations(const Locale('id')).failureStorage,
      );

      locale = const Locale('en');

      expect(
        live.messageFor(failure),
        lookupAppLocalizations(const Locale('en')).failureStorage,
      );
    });

    test('maps unsupported support states', () {
      final english = L10nFailureMessages(
        resolveLocale: () => const Locale('en'),
      );

      expect(
        english.messageFor(
          const Failure(
            code: FailureCode.unsupportedDevice,
            message: 'No sensor',
          ),
        ),
        lookupAppLocalizations(const Locale('en')).failureUnsupported,
      );
      expect(
        english.messageFor(
          const Failure(
            code: FailureCode.unsupportedPlatform,
            message: 'No web support',
          ),
        ),
        lookupAppLocalizations(const Locale('en')).failureUnsupported,
      );
    });

    test('maps cancelled groups to the cancellation copy', () {
      expect(
        messages.messageFor(
          const Failure(code: FailureCode.mediaCancelled, message: 'cancelled'),
        ),
        lookupAppLocalizations(const Locale('id')).failureCancelled,
      );
    });
  });
}
