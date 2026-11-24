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
            .subscribe((RealtimeSubscribeStatus status, Object? error) {
              if (controller.isClosed || channel != active) {
                return;
              }
              handleSubscribeStatus(
                status: status,
                error: error,
                table: table,
                id: id,
                controller: controller,
              );
            });
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

  /// Translates a Supabase realtime channel lifecycle status into stream
  /// errors or completion on [controller].
  static void handleSubscribeStatus({
    required RealtimeSubscribeStatus status,
    required Object? error,
    required String table,
    required String id,
    required StreamController<Map<String, Object?>?> controller,
  }) {
    if (controller.isClosed) {
      return;
    }
    switch (status) {
      case RealtimeSubscribeStatus.subscribed:
        break;
      case RealtimeSubscribeStatus.channelError:
        controller.addError(
          mapSupabaseError(
            error ??
                StateError('Supabase realtime channel error on $table:$id.'),
            fallbackCode: FailureCode.remoteDatabaseUnavailable,
            fallbackKind: FailureKind.network,
          ),
        );
      case RealtimeSubscribeStatus.timedOut:
        controller.addError(
          Failure(
            code: FailureCode.networkTimeout,
            message: 'Supabase realtime subscription timed out for $table:$id.',
            kind: FailureKind.network,
            isRetryable: true,
            cause: error,
          ),
        );
      case RealtimeSubscribeStatus.closed:
        unawaited(controller.close());
    }
  }
}
