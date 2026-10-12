-- ============================================================
-- BILFEN BİLİŞİM AI — ÖĞRETMEN KAYDI ADMIN ONAY MİGRASYONU (v2.9)
-- Öğretmen kayıtları artık 'ogretmen_bekliyor' rolüyle yazılır;
-- admin panelden onaylanınca 'ogretmen' olur ve giriş açılır.
--
-- Kurulum: Supabase → SQL Editor → bu dosyanın tamamını çalıştır.
-- Tekrar çalıştırmak güvenlidir (idempotent). Öğrenci verisi SİLMEZ.
--
-- ⚠️ DOĞRU PROJEYİ SEÇ: bilfen portalının projesi
--    zvqwhesibqntcnpqoytm.supabase.co
-- ============================================================

-- ------------------------------------------------------------
-- 1) profil.rol check constraint'ini 'ogretmen_bekliyor' dahil
--    yeni listeye genişlet.
-- ------------------------------------------------------------
alter table public.profil drop constraint if exists profil_rol_check;
alter table public.profil add constraint profil_rol_check
  check (rol in ('ogretmen', 'ogrenci', 'ogretmen_bekliyor'));

-- ------------------------------------------------------------
-- 2) RLS politikaları: yeni rol yazılabilir ama okunması da
--    gerekir (admin listeleyip onaylayacak). Mevcut politikalar
--    okumaya zaten izin verir; yazma politikası rol-agnostiktir.
--    (profil_anon_ekler_ogrenci_haric politikası yeni rolü de
--    kapsar — rol is distinct from 'ogrenci' koşulu true verir.)
--    Burada ek bir işlem gerekmez; idempotentlik için yalnızca
--    constraint güncellemesi yeterli.
-- ------------------------------------------------------------

-- Bitti. Onay sonrası panelde rol PATCH ile 'ogretmen' yapılır.
