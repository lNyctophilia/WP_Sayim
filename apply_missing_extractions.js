const fs = require('fs');

const replacements = [
    {
        file: './lib/features/home/presentation/pages/home_page.dart',
        target: /isTr\s*\?\s*'Bu ay \$\{data\.totalDays\} gün çalıştın, harika gidiyorsun!'\s*:\s*'You worked \$\{data\.totalDays\} days this month, keep it up!'/g,
        replacement: "AppStrings.getFormat('worked_days_msg', isTr ? 'tr' : 'en', [data.totalDays])"
    },
    {
        file: './lib/features/manager/presentation/pages/add_person_to_sayim_page.dart',
        target: /isTr\s*\?\s*'Davet Gönder \(\$\{_selectedConfigs\.length\} Kişi\)'\s*:\s*'Send Invites \(\$\{_selectedConfigs\.length\} People\)'/g,
        replacement: "AppStrings.getFormat('send_invites_count', isTr ? 'tr' : 'en', [_selectedConfigs.length])"
    },
    {
        file: './lib/features/manager/presentation/pages/create_past_sayim_page.dart',
        target: /widget\.lang\.currentLang == 'tr'\s*\?\s*'En az bir saat grubu eklemelisiniz\.'\s*:\s*'You must add at least one time group\.'/g,
        replacement: "AppStrings.get('add_time_group_error', widget.lang.currentLang)"
    },
    {
        file: './lib/features/manager/presentation/pages/create_past_sayim_page.dart',
        target: /widget\.lang\.currentLang == 'tr'\s*\?\s*'Standart sayıdan fazla kişi seçemezsiniz!\\nPersonel: \$selectedPersonel\/\$targetPersonel, Yönetici: \$selectedYonetici\/\$targetYonetici'\s*:\s*'You cannot select more people than the standard count!\\nPersonnel: \$selectedPersonel\/\$targetPersonel, Manager: \$selectedYonetici\/\$targetYonetici'/g,
        replacement: "AppStrings.getFormat('too_many_people_error', widget.lang.currentLang, [selectedPersonel, targetPersonel, selectedYonetici, targetYonetici])"
    },
    {
        file: './lib/features/manager/presentation/pages/create_past_sayim_page.dart',
        target: /widget\.lang\.currentLang == 'tr'\s*\?\s*'Eksik Kişi Seçimi'\s*:\s*'Missing Personnel'/g,
        replacement: "AppStrings.get('missing_personnel_title', widget.lang.currentLang)"
    },
    {
        file: './lib/features/manager/presentation/pages/create_past_sayim_page.dart',
        target: /widget\.lang\.currentLang == 'tr'\s*\?\s*'Sayım için hedeflenen sayıdan az kişi seçtiniz\.\\nEksik Personel: \$\{targetPersonel - selectedPersonel\}\\nEksik Yönetici: \$\{targetYonetici - selectedYonetici\}\\nYine de oluşturmak istiyor musunuz\? \(Sonradan kişi ekleyebilirsiniz\)'\s*:\s*'You have selected fewer people than targeted\.\\nMissing Personnel: \$\{targetPersonel - selectedPersonel\}\\nMissing Manager: \$\{targetYonetici - selectedYonetici\}\\nDo you still want to create it\? \(You can add people later\)'/g,
        replacement: "AppStrings.getFormat('not_enough_people_msg', widget.lang.currentLang, [targetPersonel - selectedPersonel, targetYonetici - selectedYonetici])"
    },
    {
        file: './lib/features/manager/presentation/pages/create_past_sayim_page.dart',
        target: /widget\.lang\.currentLang == 'tr'\s*\?\s*'İptal'\s*:\s*'Cancel'/g,
        replacement: "AppStrings.get('cancel', widget.lang.currentLang)"
    },
    {
        file: './lib/features/manager/presentation/pages/create_past_sayim_page.dart',
        target: /widget\.lang\.currentLang == 'tr'\s*\?\s*'Oluştur'\s*:\s*'Create'/g,
        replacement: "AppStrings.get('create', widget.lang.currentLang)"
    },
    {
        file: './lib/features/manager/presentation/pages/create_past_sayim_page.dart',
        target: /widget\.lang\.currentLang == 'tr'\s*\?\s*'Geçmiş sayım başarıyla kaydedildi\.'\s*:\s*'Past count saved successfully\.'/g,
        replacement: "AppStrings.get('past_count_saved', widget.lang.currentLang)"
    },
    {
        file: './lib/features/manager/presentation/pages/create_sayim_page.dart',
        target: /widget\.lang\.currentLang == 'tr'\s*\?\s*'En az bir saat grubu eklemelisiniz\.'\s*:\s*'You must add at least one time group\.'/g,
        replacement: "AppStrings.get('add_time_group_error', widget.lang.currentLang)"
    },
    {
        file: './lib/features/manager/presentation/pages/create_sayim_page.dart',
        target: /widget\.lang\.currentLang == 'tr'\s*\?\s*'Standart sayıdan fazla kişi seçemezsiniz!\\nPersonel: \$selectedPersonel\/\$targetPersonel, Yönetici: \$selectedYonetici\/\$targetYonetici'\s*:\s*'You cannot select more people than the standard count!\\nPersonnel: \$selectedPersonel\/\$targetPersonel, Manager: \$selectedYonetici\/\$targetYonetici'/g,
        replacement: "AppStrings.getFormat('too_many_people_error', widget.lang.currentLang, [selectedPersonel, targetPersonel, selectedYonetici, targetYonetici])"
    },
    {
        file: './lib/features/manager/presentation/pages/create_sayim_page.dart',
        target: /widget\.lang\.currentLang == 'tr'\s*\?\s*'Eksik Kişi Seçimi'\s*:\s*'Missing Personnel'/g,
        replacement: "AppStrings.get('missing_personnel_title', widget.lang.currentLang)"
    },
    {
        file: './lib/features/manager/presentation/pages/create_sayim_page.dart',
        target: /widget\.lang\.currentLang == 'tr'\s*\?\s*'Sayım için hedeflenen sayıdan az kişi seçtiniz\.\\nEksik Personel: \$\{targetPersonel - selectedPersonel\}\\nEksik Yönetici: \$\{targetYonetici - selectedYonetici\}\\nYine de oluşturmak istiyor musunuz\? \(Sonradan kişi ekleyebilirsiniz\)'\s*:\s*'You have selected fewer people than targeted\.\\nMissing Personnel: \$\{targetPersonel - selectedPersonel\}\\nMissing Manager: \$\{targetYonetici - selectedYonetici\}\\nDo you still want to create it\? \(You can add people later\)'/g,
        replacement: "AppStrings.getFormat('not_enough_people_msg', widget.lang.currentLang, [targetPersonel - selectedPersonel, targetYonetici - selectedYonetici])"
    },
    {
        file: './lib/features/manager/presentation/pages/create_sayim_page.dart',
        target: /widget\.lang\.currentLang == 'tr'\s*\?\s*'İptal'\s*:\s*'Cancel'/g,
        replacement: "AppStrings.get('cancel', widget.lang.currentLang)"
    },
    {
        file: './lib/features/manager/presentation/pages/create_sayim_page.dart',
        target: /widget\.lang\.currentLang == 'tr'\s*\?\s*'Oluştur'\s*:\s*'Create'/g,
        replacement: "AppStrings.get('create', widget.lang.currentLang)"
    },
    {
        file: './lib/features/manager/presentation/pages/create_sayim_page.dart',
        target: /widget\.lang\.currentLang == 'tr'\s*\?\s*'Sayım başarıyla oluşturuldu ve davetler gönderildi\.'\s*:\s*'Count created successfully and invitations sent\.'/g,
        replacement: "AppStrings.get('count_created_sent', widget.lang.currentLang)"
    },
    {
        file: './lib/features/manager/presentation/pages/edit_sayim_page.dart',
        target: /widget\.lang\.currentLang == 'tr'\s*\?\s*'En az bir saat grubu eklemelisiniz\.'\s*:\s*'You must add at least one time group\.'/g,
        replacement: "AppStrings.get('add_time_group_error', widget.lang.currentLang)"
    },
    {
        file: './lib/features/manager/presentation/pages/edit_sayim_page.dart',
        target: /widget\.lang\.currentLang == 'tr'\s*\?\s*'Standart sayıdan fazla kişi seçemezsiniz!\\nPersonel: \$selectedPersonel\/\$targetPersonel, Yönetici: \$selectedYonetici\/\$targetYonetici'\s*:\s*'You cannot select more people than the standard count!\\nPersonnel: \$selectedPersonel\/\$targetPersonel, Manager: \$selectedYonetici\/\$targetYonetici'/g,
        replacement: "AppStrings.getFormat('too_many_people_error', widget.lang.currentLang, [selectedPersonel, targetPersonel, selectedYonetici, targetYonetici])"
    },
    {
        file: './lib/features/manager/presentation/pages/edit_sayim_page.dart',
        target: /widget\.lang\.currentLang == 'tr'\s*\?\s*'Eksik Kişi Seçimi'\s*:\s*'Missing Personnel'/g,
        replacement: "AppStrings.get('missing_personnel_title', widget.lang.currentLang)"
    },
    {
        file: './lib/features/manager/presentation/pages/edit_sayim_page.dart',
        target: /widget\.lang\.currentLang == 'tr'\s*\?\s*'Sayım için hedeflenen sayıdan az kişi seçtiniz\.\\nEksik Personel: \$\{targetPersonel - selectedPersonel\}\\nEksik Yönetici: \$\{targetYonetici - selectedYonetici\}\\nYine de güncellemek istiyor musunuz\? \(Sonradan kişi ekleyebilirsiniz\)'\s*:\s*'You have selected fewer people than targeted\.\\nMissing Personnel: \$\{targetPersonel - selectedPersonel\}\\nMissing Manager: \$\{targetYonetici - selectedYonetici\}\\nDo you still want to update it\? \(You can add people later\)'/g,
        replacement: "AppStrings.getFormat('not_enough_people_update_msg', widget.lang.currentLang, [targetPersonel - selectedPersonel, targetYonetici - selectedYonetici])"
    },
    {
        file: './lib/features/manager/presentation/pages/edit_sayim_page.dart',
        target: /widget\.lang\.currentLang == 'tr'\s*\?\s*'İptal'\s*:\s*'Cancel'/g,
        replacement: "AppStrings.get('cancel', widget.lang.currentLang)"
    },
    {
        file: './lib/features/manager/presentation/pages/edit_sayim_page.dart',
        target: /widget\.lang\.currentLang == 'tr'\s*\?\s*'Güncelle'\s*:\s*'Update'/g,
        replacement: "AppStrings.get('update_btn', widget.lang.currentLang)"
    },
    {
        file: './lib/features/manager/presentation/pages/edit_sayim_page.dart',
        target: /widget\.lang\.currentLang == 'tr'\s*\?\s*'Sayım başarıyla güncellendi\.'\s*:\s*'Count updated successfully\.'/g,
        replacement: "AppStrings.get('count_updated', widget.lang.currentLang)"
    },
    {
        file: './lib/features/manager/presentation/pages/shuttle_panel_page.dart',
        target: /isTr\s*\?\s*'Şu personellerin konumu yok ve rotaya eklenemedi: \$\{missingLocationStaff\.join\(\', \'\)\}'\s*:\s*'These staff members have no location and were skipped: \$\{missingLocationStaff\.join\(\', \'\)\}'/g,
        replacement: "AppStrings.getFormat('shuttle_missing_location', isTr ? 'tr' : 'en', [missingLocationStaff.join(', ')])"
    },
    {
        file: './lib/features/manager/presentation/pages/shuttle_panel_page.dart',
        target: /isTr\s*\?\s*'Rota "Mevcut Konum"dan başlar, seçilen personellere uğrar ve sizin konumunuzda \(\$\{widget\.currentUser\.fullName\}\) biter\.'\s*:\s*'The route starts at "Current Location", visits selected staff, and ends at your location \(\$\{widget\.currentUser\.fullName\}\)\.'/g,
        replacement: "AppStrings.getFormat('shuttle_route_desc', isTr ? 'tr' : 'en', [widget.currentUser.fullName])"
    },
    {
        file: './lib/features/manager/presentation/pages/shuttle_panel_page.dart',
        target: /isTr\s*\?\s*'Seçilen: \$\{_selectedStaff\.length\} \/ \$_maxSelection'\s*:\s*'Selected: \$\{_selectedStaff\.length\} \/ \$_maxSelection'/g,
        replacement: "AppStrings.getFormat('shuttle_selected_count', isTr ? 'tr' : 'en', [_selectedStaff.length, _maxSelection])"
    },
    {
        file: './lib/features/manager/presentation/widgets/staff_picker.dart',
        target: /widget\.isTr\s*\?\s*'Personel: \$\{_configs\.where\(\(c\) => c\.isSelected && c\.role == DavetRole\.staff\)\.length \+ widget\.alreadySelectedPersonel\}\/\$\{widget\.targetPersonel\} \| Yönetici: \$\{_configs\.where\(\(c\) => c\.isSelected && c\.role == DavetRole\.manager\)\.length \+ widget\.alreadySelectedYonetici\}\/\$\{widget\.targetYonetici\}'\s*:\s*'Staff: \$\{_configs\.where\(\(c\) => c\.isSelected && c\.role == DavetRole\.staff\)\.length \+ widget\.alreadySelectedPersonel\}\/\$\{widget\.targetPersonel\} \| Manager: \$\{_configs\.where\(\(c\) => c\.isSelected && c\.role == DavetRole\.manager\)\.length \+ widget\.alreadySelectedYonetici\}\/\$\{widget\.targetYonetici\}'/g,
        replacement: "AppStrings.getFormat('staff_selection_count', widget.isTr ? 'tr' : 'en', [_configs.where((c) => c.isSelected && c.role == DavetRole.staff).length + widget.alreadySelectedPersonel, widget.targetPersonel, _configs.where((c) => c.isSelected && c.role == DavetRole.manager).length + widget.alreadySelectedYonetici, widget.targetYonetici])"
    },
    {
        file: './lib/features/settings/presentation/pages/global_settings_page.dart',
        target: /widget\.lang\.currentLang == 'tr'\s*\?\s*'Ayarlar başarıyla kaydedildi\.'\s*:\s*'Settings saved successfully\.'/g,
        replacement: "AppStrings.get('settings_saved', widget.lang.currentLang)"
    },
    {
        file: './lib/features/settings/presentation/pages/global_settings_page.dart',
        target: /widget\.lang\.currentLang == 'tr'\s*\?\s*'Hata: \$e'\s*:\s*'Error: \$e'/g,
        replacement: "AppStrings.get('error_prefix', widget.lang.currentLang) + e.toString()"
    },
    {
        file: './lib/features/staff/presentation/pages/invitations_page.dart',
        target: /davet\.sehirIciDisi == SehirTipi\.ici\s*\?\s*'Ş\. İçi'\s*:\s*'Ş\. Dışı'/g,
        replacement: "davet.sehirIciDisi == SehirTipi.ici ? AppStrings.get('city_inner_short', isTr ? 'tr' : 'en') : AppStrings.get('city_outer_short', isTr ? 'tr' : 'en')"
    }
];

