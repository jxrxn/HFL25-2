import 'dart:convert';
import 'package:v03/models/hero_model.dart';

void main() {
  final jsonMap = {
    "id": "70",
    "name": "Batman",
    "powerstats": {"strength": "26", "intelligence": "100"},
    "biography": {"full-name": "Bruce Wayne"},
    "appearance": {"gender": "Male"},
  };

  final hero = HeroModel.fromJson(jsonMap);
  print(hero); // använder toString()
  print(jsonEncode(hero.toJson())); // rundresa till JSON
}
