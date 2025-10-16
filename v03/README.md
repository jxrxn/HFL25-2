# HeroDex 3000

En Dart-app du kan använda i terminalen. Skapa, visa, sök och ta bort hjältar.  
Sparas automatiskt i JSON-format.

---

## ⚙️ Funktioner
1. Lägg till hjälte (namn, styrka, specialkraft, kön, ursprung, alignment)
2. Visa hjältar (sorterade efter styrka)
3. Sök efter hjältar
4. Ta bort hjälte (via nummer eller namn)
5. Automatisk spara/ladda från `heroes.json`

  •	 Central service-locator via GetIt (`initStore()` / `store`) säkerställer global tillgång till datalagret.  
  •  Dependency Injection via GetIt gör det enkelt att byta mellan produktions- och testläge.  
  •	 Abstrakt interface (HeroDataManaging) gör det lätt att byta ut lagring (t.ex. fil, API, moln).  
  •  JSON-persistens via dart:io och dart:convert.  
  •	 Färgade meddelanden för info, felmeddelanden och varningar.  
  •	 Varje hjälte får ett globalt unikt ID (UUID v4) genererat med paketet uuid.  

---

## 💡 Gör såhär

### Gå till din GitHub-mapp (eller där du vill ha projektet)
```bash
cd ~/Documents/GitHub
```

### Klona projektet (skapar mappen HFL25-2)
```bash
git clone https://github.com/jxrxn/HFL25-2.git
```

### Gå in i version 02
```bash
cd HFL25-2/v03
```

### Hämta paket
```bash
dart pub get
```

### Initiera rätt datalager (sker automatiskt)
Programmet använder `initStore()` i `app_store.dart` för att välja rätt datafil:
- standard: `heroes.json`
- `--mock`: `test/mock_heroes.json`
- `--data=filnamn.json`: valfri fil

### Kör programmet
```bash
dart run bin/herodex.dart
```


## 🧪 Olika lägen

Du kan nu starta HeroDex i tre olika lägen:

| Läge | Kommando | Beskrivning |
|------|-----------|-------------|
| **Standardläge** | `dart run bin/herodex.dart` | Läser och sparar hjältar i `heroes.json` |
| **Mockläge** | `dart run bin/herodex.dart --mock` | Använder testfilen test/mock_heroes.json (exempeldata med tre filosofer) |
| **Egen datafil** | `dart run bin/herodex.dart --data=custom.json` | Använder en specifik JSON-fil för lagring — har högst prioritet och vinner över --mock |


## 📘 Förklaring

•	`--data=` används alltid om den finns
•	annars används `--mock` om den flaggan finns
•	annars används standard (heroes.json)


##  ✅ Tester

Projektet innehåller enhetstester i test/:  
	•	hero_data_manager_test.dart  
	•	hero_data_manager_mock_test.dart  
	•	hero_model_test.dart  
	•	class_abstract_test.dart  

Kör alla tester:
```bash
dart test
```
