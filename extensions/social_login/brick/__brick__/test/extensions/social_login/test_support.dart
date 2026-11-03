import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:kiln_core/kiln_core.dart';
import 'package:{{app_name}}/extensions/social_login/apple_credential_gateway.dart';
import 'package:{{app_name}}/extensions/social_login/google_credential_gateway.dart';
import 'package:{{app_name}}/extensions/social_login/social_availability.dart';

const SocialCredential sampleGoogleCredential = SocialCredential(
  provider: SocialProvider.google,
  idToken: 'google-id-token',
  email: 'user@gmail.com',
  displayName: 'Tegar',
);

const SocialCredential sampleAppleCredential = SocialCredential(
  provider: SocialProvider.apple,
  idToken: 'apple-id-token',
  email: 'user@privaterelay.appleid.com',
);

final class FakeGoogleCredentialGateway implements GoogleCredentialGateway {
  SocialCredential? credential;
  Object? failure;
  int signOutCalls = 0;
  String? clientId;
  String? serverClientId;

  @override
  Future<SocialCredential?> signIn({
    String? clientId,
    String? serverClientId,
  }) async {
    this.clientId = clientId;
    this.serverClientId = serverClientId;
    final error = failure;
    if (error != null) {
      throw error;
    }
    return credential;
  }

  @override
  Future<void> signOut() async {
    signOutCalls++;
  }
}

final class FakeAppleCredentialGateway implements AppleCredentialGateway {
  SocialCredential? credential;
  Object? failure;
  String? nonce;
  String? nonceSha256;
  String? serviceId;
  String? redirectUri;

  @override
  Future<SocialCredential?> signIn({
    required String nonce,
    required String nonceSha256,
    String? serviceId,
    String? redirectUri,
  }) async {
    this.nonce = nonce;
    this.nonceSha256 = nonceSha256;
    this.serviceId = serviceId;
    this.redirectUri = redirectUri;
    final error = failure;
    if (error != null) {
      throw error;
    }
    return credential;
  }
}

final class FakeSocialLogin implements SocialLogin {
  FakeSocialLogin({this.credential, this.failure, this.completer});

  SocialCredential? credential;
  Failure? failure;
  Completer<SocialCredential?>? completer;
  final List<SocialProvider> providers = <SocialProvider>[];
  int signOutCalls = 0;

  @override
  Future<SocialCredential?> signIn(SocialProvider provider) async {
    providers.add(provider);
    final pending = completer;
    if (pending != null) {
      return pending.future;
    }
    final error = failure;
    if (error != null) {
      throw error;
    }
    return credential;
  }

  @override
  Future<void> signOut() async {
    signOutCalls++;
  }
}

SocialAvailability androidAvailability() {
  return const SocialAvailability(platform: TargetPlatform.android);
}

SocialAvailability iosAvailability() {
  return const SocialAvailability(platform: TargetPlatform.iOS);
}
