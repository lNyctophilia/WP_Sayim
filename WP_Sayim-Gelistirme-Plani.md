# Day Track — Çok Kullanıcılı Sisteme Geçiş Planı

## 0. Özet Karar Tablosu

| Konu | Karar |
|---|---|
| Mevcut teknoloji | Flutter (Dart) |
| Yeni backend | Firebase (Auth + Firestore + Cloud Messaging + Cloud Functions) |
| Plan | Spark (ücretsiz) başlangıç, bildirimler için Blaze'e geçiş gerekebilir (aşağıda açıklandı) |
| Hesap oluşturma | Yönetici, kullanıcı adı + şifre oluşturup personele iletir |
| Sayım süresi | Tek gün, tek görev |
| Roller | Sahip (Owner) → Yönetici → Personel |

---

## 1. Rol Hiyerarşisi

```
OWNER (sen — süper yönetici)
 ├─ Yönetici hesabı oluşturur/siler
 ├─ Bunun dışında normal bir YÖNETİCİ gibi çalışır (sayım oluşturabilir, sahaya da girebilir)
 │
YÖNETİCİLER (owner dahil, aralarında eşit yetkili)
 ├─ TÜM personeli görebilir (sadece kendi davet ettikleri değil)
 ├─ Sayım oluşturur, personel ve/veya diğer yöneticileri davet eder
 ├─ Bir sayıma başka bir yöneticiyi "yönetici" sıfatıyla veya "personel" sıfatıyla ekleyebilir
 │   (yani bir sayımda 2 yönetici olabilir: sayımı oluşturan + davet ettiği bir başka yönetici)
 ├─ Henüz kabul/red edilmemiş (pending) davetlerde kişi çıkarabilir / yeni kişi ekleyebilir
 ├─ Pending davetlere "hatırlatma" bildirimi tekrar gönderebilir
 │
 └─ PERSONEL
     ├─ Davet alır, kabul/red eder
     ├─ Kendi takvimini görür (şu anki uygulamadaki ekranın birebir aynısı: ücret, iş sayısı,
     │   iş yoğunluğu grafiği, son notlar) — sadece artık veriyi KENDİSİ girmiyor
     └─ Daveti kabul edince o günün verisi (yer, saat, ücret, şehir içi/dışı) otomatik olarak
         takvimine işleniyor
```

**Not:** "Owner" ayrı bir kullanıcı tipi değil, yöneticilerin bir üst kademesi — tek farkı yeni yönetici hesabı açıp kapatabilmesi. Bu yüzden ayrı bir "Owner Panel" yerine, Yönetici Panel içine sadece owner'da görünen bir **"Yönetici Yönetimi"** sekmesi ekleyeceğiz.

**Açık kalan tek varsayım:** Bir sayıma ikinci yönetici olarak eklenen kişi, o sayımı da düzenleyebilsin mi (kişi ekle/çıkar, iptal) yoksa sadece sahada "yönetici sıfatıyla" bulunup düzenleme yetkisi sayımı oluşturanda mı kalsın? Şimdilik **"evet, düzenleyebilir"** varsayımıyla ilerliyorum — istersen değiştiririz.

---

## 2. Veri Modeli (Firestore)

```
users/{userId}
  - username
  - passwordHash (bkz. Bölüm 3 — Firebase Auth üzerinden yönetilecek)
  - fullName
  - roles: ["owner" | "manager" | "staff"]
  - defaultWage (opsiyonel, kişiye özel varsayılan ücret)
  - createdBy (hangi yönetici/owner oluşturdu)
  - active: true/false

sayimlar/{sayimId}
  - note (rich text) → artık sadece yer/iş bilgisi: "Otogar Muğla Watsons" (saat gruplardan geliyor)
  - date
  - maxKisi: 20
  - createdBy (yöneticiId)
  - status: "open" | "closed"
  - gruplar: [                     // max 3 grup, her birinin kendi saati var
      { grupId: 1, saat: "13:00" },
      { grupId: 2, saat: "13:30" },
      { grupId: 3, saat: "14:00" }
    ]
  - invitedUserIds: [...]

davetler/{davetId}
  - sayimId
  - userId
  - status: "pending" | "accepted" | "declined"
  - role: "manager" | "staff"     // bu sayımdaki sıfatı — diğer yöneticiler de "personel" olarak eklenebilir
  - grupId                        // hangi saat grubuna dahil
  - sehirIciDisi: "ici" | "disi"
  - ucret: number
  - respondedAt
  - lastReminderAt                // en son hatırlatma bildirimi ne zaman gönderildi

personel_takvimi/{userId}/gunler/{tarih}
  - sehirIciDisi
  - ucret
  - not
  - sayimId (referans)
```

Mevcut tek-kullanıcı yapındaki `gün → {şehir içi/dışı, ücret, not}` modeli aynen `personel_takvimi` altına taşınıyor; sadece bu veriyi artık kullanıcı kendisi değil, yönetici davet üzerinden dolduruyor.

