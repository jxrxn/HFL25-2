# Miniräknare

En miniräknare byggd i **Flutter** — med live-uträkning, ljust/mörkt-läge, tusentalsavgränsning och intelligent hantering av procent, operatorer och decimaler.

---

## Funktioner

- **Live-uträkning:** resultatet uppdateras direkt medan du skriver.  
- **Visuell remsa:** den aktuella uträkningen visas i en diskret remsa ovanför resultatet.  
- **Smart procent:**  
  - `12 / 10 %` → `120`  
  - `50 + 10 %` → `55`  
- **Långt tryck på `C`:** nollställer allt (AC).  
  Kort tryck raderar senaste tecken.  
- **Tusentalsavgränsning:** stora tal visas som `1 234 567`.  
- **Kopiera resultat:** tryck på visningen för att kopiera talet till urklipp.  
- **Dark / Light mode** enligt systemtema eller manuellt via AppBar-knappen.

---

## Live-calculation preview

När du matar in ett uttryck, visas resultatet direkt i huvuddisplayen medan du skriver.
Exempel:
	•	Skriver du: 20 + 3 × 2
så visas 26 redan innan du tryckt =.
	•	Vid operatorkedjor visas det korrekta resultatet enligt operatorprioritet.

Previewn stängs av när du:
	•	just gjort =
	•	raderar till tomt uttryck
	•	eller är i ett fel-tillstånd.

---  

## Begränsningar

Miniräknaren följer samma säkerhetsgränser som iOS och Android för att undvika fel i flyttalsberäkningar:
	•	Max säkert heltal: 999 999 999 999 999 (15 siffror)
	•	Max total längd: 20 tecken inkl. decimaler
	•	Resultat som överskrider det visas inte, utan triggar felhantering.

Det gör räknaren stabil även vid stora tal.

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
 │   └─ calculator_live_test.dart
 │   └─ calculator_test.dart
 └─ pubspec.yaml
 ```

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


