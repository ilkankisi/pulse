import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';
import 'package:pulse/features/pulse/data/safety_moderation_api.dart';
import 'package:pulse/features/pulse/domain/moderation_models.dart';

import 'package:pulse/core/network/api_routes.dart';

void main() {
  test('block canonical profile block yoluna POST gönderir', () async {
    final dio = Dio(BaseOptions(baseUrl: 'http://127.0.0.1:5000'));
    final adapter = DioAdapter(dio: dio);
    final api = SafetyModerationApi(dio: dio);

    addTearDown(() => dio.close(force: true));

    adapter.onPost(
      '/api/v1/profiles/ayse/block',
      (server) => server.reply(200, <String, dynamic>{
        'id': 9,
        'username': 'ayse',
        'isBlocked': true,
      }),
    );

    final result = await api.blockUser('ayse');

    expect(result.id, 9);
    expect(result.username, 'ayse');
    expect(result.isBlocked, isTrue);
  });

  test('unblock canonical profile block yoluna DELETE gönderir', () async {
    final dio = Dio(BaseOptions(baseUrl: 'http://127.0.0.1:5000'));
    final adapter = DioAdapter(dio: dio);
    final api = SafetyModerationApi(dio: dio);

    addTearDown(() => dio.close(force: true));

    adapter.onDelete(
      '/api/v1/profiles/ayse/block',
      (server) => server.reply(204, null),
    );

    await api.unblockUser('ayse');
  });

  test('blocks 404 empty liste döner', () async {
    final dio = Dio(BaseOptions(baseUrl: 'http://127.0.0.1:5000'));
    final adapter = DioAdapter(dio: dio);
    final api = SafetyModerationApi(dio: dio);

    addTearDown(() => dio.close(force: true));

    adapter.onGet(
      ApiRoutes.blocks,
      (server) => server.reply(404, <String, dynamic>{
        'error': 'Not found',
        'field': null,
      }),
    );

    expect(await api.getBlockedUsers(), isEmpty);
  });

  test('report canonical body ile POST gönderir', () async {
    final dio = Dio(BaseOptions(baseUrl: 'http://127.0.0.1:5000'));
    final adapter = DioAdapter(dio: dio);
    final api = SafetyModerationApi(dio: dio);

    addTearDown(() => dio.close(force: true));

    const body = <String, dynamic>{
      'targetType': 'post',
      'targetId': 42,
      'reason': 'harassment',
      'details': 'Rahatsız edici içerik',
    };

    adapter.onPost(
      '/api/v1/reports',
      (server) => server.reply(201, <String, dynamic>{
        'id': 10,
        ...body,
        'status': 'pending',
        'createdAt': '2026-08-10T10:00:00Z',
      }),
      data: body,
    );

    final report = await api.createReport(
      const CreateReportRequest(
        targetType: ReportTargetType.post,
        targetId: 42,
        reason: ReportReason.harassment,
        details: 'Rahatsız edici içerik',
      ),
    );

    expect(report.id, 10);
    expect(report.status, ModerationStatus.pending);
  });

  test('report tokenları backend ile birebir yazılır', () {
    const request = CreateReportRequest(
      targetType: ReportTargetType.user,
      targetId: 9,
      reason: ReportReason.fakeAccount,
    );

    expect(request.toJson(), <String, dynamic>{
      'targetType': 'user',
      'targetId': 9,
      'reason': 'fakeAccount',
      'details': null,
    });
  });

  test('moderation 404 empty queue döner', () async {
    final dio = Dio(BaseOptions(baseUrl: 'http://127.0.0.1:5000'));
    final adapter = DioAdapter(dio: dio);
    final api = SafetyModerationApi(dio: dio);

    addTearDown(() => dio.close(force: true));

    adapter.onGet(
      ApiRoutes.moderationReports,
      (server) => server.reply(404, <String, dynamic>{
        'error': 'Not found',
        'field': null,
      }),
    );

    expect(await api.getModerationReports(), isEmpty);
  });

  test('resolve canonical action ve note body ile POST gönderir', () async {
    final dio = Dio(BaseOptions(baseUrl: 'http://127.0.0.1:5000'));
    final adapter = DioAdapter(dio: dio);
    final api = SafetyModerationApi(dio: dio);

    addTearDown(() => dio.close(force: true));

    const body = <String, dynamic>{
      'action': 'removePost',
      'note': 'İçerik kaldırıldı',
    };

    adapter.onPost(
      ApiRoutes.moderationResolve(7),
      (server) => server.reply(200, <String, dynamic>{
        'id': 7,
        'status': 'resolved',
        'action': 'removePost',
        'resolvedAt': '2026-08-10T11:00:00Z',
        'resolvedByUserId': 2,
      }),
      data: body,
    );

    final result = await api.resolveReport(
      7,
      const ResolveReportRequest(
        action: ModerationAction.removePost,
        note: 'İçerik kaldırıldı',
      ),
    );

    expect(result.status, ModerationStatus.resolved);
    expect(result.action, ModerationAction.removePost);
  });

  test('dismiss canonical endpointine body olmadan POST gönderir', () async {
    final dio = Dio(BaseOptions(baseUrl: 'http://127.0.0.1:5000'));
    final adapter = DioAdapter(dio: dio);
    final api = SafetyModerationApi(dio: dio);

    addTearDown(() => dio.close(force: true));

    adapter.onPost(
      '/api/v1/moderation/reports/8/dismiss',
      (server) =>
          server.reply(200, <String, dynamic>{'id': 8, 'status': 'dismissed'}),
    );

    await api.dismissReport(8);
  });
}
