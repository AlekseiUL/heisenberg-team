const lz = require('lz-string');

// Helper to create rectangle with bound text
function createBox(id, x, y, w, h, stroke, bg, text, fontSize = 14) {
  const textId = id + "-text";
  return [
    {
      type: "rectangle",
      id: id,
      x: x,
      y: y,
      width: w,
      height: h,
      strokeColor: stroke,
      backgroundColor: bg,
      fillStyle: "solid",
      strokeWidth: 2,
      roundness: { type: 3 },
      boundElements: [{ type: "text", id: textId }],
      seed: Math.floor(Math.random() * 100000)
    },
    {
      type: "text",
      id: textId,
      x: x + 10,
      y: y + 10,
      width: w - 20,
      height: h - 20,
      text: text,
      fontSize: fontSize,
      fontFamily: 1,
      textAlign: "left",
      verticalAlign: "top",
      strokeColor: "#ffffff",
      containerId: id,
      seed: Math.floor(Math.random() * 100000)
    }
  ];
}

// Helper for standalone text
function createText(id, x, y, text, fontSize, color) {
  return {
    type: "text",
    id: id,
    x: x,
    y: y,
    width: text.length * fontSize * 0.6,
    height: fontSize * 1.5,
    text: text,
    fontSize: fontSize,
    fontFamily: 1,
    strokeColor: color,
    seed: Math.floor(Math.random() * 100000)
  };
}

// Helper for arrow
function createArrow(id, x, y, dx, dy, color) {
  return {
    type: "arrow",
    id: id,
    x: x,
    y: y,
    width: Math.abs(dx),
    height: Math.abs(dy),
    strokeColor: color,
    strokeWidth: 3,
    points: [[0, 0], [dx, dy]],
    seed: Math.floor(Math.random() * 100000)
  };
}

let elements = [];

// ========== TITLE ==========
elements.push(...createBox("title", 50, 20, 900, 60, "#4338ca", "#1e1b4b", 
  "🦀 Система агентов OpenClaw — Полный цикл работы", 26));

// ========== SECTION 1 ==========
elements.push(createText("sec1", 50, 100, "ЭТАП 1: Путь запроса от пользователя к агенту", 20, "#22c55e"));

// User box
elements.push(...createBox("user", 50, 150, 150, 100, "#3b82f6", "#1e3a8a",
  "👤 Пользователь\n\nПишет сообщение\nв Telegram", 14));

// Arrow 1
elements.push(createArrow("arr1", 205, 200, 55, 0, "#22c55e"));
elements.push(createText("arr1-lbl", 210, 175, "текст", 12, "#9ca3af"));

// Gateway box
elements.push(...createBox("gateway", 265, 140, 200, 120, "#f97316", "#7c2d12",
  "⚡ Gateway\n\n• Получает webhook\n• Определяет агента\n• Загружает контекст\n• Формирует промпт", 13));

// Arrow 2
elements.push(createArrow("arr2", 470, 200, 55, 0, "#22c55e"));
elements.push(createText("arr2-lbl", 473, 175, "промпт", 12, "#9ca3af"));

// Claude API box
elements.push(...createBox("api", 530, 140, 170, 120, "#a855f7", "#581c87",
  "🤖 Claude API\n\n• Получает промпт\n• Думает (reasoning)\n• Генерирует ответ\n• Вызывает tools", 13));

// Arrow 3
elements.push(createArrow("arr3", 705, 200, 55, 0, "#22c55e"));
elements.push(createText("arr3-lbl", 710, 175, "ответ", 12, "#9ca3af"));

// Agent box
elements.push(...createBox("agent", 765, 140, 200, 120, "#4338ca", "#312e81",
  "🦀 {{AGENT_NICKNAME}} (Агент)\n\n• Анализирует запрос\n• Использует tools/skills\n• Читает/пишет память\n• Формирует ответ", 13));

// ========== SECTION 2 ==========
elements.push(createText("sec2", 50, 290, "ЭТАП 2: Создание Sub-agent (для параллельных задач)", 20, "#22c55e"));

// Orchestrator box
elements.push(...createBox("orch", 50, 340, 260, 200, "#4338ca", "#312e81",
  "🦀 {{AGENT_NICKNAME}} — Оркестратор\n\nКогда задача сложная:\n1. Разбиваю на подзадачи\n2. Вызываю sessions_spawn()\n3. Каждый sub-agent работает\n   параллельно и независимо\n4. Жду результаты\n5. Собираю итоговый ответ", 13));

// Arrow spawn
elements.push(createArrow("spawn-arr", 315, 400, 70, 0, "#22c55e"));
elements.push(createText("spawn-lbl", 320, 375, "spawn()", 14, "#22c55e"));

// Sub-agents container
elements.push(...createBox("subs", 390, 330, 300, 220, "#374151", "#111827",
  "Sub-agents (изолированные сессии)", 14));

