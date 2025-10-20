// lib/services/superhero_api_service.dart
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:v04/models/hero_model.dart';

class SuperheroApiService {
  SuperheroApiService(this._token, {HttpClient? client})
      : _client = client ?? HttpClient();

  final String _token;
  final HttpClient _client;

  Future<List<HeroModel>> searchByName(String rawQuery) async {
    final q = rawQuery.trim();
    if (q.isEmpty) return const <HeroModel>[];

    // --- NYTT: generera smarta varianter, inkl. auto-insert före suffix ---
    List<String> variants(String s) {
      final base = s.toLowerCase();

      // Hjälpsuffix som ofta skrivs ihop, med minus eller med mellanslag
      const suffixes = ['man', 'woman', 'boy', 'girl', 'men', 'women'];

      final v = <String>{
        base,
        base.replaceAll('-', ' '),
        base.replaceAll(' ', '-'),
        base.replaceAll(RegExp(r'[\s\-]+'), ''), // helt hopskrivet
      };

      // Om ordet slutar på ett av suffixen: lägg in former där vi bryter före suffixet
      for (final suf in suffixes) {
        if (base.endsWith(suf) && base.length > suf.length) {
          final stem = base.substring(0, base.length - suf.length);
          // undvik dubbla separatorer om stem redan slutar med '-' eller ' '
          final stemTrim = stem.replaceAll(RegExp(r'[\s\-]+$'), '');
          v.add('$stemTrim-$suf');
          v.add('$stemTrim $suf');
        }
      }

      return v.toList();
    }
    // -----------------------------------------------------------------------

    Future<List<HeroModel>> tryOnce(String term) async {
      final uri = Uri.parse(
        'https://superheroapi.com/api/$_token/search/${Uri.encodeComponent(term)}',
      );

      try {
        final req = await _client.getUrl(uri);
        final res = await req.close().timeout(const Duration(seconds: 8));
        if (res.statusCode != 200) return const [];

        final body = await res.transform(utf8.decoder).join();
        final decoded = jsonDecode(body);
        if (decoded is! Map || decoded['response'] != 'success' || decoded['results'] is! List) {
          return const [];
        }

        final results = (decoded['results'] as List).cast<Map<String, dynamic>>();
        return results.map(HeroModel.fromJson).toList();
      } on TimeoutException {
        return const [];
      } on SocketException {
        return const [];
      } on FormatException {
        return const [];
      }
    }

    // Testa varianterna i ordning, returnera så fort vi får träffar
    final tried = <String>{};
    for (final term in variants(q)) {
      if (tried.contains(term)) continue;
      tried.add(term);
      final hits = await tryOnce(term);
      if (hits.isNotEmpty) return hits;
    }

    return const [];
  }

  void close() => _client.close(force: true);
}