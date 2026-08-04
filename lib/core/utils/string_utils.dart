class StringUtils {
  static String formatCompanyName(String text) {
    if (text.trim().isEmpty) return text;
    final trimmed = text.trim();
    
    // Check if the string is all lowercase
    final isAllLowerCase = trimmed == trimmed.replaceAll('I', 'ı').replaceAll('İ', 'i').toLowerCase();
    
    if (isAllLowerCase) {
      return formatTitleCase(trimmed);
    }
    return trimmed;
  }

  static String formatTitleCase(String text) {
    if (text.trim().isEmpty) return text;
    return text.trim().split(' ').map((word) {
      if (word.isEmpty) return word;
      String firstLetter = word[0];
      String rest = word.substring(1);
      
      // Turkish capitalization for the first letter
      if (firstLetter == 'i') firstLetter = 'İ';
      else if (firstLetter == 'ı') firstLetter = 'I';
      else firstLetter = firstLetter.toUpperCase();

      // Turkish lowercase for the rest
      rest = rest.replaceAll('I', 'ı').replaceAll('İ', 'i').toLowerCase();

      return firstLetter + rest;
    }).join(' ');
  }
}
