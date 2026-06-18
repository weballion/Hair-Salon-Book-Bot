# HairBook

Telegram-бот для управления записями парикмахера. Фаза 1 (MVP).

## Стек

| Компонент | Сервис |
|-----------|--------|
| Оркестрация | n8n self-hosted на Railway |
| База данных | Supabase PostgreSQL (Frankfurt) |
| Telegram-бот | n8n Telegram Trigger |
| Голос → текст | Groq Whisper (whisper-large-v3-turbo) |
| Понимание текста | Groq LLM (llama-3.3-70b-versatile) |

Итого: **€0/мес** на free tier.

## Структура

```
hairbook/
├── database/
│   └── schema.sql        # CREATE TABLE + тестовые данные
├── n8n/
│   └── workflows/        # экспорты JSON-воркфлоу из n8n
├── docs/
│   └── hairbook-phase1-mvp.md
├── .env.example
└── README.md
```

## Быстрый старт

### 1. База данных (Supabase)

```bash
# Открыть SQL Editor в supabase.com и выполнить:
database/schema.sql
```

### 2. Переменные окружения

```bash
cp .env.example .env
# заполнить значения
```

### 3. n8n на Railway

1. railway.com → New Project → шаблон n8n
2. Добавить Credentials: Telegram, Groq (HTTP Header Auth), Supabase
3. Импортировать воркфлоу из `n8n/workflows/`

## Возможности (Фаза 1)

- Диалог на естественном языке (DE/RU)
- Голосовые сообщения (транскрибация через Groq Whisper)
- Reply Keyboard с быстрыми кнопками
- Inline кнопки для уточняющего диалога
- Создание / отмена / перенос записей
- Просмотр расписания (день, неделя, свободные окна)
- Проверка рабочих часов, перерывов, буфера между записями
