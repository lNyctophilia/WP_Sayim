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
const regex = /isTr\s*\?\s*(['"])(.*?)\1\s*:\s*(['"])(.*?)\3/g;
const matches = [];

files.forEach(file => {
    const content = fs.readFileSync(file, 'utf8');
    let m;
    while ((m = regex.exec(content)) !== null) {
        matches.push({ file, tr: m[2], en: m[4], original: m[0] });
    }
});

fs.writeFileSync('matches.json', JSON.stringify(matches, null, 2));
console.log('Done, wrote matches.json');
