import 'package:firebase_analytics/firebase_analytics.dart';

class AnalyticsService {
  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  Future<void> logLogin() => _analytics.logLogin();

  Future<void> logSearch(String query, String module) {
    return _analytics.logEvent(
      name: 'search_used',
      parameters: <String, Object>{
        'query': query,
        'module': module,
      },
    );
  }

  Future<void> logCreatePost(String type) {
    return _analytics.logEvent(
      name: 'create_post',
      parameters: <String, Object>{'type': type},
    );
  }
}
