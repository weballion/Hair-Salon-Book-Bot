# HairBook

Telegram-бот для управления записями парикмахерского салона — расписание, бронирование, отмена. Работает полностью на бесплатных тарифах: **€0/мес**.

## Стек

| Компонент | Сервис | Зачем |
|-----------|--------|-------|
| Оркестрация | [n8n](https://n8n.io) self-hosted на [Railway](https://railway.com) | No-code воркфлоу, встроенный Telegram Trigger |
| База данных | [Supabase](https://supabase.com) PostgreSQL (Frankfurt) | PostgREST API из коробки, RLS, free tier 500 MB |
| Голос → текст | [Groq](https://groq.com) Whisper (`whisper-large-v3-turbo`) | Быстрая транскрибация, бесплатный tier |
| NLU | [Groq](https://groq.com) LLM (`llama-3.3-70b-versatile`) | Парсинг намерений из текста и голоса |
| Бот | Telegram Bot API через n8n Webhook | Без собственного сервера |

## Фаза 1 — что реализовано

### Навигация
- `/start` — приветствие + Reply Keyboard (постоянное меню)
- Кнопки: `📅 Сегодня` · `📅 Завтра` · `📅 Неделя` · `📅 30 дней вперед` · `🟢 Свободные окна` · `✅ Новая запись` · `💼 Услуги`

### Просмотр расписания
- День / неделя / 30 дней — через кнопки или голос/текст
- Формат: `🕐 14:00–14:30  Анна · Стрижка женская · 60 мин`
- Сортировка по времени (Europe/Berlin), полный диапазон записи
- Инлайн-кнопки отмены прямо в расписании

### Отмена записей
- Кнопка `❌ 14:00 Анна` → PATCH `status = cancelled`
- Расписание автоматически обновляется после отмены

### Свободные окна
- Просмотр свободного времени на выбранный день
- Учёт рабочего расписания мастера, обеденного перерыва, буфера между записями
- Выравнивание по часовым границам: `12:15–13:15` → `12:15–13:00 + 13:00–14:00`
- Навигация вперёд/назад по дням (инлайн-кнопки)

### Новая запись
Пошаговый диалог через инлайн-кнопки:
1. `🟢 Свободные окна` → выбор дня
2. Выбор временного окна
3. Выбор услуги (фильтрация по длительности окна)
4. Ввод имени клиента (текстовое сообщение)
5. Карточка подтверждения (дата, время, имя, услуга, цена, длительность)
6. `✅ Подтвердить` → INSERT в Supabase → `✅ Запись создана! ⏰ 14:00–15:00`

### Список услуг
- Все активные услуги с ценой и длительностью

### Голосовые сообщения
- Поддержка voice messages в Telegram
- Транскрибация через Groq Whisper
- Результат идёт в тот же NLU-пайплайн что и текст
- Распознаёт: расписание (сегодня/завтра/неделя/30 дней), свободные окна, список услуг

## Архитектура воркфлоу (n8n, 64 ноды)

```
Telegram Trigger
  └── Auth Check (whitelist по chat_id)
        ├── Callback? → YES → Callback Router (switch по префиксу)
        │                       ├── cancel:   → отмена → расписание
        │                       ├── slots:    → свободные окна на дату
        │                       ├── slot:     → список услуг для окна
        │                       ├── book:     → сохранить контекст → запросить имя
        │                       └── confirm:  → прочитать имя → INSERT → уведомление
        └── Callback? → NO  → Voice?
                                ├── YES → Groq Whisper → Build Prompt
                                └── NO  → /start?
                                            ├── YES → Welcome
                                            └── NO  → Load Conv State
                                                        ├── awaiting_name → карточка подтверждения
                                                        └── иначе → Groq LLM → Action Switch
                                                                      ├── view_schedule
                                                                      ├── list_services
                                                                      ├── free_slots
                                                                      └── unknown → "не понял"
```

**Callback data format:**
- `slot:YYYYMMDD:HHMM:durationMin` — выбранное окно
- `book:YYYYMMDD:HHMM:serviceId` — выбранная услуга
- `confirm:YYYYMMDD:HHMM:serviceId:durationMin` — подтверждение

## Структура проекта

```
hairbook/
├── database/
│   └── schema.sql              # CREATE TABLE + RLS + seed данные
├── n8n/
│   └── workflows/
│       └── hairbook-main.json  # Экспорт workflow (с плейсхолдерами вместо токенов)
├── docs/
├── .env.example
└── README.md
```

## Настройка

### 1. Supabase

1. Создать проект на [supabase.com](https://supabase.com) (Frankfurt для низкой латентности)
2. SQL Editor → выполнить `database/schema.sql` (создаёт таблицы, RLS, seed-данные)
3. Settings → API → скопировать **Project URL** и **anon key**

### 2. Telegram Bot

1. [@BotFather](https://t.me/BotFather) → `/newbot` → получить токен
2. Написать боту что-нибудь, открыть `https://api.telegram.org/bot<TOKEN>/getUpdates`
3. Найти `result[0].message.chat.id` — это ваш `telegram_chat_id` (нужен для auth + seed)

### 3. Groq API

1. Зарегистрироваться на [console.groq.com](https://console.groq.com)
2. API Keys → Create → скопировать ключ

### 4. n8n на Railway

1. [railway.com](https://railway.com) → New Project → Deploy Template → n8n
2. После деплоя открыть n8n UI, добавить Credentials:
   - **Telegram HairBook Bot** (тип: Telegram API): вставить Bot Token
   - **Groq API** (тип: HTTP Header Auth): Header Name `Authorization`, Value `Bearer YOUR_GROQ_KEY`
3. Workflows → Import → загрузить `n8n/workflows/hairbook-main.json`
4. Найти и заменить в воркфлоу:
   - `YOUR_SUPABASE_URL` → ваш Supabase Project URL
   - `YOUR_SUPABASE_ANON_KEY` → ваш anon key
   - `YOUR_BOT_TOKEN` → ваш Telegram Bot Token
   - `27020283` → ваш `telegram_chat_id` (Auth Check, Get Stylist, Get Stylist ID, seed данные)
5. Активировать workflow (toggle Active)

### 5. Переменные окружения (локальная разработка)

```bash
cp .env.example .env
# Заполнить значения
```

> ⚠️ `.env` добавлен в `.gitignore` — никогда не коммитьте реальные токены

## Фаза 2 — в планах

### Голосовое бронирование
- «Запишите Анну на пятницу в 14 на стрижку» → парсинг через LLM → проверка слота → INSERT
- Без кнопок, полностью через естественный язык

### Напоминания
- Cron-воркфлоу: за день и за час до записи → уведомление мастеру (и клиенту при наличии номера)

### Перенос записей
- Отмена + подбор нового времени в одном диалоге

### Мультимастер
- Несколько стилистов, авторизация каждого по `chat_id`
- Общее/раздельное расписание

### Клиентские профили
- История посещений, предпочтения, номер телефона
- Поиск клиента по имени при бронировании

### Веб-дашборд
- Supabase Studio / Retool / n8n Form для просмотра и редактирования данных

## Лицензия

MIT
