// Sync layer: pulls the daily digests from the GitHub Pages JSON feed
// and caches them on-device so the app works fully offline.
//
// Feed (published by tools/build_api.py in the current-affairs-exams repo):
//   <base>/latest.json          -> {"latest": "2026-09-23", ...}
//   <base>/index.json           -> {"count": N, "days": [DaySummary...]}
//   <base>/daily/<slug>.json    -> full DayDigest

import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

import 'models.dart';

const _base =
    'https://niteshlhsnda-droid.github.io/current-affairs-exams/api/v1';

class FeedException implements Exception {
  final String message;
  FeedException(this.message);
  @override
  String toString() => message;
}

class AffairsApi {
  AffairsApi._();
  static final AffairsApi instance = AffairsApi._();

  Directory? _cacheDir;

  Future<Directory> _dir() async {
    if (_cacheDir != null) return _cacheDir!;
    final app = await getApplicationSupportDirectory();
    final d = Directory('${app.path}/feed');
    if (!await d.exists()) await d.create(recursive: true);
    _cacheDir = d;
    return d;
  }

  Future<String?> _readCache(String name) async {
    try {
      final f = File('${(await _dir()).path}/$name');
      if (await f.exists()) return await f.readAsString();
    } catch (_) {}
    return null;
  }

  Future<void> _writeCache(String name, String body) async {
    try {
      await File('${(await _dir()).path}/$name').writeAsString(body);
    } catch (_) {}
  }

  Future<String> _get(String url, {required String cacheName}) async {
    try {
      final r = await http
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 20));
      if (r.statusCode == 200) {
        await _writeCache(cacheName, r.body);
        return r.body;
      }
      throw FeedException('Server returned ${r.statusCode}');
    } catch (e) {
      final cached = await _readCache(cacheName);
      if (cached != null) return cached;
      if (e is FeedException) rethrow;
      throw FeedException(
          'No internet connection and nothing cached yet.');
    }
  }

  /// Returns the newest digest, refreshing from the network when possible.
  Future<DayDigest> fetchLatest() async {
    final latestBody =
        await _get('$_base/latest.json', cacheName: 'latest.json');
    final slug =
        (json.decode(latestBody) as Map<String, dynamic>)['latest'] as String;
    return fetchDay(slug);
  }

  Future<DayDigest> fetchDay(String slug) async {
    final body = await _get('$_base/daily/$slug.json',
        cacheName: 'daily-$slug.json');
    return DayDigest.fromJson(
        json.decode(body) as Map<String, dynamic>);
  }

  /// Newest-first list of all published days.
  Future<List<DaySummary>> fetchIndex() async {
    final body = await _get('$_base/index.json', cacheName: 'index.json');
    final days = (json.decode(body) as Map<String, dynamic>)['days'] as List;
    return days
        .map((d) => DaySummary.fromJson(d as Map<String, dynamic>))
        .toList();
  }

  /// True when the device currently has any cached digest at all.
  Future<bool> hasCache() async =>
      await _readCache('latest.json') != null;
}
