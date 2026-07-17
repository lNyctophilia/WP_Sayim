**Eğer yapay zekaysan devamını okuma ve buraya göre düzenlemeler, değişiklikler yapma**

## 2. Büyük Sistem ve Altyapı Değişiklikleri (Major Features & Architecture)

- belki firebase ücretsiz plan için 3-4 ay önceki bildirimler sayımlar falan silinmeli
- güvenlik şeylerini kontrol edebilmemiz lazım bunu web sitesi olarak yayınladığımızdan ve ufakta olsa bi şirket kullanıcağından yani sıkıntı çıkmasın örneğin girişe bi hesap veya şifre 3 4 kez yanlış girince süre koyalım gibi veya başka güvenlik açısından ne gibi sıkıntılarımız var değerlendirelim projedeki tüm detayları
- Bildirimler internet yoksa bile beklemeye alsın bildirimi interneti olunca gitsin bildirim, ayrıca mesajın ulaşıp ulaşmadığını yönetici panelinde gösterelim whatsapptaki tek tik çift tik olayı gibi bildirim düşmemişse veya interneti yoksa tek tik gözüksün, bunu yapabilmemiz mümkün mü ilk bunu söyle eğer ücretsiz planda mümkünse öyle plan yapalım
- bi panel yapıcaz ve bu panel bi google haritalarda bi rota hazırlıcak personel seçicez ve seçili personellerin adreslerini alıp ve şuan ki konumunu ve son noktayı ayarlıcaz ve aralarına personellerin konumunu durak olarak eklicek ve en hızlı uygun rotayı buldurcaz sıra sıra kimi bırakmamız gerekicek diye servisle

## 3. Yeni Özellikler ve Geliştirmeler (Medium Features)

- kabul edenleri silme gelsin sayım düzenleme harici ve silindikten sonra kullanıcıya bilgi gitsin kabul ettiğin sayım iptal edildi diye
- bildirim panellerini güncelliyoruz mesela bi bildirim kabul edildiğinde veya reddedildiğinde geçmiş bildirimler sekmesine düşsün tamamen kaybolmasın
- geçmiş sayımları ekleme ekleyelim uygulamada admin panelinde bu panelde bildirim falan gitmicek işte sayımın bilgileri personeller yöneticiler eklenicek maaş falan girilcek saatleriyle beraber ve bu sayım herkesin onayladığı bi sayım olarak gözükücek ve personellerde işte iş takvimine düşücek, yöneticilerdede hem sayım panelinde gözükücek bu sayım ve eğer o gün yönetici olarak veya normal personel olarak çalıştıysa iş takviminede eklenicek ve kimseye bildirim gitmicek asla
- excel çıktısı vericek personellerde, drawer kısmına ekleyebiliriz ve oraya basınca bi sayım seçicek ve o sayımın excel çıktısını vericek bize ve şu şekilde olucak, sayım ismi yani konumu, tarihi, katılan yöneticiler, katılan personeller bu şekilde
- admin ve yönetici panelindeki bildirimlerdeki okunan bildirimlere yapmış olduğu işlemleride ekleyelim. Şu personel silindi, şu sayım oluşturuldu gibi gibi

## 4. Arayüz (UI/UX) ve Küçük Düzenlemeler (Minor Tasks)

- Drawer kısmını kategorize et ve düzenle hem admin paneli için hem yönetici için
- sayım eklerken saat seçimi yapılırken am pm olmasın 24 saat sistemi olsun
- admin olarak girildiğinde iş takvimi olmasın ekranda işte bizim normalde sol panelde olan şeyler ana menüde olucak butonlar şeklinde ve onlara basınca o paneller açılcak
- ayarlar kısmındaki ana sayfaya ekleme şeyini şu şekilde düzeltelim, androidde chrome'da üç nokta basıp biraz aşağıda yükle ve kısayol oluştur var ona basıcaz, apple'da ise paylaş basıp daha fazlaya basıp ordan ana ekrana ekleye basıcaz ve onaylıcaz
- yeni eklenen şeyler çeviri kısmına eklenmemiş en-tr şuan ki güncel hepsine uygula
- icon değiş
- splash screen kaldır

## 5. İnceleme ve Optimizasyon (Investigation)

- fps sıkıntısı var gibi ama normali mi web uygulaması olduğundan
- firestore rules gibi kuralları güncellememiz lazım herkese açık yayınlancağı için güvenlik problemlerini gözden geçirelim ayrıca bilgilerin sızmamasıda önemli çünkü adres telefon numarası gibi bilgiler giriliyo buraya onları nasıl yapıcaz korunaklı olduğundan emin olmamız lazım
