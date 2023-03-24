import 'dart:async';
import 'dart:io';

import 'package:conduit/conduit.dart';
import '../util/app_response.dart';
import 'package:jaguar_jwt/jaguar_jwt.dart';

class AppTokenController extends Controller {
  @override
  FutureOr<RequestOrResponse?> handle(Request request) {
    try {
      // get token from header query
      final header = request.raw.headers.value(HttpHeaders.authorizationHeader);
      // from header get token
      final token = const AuthorizationBearerParser().parse(header);

      // get jwtClaim for check token
      final jwtClaim = verifyJwtHS256Signature(token ?? "", "SECRET_KEY");
      // validate token
      jwtClaim.validate();
      return request;
    } on JwtException catch (e) {
      return AppResponse.serverError(e.message);
    }
  }
}
