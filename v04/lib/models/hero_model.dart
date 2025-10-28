// lib/models/hero_model.dart
//
// Stark-typad hjältemodell med bakåtkompatibilitet.
// - Fält: id, name, powerstats, appearance, biography, work
// - fromJson hanterar både typad och "lös" JSON utan att krascha
// - toShortString används i CLI-listor
// - alignmentNormalized normaliserar alignment till: good / bad / neutral

import 'package:v04/models/appearance.dart';
import 'package:v04/models/biography.dart';
import 'package:v04/models/powerstats.dart';
import 'package:v04/models/work.dart';

// Re-export för bekväm import från en plats
export 'package:v04/models/powerstats.dart';
export 'package:v04/models/appearance.dart';
export 'package:v04/models/biography.dart';
export 'package:v04/models/work.dart';

class HeroModel {
  final String id;
  final String name;
  final Powerstats? powerstats;
  final Appearance? appearance;
  final Biography? biography;
  final Work? work;

  const HeroModel({
    required this.id,
    required this.name,
    this.powerstats,
    this.appearance,
    this.biography,
    this.work,
  });

  /// Primär, robust fromJson:
  /// - Tål att nycklar saknas
  /// - Tål att värden är "stringiga" (submodeller fixar)
  /// - Returnerar aldrig null (utan en tom/partial HeroModel)
  factory HeroModel.fromJson(Map<String, dynamic> json) {
    Powerstats? _ps(dynamic v) =>
        (v is Map<String, dynamic>) ? Powerstats.fromJson(v) : null;
    Appearance? _ap(dynamic v) =>
        (v is Map<String, dynamic>) ? Appearance.fromJson(v) : null;
    Biography? _bi(dynamic v) =>
        (v is Map<String, dynamic>) ? Biography.fromJson(v) : null;
    Work? _wo(dynamic v) =>
        (v is Map<String, dynamic>) ? Work.fromJson(v) : null;

    return HeroModel(
      id: '${json['id'] ?? ''}',
      name: '${json['name'] ?? ''}',
      powerstats: _ps(json['powerstats']),
      appearance: _ap(json['appearance']),
      biography: _bi(json['biography']),
      work: _wo(json['work']),
    );
  }

  /// Bakåtkompatibel inläsning om man uttryckligen vill signalera "lös" JSON.
  /// (Praktiskt i tester som matar äldre struktur.)
  factory HeroModel.fromLooseJson(Map<String, dynamic> json) =>
      HeroModel.fromJson(json);

  /// Hjälp för "stringigt" API-svar — samma som fromJson idag,
  /// men separerad för tydlighet och framtida skillnader.
  factory HeroModel.fromApiJson(Map<String, dynamic> json) =>
      HeroModel.fromJson(json);

  Map<String, dynamic> toJson() => {
        'id'       : id,
        'name'     : name,
        if (powerstats != null) 'powerstats': powerstats!.toJson(),
        if (appearance != null) 'appearance': appearance!.toJson(),
        if (biography != null) 'biography' : biography!.toJson(),
        if (work != null) 'work'           : work!.toJson(),
      };

  // === Helpers ===

  int get strength => powerstats?.strength ?? 0;

  /// Normaliserar alignment till en av: 'good' | 'bad' | 'neutral'
  String get alignmentNormalized {
    final raw = (biography?.alignment ?? '').toLowerCase().trim();
    if (raw.isEmpty) return 'neutral';
    if (raw.contains('good')) return 'good';
    if (raw.contains('bad') || raw.contains('evil')) return 'bad';
    return 'neutral';
    }

  /// Kompakt rad för CLI onlinesök / kortlistor
  String toShortString() {
    final fullName = biography?.fullName ?? 'Okänt';
    final gender   = appearance?.gender ?? 'Okänt';
    return "$name ($fullName) | styrka: $strength | kön: $gender";
  }

  @override
  String toString() => 'HeroModel($name, id=$id)';

  HeroModel copyWith({
    String? id,
    String? name,
    Powerstats? powerstats,
    Appearance? appearance,
    Biography? biography,
    Work? work,
  }) {
    return HeroModel(
      id: id ?? this.id,
      name: name ?? this.name,
      powerstats: powerstats ?? this.powerstats,
      appearance: appearance ?? this.appearance,
      biography: biography ?? this.biography,
      work: work ?? this.work,
    );
  }
}