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
      'tr': '2. "Daha Fazla" seçeneğine basıp oradan "Ana Ekrana Ekle"ye dokunun',
      'en': '2. Tap on "More" and from there tap on "Add to Home Screen"'
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
    'address_hint': {'tr': 'Örn: Kadıköy / İstanbul', 'en': 'e.g. Kadikoy / Istanbul'},
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

  static String getMonth(int month, String lang) {
    if (month < 1 || month > 12) return '';
    return get(monthKeys[month - 1], lang);
  }

  static String getDay(int index, String lang) {
    if (index < 0 || index > 6) return '';
    return get(dayKeys[index], lang);
  }
}
