import 'package:kiln_testing/kiln_testing.dart';
import 'package:{{app_name}}/extensions/supabase/supabase_auth_repository.dart';
import 'package:{{app_name}}/extensions/supabase/supabase_file_storage.dart';
import 'package:{{app_name}}/extensions/supabase/supabase_remote_database.dart';

import 'test_support.dart';

void main() {
  authRepositoryContract(
    description: 'SupabaseAuthRepository',
    create: () {
      final gateway = FakeSupabaseGateway();
      return SupabaseAuthRepository(
        gateway: gateway,
        redirectUri: Uri.parse('kiln-auth://auth-callback'),
      );
    },
  );

  socialAuthContract(
    description: 'SupabaseSocialAuth',
    create: () {
      final gateway = FakeSupabaseGateway();
      return SupabaseSocialAuth(gateway: gateway, config: testConfig());
    },
  );

  remoteDatabaseContract(
    description: 'SupabaseRemoteDatabase',
    create: () {
      final store = FakeDocumentStore();
      return SupabaseRemoteDatabase(
        postgrest: FakePostgrestGateway(store: store),
        realtime: FakeSupabaseRealtimeGateway(store),
      );
    },
  );

  fileStorageContract(
    description: 'SupabaseFileStorage',
    create: () => SupabaseFileStorage(gateway: FakeSupabaseStorageGateway()),
  );
}
