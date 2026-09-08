import 'package:dio/dio.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';

final accountSecurityApiProvider = Provider<AccountSecurityApi>((ref) {
  return AccountSecurityApi(dio: ref.watch(dioProvider));
});

class AccountSecurityApi {
  AccountSecurityApi({required Dio dio}) : _dio = dio;

  final Dio _dio;

  Future<void> blockUser(String username) async {
    await _dio.post<void>('/api/v1/profiles/$username/block');
  }

  Future<void> unblockUser(String username) async {
    await _dio.delete<void>('/api/v1/profiles/$username/block');
  }
}
