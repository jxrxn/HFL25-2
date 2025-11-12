# Miniräknare

En miniräknare byggd i **Flutter** — med live-uträkning, ljust/mörkt-läge, tusentalsavgränsning och intelligent hantering av procent, operatorer och decimaler.

---

## Funktioner

- **Live-uträkning:** resultatet uppdateras direkt medan du skriver.  
- **Visuell remsa:** den aktuella uträkningen visas i en diskret remsa under resultatet.  
- **Smart procent:**  
  - `12 / 10 %` → `120`  
  - `50 + 10 %` → `55`  
- **Långtryck på `C`:** nollställer allt (AC).  
  Kort tryck raderar senaste tecken.  
- **Separat logik:** all beräkningslogik finns i `calculator_engine.dart` för tydlig separation mellan UI och logik.  
- **Tusentalsavgränsning:** stora tal visas som `1 234 567`.  
- **Kopiera resultat:** tryck på visningen för att kopiera talet till urklipp.  
- **Dark / Light mode** enligt systemtema eller manuellt via AppBar-knappen.  

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


