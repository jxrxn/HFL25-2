// lib/ui/cli_utils.dart
// Enkla CLI-hjälpare + ANSI-färger samlade på ett ställe.

const String red = '\x1B[31m';
const String green = '\x1B[32m';
const String yellow = '\x1B[33m';
const String cyan = '\x1B[36m';
const String reset = '\x1B[0m';

void printError(String msg) => print("$red$msg$reset");
void printSuccess(String msg) => print("$green$msg$reset");
void printInfo(String msg) => print("$cyan$msg$reset");
void printWarn(String msg) => print("$yellow$msg$reset");

String label(String text) => "$cyan$text:$reset";