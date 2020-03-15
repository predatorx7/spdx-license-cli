import 'package:sample/string_match.dart' as stringMatch;

void main(List<String> args) {
  double res;
  print(args);
  res = stringMatch.diceMatch(args[0], args[1]);
  print(res);
}
