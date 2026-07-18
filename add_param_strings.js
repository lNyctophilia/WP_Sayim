const fs = require('fs');

const appStringsPath = './lib/core/constants/app_strings.dart';
let appStringsContent = fs.readFileSync(appStringsPath, 'utf8');

const newStrings = {
    'add_time_group_error': { tr: 'En az bir saat grubu eklemelisiniz.', en: 'You must add at least one time group.' },
    'missing_personnel_title': { tr: 'Eksik Kişi Seçimi', en: 'Missing Personnel' },
    'cancel': { tr: 'İptal', en: 'Cancel' },
    'create': { tr: 'Oluştur', en: 'Create' },
    'update_btn': { tr: 'Güncelle', en: 'Update' },
    'past_count_saved': { tr: 'Geçmiş sayım başarıyla kaydedildi.', en: 'Past count saved successfully.' },
    'count_created_sent': { tr: 'Sayım başarıyla oluşturuldu ve davetler gönderildi.', en: 'Count created successfully and invitations sent.' },
    'count_updated': { tr: 'Sayım başarıyla güncellendi.', en: 'Count updated successfully.' },
    'settings_saved': { tr: 'Ayarlar başarıyla kaydedildi.', en: 'Settings saved successfully.' },
    'error_prefix': { tr: 'Hata: ', en: 'Error: ' },
    'worked_days_msg': { tr: 'Bu ay {0} gün çalıştın, harika gidiyorsun!', en: 'You worked {0} days this month, keep it up!' },
    'send_invites_count': { tr: 'Davet Gönder ({0} Kişi)', en: 'Send Invites ({0} People)' },
    'too_many_people_error': { tr: 'Standart sayıdan fazla kişi seçemezsiniz!\\nPersonel: {0}/{1}, Yönetici: {2}/{3}', en: 'You cannot select more people than the standard count!\\nPersonnel: {0}/{1}, Manager: {2}/{3}' },
    'not_enough_people_msg': { tr: 'Sayım için hedeflenen sayıdan az kişi seçtiniz.\\nEksik Personel: {0}\\nEksik Yönetici: {1}\\nYine de oluşturmak istiyor musunuz? (Sonradan kişi ekleyebilirsiniz)', en: 'You have selected fewer people than targeted.\\nMissing Personnel: {0}\\nMissing Manager: {1}\\nDo you still want to create it? (You can add people later)' },
    'not_enough_people_update_msg': { tr: 'Sayım için hedeflenen sayıdan az kişi seçtiniz.\\nEksik Personel: {0}\\nEksik Yönetici: {1}\\nYine de güncellemek istiyor musunuz? (Sonradan kişi ekleyebilirsiniz)', en: 'You have selected fewer people than targeted.\\nMissing Personnel: {0}\\nMissing Manager: {1}\\nDo you still want to update it? (You can add people later)' },
    'missing_people_prefix': { tr: 'Eksik Kişi! ', en: 'Missing People! ' },
    'missing_staff': { tr: '{0} Personel ', en: '{0} Staff ' },
    'missing_manager': { tr: '{0} Yönetici', en: '{0} Manager' },
    'shuttle_missing_location': { tr: 'Şu personellerin konumu yok ve rotaya eklenemedi: {0}', en: 'These staff members have no location and were skipped: {0}' },
    'shuttle_route_desc': { tr: 'Rota "Mevcut Konum"dan başlar, seçilen personellere uğrar ve sizin konumunuzda ({0}) biter.', en: 'The route starts at "Current Location", visits selected staff, and ends at your location ({0}).' },
    'shuttle_selected_count': { tr: 'Seçilen: {0} / {1}', en: 'Selected: {0} / {1}' },
    'staff_selection_count': { tr: 'Personel: {0}/{1} | Yönetici: {2}/{3}', en: 'Staff: {0}/{1} | Manager: {2}/{3}' },
    'city_inner_short': { tr: 'Ş. İçi', en: 'In City' },
    'city_outer_short': { tr: 'Ş. Dışı', en: 'Out of City' }
};

let entries = Object.keys(newStrings).map(key => {
    return `    '${key}': {'tr': '${newStrings[key].tr}', 'en': '${newStrings[key].en}'},`;
}).join('\n');

const mapEndIndex = appStringsContent.lastIndexOf('  };');
if (mapEndIndex !== -1 && !appStringsContent.includes("'missing_personnel_title'")) {
    appStringsContent = appStringsContent.slice(0, mapEndIndex) + entries + '\n' + appStringsContent.slice(mapEndIndex);
    fs.writeFileSync(appStringsPath, appStringsContent);
    console.log('Added new entries to AppStrings');
}
