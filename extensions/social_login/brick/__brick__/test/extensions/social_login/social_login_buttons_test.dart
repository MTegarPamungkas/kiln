import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kiln_core/kiln_core.dart';
import 'package:{{app_name}}/extensions/social_login/social_login_config.dart';
import 'package:{{app_name}}/extensions/social_login/widgets/social_login_buttons.dart';

import 'test_support.dart';

void main() {
  testWidgets('shows only ready providers', (tester) async {
    final login = FakeSocialLogin(credential: sampleGoogleCredential);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SocialLoginButtons(
            login: login,
            availability: androidAvailability(),
            config: const SocialLoginConfig(
              googleServerClientId: 'server',
              enabledProviders: <SocialProvider>{SocialProvider.google},
            ),
          ),
        ),
      ),
    );

    expect(find.text('Lanjut dengan Google'), findsOneWidget);
    expect(find.text('Lanjut dengan Apple'), findsNothing);
  });

  testWidgets('shows Apple natively on iOS without a service id', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SocialLoginButtons(
            login: FakeSocialLogin(),
            availability: iosAvailability(),
            config: const SocialLoginConfig(),
          ),
        ),
      ),
    );

    expect(find.text('Lanjut dengan Apple'), findsOneWidget);
    expect(find.text('Lanjut dengan Google'), findsNothing);
  });

  testWidgets('sends the chosen provider to SocialLogin', (tester) async {
    final login = FakeSocialLogin(credential: sampleGoogleCredential);
    SocialCredential? received;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SocialLoginButtons(
            login: login,
            availability: androidAvailability(),
            config: const SocialLoginConfig(googleServerClientId: 'server'),
            onCredential: (credential) => received = credential,
          ),
        ),
      ),
    );

    await tester.tap(find.text('Lanjut dengan Google'));
    await tester.pumpAndSettle();

    expect(login.providers, [SocialProvider.google]);
    expect(received, same(sampleGoogleCredential));
  });
}
