import 'package:conduit/conduit.dart';

class FinanceRecord extends ManagedObject<_FinanceRecord>
    implements _FinanceRecord {}

class _FinanceRecord {
  @primaryKey
  int? id;

  @Column(indexed: true)
  int? transactionNumber;

  @Column(indexed: true)
  String? transactionName;

  @Column(nullable: true)
  String? description;

  @Column(indexed: true)
  String? category;

  @Column(indexed: true)
  DateTime? transactionDate;

  @Column()
  double? transactionAmount;

  @Column()
  bool is_deleted = false;
}