**Grup sistemi mantığı:** Yönetici sayım oluştururken personeli en fazla 3 gruba ayırabilir (örn. "erken gelenler", "depoya girenler" vb.), her grubun kendi saati olur. Personel daveti kabul ettiğinde takvimine düşen not, sayımın genel notu + kendi grubunun saati birleştirilerek oluşur: `"Otogar Muğla Watsons" + "13:00" → "Otogar Muğla Watsons 13:00"`.

---

## 3. Kimlik Doğrulama — "Kullanıcı Adı + Şifre" Nasıl Yapılır?

Firebase Authentication temelde **e-posta** bazlıdır, kullanıcı adı kabul etmez. İki seçenek var:

**A) Sahte e-posta (pseudo-email) yöntemi — Önerilen, tamamen ücretsiz**
- Yönetici "ahmet.yilmaz" gibi bir kullanıcı adı girer.
- Uygulama arka planda bunu `ahmet.yilmaz@daytrack.local` gibi bir adrese çevirip Firebase Auth'ta email/password hesabı olarak oluşturur.
- Personel girişte sadece kullanıcı adı + şifre görür, e-posta hiç görünmez.
- Şifreyi ilk oluşturmada yönetici belirler, personel istersen sonradan değiştirebilir.

**B) Custom Auth (Cloud Functions ile kendi token sistemin)**
- Daha esnek ama Blaze plan (faturalı) gerektirir ve gereksiz karmaşıklık katar.

→ **A seçeneğini öneriyorum**, tamamen Spark (ücretsiz) planda çalışır.

---

## 4. Yetkilendirme (Firestore Security Rules)

Firestore kuralları rol bazlı olacak, örnek mantık:
- `owner` → her koleksiyonda tam okuma/yazma
- `manager` → sadece kendi oluşturduğu `sayimlar` ve bunlara bağlı `davetler`i yazabilir, `users` içinde sadece `staff` rolündekileri görebilir/oluşturabilir
- `staff` → sadece kendi `davetler` ve kendi `personel_takvimi` verisini okuyabilir, sadece `davet.status` alanını güncelleyebilir

Bu kuralları yazmak ayrı bir teknik adım, geliştirme sırasında birlikte hazırlarız.

---

## 5. Bildirim Sistemi (Kritik Nokta — Maliyet Etkisi Var)

Personel davet aldığında, yönetici kabul/red bildirimini aldığında ve yönetici pending (bekleyen) davetlere **tekrar hatırlatma bildirimi** gönderdiğinde **push notification** göndermek için:
- Firestore'da bir yazı (davet oluşturma) olduğunda otomatik tetiklenen bir **Cloud Function** gerekir → bu fonksiyon FCM (Firebase Cloud Messaging) ile bildirimi gönderir.
- **Sorun:** Cloud Functions'ı deploy edebilmek için Firebase'in **Blaze (kullandıkça öde) planına** geçmen gerekiyor. Ancak:
  - Blaze plana geçmek **kredi kartı ister ama otomatik ücret kesmez** — ücretsiz kotanın (aylık 2M çağrı, vs.) içinde kaldığın sürece **0 TL** ödersin.
  - Sizin ölçeğinizde (birkaç yönetici, birkaç onlarca personel) bu kotayı aşmanız pratikte imkansız.
- **Alternatif (Cloud Function kullanmadan):** Personel uygulamayı açtığında Firestore'u dinleyip (real-time listener) uygulama içi bildirim gösterme — ama bu, **uygulama kapalıyken** telefon bildirimi göndermez. Saha ekibi için bu muhtemelen yetersiz olur.

→ **Önerim:** Blaze plana geçin (kart bilgisi girilir ama kullanım ücretsiz kotada kalacağı için fatura gelmez), Cloud Functions + FCM kullanın. İstersen bunu netleştirmek için Firebase'in güncel fiyatlandırma sayfasını da kontrol edip teyit edebilirim.

---

## 6. Ekran/Modül Listesi

