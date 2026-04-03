#!/bin/bash
# gemini.sh — Обёртка для Gemini CLI
# Использование: ./gemini.sh "запрос" [модель]
# Модели: pro (по умолчанию), flash
# Конфиг: ~/.config/gemini-cli/settings.json

QUERY="$1"
MODEL="${2}"

if [ -z "$QUERY" ]; then
    echo "Использование: $0 \"запрос\" [flash|pro]"
    exit 1
fi

# Если модель не указана, используется из конфига (gemini-2.5-pro)
if [ -n "$MODEL" ]; then
    case "$MODEL" in
        flash|f)
            MODEL_FLAG="-m gemini-2.5-flash"
            ;;
        pro|p)
            MODEL_FLAG="-m gemini-2.5-pro"
            ;;
        *)
            MODEL_FLAG="-m $MODEL"
            ;;
    esac
else
    MODEL_FLAG=""
fi

# Таймаут 30 секунд - если Gemini API лагает, не зависаем
perl -e 'alarm 30; exec @ARGV' -- gemini $MODEL_FLAG "$QUERY" 2>/dev/null
exit_code=$?
if [ $exit_code -eq 142 ]; then
    echo "ERROR: Gemini timeout (30s)" >&2
    exit 1
fi
exit $exit_code
