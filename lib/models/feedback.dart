/// Mirrors the nps-api JSON contract at docs/feedback-v1.json.
/// Field names use snake_case in JSON; Dart properties use camelCase.
class Feedback {
  Feedback({
    required this.app,
    required this.appVersion,
    required this.platform,
    required this.timestamp,
    required this.npsRating,
    this.timezone,
    this.comment,
  })  : assert(npsRating >= 1 && npsRating <= 10, 'rating must be 1..10'),
        npsCategory = _categoryFor(npsRating);

  static const String schemaVersion = '1.0';

  final String app;
  final String appVersion;
  final String platform;
  final String timestamp;
  final int npsRating;
  final String npsCategory;
  final String? timezone;
  final String? comment;

  static String _categoryFor(int rating) {
    if (rating <= 6) return 'detractor';
    if (rating <= 8) return 'passive';
    return 'promoter';
  }

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{
      'schema_version': schemaVersion,
      'app': app,
      'app_version': appVersion,
      'platform': platform,
      'timestamp': timestamp,
      'nps_rating': npsRating,
      'nps_category': npsCategory,
    };
    if (timezone != null && timezone!.isNotEmpty) {
      json['timezone'] = timezone;
    }
    if (comment != null && comment!.isNotEmpty) {
      json['comment'] = comment;
    }
    return json;
  }
}