**Yönetici Yönetimi (sadece owner'da görünür sekme)**
- Yönetici oluştur/sil/düzenle

**Yönetici Panel (yeni, tüm yöneticilerde — owner dahil)**
- "Sayım Oluştur": not (rich text, sadece yer/iş bilgisi), tarih, max kişi sayısı
- Grup oluşturma: en fazla 3 grup, her grubun kendi saati
- Personel/yönetici seçici: tüm personeli ve tüm diğer yöneticileri listeler, tekli seçim + "Hepsini Seç"
- Her seçilen kişi için: hangi gruba dahil (saat), rolü (yönetici mi/personel mi bu sayımda), şehir içi/dışı, ücret (çift ücret dahil)
- "Davet Gönder" butonu
- Gönderilen davetlerin durum listesi (kabul/red/bekliyor)
  - Pending kişilere **"Hatırlat"** butonu → tekrar bildirim gönderir
  - Pending kişileri sayımdan çıkarabilir, yeni kişi ekleyebilir
  - Reddedenleri çıkarıp yerine yeni kişi davet edebilme

**Personel Uygulaması (mevcut ekranın devamı)**
- Bildirim → Davet detay ekranı → Kabul/Red
- Kabul edilince o günün verisi (yer + grup saati + ücret + şehir içi/dışı) otomatik takvime düşer
- Geri kalan her şey **aynen kalır**: özet bar, iş yoğunluğu grafiği, son notlar, kendi ücreti ve toplam iş sayısı — sadece bu veriler artık kendisi girmiyor, davet kabulüyle otomatik doluyor. Veri kaynağı local'den Firestore'a taşınır.

---

## 7. Mevcut Koddan Ne Silinir, Ne Kalır, Ne Eklenir?

**Kalacaklar (mantık aynen taşınır):**
- Takvim UI (aylık görünüm, Pazartesi başlangıç, gün hücreleri)
- Gün formu tasarımı (şehir içi/dışı, ücret, not) — sadece artık "kimin dolduracağı" değişiyor
- İş yoğunluğu grafiği, alt özet bar, son notlar bölümü
- Ayarlar ekranı (dil seçimi vs. aynen kalır)

**Silinecek/Değişecek:**
- Local storage (SharedPreferences/SQLite her ne kullanıyorsan) → Firestore'a taşınacak
- Güne tıklayınca açılan form artık **personel tarafından düzenlenemeyecek, sadece görüntülenecek** (mevcut form UI'ı "salt okunur" moda çevrilecek — veri girişi tamamen yöneticiden geliyor)

**Yeni Eklenecek:**
- Login ekranı (kullanıcı adı + şifre)
- Owner Panel
- Yönetici Panel (sayım oluşturma + davet yönetimi)
- Bildirim dinleme ve davet kabul/red ekranı
- Rol bazlı yönlendirme (login sonrası kullanıcı rolüne göre farklı ana ekran)

---

## 8. Adım Adım Geliştirme Sırası

1. **Firebase projesini kur** — Auth, Firestore, Cloud Messaging'i etkinleştir.
2. **Veri modelini Firestore'da oluştur** (Bölüm 2'deki koleksiyonlar).
3. **Login sistemini yaz** (pseudo-email yöntemiyle kullanıcı adı+şifre girişi).
4. **Rol bazlı yönlendirme** — login sonrası owner/manager/staff'a göre farklı ana ekran.
5. **Owner Panel'i yap** — yönetici oluşturma ekranı önce, çünkü diğer her şey buna bağlı.
6. **Yönetici Panel — Sayım Oluşturma** ekranını yap (not, tarih, max kişi, personel seçici).
7. **Davet gönderme mantığı** — Firestore'a yazma + Cloud Function ile FCM bildirimi (Blaze'e geçiş burada gerekiyor).
8. **Personel tarafı — bildirim alma ve kabul/red ekranı.**
9. **Kabul edilince personel_takvimi otomatik güncellensin** — mevcut takvim ekranın bu veriyi okuyacak şekilde bağlanması.
10. **Yönetici tarafında davet durumu takibi** (kabul/red listesi, red edeni çıkarıp yeni davet gönderme).
11. **Firestore Security Rules'ı yaz** — rol bazlı erişim kısıtlamaları.
12. **Test** — en az 1 owner, 2 yönetici, birkaç personel hesabıyla uçtan uca test.
13. **Yayına alma** (Play Store/App Store güncellemesi).

---

## 9. Cevaplanan Kararlar (özet)

- ✅ Yöneticiler tüm personeli görebilir (sadece kendi davet ettikleri değil)
- ✅ Pending davetlere tekrar hatırlatma bildirimi gönderilebilir
- ✅ Yönetici, pending davetlerde kişi çıkarabilir/ekleyebilir
- ✅ Personel kendi ücret/iş sayısı/yoğunluk verisini görmeye devam eder, sadece artık kendisi girmiyor
- ✅ Owner = sen + yöneticiler eşit yetkili katman, owner'ın tek farkı yönetici oluşturup silebilmesi
- ✅ Max 3 saat grubu, gruba göre not sonuna saat ekleniyor
- ✅ Bir yönetici başka bir yöneticiyi sayıma "yönetici" veya "personel" sıfatıyla ekleyebilir

**Tek açık varsayım** (Bölüm 1'in sonunda not edildi): İkinci yönetici olarak eklenen kişi o sayımı düzenleyebilir mi? Şimdilik "evet" varsayıyorum.

Bu haliyle plan tamamlandı sayılır. Bir sonraki adım **Bölüm 8, Adım 1-2**: Firebase projesinin kurulması ve Firestore veri modelinin oluşturulması. Onaylarsan doğrudan koda geçebiliriz — hangi adımdan başlamak istersin?
