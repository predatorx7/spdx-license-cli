/// Returns Map with the bigrams of strings. Also set a matched flag to false,
/// this flag becomes true when matched to another bigram so that it is not
/// counted twice
List<String> getBigrams(String w, row) {
  List<String> bigrams;
  bigrams = [];
  int i;
  for (i = 0; i < w.length - 1; i++) {
    var bigram = w.substring(i, i + 2);
    bigrams.add(bigram);
  }
  return bigrams;
}

/// Returns the Sørensen–Dice Coefficient for 2 strings
double diceMatch(String string1, String string2) {
  print('Comparing $string1 against $string2.');

  // Bigram: Constructing a list of letter pairs from each word
  var bigramsOfString1 = getBigrams(string1, 1);
  var bigramsOfString2 = getBigrams(string2, 2);

  // find how many bigrams from word 1 are present in the bigrams from word 2
  var matchingPairs = 0;

  // The Sørensen–Dice similarity score, updated incrementally
  var score = 0.0;

  // total number of bigrams in both words
  var max = (string1.length + string2.length - 2);

  for (var i = 0; i < bigramsOfString1.length; i += 1) {
    var string1b = bigramsOfString1[i];

    // Remove out if the current bigram has a match in the second word
    bigramsOfString2.removeWhere((String string2b) {
      if (string1b == string2b) {
        // Increasing count of matches by two since the bigrams occurs once
        // in each word
        matchingPairs += 2;

        // updating score iteratively
        score = matchingPairs / max;
        return true;
      } else {
        return false;
      }
    });
  }

  // results
  print(
      'There were $matchingPairs matching bigrams from a possible total of $max. The Sørensen–Dice similarity index is $score');
  return score;
}
