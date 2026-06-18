-- HairBook Phase 1 MVP
-- Supabase PostgreSQL schema

-- ============================================================
-- TABLES
-- ============================================================

CREATE TABLE stylists (
  id               UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  name             TEXT        NOT NULL,
  telegram_chat_id BIGINT      UNIQUE NOT NULL,
  language         TEXT        DEFAULT 'de',  -- 'de' | 'ru'
  buffer_minutes   INT         DEFAULT 15,
  working_hours    JSONB       NOT NULL,
  created_at       TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE services (
  id                   UUID    PRIMARY KEY DEFAULT gen_random_uuid(),
  stylist_id           UUID    REFERENCES stylists(id) ON DELETE CASCADE,
  name                 TEXT    NOT NULL,
  default_duration_min INT     NOT NULL DEFAULT 60,
  is_active            BOOLEAN DEFAULT true
);

CREATE TABLE clients (
  id         UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  name       TEXT        NOT NULL,
  phone      TEXT,
  notes      TEXT,
  created_at TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE appointments (
  id           UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  stylist_id   UUID        REFERENCES stylists(id),
  client_id    UUID        REFERENCES clients(id),
  service_id   UUID        REFERENCES services(id),
  start_time   TIMESTAMPTZ NOT NULL,
  end_time     TIMESTAMPTZ NOT NULL,
  duration_min INT         NOT NULL,
  status       TEXT        DEFAULT 'confirmed'
               CHECK (status IN ('confirmed', 'cancelled', 'completed', 'no_show')),
  notes        TEXT,
  created_at   TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX idx_appointments_time
  ON appointments (stylist_id, start_time)
  WHERE status = 'confirmed';

CREATE TABLE conversation_state (
  chat_id      BIGINT      PRIMARY KEY,
  current_step TEXT,
  context      JSONB       DEFAULT '{}',
  updated_at   TIMESTAMPTZ DEFAULT now()
);

-- ============================================================
-- SEED DATA
-- ============================================================

-- Stylist (telegram_chat_id = ваш реальный chat_id)
INSERT INTO stylists (name, telegram_chat_id, language, buffer_minutes, working_hours)
VALUES (
  'Maria Testova',
  27020283,
  'ru',
  15,
  '{
    "mon": {"start":"09:00","end":"18:00","break_start":"13:00","break_end":"14:00"},
    "tue": {"start":"09:00","end":"18:00","break_start":"13:00","break_end":"14:00"},
    "wed": null,
    "thu": {"start":"09:00","end":"20:00","break_start":"13:00","break_end":"14:00"},
    "fri": {"start":"09:00","end":"18:00","break_start":"13:00","break_end":"14:00"},
    "sat": {"start":"09:00","end":"14:00","break_start":null,"break_end":null},
    "sun": null
  }'::jsonb
);

-- Services (ссылаются на stylist через subquery)
INSERT INTO services (stylist_id, name, default_duration_min)
SELECT id, 'Damenhaarschnitt / Стрижка женская',      60 FROM stylists WHERE telegram_chat_id = 27020283 UNION ALL
SELECT id, 'Herrenhaarschnitt / Стрижка мужская',     30 FROM stylists WHERE telegram_chat_id = 27020283 UNION ALL
SELECT id, 'Kinderhaarschnitt / Стрижка детская',     30 FROM stylists WHERE telegram_chat_id = 27020283 UNION ALL
SELECT id, 'Färben komplett / Окрашивание полное',   120 FROM stylists WHERE telegram_chat_id = 27020283 UNION ALL
SELECT id, 'Ansatz färben / Окрашивание корни',       60 FROM stylists WHERE telegram_chat_id = 27020283 UNION ALL
SELECT id, 'Strähnchen / Мелирование',                90 FROM stylists WHERE telegram_chat_id = 27020283 UNION ALL
SELECT id, 'Balayage / Балаж',                       150 FROM stylists WHERE telegram_chat_id = 27020283 UNION ALL
SELECT id, 'Haarkur / Маска для волос',               30 FROM stylists WHERE telegram_chat_id = 27020283 UNION ALL
SELECT id, 'Keratin-Behandlung / Кератин',           180 FROM stylists WHERE telegram_chat_id = 27020283 UNION ALL
SELECT id, 'Föhnen / Укладка феном',                  30 FROM stylists WHERE telegram_chat_id = 27020283 UNION ALL
SELECT id, 'Hochsteckfrisur / Прическа торжество',    60 FROM stylists WHERE telegram_chat_id = 27020283 UNION ALL
SELECT id, 'Schnitt + Färben / Стрижка + окраска',  150 FROM stylists WHERE telegram_chat_id = 27020283 UNION ALL
SELECT id, 'Schnitt + Strähnchen / Стрижка + мелир', 120 FROM stylists WHERE telegram_chat_id = 27020283;

-- Clients
INSERT INTO clients (name, phone, notes) VALUES
  ('Max Mustermann',   '+49 170 0000001', 'Stammkunde, kurzer Haarschnitt'),
  ('Erika Musterfrau', '+49 170 0000002', 'Blondierung alle 8 Wochen'),
  ('Anna Beispiel',    '+49 170 0000003', 'Empfindliche Kopfhaut'),
  ('Иван Тестов',      '+49 170 0000004', 'Предпочитает говорить по-русски'),
  ('Лиза Пробная',     '+49 170 0000005', 'Новый клиент');
