import 'package:conduit/conduit.dart';

import '../model/finance_record.dart';

class FinanceRecordSearchController extends ResourceController {
  FinanceRecordSearchController(this.context);

  final ManagedContext context;

  @Operation.get('by')
  Future<Response> searchFinanceRecords(
      @Bind.path('by') String by, @Bind.query('query') String query) async {
    final financeRecordQuery = Query<FinanceRecord>(context)
      ..where((f) => f.transactionName).contains(query, caseSensitive: false);
    final matchingRecords = await financeRecordQuery.fetch();

    return Response.ok(matchingRecords);
  }
}
