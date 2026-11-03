import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart' as models;

/// Document access that can be replaced with an in-memory fake.
abstract interface class AppwriteDatabaseGateway {
  /// Creates a document with a generated id and returns it, including `id`.
  Future<Map<String, Object?>> createRow(
    String tableId,
    Map<String, Object?> data,
  );

  /// Returns null when the document does not exist.
  Future<Map<String, Object?>?> getRow(String tableId, String rowId);

  Future<List<Map<String, Object?>>> listRows(
    String tableId, {
    List<String> queries = const <String>[],
  });

  Future<Map<String, Object?>> updateRow(
    String tableId,
    String rowId,
    Map<String, Object?> data,
  );

  Future<void> deleteRow(String tableId, String rowId);
}

/// [AppwriteDatabaseGateway] backed by the Appwrite `TablesDB` service.
///
/// Appwrite 1.8 renamed documents in collections to rows in tables; the
/// [RemoteDatabase] collection argument is used as the table id.
final class SdkAppwriteDatabaseGateway implements AppwriteDatabaseGateway {
  SdkAppwriteDatabaseGateway({
    required this.tables,
    required this.databaseId,
  });

  final TablesDB tables;
  final String databaseId;

  @override
  Future<Map<String, Object?>> createRow(
    String tableId,
    Map<String, Object?> data,
  ) async {
    final row = await tables.createRow(
      databaseId: databaseId,
      tableId: tableId,
      rowId: ID.unique(),
      data: data,
    );
    return _fromRow(row);
  }

  @override
  Future<Map<String, Object?>?> getRow(String tableId, String rowId) async {
    try {
      final row = await tables.getRow(
        databaseId: databaseId,
        tableId: tableId,
        rowId: rowId,
      );
      return _fromRow(row);
    } on AppwriteException catch (error) {
      if (error.code == 404) {
        return null;
      }
      rethrow;
    }
  }

  @override
  Future<List<Map<String, Object?>>> listRows(
    String tableId, {
    List<String> queries = const <String>[],
  }) async {
    final result = await tables.listRows(
      databaseId: databaseId,
      tableId: tableId,
      queries: queries.isEmpty ? null : queries,
    );
    return result.rows.map(_fromRow).toList(growable: false);
  }

  @override
  Future<Map<String, Object?>> updateRow(
    String tableId,
    String rowId,
    Map<String, Object?> data,
  ) async {
    final row = await tables.updateRow(
      databaseId: databaseId,
      tableId: tableId,
      rowId: rowId,
      data: data,
    );
    return _fromRow(row);
  }

  @override
  Future<void> deleteRow(String tableId, String rowId) async {
    await tables.deleteRow(
      databaseId: databaseId,
      tableId: tableId,
      rowId: rowId,
    );
  }

  Map<String, Object?> _fromRow(models.Row row) {
    final document = <String, Object?>{...row.data};
    document['id'] = row.$id;
    return document;
  }
}
