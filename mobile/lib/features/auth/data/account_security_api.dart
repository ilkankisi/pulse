import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_routes.dart';

final accountSecurityApiProvider = Provider<AccountSecurityApi>((ref) {
  return AccountSecurityApi(dio: ref.watch(dioProvider));
});

class AccountSecurityApi {
  AccountSecurityApi({required Dio dio}) : _dio = dio;

  final Dio _dio;

  Future<void> blockUser(String username) async {
    await _dio.post<void>(ApiRoutes.profileBlock(username));
  }

  Future<void> unblockUser(String username) async {
    await _dio.delete<void>(ApiRoutes.profileBlock(username));
  }
}
