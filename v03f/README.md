# Miniräknare

### En miniräknare byggd i Flutter    
Live-uträkning, mörkt/ljust läge, tusentalsavgränsning, korrekt procentlogik och korrekta decimaler (ingen flyttalsavrundning).  
Korrekt operatorprioritet (×/÷ före +/−). Decimaltecken visas som komma.  

---

# Funktioner

### Exakt beräkning  
Max heltalsstorlek, 27 siffror:  
999 999 999 999 999 999 999 999 999  
10²⁷ – 1  
≈ 1 kvadriljard (lång skala, Sverige)  
≈ 1 octillion (kort skala, t.ex. USA)  

Räknaren använder Decimal-biblioteket istället för IEEE-754 double precision (64-bit flyttal) vilket undviker avrundningsfel som:  
999 999 999.2 → 999 999 999.200000047684  
eller:
0,1 + 0,2 = 0,30000000000000004 (0,1 och 0,2 kan inte representeras exakt i binär form).  

---

### Live-uträkning
Resultatet uppdateras direkt medan du skriver.  
Exempel:  
`20 + 3 × 2` → visar **26** direkt, även innan du tryckt `=`.

---

### Beräkningshistorik
Den övre remsan visar alltid aktuellt uttryck:
- Visar siffror och operatorer så fort de skrivs  
- Kan scrollas i sidled och rullar automatiskt för att visa senaste delen  
- Visar även kompletta uttryck efter `=`:  
  `20 + 3 × 2 = 26`

---

### Procentlogik  
```text
| Uträkning        | Tolkas som                | Resultat |  
|------------------|---------------------------|----------|  
| 50 + 10 %        | 50 + (10% av 50)          | 55       |  
| 50 - 10 %        | 50 - (10% av 50)          | 45       |  
| 100 × 10 %       | 100 × 0.10                | 10       |  
| 100 ÷ 10 %       | 100 ÷ 0.10                | 1000     |  
| 10 %             | 10 ÷ 100                  | 0.1      |  
```

---

### Rensa & redigera
Kort tryck på `C` raderar det senaste.  
Långt tryck på `C` rensar allt (AC).  

---

### Kopiera resultat eller uträkning

Tryck på stora talet eller på uträkningen i remsan för att kopiera till urklipp.

---

### Tangentbordsgenvägar

För desktop- och webversionerna fungerar tangentbordet för att räkna:

Siffror & decimal  
  `0–9` → siffror  
  `,` eller `.` → decimal  

Operatorer  
  `+` → plus  
  `-` → minus  
  `*` → multiplikation  
  `/` → division  
  `%` → procent  

Beräkna  
  `=`  
  `Enter`  
  Numpad `Enter`  

Radera  
  `Backspace` → C (radera senaste)  
  `Cmd+Backspace` eller `Ctrl+Backspace` (mac) → AC  
  `Ctrl+Backspace` (Win/Linux) → AC  
  (På numpad) Clear-knappen `[⌧]` → AC (fungerar bäst i webbläsare)  

---

### Mörkt & ljust tema

Automatiskt efter systemtema, eller manuellt via AppBar-knappen.

---

## Struktur

```text
v03f/
 ├─ lib/
 │   ├─ main.dart
 │   ├─ calculator_screen.dart
 │   ├─ calc_button.dart
 │   ├─ logic/
 │   │   └─ calculator_engine.dart
 │   └─ ui/
 │       ├─ display_widget.dart
 │       └─ button_grid.dart
 ├─ test/
 │   ├─ calculator_live_test.dart
 │   └─ calculator_strip_test.dart
 └─ pubspec.yaml
 ```
 ---
 
 ## Installation

1.	Klona projektet

```bash
git clone https://github.com/jxrxn/HFL25-2.git
cd HFL25-2/v03f
```

2.	Installera beroenden

```bash
flutter pub get
```

3.	Kör appen

```bash
flutter run
```

4.	Kör tester

```bash
flutter test
```


