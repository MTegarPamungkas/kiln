import 'package:flutter_test/flutter_test.dart';
import 'package:full_stack/extensions/go_router/app_routes.dart';

void main() {
  test('route paths are unique and absolute', () {
    expect(AppRoutes.paths.toSet(), hasLength(AppRoutes.paths.length));
    expect(
      AppRoutes.paths.every((String path) => path.startsWith('/')),
      isTrue,
    );
    expect(AppRoutes.paths, contains(AppRoutes.home));
    expect(AppRoutes.paths, contains(AppRoutes.signIn));
  });

  test('route names are unique and match the path count', () {
    expect(AppRoutes.names.toSet(), hasLength(AppRoutes.names.length));
    expect(AppRoutes.names, hasLength(AppRoutes.paths.length));
  });
}
