-- ============================================================
-- Bilfen DigiQuest – Performans düzeltmesi (v2.9.7 · 2026-10-20)
--
-- Sorun: ozel_etkinlik tablosunun icerik sütunundaki tam HTML dosyaları
--        (gömülü base64 görsellerle MB boyutunda) TÜM satırlarla birlikte
--        çekilmeye çalışıldığında istek Postgres tarafında
--        "canceling statement due to statement timeout" (57014) ile kesiliyor.
--        Panelde bunun görünen belirtisi: son eklenen etkinlikler
--        yönetici onay listesine düşmüyor ("Henüz öğretmen etkinliği yok").
--
-- Çözüm (iki katman):
--   1) panel.html artık liste isteklerinde icerik'i ÇEKMEZ; içeriği
--      kullanacak işlem (Görüntüle/İndir/Oynat/Düzenle/Yedek) satır başına
--      ayrı tek-satır fetch yapar → her istek hızlı.
--   2) Bu dosya DB tarafını serinletir: tarih indeksleri + ANALYZE.
--
-- Supabase Dashboard → SQL Editor'a yapıştırıp RUN de. Idempotenttir;
-- tekrar çalıştırmak güvenlidir.
-- ============================================================

-- 1) Tarih indeksleri (sıralama istekleri indekten okur, sort yapmaz)
create index if not exists ozel_etkinlik_tarih_idx
  on ozel_etkinlik (olusturma_tarihi desc);

create index if not exists ozel_etkinlik_durum_tarih_idx
  on ozel_etkinlik (durum, olusturma_tarihi desc);

create index if not exists tamamlanan_tarih_idx
  on tamamlanan (tarih desc);

-- 2) İstatistikleri tazele, şişmiş ölü satırları topla
--    (Not: bazı ortamlarda VACUUM işlem altında reddedilir; hata alırsan
--     her satırı SQL Editor'da TEK TEK çalıştır.)
vacuum (analyze) ozel_etkinlik;
vacuum (analyze) etkinlik_atama;
vacuum (analyze) tamamlanan;
vacuum (analyze) profil;

-- 3) Kontrol (opsiyonel): bekleyen onay sayısı
-- select count(*) from ozel_etkinlik where durum = 'bekliyor';
