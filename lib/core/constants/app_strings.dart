import 'package:daytrack/core/constants/app_strings.dart';
/// Tüm UI string'leri — Türkçe ve İngilizce
class AppStrings {
  AppStrings._();

  static const Map<String, Map<String, String>> _strings = {
    'app_name': {'tr': 'WP Sayım', 'en': 'WP Sayım'},

    // Takvim
    'total_days': {'tr': 'Toplam Gün', 'en': 'Total Days'},
    'total_earnings': {'tr': 'Toplam Kazanç', 'en': 'Total Earnings'},

    // Gün isimleri (kısa)
    'mon': {'tr': 'Pzt', 'en': 'Mon'},
    'tue': {'tr': 'Sal', 'en': 'Tue'},
    'wed': {'tr': 'Çar', 'en': 'Wed'},
    'thu': {'tr': 'Per', 'en': 'Thu'},
    'fri': {'tr': 'Cum', 'en': 'Fri'},
    'sat': {'tr': 'Cmt', 'en': 'Sat'},
    'sun': {'tr': 'Paz', 'en': 'Sun'},

    // Ay isimleri
    'january': {'tr': 'Ocak', 'en': 'January'},
    'february': {'tr': 'Şubat', 'en': 'February'},
    'march': {'tr': 'Mart', 'en': 'March'},
    'april': {'tr': 'Nisan', 'en': 'April'},
    'may': {'tr': 'Mayıs', 'en': 'May'},
    'june': {'tr': 'Haziran', 'en': 'June'},
    'july': {'tr': 'Temmuz', 'en': 'July'},
    'august': {'tr': 'Ağustos', 'en': 'August'},
    'september': {'tr': 'Eylül', 'en': 'September'},
    'october': {'tr': 'Ekim', 'en': 'October'},
    'november': {'tr': 'Kasım', 'en': 'November'},
    'december': {'tr': 'Aralık', 'en': 'December'},

    // Form
    'city_inner': {'tr': 'Şehir İçi', 'en': 'In City'},
    'city_outer': {'tr': 'Şehir Dışı', 'en': 'Out of City'},
    'payment': {'tr': 'Ücret', 'en': 'Payment'},
    'note': {'tr': 'Not', 'en': 'Note'},
    'note_hint': {
      'tr': 'Gittiğiniz şehir, detaylar...',
      'en': 'City visited, details...'
    },
    'save': {'tr': 'Kaydet', 'en': 'Save'},
    'delete': {'tr': 'Sil', 'en': 'Delete'},
    'delete_confirm': {
      'tr': 'Bu kaydı silmek istediğinize emin misiniz?',
      'en': 'Are you sure you want to delete this entry?'
    },
    'cancel': {'tr': 'İptal', 'en': 'Cancel'},
    'currency_symbol': {'tr': '₺', 'en': '₺'},

    // Ayarlar
    'settings': {'tr': 'Ayarlar', 'en': 'Settings'},
    'default_payments': {'tr': 'Varsayılan Ücretler', 'en': 'Default Payments'},
    'city_inner_payment': {
      'tr': 'Şehir İçi Ücreti',
      'en': 'In City Payment'
    },
    'city_outer_payment': {
      'tr': 'Şehir Dışı Ücreti',
      'en': 'Out of City Payment'
    },
    'language': {'tr': 'Dil', 'en': 'Language'},
    'turkish': {'tr': 'Türkçe', 'en': 'Türkçe'},
    'english': {'tr': 'English', 'en': 'English'},
    'delete_all_data': {
      'tr': 'Tüm Verileri Sil',
      'en': 'Delete All Data'
    },
    'delete_all_confirm': {
      'tr': 'Tüm iş günü verileriniz silinecek. Bu işlem geri alınamaz!',
      'en': 'All work day data will be deleted. This cannot be undone!'
    },
    'data_deleted': {
      'tr': 'Tüm veriler silindi',
      'en': 'All data deleted'
    },
    'version': {'tr': 'Versiyon', 'en': 'Version'},
    'developer': {'tr': 'Geliştirici', 'en': 'Developer'},
    'all_rights_reserved': {
      'tr': 'Tüm hakları saklıdır',
      'en': 'All rights reserved'
    },
    'about': {'tr': 'Hakkında', 'en': 'About'},
    'general': {'tr': 'Genel', 'en': 'General'},
    'data': {'tr': 'Veri', 'en': 'Data'},
    'saved': {'tr': 'Kaydedildi', 'en': 'Saved'},
    'no_note': {'tr': 'Not yok', 'en': 'No note'},
    'no_entry': {'tr': 'Kayıt yok', 'en': 'No entry'},
    'install_guide': {'tr': 'Ana Ekrana Ekle', 'en': 'Add to Home Screen'},
    'install_guide_title': {
      'tr': 'Uygulamayı Ana Ekrana Ekle',
      'en': 'Add App to Home Screen'
    },
    'install_guide_subtitle': {
      'tr': 'Cihazınıza göre aşağıdaki adımları takip edin:',
      'en': 'Follow the steps below for your device:'
    },
    'install_android_title': {'tr': 'Android (Chrome)', 'en': 'Android (Chrome)'},
    'install_android_step1': {
      'tr': '1. Chrome\'da sağ üstteki üç nokta menüsüne (⋮) dokunun',
      'en': '1. Tap the three-dot menu (⋮) in Chrome\'s top right'
    },
    'install_android_step2': {
      'tr': '2. Biraz aşağı kaydırıp "Yükle ve kısayol oluştur" seçeneğine basın',
      'en': '2. Scroll down a bit and tap on "Install and create shortcut"'
    },
    'install_android_step3': {
      'tr': '3. Açılan pencerede onaylayarak işlemi tamamlayın',
      'en': '3. Confirm in the opened window to complete the process'
    },
    'install_android_step4': {
      'tr': '✅ Artık ana ekranınızda uygulama ikonu görünecek!',
      'en': '✅ The app icon will now appear on your home screen!'
    },
    'install_ios_title': {'tr': 'iPhone / iPad (Safari)', 'en': 'iPhone / iPad (Safari)'},
    'install_ios_step1': {
      'tr': '1. Safari\'nin alt menüsündeki Paylaş (⬆) ikonuna dokunun',
      'en': '1. Tap the Share (⬆) icon in Safari\'s bottom menu'
    },
    'install_ios_step2': {
      'tr': '2. Biraz aşağı kaydırıp gri listeden "Ana Ekrana Ekle"ye dokunun. (Eğer görünmüyorsa "Daha Fazla" seçeneği içinden bulabilirsiniz)',
      'en': '2. Scroll down a bit and tap "Add to Home Screen" from the gray list. (If not visible, tap "More" to find it)'
    },
    'install_ios_step3': {
      'tr': '3. Açılan pencerede onaylayarak işlemi tamamlayın',
      'en': '3. Confirm in the opened window to complete the process'
    },
    'install_ios_step4': {
      'tr': '✅ Artık ana ekranınızda uygulama ikonu görünecek!',
      'en': '✅ The app icon will now appear on your home screen!'
    },
    'install_ios_warning': {
      'tr': '⚠️ Bildirim almak için iOS 16.4 veya üzeri gereklidir.',
      'en': '⚠️ iOS 16.4 or later is required for notifications.'
    },

    // Login
    'login_subtitle': {
      'tr': 'Hesabınıza giriş yapın',
      'en': 'Sign in to your account'
    },
    'login_username_hint': {'tr': 'Telefon Numarası', 'en': 'Phone Number'},
    'login_password_hint': {'tr': 'Şifre', 'en': 'Password'},
    'login_button': {'tr': 'Giriş Yap', 'en': 'Sign In'},
    'login_username_required': {
      'tr': 'Kullanıcı adı gerekli',
      'en': 'Username is required'
    },
    'login_password_required': {
      'tr': 'Şifre gerekli',
      'en': 'Password is required'
    },
    'login_invalid_credentials': {
      'tr': 'Kullanıcı adı veya şifre hatalı',
      'en': 'Invalid username or password'
    },
    'login_account_disabled': {
      'tr': 'Bu hesap devre dışı bırakılmış',
      'en': 'This account has been disabled'
    },
    'login_too_many_attempts': {
      'tr': 'Çok fazla deneme. Lütfen biraz bekleyin.',
      'en': 'Too many attempts. Please wait a moment.'
    },
    'login_error': {
      'tr': 'Giriş yapılırken bir hata oluştu',
      'en': 'An error occurred during login'
    },
    'login_failed': {
      'tr': 'Giriş başarısız. Lütfen tekrar deneyin.',
      'en': 'Login failed. Please try again.'
    },
    'account': {'tr': 'Hesap', 'en': 'Account'},
    'logout': {'tr': 'Çıkış Yap', 'en': 'Sign Out'},
    'logout_confirm': {
      'tr': 'Çıkış yapmak istediğinize emin misiniz?',
      'en': 'Are you sure you want to sign out?'
    },

    // Manager Drawer & Tools
    'staff_panel': {'tr': 'Personel Paneli', 'en': 'Staff Panel'},
    'calendar_dashboard': {'tr': 'Takvim / İş Takip', 'en': 'Calendar / Dashboard'},
    'staff_home': {'tr': 'Personel Ana Ekranı', 'en': 'Staff Home Screen'},
    'manager_tools': {'tr': 'Yönetici Araçları', 'en': 'Manager Tools'},
    'manager_panel': {'tr': 'Yönetici Paneli', 'en': 'Manager Panel'},
    'manager_panel_desc': {'tr': 'Sayımlar ve Personeller', 'en': 'Counts and Staff'},
    'shuttle_planning': {'tr': 'Servis / Rota Planlama', 'en': 'Shuttle / Route Planning'},
    'shuttle_route_desc': {'tr': 'Personel Servis Rotası', 'en': 'Staff Shuttle Route'},
    'export_excel': {'tr': 'Excel Çıktısı Al', 'en': 'Export Excel'},
    'export_reports': {'tr': 'Sayım Raporları', 'en': 'Count Reports'},
    'system_tools': {'tr': 'Sistem Araçları', 'en': 'System Tools'},
    'edit_profiles': {'tr': 'Profilleri Düzenle', 'en': 'Edit Profiles'},
    'add_past_count': {'tr': 'Geçmiş Sayım Ekle', 'en': 'Add Past Count'},
    'global_wage_settings': {'tr': 'Genel Ücret Ayarları', 'en': 'Global Wage Settings'},

    // User Management
    'register': {'tr': 'Kayıt Ol', 'en': 'Register'},
    'register_subtitle': {'tr': 'Yeni bir hesap oluşturun', 'en': 'Create a new account'},
    'full_name': {'tr': 'Ad Soyad', 'en': 'Full Name'},
    'full_name_required': {'tr': 'Ad Soyad gerekli', 'en': 'Full name is required'},
    'phone_number': {'tr': 'Telefon Numarası', 'en': 'Phone Number'},
    'phone_number_hint': {'tr': 'Örn: 05551234567', 'en': 'e.g. 05551234567'},
    'phone_number_required': {'tr': 'Telefon numarası gerekli', 'en': 'Phone number is required'},
    'phone_note': {'tr': 'İletişim kurabilmek için gereklidir.', 'en': 'Required for contact purposes.'},
    'address': {'tr': 'Adres', 'en': 'Address'},
    'address_hint': {'tr': 'Örn: Denizli, Merkezefendi, Gümüşçay Mahallesi', 'en': 'e.g. Denizli, Merkezefendi, Gumuscay Neighborhood'},
    'address_required': {'tr': 'Adres gerekli', 'en': 'Address is required'},
    'address_note': {'tr': 'Servis güzergahı planlaması için gereklidir.', 'en': 'Required for service route planning.'},
    'no_account': {'tr': 'Hesabınız yok mu?', 'en': 'Don\'t have an account?'},
    'register_success': {'tr': 'Başvurunuz alındı. Yönetici onayından sonra giriş yapabilirsiniz.', 'en': 'Application received. You can login after manager approval.'},
    'pending_approval': {'tr': 'Hesabınız henüz onaylanmamış. Lütfen yöneticinin onaylamasını bekleyin.', 'en': 'Your account is not approved yet. Please wait for manager approval.'},
    'approve': {'tr': 'Onayla', 'en': 'Approve'},
    'reject': {'tr': 'Reddet', 'en': 'Reject'},
    'pending_approvals': {'tr': 'Onay Bekleyenler', 'en': 'Pending Approvals'},
    'existing_staff': {'tr': 'Mevcut Personel', 'en': 'Existing Staff'},
    'no_pending_approvals': {'tr': 'Onay bekleyen başvuru yok', 'en': 'No pending applications'},

    'username_taken': {
      'tr': 'Bu kullanıcı adı zaten alınmış',
      'en': 'This username is already taken'
    },
    'password_too_weak': {
      'tr': 'Şifre çok zayıf',
      'en': 'Password is too weak'
    },
    'user_created_success': {
      'tr': 'Kullanıcı başarıyla oluşturuldu',
      'en': 'User created successfully'
    },
    'user_create_error': {
      'tr': 'Kullanıcı oluşturulurken bir hata oluştu',
      'en': 'An error occurred while creating user'
    },
    
    // Global Settings
    'global_settings': {'tr': 'Genel Ayarlar', 'en': 'Global Settings'},
    'default_wages': {'tr': 'Varsayılan Ücretler', 'en': 'Default Wages'},
    'staff_in_city': {'tr': 'Personel (Şehir İçi)', 'en': 'Staff (In-City)'},
    'staff_out_city': {'tr': 'Personel (Şehir Dışı)', 'en': 'Staff (Out-of-City)'},
    'manager_in_city': {'tr': 'Yönetici (Şehir İçi)', 'en': 'Manager (In-City)'},
    'manager_out_city': {'tr': 'Yönetici (Şehir Dışı)', 'en': 'Manager (Out-of-City)'},

    // User Edit Dialog
    'username': {'tr': 'Kullanıcı Adı', 'en': 'Username'},
    'username_hint': {'tr': 'Örn: ahmet.yilmaz', 'en': 'e.g. john.doe'},
    'password': {'tr': 'Şifre', 'en': 'Password'},
    'password_leave_empty': {'tr': 'Değiştirmek istemiyorsanız boş bırakın', 'en': 'Leave empty to keep unchanged'},
    'update': {'tr': 'Güncelle', 'en': 'Update'},

    // Group Selector
    'time_groups_max': {'tr': 'Saat Grupları (Max 10)', 'en': 'Time Groups (Max 10)'},
    'add_group': {'tr': 'Grup Ekle', 'en': 'Add Group'},
    'group': {'tr': 'Grup', 'en': 'Group'},

    // Sayim List
    'error_occurred': {'tr': 'Bir hata oluştu:\n', 'en': 'An error occurred:\n'},
    'no_counts_found': {'tr': 'Henüz sayım bulunmuyor.', 'en': 'No counts found yet.'},
    'unnamed_count': {'tr': 'İsimsiz Sayım', 'en': 'Unnamed Count'},
    'status_open': {'tr': 'Açık', 'en': 'Open'},
    'status_closed': {'tr': 'Kapalı', 'en': 'Closed'},

    // Staff Picker
    'staff_selection': {'tr': 'Personel Seçimi', 'en': 'Staff Selection'},
    'select_all': {'tr': 'Hepsini Seç', 'en': 'Select All'},
    'me_suffix': {'tr': ' (Ben)', 'en': ' (Me)'},
    'role_staff': {'tr': 'Personel', 'en': 'Staff'},
    'role_manager': {'tr': 'Yönetici', 'en': 'Manager'},
    'select_group': {'tr': 'Grup Seç', 'en': 'Select Group'},
    'multiplier': {'tr': 'Çarpan', 'en': 'Multiplier'},
    'wage': {'tr': 'Ücret', 'en': 'Wage'},

    // User List Tab
    'reject_delete_confirm': {'tr': 'Bu başvuruyu reddetmek ve silmek istediğinize emin misiniz?', 'en': 'Are you sure you want to reject and delete this application?'},
    'delete_user_confirm': {'tr': 'Bu kullanıcıyı silmek istediğinize emin misiniz?', 'en': 'Are you sure you want to delete this user?'},
    'managers': {'tr': 'Yöneticiler', 'en': 'Managers'},
    'no_managers_yet': {'tr': 'Henüz yönetici yok', 'en': 'No managers yet'},
    'no_staff_yet': {'tr': 'Henüz personel yok', 'en': 'No staff yet'},
    'role_owner': {'tr': 'Sahip', 'en': 'Owner'},
    'inactive': {'tr': 'Pasif', 'en': 'Inactive'},

    // Extra user edit strings
    'user_details_updated': {'tr': 'Kullanıcı bilgileri güncellendi.', 'en': 'User details updated.'},
    'update_error': {'tr': 'Güncelleme sırasında bir hata oluştu.', 'en': 'An error occurred during update.'},
    'edit_manager': {'tr': 'Yöneticiyi Düzenle', 'en': 'Edit Manager'},
    'edit_staff': {'tr': 'Personeli Düzenle', 'en': 'Edit Staff'},
    'full_name_hint': {'tr': 'Örn: Ahmet Yılmaz', 'en': 'e.g. John Doe'},
    'min_3_chars': {'tr': 'En az 3 karakter', 'en': 'Min 3 characters'},
    'min_6_chars': {'tr': 'En az 6 karakter', 'en': 'Min 6 characters'},
    'username_required': {'tr': 'Kullanıcı adı gerekli', 'en': 'Username is required'},
    'notifications': {'tr': 'Bildirimler', 'en': 'Notifications'},
    'sayim_reminder': {'tr': 'Sayım Hatırlatıcı', 'en': 'Count Reminder'},
    // Newly extracted
    'hello': {'tr': 'Merhaba,', 'en': 'Hello,'},
    'welcome_user': {'tr': 'Hoşgeldin {0}', 'en': 'Welcome {0}'},
    'no_entries_for_this_month_yet_let': {'tr': 'Bu ay için henüz kayıt girmedin. Hadi başlayalım!', 'en': 'No entries for this month yet. Let\'s start!'},
    'monthly_work_intensity': {'tr': 'Aylık İş Yoğunluğu', 'en': 'Monthly Work Intensity'},
    'recent_notes': {'tr': 'Son Rotalar', 'en': 'Recent Routes'},
    'error_loading_data': {'tr': 'Veriler yüklenirken hata oluştu', 'en': 'Error loading data'},
    'invites_sent': {'tr': 'Davetler gönderildi!', 'en': 'Invites sent!'},
    'an_error_occurred': {'tr': 'Hata oluştu', 'en': 'An error occurred'},
    'add_person': {'tr': 'Kişi Ekle', 'en': 'Add Person'},
    'basic_info': {'tr': 'Temel Bilgiler', 'en': 'Basic Info'},
    'note_job_location': {'tr': 'Not / İş / Yer', 'en': 'Note / Job / Location'},
    'cannot_be_empty': {'tr': 'Boş bırakılamaz', 'en': 'Cannot be empty'},
    'standard_personnel': {'tr': 'Standart Personel', 'en': 'Standard Personnel'},
    'standard_manager': {'tr': 'Standart Yönetici', 'en': 'Standard Manager'},
    'city_type': {'tr': 'Şehir İçi/Dışı', 'en': 'City Type'},
    'in_city': {'tr': 'Şehir İçi', 'en': 'In-City'},
    'out_of_city': {'tr': 'Şehir Dışı', 'en': 'Out-of-City'},
    'global_multiplier': {'tr': 'Yevmiye Çarpanı', 'en': 'Global Multiplier'},
    'save_count': {'tr': 'Sayımı Kaydet', 'en': 'Save Count'},
    'create_new_count': {'tr': 'Yeni Sayım Oluştur', 'en': 'Create New Count'},
    'send_invitations': {'tr': 'Davet Gönder', 'en': 'Send Invitations'},
    'an_error_occurred_during_update': {'tr': 'Güncelleme sırasında bir hata oluştu.', 'en': 'An error occurred during update.'},
    'select_user': {'tr': 'Kullanıcı Seçin', 'en': 'Select User'},
    'select_a_person': {'tr': 'Bir kişi seçin', 'en': 'Select a person'},
    'e_g_john_doe': {'tr': 'Örn: Ahmet Yılmaz', 'en': 'e.g. John Doe'},
    'required': {'tr': 'Gerekli', 'en': 'Required'},
    'e_g_05551234567': {'tr': 'Örn: 05551234567', 'en': 'e.g. 05551234567'},
    'for_service_route': {'tr': 'Servis güzergahı için', 'en': 'For service route'},
    'set_new_password': {'tr': 'Yeni şifre belirleyin', 'en': 'Set new password'},
    'role': {'tr': 'Rol', 'en': 'Role'},
    'staff': {'tr': 'Personel', 'en': 'Staff'},
    'manager': {'tr': 'Yönetici', 'en': 'Manager'},
    'owner': {'tr': 'Sahip (Owner)', 'en': 'Owner'},
    'edit_count': {'tr': 'Sayımı Düzenle', 'en': 'Edit Count'},
    'please_select_a_count_to_export_to_excel': {'tr': 'Lütfen Excel çıktısı almak istediğiniz sayımı seçin.', 'en': 'Please select a count to export to Excel.'},
    'select_count': {'tr': 'Sayım Seçin', 'en': 'Select Count'},
    'count_summary': {'tr': 'Sayım Özeti', 'en': 'Count Summary'},
    'invited': {'tr': 'Kişi Davet Edildi', 'en': 'Invited'},
    'download_excel': {'tr': 'Excel İndir', 'en': 'Download Excel'},
    'counts': {'tr': 'Sayımlar', 'en': 'Counts'},
    'delete_count': {'tr': 'Sayımı Sil', 'en': 'Delete Count'},
    'are_you_sure_you_want_to_delete_this_count_and_all_related_invitations_calendar_records_this_action_cannot_be_undone': {'tr': 'Bu sayımı ve bağlantılı tüm davet/takvim kayıtlarını silmek istediğinize emin misiniz? Bu işlem geri alınamaz.', 'en': 'Are you sure you want to delete this count and all related invitations/calendar records? This action cannot be undone.'},
    'count_deleted_successfully': {'tr': 'Sayım başarıyla silindi.', 'en': 'Count deleted successfully.'},
    'count_not_found_or_deleted': {'tr': 'Sayım bulunamadı veya silinmiş.', 'en': 'Count not found or deleted.'},
    'count_details': {'tr': 'Sayım Detayı', 'en': 'Count Details'},
    'edit': {'tr': 'Düzenle', 'en': 'Edit'},
    'accepted': {'tr': 'Kabul', 'en': 'Accepted'},
    'pending': {'tr': 'Bekliyor', 'en': 'Pending'},
    'declined': {'tr': 'Red', 'en': 'Declined'},
    'no_one_found': {'tr': 'Kimse bulunamadı', 'en': 'No one found'},
    'loading': {'tr': 'Yükleniyor...', 'en': 'Loading...'},
    'deleted': {'tr': 'Silindi', 'en': 'Deleted'},
    'remind': {'tr': 'Hatırlat', 'en': 'Remind'},
    'please_wait_5_minutes_before_sending_another_reminder': {'tr': 'Lütfen yeni bir hatırlatma göndermeden önce 5 dakika bekleyin.', 'en': 'Please wait 5 minutes before sending another reminder.'},
    'reminder_sent': {'tr': 'Hatırlatma gönderildi.', 'en': 'Reminder sent.'},
    'remove': {'tr': 'Kaldır', 'en': 'Remove'},
    'remove_person': {'tr': 'Kişiyi Çıkar', 'en': 'Remove Person'},
    'are_you_sure_you_want_to_remove_username_from_this_count_a_cancellation_notification_will_be_sent_to_the_user': {'tr': '{0} isimli personeli bu sayımdan çıkarmak istediğinize emin misiniz? (Kullanıcıya iptal bildirimi gönderilecektir)', 'en': 'Are you sure you want to remove {0} from this count? (A cancellation notification will be sent to the user)'},
    'person_successfully_removed_and_notification_sent': {'tr': 'Kişi başarıyla çıkarıldı ve bildirim gönderildi.', 'en': 'Person successfully removed and notification sent.'},
    're_invite': {'tr': 'Tekrar Davet Et', 'en': 'Re-invite'},
    'reinvited': {'tr': 'Yeniden davet gönderildi', 'en': 'Reinvited'},
    'you_can_select_up_to_maxselection_people': {'tr': 'En fazla {0} kişi seçebilirsiniz!', 'en': 'You can select up to {0} people!'},
    'please_add_an_address_or_location_to_your_profile_the_destination_will_be_your_location': {'tr': 'Lütfen kendi profilinize bir adres veya konum ekleyin. Bitiş noktası sizin konumunuz olacaktır.', 'en': 'Please add an address or location to your profile. The destination will be your location.'},
    'please_select_at_least_one_staff': {'tr': 'Lütfen en az bir personel seçin.', 'en': 'Please select at least one staff.'},
    'no_selected_staff_with_valid_location': {'tr': 'Geçerli konuma sahip seçili personel yok.', 'en': 'No selected staff with valid location.'},
    'could_not_open_map_e': {'tr': 'Harita açılamadı: {0}', 'en': 'Could not open map: {0}'},
    'shuttle_route_planning': {'tr': 'Servis / Rota Planlama', 'en': 'Shuttle / Route Planning'},
    'location_saved': {'tr': 'Konum kayıtlı', 'en': 'Location saved'},
    'no_location_address': {'tr': 'Konum/Adres bilgisi yok!', 'en': 'No location/address!'},
    'open_route_on_map': {'tr': 'Rotayı Haritada Aç', 'en': 'Open Route on Map'},
    'no_personnel_available': {'tr': 'Seçilebilecek personel bulunmuyor.', 'en': 'No personnel available.'},
    'add_time_group_error': {'tr': 'En az bir saat grubu eklemelisiniz.', 'en': 'You must add at least one time group.'},
    'missing_personnel_title': {'tr': 'Eksik Kişi Seçimi', 'en': 'Missing Personnel'},

    'create': {'tr': 'Oluştur', 'en': 'Create'},
    'update_btn': {'tr': 'Güncelle', 'en': 'Update'},
    'past_count_saved': {'tr': 'Geçmiş sayım başarıyla kaydedildi.', 'en': 'Past count saved successfully.'},
    'count_created_sent': {'tr': 'Sayım başarıyla oluşturuldu ve davetler gönderildi.', 'en': 'Count created successfully and invitations sent.'},
    'count_updated': {'tr': 'Sayım başarıyla güncellendi.', 'en': 'Count updated successfully.'},
    'settings_saved': {'tr': 'Ayarlar başarıyla kaydedildi.', 'en': 'Settings saved successfully.'},
    'error_prefix': {'tr': 'Hata: ', 'en': 'Error: '},
    'worked_days_msg': {'tr': 'Bu ay {0} gün çalıştın, harika gidiyorsun!', 'en': 'You worked {0} days this month, keep it up!'},
    'send_invites_count': {'tr': 'Davet Gönder ({0} Kişi)', 'en': 'Send Invites ({0} People)'},
    'too_many_people_error': {'tr': 'Standart sayıdan fazla kişi seçemezsiniz!\nPersonel: {0}/{1}, Yönetici: {2}/{3}', 'en': 'You cannot select more people than the standard count!\nPersonnel: {0}/{1}, Manager: {2}/{3}'},
    'not_enough_people_msg': {'tr': 'Sayım için hedeflenen sayıdan az kişi seçtiniz.\nEksik Personel: {0}\nEksik Yönetici: {1}\nYine de oluşturmak istiyor musunuz? (Sonradan kişi ekleyebilirsiniz)', 'en': 'You have selected fewer people than targeted.\nMissing Personnel: {0}\nMissing Manager: {1}\nDo you still want to create it? (You can add people later)'},
    'not_enough_people_update_msg': {'tr': 'Sayım için hedeflenen sayıdan az kişi seçtiniz.\nEksik Personel: {0}\nEksik Yönetici: {1}\nYine de güncellemek istiyor musunuz? (Sonradan kişi ekleyebilirsiniz)', 'en': 'You have selected fewer people than targeted.\nMissing Personnel: {0}\nMissing Manager: {1}\nDo you still want to update it? (You can add people later)'},
    'missing_people_prefix': {'tr': 'Eksik Kişi! ', 'en': 'Missing People! '},
    'missing_staff': {'tr': '{0} Personel ', 'en': '{0} Staff '},
    'missing_manager': {'tr': '{0} Yönetici', 'en': '{0} Manager'},
    'shuttle_missing_location': {'tr': 'Şu personellerin konumu yok ve rotaya eklenemedi: {0}', 'en': 'These staff members have no location and were skipped: {0}'},

    'shuttle_selected_count': {'tr': 'Seçilen: {0} / {1}', 'en': 'Selected: {0} / {1}'},
    'staff_selection_count': {'tr': 'Personel: {0}/{1} | Yönetici: {2}/{3}', 'en': 'Staff: {0}/{1} | Manager: {2}/{3}'},
    'city_inner_short': {'tr': 'Ş. İçi', 'en': 'In City'},
    'city_outer_short': {'tr': 'Ş. Dışı', 'en': 'Out of City'},
  };

  static const List<String> monthKeys = [
    'january', 'february', 'march', 'april', 'may', 'june',
    'july', 'august', 'september', 'october', 'november', 'december',
  ];

  static const List<String> dayKeys = [
    'mon', 'tue', 'wed', 'thu', 'fri', 'sat', 'sun',
  ];

  static String get(String key, String lang) {
    return _strings[key]?[lang] ?? key;
  }

  static String getFormat(String key, String lang, List<dynamic> args) {
    String str = get(key, lang);
    for (int i = 0; i < args.length; i++) {
      str = str.replaceAll('{$i}', args[i].toString());
    }
    return str;
  }

  static String getMonth(int month, String lang) {
    if (month < 1 || month > 12) return '';
    return get(monthKeys[month - 1], lang);
  }

  static String getDay(int index, String lang) {
    if (index < 0 || index > 6) return '';
    return get(dayKeys[index], lang);
  }
}
