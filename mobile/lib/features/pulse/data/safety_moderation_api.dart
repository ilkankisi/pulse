import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../domain/moderation_models.dart';

final safetyModerationApiProvider = Provider<SafetyModerationApi>((ref) {
  return SafetyModerationApi(dio: ref.watch(dioProvider));
});

class SafetyModerationApi {
  SafetyModerationApi({required Dio dio}) : _dio = dio;

  final Dio _dio;

  Future<BlockResult> blockUser(String username) async {
    final response = await _dio.post<dynamic>(
      '/api/v1/profiles/${Uri.encodeComponent(username)}/block',
    );

    return BlockResult.fromJson(_requireMap(response.data));
  }

  Future<void> unblockUser(String username) async {
    await _dio.delete<dynamic>(
      '/api/v1/profiles/${Uri.encodeComponent(username)}/block',
    );
  }

  Future<List<BlockedUser>> getBlockedUsers() async {
    try {
      final response = await _dio.get<dynamic>('/api/v1/blocks');

      return _requireItems(response.data)
          .map((item) => BlockedUser.fromJson(_requireMap(item)))
          .toList(growable: false);
    } on DioException catch (error) {
      if (error.response?.statusCode == 404) {
        return const <BlockedUser>[];
      }

      rethrow;
    }
  }

  Future<ReportRecord> createReport(CreateReportRequest request) async {
    final response = await _dio.post<dynamic>(
      '/api/v1/reports',
      data: request.toJson(),
    );

    return ReportRecord.fromJson(_requireMap(response.data));
  }

  Future<List<ReportRecord>> getModerationReports() async {
    try {
      final response = await _dio.get<dynamic>('/api/v1/moderation/reports');

      return _requireItems(response.data)
          .map((item) => ReportRecord.fromJson(_requireMap(item)))
          .toList(growable: false);
    } on DioException catch (error) {
      if (error.response?.statusCode == 404) {
        return const <ReportRecord>[];
      }

      rethrow;
    }
  }

  Future<ReportRecord> getModerationReport(int reportId) async {
    final response = await _dio.get<dynamic>(
      '/api/v1/moderation/reports/$reportId',
    );

    return ReportRecord.fromJson(_requireMap(response.data));
  }

  Future<ResolveReportResult> resolveReport(
    int reportId,
    ResolveReportRequest request,
  ) async {
    final response = await _dio.post<dynamic>(
      '/api/v1/moderation/reports/$reportId/resolve',
      data: request.toJson(),
    );

    return ResolveReportResult.fromJson(_requireMap(response.data));
  }

  Future<void> dismissReport(int reportId) async {
    await _dio.post<dynamic>('/api/v1/moderation/reports/$reportId/dismiss');
  }

  Map<String, dynamic> _requireMap(dynamic value) {
    if (value is Map<String, dynamic>) {
      return value;
    }

    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }

    throw const FormatException('API response JSON object olmalıdır.');
  }

  List<dynamic> _requireItems(dynamic value) {
    if (value is List) {
      return value;
    }

    final map = _requireMap(value);
    final items = map['items'];

    if (items is List) {
      return items;
    }

    throw const FormatException(
      'API response liste veya items listesi içermelidir.',
    );
  }
}
