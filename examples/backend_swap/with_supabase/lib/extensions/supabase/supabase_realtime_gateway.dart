// ignore_for_file: prefer_initializing_formals

import 'dart:async';

import 'package:kiln_core/kiln_core.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'supabase_client.dart';
import 'supabase_failure_mapper.dart';

/// Supabase realtime channel used by `RemoteDatabase.watch`.
abstract interface class SupabaseRealtimeGateway {
  /// Emits the latest row on insert/update, and null when the row is deleted.
  /// The stream stops emitting once the subscription is cancelled.
  Stream<Map<String, Object?>?> watchRow(String table, String id);
}

/// [SupabaseRealtimeGateway] backed by the Supabase `RealtimeClient`.
final class SdkSupabaseRealtimeGateway implements SupabaseRealtimeGateway {
  SdkSupabaseRealtimeGateway({
    required SupabaseClientProvider provider,
    this.schema = 'public',
  }) : _provider = provider;

  final SupabaseClientProvider _provider;
  final String schema;

  @override
  Stream<Map<String, Object?>?> watchRow(String table, String id) {
    final controller = StreamController<Map<String, Object?>?>();
    RealtimeChannel? channel;

    controller.onListen = () {
      try {
        final active = _provider.client.channel('kiln:$schema:$table:$id');
        channel = active;
        active
            .onPostgresChanges(
              event: PostgresChangeEvent.all,
              schema: schema,
              table: table,
              filter: PostgresChangeFilter(
                type: PostgresChangeFilterType.eq,
                column: 'id',
                value: id,
              ),
              callback: (payload) {
                if (controller.isClosed || channel != active) {
                  return;
                }
                switch (payload.eventType) {
                  case PostgresChangeEvent.delete:
                    controller.add(null);
                  case PostgresChangeEvent.insert:
                  case PostgresChangeEvent.update:
                    controller.add(
                      Map<String, Object?>.from(payload.newRecord),
                    );
                  case PostgresChangeEvent.all:
                    break;
                }
              },
            )
            .subscribe();
      } on Object catch (error, stackTrace) {
        controller.addError(
          mapSupabaseError(
            error,
            stackTrace: stackTrace,
            fallbackCode: FailureCode.remoteDatabaseUnavailable,
            fallbackKind: FailureKind.network,
          ),
        );
      }
    };

    controller.onCancel = () async {
      final active = channel;
      channel = null;
      if (active != null) {
        await active.unsubscribe();
      }
    };

    return controller.stream;
  }
}
