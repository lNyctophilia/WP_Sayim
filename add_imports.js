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

files.forEach(file => {
    let content = fs.readFileSync(file, 'utf8');
    if (content.includes('AppStrings') && !content.includes('app_strings.dart')) {
        const importStatement = "import 'package:daytrack/core/constants/app_strings.dart';\n";
        // insert after first import or at top
        const firstImportIndex = content.indexOf('import ');
        if (firstImportIndex !== -1) {
            content = content.substring(0, firstImportIndex) + importStatement + content.substring(firstImportIndex);
        } else {
            content = importStatement + content;
        }
        fs.writeFileSync(file, content);
        console.log('Added import to', file);
    }
});
