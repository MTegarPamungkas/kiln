import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kiln_core/kiln_core.dart';
import 'package:{{app_name}}/extensions/social_login/social_login_config.dart';
import 'package:{{app_name}}/extensions/social_login/widgets/social_login_panel.dart';

import 'test_support.dart';

const _config = SocialLoginConfig(googleServerClientId: 'server');

void main() {
  testWidgets('shows a failure message from the provider', (tester) async {
    final login = FakeSocialLogin(
      failure: const Failure(
        code: FailureCode.authProviderDisabled,
        message: 'Google belum siap.',
        kind: FailureKind.authentication,
      ),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SocialLoginPanel(
            login: login,
            availability: androidAvailability(),
            config: _config,
          ),
        ),
      ),
    );

    await tester.tap(find.text('Lanjut dengan Google'));
    await tester.pumpAndSettle();

    expect(find.text('Google belum siap.'), findsOneWidget);
  });

  testWidgets('shows progress while signing in', (tester) async {
    final completer = Completer<SocialCredential?>();
    final login = FakeSocialLogin(completer: completer);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SocialLoginPanel(
            login: login,
            availability: androidAvailability(),
            config: _config,
          ),
        ),
      ),
    );

    await tester.tap(find.text('Lanjut dengan Google'));
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    completer.complete(sampleGoogleCredential);
    await tester.pumpAndSettle();

    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('forwards the credential', (tester) async {
    final login = FakeSocialLogin(credential: sampleGoogleCredential);
    SocialCredential? received;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SocialLoginPanel(
            login: login,
            availability: androidAvailability(),
            config: _config,
            onCredential: (credential) => received = credential,
          ),
        ),
      ),
    );

    await tester.tap(find.text('Lanjut dengan Google'));
    await tester.pumpAndSettle();

    expect(received, same(sampleGoogleCredential));
  });
}
