// ignore_for_file: prefer_initializing_formals

import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:kiln_core/kiln_core.dart';

import 'neon_config.dart';
import 'neon_failure_mapper.dart';
import 'neon_token_provider.dart';

/// PostgREST filter operators used by the extension.
enum PostgrestOperator {
  equals,
  notEquals,
  greaterThan,
  greaterThanOrEqual,
  lessThan,
  lessThanOrEqual,
  inList,
  notInList,
  contains,
  isNull,
  isNotNull,
}

/// One PostgREST condition ready to be applied to a query.
final class PostgrestFilter {
  const PostgrestFilter(this.column, this.operator, [this.value]);

  final String column;
  final PostgrestOperator operator;
  final Object? value;

  @override
  String toString() => 'PostgrestFilter($column, ${operator.name}, $value)';
}

/// One PostgREST ordering clause.
final class PostgrestOrder {
  const PostgrestOrder(this.column, {this.ascending = true});

  final String column;
  final bool ascending;

  @override
  String toString() => 'PostgrestOrder($column, ascending: $ascending)';
}

/// PostgREST query produced by mapping a [RemoteQuery].
final class PostgrestQuery {
  const PostgrestQuery({
    this.filters = const <PostgrestFilter>[],
    this.orderBy = const <PostgrestOrder>[],
    this.limit,
    this.offset = 0,
  });

  final List<PostgrestFilter> filters;
  final List<PostgrestOrder> orderBy;
  final int? limit;
  final int offset;
}

/// PostgREST operations used by [NeonRemoteDatabase], wrapped so they can be
/// faked in tests.
abstract interface class PostgrestGateway {
  Future<Map<String, Object?>> insert(String table, Map<String, Object?> data);

  Future<Map<String, Object?>?> selectById(String table, String id);

  Future<List<Map<String, Object?>>> select(String table, {PostgrestQuery? query});

  /// Null when no row with [id] exists.
  Future<Map<String, Object?>?> updateById(
    String table,
    String id,
    Map<String, Object?> data,
  );

  /// False when no row with [id] exists.
  Future<bool> deleteById(String table, String id);
}

/// A non-2xx response from the Neon Data API (PostgREST).
final class NeonApiException implements Exception {
  const NeonApiException(this.message, {this.statusCode, this.code});

  final String message;
  final int? statusCode;
  final String? code;

  @override
  String toString() => 'NeonApiException($statusCode, $code): $message';
}

/// [PostgrestGateway] backed by a PostgREST-compatible Neon Data API over
/// `package:http`.
///
/// Requests carry the bearer [NeonConfig.apiKey] and the configured schema
/// through `Accept-Profile`/`Content-Profile`. All bodies are JSON and
/// mutations request a representation back so the caller gets the row.
final class HttpNeonGateway implements PostgrestGateway {
  HttpNeonGateway({
    required NeonConfig config,
    http.Client? client,
    NeonTokenProvider? tokenProvider,
  }) : _config = config,
       _client = client ?? http.Client(),
       _tokenProvider = tokenProvider ?? _providerFor(config);

  final NeonConfig _config;
  final http.Client _client;
  final NeonTokenProvider? _tokenProvider;

  static NeonTokenProvider? _providerFor(NeonConfig config) {
    if (config.apiKey.trim().isNotEmpty) {
      return StaticNeonTokenProvider(config.apiKey);
    }
    final authUrl = config.authUrl?.trim();
    if (authUrl != null && authUrl.isNotEmpty) {
      return NeonAnonymousTokenProvider(authUrl: authUrl);
    }
    return null;
  }

