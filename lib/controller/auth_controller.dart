import 'dart:io';

import 'package:conduit/conduit.dart';

import 'package:jaguar_jwt/jaguar_jwt.dart';

import '../model/response.dart';
import '../model/user.dart';
import '../util/app_response.dart';
import '../util/app_util.dart';

class AppAuthController extends ResourceController {
  AppAuthController(this.managedContext);

  final ManagedContext managedContext;

  @Operation.post()
  Future<Response> signIn(@Bind.body() User user) async {
    if (user.password == null || user.userName == null) {
      return Response.badRequest(
          body: ModelResponse(message: 'Поля password и username обязательны'));
    }

    try {
      // find user by name in database
      final qFindUser = Query<User>(managedContext)
        ..where((element) => element.userName).equalTo(user.userName)
        ..returningProperties(
          (element) => [
            element.id,
            element.salt,
            element.hashPassword,
          ],
        );

      // get first element from list
      final findUser = await qFindUser.fetchOne();

      if (findUser == null) {
        throw QueryException.input('Пользователь не найден', []);
      }

      // generate hash password for next check
      final requestHashPassword =
          generatePasswordHash(user.password ?? '', findUser.salt ?? '');

      // chack [assword]
      if (requestHashPassword == findUser.hashPassword) {
        // update password token
        _updateTokens(findUser.id ?? -1, managedContext);

        // get user data
        final newUser =
            await managedContext.fetchObjectWithID<User>(findUser.id);

        return Response.ok(ModelResponse(
          data: newUser!.backing.contents,
          message: 'Успешная авторизация',
        ));
      } else {
        throw QueryException.input('Не верный пароль', []);
      }
    } catch (e) {
      return AppResponse.serverError(e);
    }
  }

  @Operation.put()
  Future<Response> signUp(@Bind.body() User user) async {
    if (user.password == null || user.userName == null || user.email == null) {
      return Response.badRequest(
        body:
            ModelResponse(message: 'Поля  password username email обязательны'),
      );
    }

    // generate salt
    final salt = generateRandomSalt();
    // generate hash password
    final hashPassword = generatePasswordHash(user.password!, salt);

    try {
      late final int id;

      // create transaction
      await managedContext.transaction((transaction) async {
        // create query for use addong
        final qCreateUser = Query<User>(transaction)
          ..values.userName = user.userName
          ..values.email = user.email
          ..values.salt = salt
          ..values.hashPassword = hashPassword;

        // add user in database
        final createdUser = await qCreateUser.insert();

        // save user id
        id = createdUser.id!;

        // update token
        _updateTokens(id, transaction);
      });

      // get user data by id
      final userData = await managedContext.fetchObjectWithID<User>(id);

      return AppResponse.ok(
        body: userData!.backing.contents,
        message: 'Пользователь успешно зарегистрировался',
      );
    } catch (e) {
      return AppResponse.serverError(e);
    }
  }

  @Operation.post('refresh')
  Future<Response> refreshToken(
      @Bind.path('refresh') String refreshToken) async {
    try {
      // get user id from jwt token
      final id = AppUtil.getIdFromToken(refreshToken);

      // get user data by her id
      final user = await managedContext.fetchObjectWithID<User>(id);

      if (user!.refreshToken != refreshToken) {
        return Response.unauthorized(body: 'Token не валидный');
      }

      // update token
      _updateTokens(id, managedContext);

      return Response.ok(
        ModelResponse(
          data: user.backing.contents,
          message: 'Токен успешно обновлен',
        ),
      );
    } catch (e) {
      return AppResponse.serverError(e);
    }
  }

  void _updateTokens(int id, ManagedContext transaction) async {
    final Map<String, String> tokens = _getTokens(id);

    final qUpdateTokens = Query<User>(transaction)
      ..where((element) => element.id).equalTo(id)
      ..values.accessToken = tokens['access']
      ..values.refreshToken = tokens['refresh'];

    await qUpdateTokens.updateOne();
  }

  // generate jwt token
  Map<String, String> _getTokens(int id) {
    final key = Platform.environment['SECRET_KEY'] ?? 'SECRET_KEY';
    final accessClaimSet = JwtClaim(
      maxAge: const Duration(hours: 1), // life time token
      otherClaims: {'id': id},
    );
    final refreshClaimSet = JwtClaim(
      otherClaims: {'id': id},
    );
    final tokens = <String, String>{};
    tokens['access'] = issueJwtHS256(accessClaimSet, key);
    tokens['refresh'] = issueJwtHS256(refreshClaimSet, key);

    return tokens;
  }
}
