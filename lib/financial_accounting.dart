import 'dart:async';
import 'dart:io';

import 'package:conduit/conduit.dart';

import '../model/user.dart';
import '../model/finance_record.dart';

import '../controller/auth_controller.dart';
import 'controller/token_controller.dart';
import 'controller/user_controller.dart';
import 'controller/finance_record_controller.dart';

class AppService extends ApplicationChannel {
  late final ManagedContext managedContext;

  @override
  Future prepare() {
    final persistentStore = _initDatabase();

    managedContext = ManagedContext(
        ManagedDataModel.fromCurrentMirrorSystem(), persistentStore);
    return super.prepare();
  }

  @override
  Controller get entryPoint => Router()
    ..route('token/[:refresh]').link(
      () => AppAuthController(managedContext),
    )
    ..route('user')
        .link(AppTokenController.new)!
        .link(() => AppUserController(managedContext))
    ..route('finance-record/pages/[:pagination]')
        .link(() => FinanceRecordController(managedContext))
    ..route('finance-record/selection/[:filter]')
        .link(() => FinanceRecordController(managedContext))
    ..route('finance-record/search/[:by]')
        .link(() => FinanceRecordController(managedContext))
    ..route('finance-record/[:id]')
        .link(() => FinanceRecordController(managedContext))
    ..route('finance-record/by-id/[:go-deleted]')
        .link(() => FinanceRecordController(managedContext));

  PersistentStore _initDatabase() {
    final username = Platform.environment['DB_USERNAME'] ?? 'postgres';
    final password = Platform.environment['DB_PASSWORD'] ?? '123';
    final host = Platform.environment['DB_HOST'] ?? '127.0.0.1';
    final port = int.parse(Platform.environment['DB_PORT'] ?? '5432');
    final databaseName =
        Platform.environment['DB_NAME'] ?? 'financial_accounting';
    return PostgreSQLPersistentStore(
        username, password, host, port, databaseName);
  }
}