// Special cases for sayim_detail_page that are highly complex
const sayimDetailReplacements = [
    {
        file: './lib/features/manager/presentation/pages/sayim_detail_page.dart',
        target: /isTr\s*\?\s*'Eksik Kişi! \$\{missingPersonel > 0 \? '\\\$missingPersonel Personel ' : ''\}\$\{missingYonetici > 0 \? '\\\$missingYonetici Yönetici' : ''\}'\s*:\s*'Missing People! \$\{missingPersonel > 0 \? '\\\$missingPersonel Staff ' : ''\}\$\{missingYonetici > 0 \? '\\\$missingYonetici Manager' : ''\}'/g,
        replacement: "AppStrings.get('missing_people_prefix', isTr ? 'tr' : 'en') + (missingPersonel > 0 ? AppStrings.getFormat('missing_staff', isTr ? 'tr' : 'en', [missingPersonel]) : '') + (missingYonetici > 0 ? AppStrings.getFormat('missing_manager', isTr ? 'tr' : 'en', [missingYonetici]) : '')"
    }
];

let filesProcessed = new Set();
[...replacements, ...sayimDetailReplacements].forEach(r => {
    try {
        let content = fs.readFileSync(r.file, 'utf8');
        content = content.replace(r.target, r.replacement);
        fs.writeFileSync(r.file, content);
        filesProcessed.add(r.file);
    } catch(e) {
        console.error("Failed on " + r.file, e);
    }
});

console.log("Replaced in " + filesProcessed.size + " files");
