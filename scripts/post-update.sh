#!/bin/bash
# Post-update hook: доставляет зависимости которые слетают при npm i -g openclaw
# Запускать после каждого обновления OpenClaw

set -e

# Cross-platform gateway restart
restart_gateway() {
  if [[ "$OSTYPE" == "darwin"* ]]; then
    launchctl kickstart -k "gui/$(id -u)/ai.openclaw.gateway" 2>&1 || true
  elif command -v systemctl &>/dev/null; then
    systemctl --user restart openclaw-gateway 2>/dev/null || \
    openclaw gateway restart
  else
    openclaw gateway restart
  fi
}

restart_doctor() {
  if [[ "$OSTYPE" == "darwin"* ]]; then
    launchctl kickstart -k "gui/$(id -u)/com.openclaw.doctor" 2>&1 || true
  elif command -v systemctl &>/dev/null; then
    systemctl --user restart openclaw-doctor 2>/dev/null || true
  fi
}

OPENCLAW_DIR="/opt/homebrew/lib/node_modules/openclaw"

# 1. Playwright (нужен для snapshot/navigate)
if ! node -e "require('playwright')" 2>/dev/null; then
    echo "📦 Устанавливаю Playwright..."
    cd "$OPENCLAW_DIR" && npm install playwright --no-save 2>&1 | tail -3
    echo "✅ Playwright установлен"
else
    echo "✅ Playwright уже на месте"
fi

# 2. Рестарт gateway чтобы подхватил новый бинарник
# ВАЖНО: НЕ использовать `openclaw gateway restart` — убивает сессию агента!
echo "🔄 Перезапускаю gateway..."
restart_gateway
sleep 5
# Проверяем что gateway поднялся
if openclaw gateway status 2>&1 | grep -q "running"; then
    echo "✅ Gateway работает"
else
    echo "❌ Gateway не поднялся! Пробую ещё раз..."
    restart_gateway
    sleep 5
fi

# 3. Перезапуск Доктора (чтобы подхватил новый бинарник)
echo "🩺 Перезапускаю Доктора..."
restart_doctor
sleep 3

# 4. Проверка Доктора
echo "🩺 Проверка Доктора..."
bash ~/Desktop/AI_DOCTOR/scripts/post-update-doctor.sh 2>&1 || true

# 5. Реиндекс памяти (после рестарта индексация может отставать)
echo "🧠 Реиндекс памяти..."
openclaw memory index --force 2>&1 | tail -3
sleep 2

# 6. Финальная проверка
echo "🔍 Финальная проверка..."
bash {{WORKSPACE_PATH}}scripts/post-update-check.sh 2>&1

echo "✅ Post-update завершён"
