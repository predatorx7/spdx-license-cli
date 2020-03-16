import 'package:sample/string_match.dart' as string_match;

void main(List<String> args) {
  double res;
  res = string_match.diceMatch(args[0], args[1]) * 100;
  print('$res%');
}
