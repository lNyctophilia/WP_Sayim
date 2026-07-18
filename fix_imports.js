const fs = require('fs');

function fix(file) {
    let content = fs.readFileSync(file, 'utf8');
    
    // Add import if missing
    if (!content.includes('app_strings.dart')) {
        const importStatement = "import 'package:daytrack/core/constants/app_strings.dart';\n";
        const firstImportIndex = content.indexOf('import ');
        if (firstImportIndex !== -1) {
            content = content.substring(0, firstImportIndex) + importStatement + content.substring(firstImportIndex);
        } else {
            content = importStatement + content;
        }
    }

    // Fix isTr in invitations_page.dart
    if (file.includes('invitations_page.dart')) {
        // Find how the current language is accessed. Let's replace isTr with widget.lang.currentLang == 'tr' or similar.
        // Wait, the original code had `AppStrings.get('city_inner_short', isTr ? 'tr' : 'en')` which caused `isTr` undefined.
        // I'll replace `isTr` with `widget.lang.currentLang == 'tr'` but first I need to see what `invitations_page.dart` uses.
        // I will just use `_isTr` or `widget.lang.currentLang == 'tr'` ? Let's check how `invitations_page.dart` knows the language.
        // We will just replace `isTr ? 'tr' : 'en'` with `'tr' /* TODO fix */` and then manually fix.
        // Actually, we can just replace `isTr ? 'tr' : 'en'` with `widget.lang.currentLang`
        content = content.replace(/isTr \? 'tr' : 'en'/g, "widget.lang.currentLang");
    }

    fs.writeFileSync(file, content);
    console.log('Fixed ' + file);
}

fix('./lib/features/settings/presentation/pages/global_settings_page.dart');
fix('./lib/features/staff/presentation/pages/invitations_page.dart');
