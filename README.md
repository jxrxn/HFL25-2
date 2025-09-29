# v01 – CLI Kalkylator

Det här är en enkel kalkylator skriven i Dart som körs i terminalen.  
Projektet är en del av repo **HFL25** för en kurs på STI.

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
   git clone https://github.com/jxrxn/HFL25.git
   cd HFL25
   ```

3. **Hämta beroenden**  
   I projektroten kör du:  
   ```bash
   dart pub get
   ```

## Användning

   **För att starta kalkylatorn**  
   I projektroten kör du:  
   ```bash
   dart run
   ```

   **Exempel**  
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