  Future<Map<String, String>> _baseHeaders() async {
    final token = await _tokenProvider?.token();
    return <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  @override
  Future<Map<String, Object?>> insert(
    String table,
    Map<String, Object?> data,
  ) async {
    final response = await _client.post(
      _resource(table),
      headers: <String, String>{
        ...await _baseHeaders(),
        'Content-Profile': _config.schema,
        'Prefer': 'return=representation',
      },
      body: jsonEncode(data),
    );
    final rows = _rows(response, FailureCode.remoteDatabaseUnavailable);
    return _single(rows, FailureCode.remoteDatabaseUnavailable);
  }

  @override
  Future<Map<String, Object?>?> selectById(String table, String id) async {
    final response = await _client.get(
      _resource(table).replace(queryParameters: <String, String>{
        'id': 'eq.$id',
        'select': '*',
      }),
      headers: <String, String>{...await _baseHeaders(), 'Accept-Profile': _config.schema},
    );
    final rows = _rows(response, FailureCode.remoteDatabaseQueryFailed);
    return rows.isEmpty ? null : rows.first;
  }

  @override
  Future<List<Map<String, Object?>>> select(
    String table, {
    PostgrestQuery? query,
  }) async {
    final response = await _client.get(
      _resource(table).replace(queryParameters: _queryParams(query)),
      headers: <String, String>{...await _baseHeaders(), 'Accept-Profile': _config.schema},
    );
    return _rows(response, FailureCode.remoteDatabaseQueryFailed);
  }

  @override
  Future<Map<String, Object?>?> updateById(
    String table,
    String id,
    Map<String, Object?> data,
  ) async {
    final response = await _client.patch(
      _resource(table).replace(queryParameters: <String, String>{'id': 'eq.$id'}),
      headers: <String, String>{
        ...await _baseHeaders(),
        'Content-Profile': _config.schema,
        'Prefer': 'return=representation',
      },
      body: jsonEncode(data),
    );
    final rows = _rows(response, FailureCode.remoteDatabaseUnavailable);
    return rows.isEmpty ? null : rows.first;
  }

  @override
  Future<bool> deleteById(String table, String id) async {
    final response = await _client.delete(
      _resource(table).replace(queryParameters: <String, String>{'id': 'eq.$id'}),
      headers: <String, String>{
        ...await _baseHeaders(),
        'Content-Profile': _config.schema,
        'Prefer': 'return=representation',
      },
    );
    final rows = _rows(response, FailureCode.remoteDatabaseUnavailable);
    return rows.isNotEmpty;
  }

  /// Releases the underlying HTTP client. The gateway is unusable afterwards.
  void close() {
    final provider = _tokenProvider;
    if (provider is NeonAnonymousTokenProvider) {
      provider.close();
    }
    _client.close();
  }

  Uri _resource(String table) => Uri.parse('${_config.dataApiUrl}/$table');

  Map<String, String> _queryParams(PostgrestQuery? query) {
    final params = <String, String>{'select': '*'};
    for (final filter in query?.filters ?? const <PostgrestFilter>[]) {
      params[filter.column] = _filterValue(filter);
    }
    final order = query?.orderBy ?? const <PostgrestOrder>[];
    if (order.isNotEmpty) {
      params['order'] = order
          .map((o) => '${o.column}.${o.ascending ? 'asc' : 'desc'}')
          .join(',');
    }
    final limit = query?.limit;
    if (limit != null) {
      params['limit'] = '$limit';
    }
    final offset = query?.offset ?? 0;
    if (offset > 0) {
      params['offset'] = '$offset';
    }
    return params;
  }

  String _filterValue(PostgrestFilter filter) {
    final value = filter.value;
    switch (filter.operator) {
      case PostgrestOperator.equals:
        return 'eq.$value';
      case PostgrestOperator.notEquals:
        return 'neq.$value';
      case PostgrestOperator.greaterThan:
        return 'gt.$value';
      case PostgrestOperator.greaterThanOrEqual:
        return 'gte.$value';
      case PostgrestOperator.lessThan:
        return 'lt.$value';
      case PostgrestOperator.lessThanOrEqual:
        return 'lte.$value';
      case PostgrestOperator.inList:
        return 'in${_csv(value)}';
      case PostgrestOperator.notInList:
        return 'not.in${_csv(value)}';
      case PostgrestOperator.contains:
        return 'cs.$value';
      case PostgrestOperator.isNull:
        return 'is.null';
      case PostgrestOperator.isNotNull:
        return 'not.is.null';
    }
  }

  String _csv(Object? value) {
    final items = value is Iterable
        ? value.map<String>(_quote)
        : <String>[_quote(value)];
    return '(${items.join(',')})';
  }

  /// PostgREST needs string values inside `in(...)` quoted; numbers and
  /// booleans stay bare.
  String _quote(Object? value) {
    if (value is num || value is bool) {
      return '$value';
    }
    return '"${'$value'.replaceAll('"', r'\"')}"';
  }

  List<Map<String, Object?>> _rows(http.Response response, FailureCode fallback) {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw mapNeonError(
        NeonApiException(
          _decodeError(response.body),
          statusCode: response.statusCode,
        ),
        fallbackCode: fallback,
      );
    }
    if (response.body.isEmpty) {
      return const <Map<String, Object?>>[];
    }
    final Object? decoded;
    try {
      decoded = jsonDecode(response.body);
    } on FormatException {
      throw mapNeonError(
        NeonApiException('The Neon Data API returned a non-JSON body.'),
        fallbackCode: fallback,
      );
    }
    final list = decoded is List ? decoded : <Object?>[decoded];
    return list
        .whereType<Map<Object?, Object?>>()
        .map((row) => row.map((k, v) => MapEntry('$k', v)))
        .toList(growable: false);
  }

  Map<String, Object?> _single(
    List<Map<String, Object?>> rows,
    FailureCode fallback,
  ) {
    if (rows.isEmpty) {
      throw mapNeonError(
        NeonApiException('The Neon Data API returned no row.'),
        fallbackCode: fallback,
      );
    }
    return rows.first;
  }

  String _decodeError(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map && decoded['message'] is String) {
        return decoded['message'] as String;
      }
    } on FormatException {
      // fall through to the raw body
    }
    return body.isEmpty ? 'Unknown Neon Data API error.' : body;
  }
}