// Sub-agent 1
elements.push(...createBox("sub1", 410, 380, 120, 60, "#22c55e", "#14532d",
  "Sub-agent #1\nРесёрч темы А", 12));

// Sub-agent 2
elements.push(...createBox("sub2", 550, 380, 120, 60, "#22c55e", "#14532d",
  "Sub-agent #2\nРесёрч темы Б", 12));

// Sub-agent 3
elements.push(...createBox("sub3", 480, 460, 120, 60, "#22c55e", "#14532d",
  "Sub-agent #3\nНаписание кода", 12));

// Announce arrow
elements.push(createArrow("ann-arr", 390, 510, -70, 0, "#f97316"));
elements.push(createText("ann-lbl", 320, 515, "результат", 12, "#f97316"));

// Sub-agent properties
elements.push(...createBox("sub-props", 710, 330, 260, 220, "#374151", "#0f172a",
  "Что получает sub-agent:\n\n✅ Изолированную сессию\n✅ AGENTS.md и TOOLS.md\n✅ Доступ к tools\n✅ Можно другую модель\n\n❌ НЕ получает:\n• IDENTITY, USER, MEMORY\n• Не может вызывать spawn", 13));

// ========== SECTION 3 ==========
elements.push(createText("sec3", 50, 580, "ЭТАП 3: Multi-agent (разные личности в одном Gateway)", 20, "#3b82f6"));

// Gateway container
elements.push(...createBox("gw", 50, 620, 920, 260, "#6366f1", "#0f0f23",
  "🌐 Один Gateway — несколько полностью изолированных агентов", 16));

// Agent Home
elements.push(...createBox("ma-home", 70, 670, 270, 190, "#22c55e", "#14532d",
  "Агент: home (семья)\n\n📁 workspace-home/\n   • IDENTITY — семейный бот\n   • MEMORY — личные дела\n   • своя история диалогов\n\n🔑 Свои API ключи\n🤖 claude-sonnet (быстрый)", 13));

// Agent Work
elements.push(...createBox("ma-work", 360, 670, 270, 190, "#f97316", "#7c2d12",
  "Агент: work (рабочий)\n\n📁 workspace-work/\n   • IDENTITY — профессионал\n   • MEMORY — рабочие дела\n   • своя история диалогов\n\n🔑 Свои API ключи\n🤖 claude-sonnet (быстрый)", 13));

// Agent Opus
elements.push(...createBox("ma-opus", 650, 670, 270, 190, "#a855f7", "#581c87",
  "Агент: opus (deep work)\n\n📁 workspace-opus/\n   • IDENTITY — аналитик\n   • MEMORY — исследования\n   • своя история диалогов\n\n🔑 Свои API ключи\n🤖 claude-opus (умный)", 13));

// Channels
elements.push(...createBox("ch-wa", 70, 910, 180, 50, "#22c55e", "#166534",
  "📱 WhatsApp личный", 14));

elements.push(...createBox("ch-tg", 400, 910, 180, 50, "#3b82f6", "#1e3a8a",
  "✈️ Telegram рабочий", 14));

elements.push(...createBox("ch-dc", 710, 910, 180, 50, "#a855f7", "#4c1d95",
  "🎮 Discord сервер", 14));

// Binding arrows
elements.push(createArrow("bind1", 160, 910, 45, -40, "#22c55e"));
elements.push(createArrow("bind2", 490, 910, 5, -40, "#f97316"));
elements.push(createArrow("bind3", 800, 910, -45, -40, "#a855f7"));

// Bindings explanation
elements.push(createText("bind-exp", 50, 980, "⬆️ Bindings — правила роутинга: какой канал/чат направляется к какому агенту", 16, "#9ca3af"));

// ========== LEGEND ==========
elements.push(...createBox("legend", 50, 1020, 920, 90, "#374151", "#111827",
  "ИТОГО:\n• Sub-agents — временные помощники для параллельных задач. Команда: sessions_spawn(task='...')\n• Multi-agent — постоянные личности с разными workspace и памятью. Команда: openclaw agents add", 14));

// Build final structure
const appState = {
  viewBackgroundColor: "#000000",
  gridSize: 20
};

const data = {
  type: "excalidraw",
  version: 2,
  source: "https://github.com/zsviczian/obsidian-excalidraw-plugin",
  elements: elements,
  appState: appState
};

// Compress
const jsonStr = JSON.stringify(data);
const compressed = lz.compressToBase64(jsonStr);

// Generate text elements section
let textElements = "";
elements.filter(e => e.type === "text").forEach(e => {
  textElements += e.text + " ^" + e.id + "\n\n";
});

// Output
const output = `---
excalidraw-plugin: parsed
tags: [excalidraw, openclaw, agents, workflow]
---

# Excalidraw Data

## Text Elements
${textElements}
%%
## Drawing
\`\`\`compressed-json
${compressed}
\`\`\`
%%`;

console.log(output);
