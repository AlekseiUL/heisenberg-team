const { events, memory, message } = require('openclaw');

const activeSkills = new Map();
const dailyCalls = new Map();
const dailyErrors = new Map();

function getTodayKey() {
  const d = new Date();
  return d.toISOString().split('T')[0];
}

// Отслеживаем запуск скилла
events.on('skillStart', (skillName) => {
  const startTime = Date.now();
  activeSkills.set(skillName, startTime);

  // Счётчик вызовов
  const key = `${skillName}::${getTodayKey()}`;
  dailyCalls.set(key, (dailyCalls.get(key) || 0) + 1);
});

// Отслеживаем завершение скилла
events.on('skillEnd', (skillName) => {
  if (!activeSkills.has(skillName)) return;
  const startTime = activeSkills.get(skillName);
  const duration = Date.now() - startTime;
  activeSkills.delete(skillName);

  // Записать в память итог времени
  const key = `${skillName}::${getTodayKey()}`;
  const prev = memory.get(key) || 0;
  memory.set(key, prev + duration);
});

// Отслеживаем ошибки
events.on('skillError', (skillName, error) => {
  const key = `${skillName}::${getTodayKey()}`;
  dailyErrors.set(key, (dailyErrors.get(key) || 0) + 1);

  // При более чем 3 ошибках за день — отправить уведомление
  if (dailyErrors.get(key) > 3) {
    message(action='send', channel='telegram', to='{{OWNER_TELEGRAM_ID}}', message=`⚠️ Внимание! Скилл ${skillName} выдаёт ошибки.`);
  }
});

// Экспорт функций для использования
module.exports = {
  name: 'SafeSkillMonitor',
  version: '0.1',
  description: 'Безопасный мониторинг скиллов OpenClaw без shell-исполнения',
  start() { /* инициализация, если нужно */ },
  stop() { /* очистка, если нужно */ }
};
