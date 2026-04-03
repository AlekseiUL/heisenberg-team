---
name: TubeScribe
description: "YouTube видео в текст + аудио-саммари. Транскрипция, разделение спикеров, ключевые цитаты, комментарии."
---

# TubeScribe 🎬 - YouTube в документ и аудио-саммари

## 📦 Установка

1. Скопируйте папку `skills/tubescribe/` в ваш workspace OpenClaw
2. Установите зависимости:
   ```bash
   brew install steipete/tap/summarize  # обязательно
   brew install pandoc ffmpeg yt-dlp     # опционально (для лучшего качества)
   ```
3. Запустите первоначальную настройку:
   ```bash
   python skills/tubescribe/scripts/setup.py
   ```
4. OpenClaw автоматически подхватит скилл при следующем сообщении
5. Проверка: отправьте агенту любую ссылку на YouTube

## 🎯 Что умеет

- **Транскрибирует любое YouTube видео** - интервью, подкасты, лекции, туториалы
- **Определяет спикеров** - автоматическая разметка участников разговора
- **Создаёт документ** - DOCX, HTML или Markdown с форматированием
- **Генерирует аудио-саммари** - MP3/WAV для прослушивания в дороге
- **Кликабельные тайм-коды** - каждая цитата ведёт на момент в видео
- **Анализ комментариев** - настроение зрителей и лучшие комментарии
- **Очередь обработки** - скидывайте несколько ссылок, обработает по порядку

### 💸 Бесплатно и без API

- Не нужны подписки или API-ключи
- Локальная обработка - всё на вашей машине
- Ничего не отправляется на сторонние сервисы
- Требуется интернет только для загрузки с YouTube

## ⚙️ Как работает

### Полный pipeline (автоматически):

1. **Извлечение** - скачивает метаданные, субтитры, комментарии с YouTube
2. **Разметка спикеров** - определяет участников и их роли
3. **Создание документа** - форматированный текст с:
   - Информация о видео (канал, дата, длительность)
   - Таблица участников
   - Саммари (3-5 абзацев)
   - Ключевые цитаты (5 лучших с тайм-кодами)
   - Анализ комментариев зрителей
   - Полная транскрипция с тайм-кодами
4. **Экспорт в DOCX** - через pandoc (или HTML/MD)
5. **Генерация аудио** - TTS из саммари
6. **Открытие папки** - результаты в `~/Documents/TubeScribe/`

### Структура вывода:

```
~/Documents/TubeScribe/
├── Название_Видео.docx          # Документ (или .html / .md)
└── Название_Видео_summary.mp3   # Аудио-саммари (или .wav)
```

### Движки TTS (на выбор):

- **mlx-audio** - самый быстрый на Apple Silicon (использует MLX backend для Kokoro)
- **Kokoro PyTorch** - резервный вариант, хорошее качество
- **Builtin macOS** - встроенный TTS (работает из коробки)

## 💡 Примеры использования

**Пример 1:** Отправьте агенту:
> https://www.youtube.com/watch?v=dQw4w9WgXcQ

**Пример 2:** Несколько ссылок подряд:
> https://youtube.com/watch?v=video1  
> https://youtube.com/watch?v=video2  
> https://youtube.com/watch?v=video3

**Пример 3:** "Сделай транскрипцию этого подкаста с разделением спикеров"

Агент запустит обработку в фоне и сообщит когда готово. Можете продолжать общаться.

## 🔧 Настройка под себя

### Конфигурация: `~/.tubescribe/config.json`

```json
{
  "output": {
    "folder": "~/Documents/TubeScribe",
    "open_folder_after": true
  },
  "document": {
    "format": "docx",
    "engine": "pandoc"
  },
  "audio": {
    "enabled": true,
    "format": "mp3",
    "tts_engine": "mlx"
  },
  "mlx_audio": {
    "model": "mlx-community/Kokoro-82M-bf16",
    "voice_blend": {"af_heart": 0.6, "af_sky": 0.4},
    "speed": 1.05
  },
  "comments": {
    "max_count": 50,
    "timeout": 90
  },
  "processing": {
    "subagent_timeout": 600,
    "cleanup_temp_files": true
  }
}
```

