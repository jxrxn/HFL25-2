# v01 – CLI Kalkylator

Det här är en enkel kalkylator skriven i Dart som körs i terminalen.  
**HFL25-2** är en repo för en kurs i Dart och Flutter på [STI](https://www.sti.se).

## Installation

1. **Installera Dart SDK**  
   Följ instruktionerna här: [dart.dev/get-dart](https://dart.dev/get-dart)  
   Kontrollera att det fungerar med:  
   ```bash
   dart --version
   ```
   
2. **Klona projektet**  
   Öppna terminalen och kör:  
   ```bash
   git clone https://github.com/jxrxn/HFL25-2.git
   cd HFL25-2
   ```

3. **Hämta beroenden**  
   I terminalen:  
   ```bash
   dart pub get
   ```

## Användning

1. **För att starta kalkylatorn**  
   I terminalen:  
   ```bash
   dart run
   ```

2. **Exempel**  
   ```bash
   Ange första talet: 10
   Ange andra talet: 5
   Vilken operation vill du göra? (+, -, *, /): *
   Resultatet är: 50
   ```

   ## Funktioner

   •	Addition (+)  
   •	Subtraktion (-)  
   •	Multiplikation (*)  
   •	Division (/), med felhantering för division med noll
