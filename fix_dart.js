const fs = require('fs');

// 1. Fix home_page.dart
let homeFile = './lib/features/home/presentation/pages/home_page.dart';
let homeContent = fs.readFileSync(homeFile, 'utf8');
homeContent = homeContent.replace(
    "(AppStrings.get('no_entries_for_this_month_yet_let', isTr ? 'tr' : 'en')s start!');",
    "AppStrings.get('no_entries_for_this_month_yet_let', isTr ? 'tr' : 'en');"
);
fs.writeFileSync(homeFile, homeContent);

// 2. Fix InvitationsPage class in invitations_page.dart
let invFile = './lib/features/staff/presentation/pages/invitations_page.dart';
let invContent = fs.readFileSync(invFile, 'utf8');
// Add lang parameter
if (!invContent.includes('LanguageService lang')) {
    invContent = invContent.replace(
        'final AppUser currentUser;',
        "final AppUser currentUser;\n  final LanguageService lang;"
    );
    invContent = invContent.replace(
        'required this.currentUser,',
        "required this.currentUser,\n    required this.lang,"
    );
    // Import LanguageService
    const lsImport = "import '../../../../core/services/language_service.dart';\n";
    invContent = lsImport + invContent;
}
fs.writeFileSync(invFile, invContent);

// 3. Update CustomTopBar to pass lang
let ctbFile = './lib/features/home/presentation/widgets/custom_top_bar.dart';
let ctbContent = fs.readFileSync(ctbFile, 'utf8');
if (!ctbContent.includes('lang: lang,')) {
    ctbContent = ctbContent.replace(
        'currentUser: currentUser!,',
        "currentUser: currentUser!,\n                                  lang: lang,"
    );
}
fs.writeFileSync(ctbFile, ctbContent);

console.log('Fixed home_page.dart, invitations_page.dart, custom_top_bar.dart');
