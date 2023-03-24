import 'dart:io';

import 'package:conduit/conduit.dart';

import '../model/user.dart';
import '../util/app_response.dart';
import '../util/app_util.dart';

class AppUserController extends ResourceController {
  AppUserController(this.managedContext);

  final ManagedContext managedContext;

  @Operation.get()
  Future<Response> getProfile(
    @Bind.header(HttpHeaders.authorizationHeader) String header,
  ) async {
    try {
      // get id user
      final id = AppUtil.getIdFromHeader(header);
      // get data user by id
      final user = await managedContext.fetchObjectWithID<User>(id);
      // delete extra parameteres for beautiful outut
      user!.removePropertiesFromBackingMap(['refreshToken', 'accessToken']);

      return AppResponse.ok(
          message: 'Успешное получение профиля', body: user.backing.contents);
    } catch (e) {
      return AppResponse.serverError(e, message: 'Ошибка получения профиля');
    }
  }

  @Operation.post()
  Future<Response> updateProfile(
    @Bind.header(HttpHeaders.authorizationHeader) String header,
    @Bind.body() User user,
  ) async {
    try {
      // get user id
      final id = AppUtil.getIdFromHeader(header);
      // get user data by id
      final fUser = await managedContext.fetchObjectWithID<User>(id);
      // query for user updating by id
      final qUpdateUser = Query<User>(managedContext)
        ..where((element) => element.id).equalTo(id) // fund user by id
        ..values.userName = user.userName ?? fUser!.userName
        ..values.email = user.email ?? fUser!.email;

      await qUpdateUser.updateOne();
      // get update user
      final findUser = await managedContext.fetchObjectWithID<User>(id);

      findUser!.removePropertiesFromBackingMap(['refreshToken', 'accessToken']);

      return AppResponse.ok(
        message: 'Успешное обновление данных',
        body: findUser.backing.contents,
      );
    } catch (e) {
      return AppResponse.serverError(e, message: 'Ошибка обновления данных');
    }
  }

  @Operation.put()
  Future<Response> updatePassword(
    @Bind.header(HttpHeaders.authorizationHeader) String header,
    @Bind.query('newPassword') String newPassword,
    @Bind.query('oldPassword') String oldPassword,
  ) async {
    try {
      final id = AppUtil.getIdFromHeader(header);

      final qFindUser = Query<User>(managedContext)
        ..where((element) => element.id).equalTo(id)
        ..returningProperties(
          (element) => [
            element.salt,
            element.hashPassword,
          ],
        );

      final fUser = await qFindUser.fetchOne();

      // create hash of old password
      final oldHashPassword =
          generatePasswordHash(oldPassword, fUser!.salt ?? "");

      // check old password with password from database
      if (oldHashPassword != fUser.hashPassword) {
        return AppResponse.badrequest(
          message: 'Неверный старый пароль',
        );
      }

      // create hash of new password
      final newHashPassword =
          generatePasswordHash(newPassword, fUser.salt ?? "");

      // create query for password updating
      final qUpdateUser = Query<User>(managedContext)
        ..where((x) => x.id).equalTo(id)
        ..values.hashPassword = newHashPassword;

      // update password
      await qUpdateUser.updateOne();

      return AppResponse.ok(body: 'Пароль успешно обновлен');
    } catch (e) {
      return AppResponse.serverError(e, message: 'Ошибка обновления пароля');
    }
  }
}
