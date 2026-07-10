# Day Track

İşe gidilen günleri, yapılan işleri ve kazançları takip etmek için geliştirilmiş bir takvim tabanlı takip uygulaması.

## 1. Genel Bakış

Day Track, kullanıcının hangi günlerde işe gittiğini, o gün şehir içi mi şehir dışı mı çalıştığını, ne kadar kazandığını ve hangi işi yaptığını kayıt altına almasını sağlayan bir mobil/masaüstü uygulamadır. Aylık takvim görünümü üzerinden çalışır ve tüm veriler gün bazlı olarak tutulur.

## 2. Karşılama Ekranı

- Uygulama açıldığında en üstte bir **hoş geldiniz mesajı** gösterilir.
- Bu mesajda kullanıcının o zamana kadar yaptığı **toplam iş/sayım sayısı** belirtilir (örn. "Hoş geldin! Şu ana kadar X iş yaptın.").

## 3. Takvim Ekranı

- Ekranın ana bölümünde, seçili ayın günlerini gösteren bir **takvim (aylık görünüm)** yer alır.
- Günler **Pazartesi** gününden başlayarak sıralanır.
- Takvimde sadece o ayda gerçekten var olan günler gösterilir (ay 28, 30 ya da 31 gün çekiyorsa ona göre listelenir, maksimum 31 gün).
- Her gün bir hücre/kutucuk olarak temsil edilir.

### 3.1 Güne Tıklama (Kayıt Girişi / Düzenleme)
Bir güne **tıklandığında** bir form ekranı açılır:
- **Şehir İçi / Şehir Dışı** seçimi sorulur.
- Seçime göre, ayarlardan belirlenmiş **varsayılan ücret** otomatik olarak forma yansıtılır:
  - Şehir içi varsayılan: **1025**
  - Şehir dışı varsayılan: **1100**
- Kullanıcı isterse bu **otomatik gelen tutarı değiştirip kendi özel tutarını** girebilir (örneğin çalışma saati normalden fazla olduğunda 2200 gibi çift bir ücret girilebilir).
- Formun alt kısmında bir **not alanı** bulunur:
  - Bu alan **rich text (zengin metin)** destekli bir not kutusudur.
  - Kullanıcı buraya o gün gittiği işi/yeri tanımlayan bir not girer (örn. "Muğla Watsons").
- Form **kaydedildiğinde**:
  - O günün bilgisi (şehir içi/dışı, ücret, not) kaydedilir.
  - O ayın **toplam iş günü sayısı** bir artar.
  - O ayın **toplam kazanılan ücreti** güncellenir.

### 3.2 Güne Basılı Tutma (Önizleme/Popup)
- Bir güne **basılı tutulduğunda (long press)**, o günün bilgileri bir **popup** içinde hızlıca görüntülenir (form açmadan önizleme).

### 3.3 Kayıt Güncelleme
- Daha önce veri girilmiş bir güne tekrar tıklanarak, o günün bilgileri (şehir içi/dışı, ücret, not) **düzenlenebilir/güncellenebilir**.

## 4. Alt Bilgi Çubuğu (Aylık Özet Bar)

Takvimin altında bulunan bir bar üzerinde şu bilgiler anlık olarak gösterilir:
- O ay içinde gidilen **toplam iş günü sayısı**
- O ay için kazanılan **toplam ücret**

## 5. İş Yoğunluğu Grafiği

- Ayrı bir barda/grafikte **iş yoğunluğu** görselleştirilir.
- Bu grafik soldan sağa doğru bir **dalga (wave)** şeklinde ilerler:
  - Art arda işe gidilen günlerde dalga **yükselir**.
  - İşe gidilmeyen günlerde dalga **azalır/düşer**.
- Böylece kullanıcı ay içindeki çalışma yoğunluğunu görsel olarak takip edebilir.

## 6. Son Notlar Bölümü

- Ekranın en altında **"Son Notlar"** başlıklı bir bölüm bulunur.
- Bu bölümde sadece kullanıcının girdiği **notlar ve ilgili gün bilgisi** listelenir (ücret/şehir içi-dışı bilgisi gösterilmez).
- Bu liste **yatay olarak sola kaydırılarak (swipe)** gezilir; böylece geçmiş notlara sırayla ulaşılabilir.

## 7. Ayarlar Ekranı

Ayarlar bölümünde şu seçenekler bulunur:
- **Varsayılan Şehir İçi Ücreti** girişi (kutucuk) — varsayılan: 1025
- **Varsayılan Şehir Dışı Ücreti** girişi (kutucuk) — varsayılan: 1100
- **Dil Seçimi**: Türkçe (TR) / İngilizce (EN)
- Sayfanın en altında:
  - **"Tüm hakları saklıdır"** yazısı
  - **Versiyon bilgisi** kutucuğu

## 8. Özellik Özeti (Kısa Liste)

| Özellik | Açıklama |
|---|---|
| Aylık takvim | Pazartesi başlangıçlı, o aya özel gün sayısı (max 31) |
| Güne tıklama | Form açılır: şehir içi/dışı seçimi, ücret, not |
| Otomatik ücret | Ayarlardaki varsayılan tutarlar forma otomatik yansır |
| Manuel ücret girişi | Kullanıcı özel/çift tutar girebilir |
| Rich text not alanı | Gidilen iş/yer bilgisi not olarak yazılır |
| Basılı tutma (long press) | Günün bilgilerini popup ile hızlı görüntüleme |
| Kayıt düzenleme | Var olan gün kaydı sonradan güncellenebilir |
| Alt özet bar | Aylık toplam iş günü + toplam ücret |
| İş yoğunluğu grafiği | Soldan sağa dalga şeklinde artan/azalan yoğunluk verisi |
| Son notlar bölümü | Kaydırmalı, sadece notları gösteren liste |
| Hoş geldiniz mesajı | Toplam yapılan iş sayısı bilgisi |
| Ayarlar | Varsayılan ücretler, dil seçimi (TR/EN) |
| Alt bilgi | Telif hakkı metni + versiyon numarası |

---
*Bu doküman, Day Track uygulamasının mevcut özelliklerini tanıtmak amacıyla hazırlanmıştır.*