### Настройки вывода:

- `output.folder` - папка для сохранения (по умолчанию `~/Documents/TubeScribe`)
- `output.open_folder_after` - открыть папку после завершения (true/false)
- `output.open_document_after` - автооткрытие документа (true/false)
- `output.open_audio_after` - автооткрытие аудио (true/false)

### Формат документа:

- `document.format` - выбор формата: `docx`, `html`, `md`
- `document.engine` - конвертер (`pandoc` - если установлен)

### Аудио:

- `audio.enabled` - генерировать аудио-саммари (true/false)
- `audio.format` - формат аудио: `mp3` (требует ffmpeg) или `wav`
- `audio.tts_engine` - движок TTS: `mlx` (быстрый на Apple Silicon), `kokoro` (PyTorch), `builtin` (macOS)

### MLX-Audio (рекомендуется для Apple Silicon):

- `mlx_audio.model` - модель MLX (по умолчанию Kokoro-82M-bf16)
- `mlx_audio.voice_blend` - микс голосов (например `{af_heart: 0.6, af_sky: 0.4}`)
- `mlx_audio.speed` - скорость (1.0 = нормально, 1.05 = +5%)

### Обработка:

- `processing.subagent_timeout` - таймаут для длинных видео (в секундах)
- `processing.cleanup_temp_files` - удалять временные файлы (true/false)

### Комментарии:

- `comments.max_count` - количество комментариев для анализа (по умолчанию 50)
- `comments.timeout` - таймаут загрузки комментариев (в секундах)

## 🛠️ Зависимости

**Обязательные:**
- `summarize` CLI - `brew install steipete/tap/summarize`
- Python 3.8+

**Опциональные (улучшают качество):**
- `pandoc` - для DOCX: `brew install pandoc`
- `ffmpeg` - для MP3: `brew install ffmpeg`
- `yt-dlp` - для комментариев: `brew install yt-dlp`
- `mlx-audio` - быстрый TTS на Apple Silicon: `pip install mlx-audio`

### Поиск yt-dlp

TubeScribe ищет yt-dlp в этом порядке:
1. Системный PATH (`which yt-dlp`)
2. Homebrew Apple Silicon (`/opt/homebrew/bin/yt-dlp`)
3. Homebrew Intel/Linux (`/usr/local/bin/yt-dlp`)
4. pip install --user (`~/.local/bin/yt-dlp`)
5. pipx (`~/.local/pipx/venvs/yt-dlp/bin/yt-dlp`)
6. Автоустановка TubeScribe (`~/.openclaw/tools/yt-dlp/yt-dlp`)

Если не найден, setup скачает standalone binary в tools директорию.

## 📋 Очередь обработки

### Проверка статуса:
```bash
python skills/tubescribe/scripts/tubescribe.py --queue-status
```

### Добавление в очередь:
```bash
python skills/tubescribe/scripts/tubescribe.py --queue-add "URL"
```

### Обработка следующего:
```bash
python skills/tubescribe/scripts/tubescribe.py --queue-next
```

### Пакетная обработка:
```bash
python skills/tubescribe/scripts/tubescribe.py url1 url2 url3
```

## ⚠️ Обработка ошибок

TubeScribe автоматически определяет и сообщает:

- ❌ Неверная ссылка
- ❌ Приватное видео
- ❌ Видео удалено
- ❌ Нет субтитров
- ❌ Ограничение по возрасту
- ❌ Блокировка в вашем регионе
- ❌ Прямая трансляция (не поддерживается)
- ❌ Сетевая ошибка
- ❌ Таймаут

## 💡 Советы

- Для длинных видео (>30 мин) увеличьте `processing.subagent_timeout` до 900 секунд
- Разделение спикеров работает лучше всего на интервью и подкастах
- Для туториалов и лекций (один спикер) метки спикеров автоматически пропускаются
- Тайм-коды кликабельны - ведут прямо на момент в видео
- Используйте пакетный режим для обработки нескольких видео подряд
