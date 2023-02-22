import 'package:conduit/conduit.dart';

import '../model/finance_record.dart';

class FinanceRecordController extends ResourceController {
  FinanceRecordController(this.context);

  final ManagedContext context;

  /* @Operation.get()
  Future<Response> getAllFinanceRecords() async {
    final financeRecordQuery = Query<FinanceRecord>(context);
    final financeRecords = await financeRecordQuery.fetch();

    return Response.ok(financeRecords);
  } */

  @Operation.get('id')
  Future<Response> getFinanceRecordByID(@Bind.path('id') int id) async {
    final financeRecordQuery = Query<FinanceRecord>(context)
      ..where((f) => f.id).equalTo(id);
    final financeRecord = await financeRecordQuery.fetchOne();

    if (financeRecord == null) {
      return Response.notFound(body: {'error': 'Finance record not found'});
    }

    return Response.ok(financeRecord);
  }

  @Operation.post()
  Future<Response> createFinanceRecord(
      @Bind.body() FinanceRecord financeRecord) async {
    final financeRecordQuery = Query<FinanceRecord>(context)
      ..values = financeRecord;
    final insertedRecord = await financeRecordQuery.insert();

    return Response.ok(insertedRecord);
  }

  @Operation.put('id')
  Future<Response> updateFinanceRecord(
      @Bind.path('id') int id, @Bind.body() FinanceRecord financeRecord) async {
    final financeRecordQuery = Query<FinanceRecord>(context)
      ..where((f) => f.id).equalTo(id)
      ..values = financeRecord;

    final updatedRecord = await financeRecordQuery.updateOne();

    if (updatedRecord == null) {
      return Response.notFound();
    }

    return Response.ok(updatedRecord);
  }

  @Operation.delete('id')
  Future<Response> deleteFinanceRecordByID(@Bind.path('id') int id) async {
    final financeRecordQuery = Query<FinanceRecord>(context)
      ..where((f) => f.id).equalTo(id);
    final deletedRecordCount = await financeRecordQuery.delete();

    if (deletedRecordCount == 0) {
      return Response.notFound();
    }

    return Response.ok({'deleted': deletedRecordCount});
  }

  @Operation.get('by')
  Future<Response> searchFinanceRecords(
      @Bind.path('by') String by, @Bind.query('query') String query) async {
    late final financeRecordQuery;
    if (by == 'by-transaction-name')
      financeRecordQuery = Query<FinanceRecord>(context)
        ..where((f) => f.transactionName).contains(query, caseSensitive: false);
    else if (by == 'by-category')
      financeRecordQuery = Query<FinanceRecord>(context)
        ..where((f) => f.category).contains(query, caseSensitive: false);
    final matchingRecords = await financeRecordQuery.fetch();

    return Response.ok(matchingRecords);
  }

  @Operation.get('pagination')
  Future<Response> getFinanceRecordsByPagination(
      {@Bind.query('page') int page = 1,
      @Bind.query('perPage') int perPage = 2}) async {
    final financeRecordQuery = Query<FinanceRecord>(context)
      ..fetchLimit = perPage
      ..offset = (page - 1) * perPage;
    final financeRecords = await financeRecordQuery.fetch();

    return Response.ok(financeRecords);
  }
}
