const fs = require('fs');
const path = require('path');

function walk(dir) {
    let results = [];
    const list = fs.readdirSync(dir);
    list.forEach(function(file) {
        file = dir + '/' + file;
        const stat = fs.statSync(file);
        if (stat && stat.isDirectory()) { 
            results = results.concat(walk(file));
        } else { 
            if (file.endsWith('.dart')) results.push(file);
        }
    });
    return results;
}

const files = walk('./lib');
let matches = [];
files.forEach(file => {
    let content = fs.readFileSync(file, 'utf8');
    // Match any ternary operator returning a string
    // e.g. condition ? 'tr_string' : 'en_string'
    const regex = /\?\s*(['"])(.*?)\1\s*:\s*(['"])(.*?)\3/g;
    let match;
    while ((match = regex.exec(content)) !== null) {
        // Find the condition before the question mark
        const before = content.substring(Math.max(0, match.index - 50), match.index);
        // Only if it doesn't look like AppStrings.get (AppStrings.get also has ? but maybe inside the arguments, wait, no, AppStrings.get(..., isTr ? 'tr' : 'en')
        // Actually, we want to find remaining un-extracted translations.
        // Usually the ones we extracted were strings, but there might be more that are strings.
        // Let's filter out 'tr' : 'en' because those are already extracted or language selectors.
        if (match[2] === 'tr' && match[4] === 'en') continue;
        if (match[2] === 'en' && match[4] === 'tr') continue;

        matches.push({
            file: file,
            before: before.trim(),
            original: match[0],
            tr: match[2],
            en: match[4]
        });
    }
});
fs.writeFileSync('all_ternaries.json', JSON.stringify(matches, null, 2));
console.log('Found ' + matches.length + ' ternaries');
