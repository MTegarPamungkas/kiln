import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kiln_core/kiln_core.dart';
import 'package:{{app_name}}/extensions/theme/theme_config.dart';
import 'package:{{app_name}}/extensions/theme/theme_support.dart';

void main() {
  test('reports theme settings and memory fallback', () {
    final support = ThemeSupport(config: ThemeConfig.defaults);

    final info = support.info;

    expect(info.isSupported, isTrue);
    expect(info.details['storage'], 'memory');
    expect(info.details['density'], 'comfortable');
  });

  test('reports persistent theme storage', () {
    final support = ThemeSupport(config: ThemeConfig.defaults, persisted: true);

    expect(support.info.details['storage'], 'storage');
  });

  test('rejects a negative corner radius', () {
    final support = ThemeSupport(
      config: ThemeConfig(seedColor: const Color(0xFF0F766E), cornerRadius: -1),
    );

    final info = support.info;

    expect(info.state, SupportState.notConfigured);
    expect(info.toFailure().kind, FailureKind.configuration);
  });
}
