import 'package:flutter_test/flutter_test.dart';
import 'package:{{app_name}}/extensions/supabase/supabase_storage_gateway.dart';

void main() {
  test('prefixes relative signed URLs with storage/v1', () {
    final uri = resolveSupabaseSignedUrl(
      'http://10.0.2.2:54321',
      '/object/sign/public/user/cover?token=abc',
    );

    expect(
      uri.toString(),
      'http://10.0.2.2:54321/storage/v1/object/sign/public/user/cover?token=abc',
    );
  });

  test('does not double-prefix storage/v1', () {
    final uri = resolveSupabaseSignedUrl(
      'https://example.supabase.co',
      '/storage/v1/object/sign/public/user/cover?token=abc',
    );

    expect(
      uri.toString(),
      'https://example.supabase.co/storage/v1/object/sign/public/user/cover?token=abc',
    );
  });

  test('keeps an absolute signed URL unchanged', () {
    const absolute = 'https://cdn.example.com/file?token=abc';

    expect(
      resolveSupabaseSignedUrl(
        'https://example.supabase.co',
        absolute,
      ).toString(),
      absolute,
    );
  });
}
