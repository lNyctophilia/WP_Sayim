const fs = require('fs');

const matches = JSON.parse(fs.readFileSync('matches.json', 'utf8'));

// Only process strings without string interpolation or simple "tr" / "en" strings
const filtered = matches.filter(m => !m.tr.includes('${') && !m.original.includes('${') && m.tr !== 'tr');

const uniquePairs = new Map();

filtered.forEach(m => {
  let keyStr = m.en.toLowerCase().replace(/[^a-z0-9]/g, '_').replace(/_+/g, '_').replace(/^_|_$/g, '');
  if (!keyStr) keyStr = 'translation_key';
  
  let key = keyStr;
  let counter = 1;
  while(uniquePairs.has(key) && uniquePairs.get(key).en !== m.en) {
    key = keyStr + '_' + counter;
    counter++;
  }
  uniquePairs.set(key, {tr: m.tr, en: m.en});
  m.key = key; // Attach key to match
});

// Update app_strings.dart
const appStringsPath = './lib/core/constants/app_strings.dart';
let appStringsContent = fs.readFileSync(appStringsPath, 'utf8');

let newEntries = [];
uniquePairs.forEach((val, key) => {
  // Check if key already exists (just a naive check)
  if (!appStringsContent.includes(`'${key}':`)) {
    let trEscaped = val.tr.replace(/'/g, "\\'");
    let enEscaped = val.en.replace(/'/g, "\\'");
    newEntries.push(`    '${key}': {'tr': '${trEscaped}', 'en': '${enEscaped}'},`);
  }
});

if (newEntries.length > 0) {
  // Find the end of the _strings map
  const insertionPoint = appStringsContent.lastIndexOf('};');
  if (insertionPoint !== -1) {
    appStringsContent = appStringsContent.substring(0, insertionPoint) +
      '    // Newly extracted\\n' +
      newEntries.join('\\n') + '\\n  ' +
      appStringsContent.substring(insertionPoint);
    fs.writeFileSync(appStringsPath, appStringsContent);
    console.log(`Added ${newEntries.length} new entries to app_strings.dart`);
  }
}

// Replace in files
const fileMatches = {};
filtered.forEach(m => {
  if (!fileMatches[m.file]) fileMatches[m.file] = [];
  fileMatches[m.file].push(m);
});

for (const file of Object.keys(fileMatches)) {
  let content = fs.readFileSync(file, 'utf8');
  let changed = false;
  
  // Sort matches by original length descending to avoid partial replacements
  fileMatches[file].sort((a, b) => b.original.length - a.original.length);

  fileMatches[file].forEach(m => {
    // Check if we need `widget.isTr` or just `isTr`
    // Wait, the regex captured `isTr ? 'A' : 'B'`, the `isTr` might have `widget.` before it, 
    // but the regex didn't capture `widget.`. It captured starting from `isTr`.
    // Actually replacing `m.original` directly is fine since it's the exact match.
    // E.g., `isTr ? 'A' : 'B'` -> `AppStrings.get('key', isTr ? 'tr' : 'en')`
    const replacement = `AppStrings.get('${m.key}', isTr ? 'tr' : 'en')`;
    
    // Using string replacement (be careful, might replace multiples, which is fine if they are identical)
    // We can replace all occurrences using split.join
    if (content.includes(m.original)) {
      content = content.split(m.original).join(replacement);
      changed = true;
    }
  });

  if (changed) {
    fs.writeFileSync(file, content);
    console.log(`Updated ${file}`);
  }
}

console.log('Refactoring complete.');
