# Мировые лучшие практики создания скиллов для AI-агентов

> **Дата ресёрча:** 07.03.2026  
> **Источники:** 25+ платформ, репозиториев, документаций  
> **Исследователь:** {{AGENT_NICKNAME}} (Deep Research Pro)

---

## 🚀 Executive Summary

Исследовал **10 основных платформ** для AI-агентов (OpenClaw, Claude Code, Cursor, CrewAI, LangChain, Semantic Kernel, n8n, OpenAI GPTs, AutoGPT, Windsurf) + изучил **30+ open-source скиллов** с GitHub.

### 🎯 Топ-5 самых важных находок

1. **Progressive Disclosure побеждает** - лучшие скиллы держат core <300 строк, детали в references/
2. **Snake_case критичен** - LLM обучены на Python, CamelCase = хуже распознавание
3. **10-20 tools maximum** - точность падает с >20 tools одновременно (OpenAI data)
4. **Security first** - 12-20% скиллов на ClawHub содержали malicious код (early 2026)
5. **Multi-agent будущее** - coordinator + specialists = лучше чем один большой агент

### 📊 Ключевые метрики

- **143K stars** - самая популярная prompt библиотека (prompts.chat)
- **33K stars** - claude-mem plugin (automated memory)
- **3500+ skills** - OpenClaw ClawHub ecosystem (фев 2026)
- **1-2 секунды** - hot-reload в OpenClaw (лучшее в индустрии)
- **<1000 tokens** - рекомендуемый размер SKILL.md

### ✅ Что работает (proven)

- Natural language instructions > JSON schemas (для accessibility)
- Async support для I/O operations (CrewAI pattern)
- Caching для expensive operations (LangChain/CrewAI)
- Namespace grouping для масштаба (OpenAI 2026)
- Error messages в descriptions (LLM может self-heal)

### ❌ Что НЕ работает (anti-patterns)

- Bloated skills (всё в одном)
- Under-documentation (минималистичные descriptions)
- Over-engineering (10+ параметров на функцию)
- No validation (принимать любой input)
- Hard-coded assumptions (предполагать context)

### 🔮 Будущее (2026-2027)

- **AI-генерируемые скиллы** - AI создаёт скиллы для AI
- **Cross-platform унификация** - MCP/OpenAPI стандарты
- **Skill composition** - комбинирование как LEGO
- **Automated testing** - CI/CD для скиллов станет нормой

---

## Содержание

1. [Обзор платформ](#1-обзор-платформ)
2. [Best Practices (синтез)](#2-best-practices-синтез)
3. [Примеры лучших скиллов](#3-примеры-лучших-скиллов)
4. [Anti-patterns](#4-anti-patterns)
5. [Agent Architecture Patterns](#5-agent-architecture-patterns)
6. [Рекомендации для нашего скилла](#6-рекомендации-для-нашего-скилла)
7. [Источники](#источники)

---

## 1. Обзор платформ

### 1.1 OpenClaw (2025-2026)

**Философия:** Local-first, natural language skills + code-based plugins

**Структура скиллов:**
```
skills/<name>/
├── SKILL.md           # YAML frontmatter + natural language instructions
├── scripts/           # Optional: executable scripts
├── references/        # Optional: documentation, examples
├── data/             # Optional: skill-specific data (NOT in memory/)
└── assets/           # Optional: images, files
```

**Плюсы:**
- ✅ **Hot-reload за 1-2 секунды** - изменения применяются без перезапуска
- ✅ **Natural language первичен** - LLM сам решает когда использовать скилл
- ✅ **Гибкость** - от простых инструкций до полноценных скриптов
- ✅ **Loading precedence** - пользовательские скиллы переопределяют встроенные
- ✅ **ClawHub ecosystem** - ~3500 скиллов (по состоянию на фев 2026)
- ✅ **Dependency injection в plugins** - полноценная интеграция с сервисами

**Минусы:**
- ❌ **Безопасность** - 12-20% скиллов на ClawHub содержали malicious код (ранний 2026)
- ❌ **Нет строгого API** - зависимость от качества промпта
- ❌ **Bloat risk** - легко создать перегруженный скилл
- ❌ **Token consumption** - каждый SKILL.md грузится в контекст

**Ключевые инсайты:**
> "Skills are not built with conventional programming interfaces; rather, they are structured instructions that the agent follows to execute commands or HTTP calls." - OpenClaw Architecture Deep Dive

**Отличие skills vs plugins:**
- **Skills** = Natural language instructions, читаются LLM на каждый запрос
- **Plugins** = TypeScript modules, грузятся в Gateway runtime, middleware-уровень

---

### 1.2 Claude Code / Anthropic

**Философия:** Slash commands + CLAUDE.md для context

**Структура:**
```
project/
├── CLAUDE.md          # Project context, guidelines
├── .claude/
│   └── commands/      # Custom slash commands
└── docs/
```

**Плюсы:**
- ✅ **Minimalist approach** - всё в одном CLAUDE.md
- ✅ **Context-aware** - файл загружается автоматически
- ✅ **Slash commands** - быстрый доступ к частым действиям

**Минусы:**
- ❌ **Single file limitation** - сложно для больших проектов
- ❌ **No marketplace** - каждый проект = отдельный CLAUDE.md

**Best practice:**
> "Keep CLAUDE.md under 3000 tokens. Use progressive disclosure - link to detailed docs instead of including everything." - Anthropic docs

---

### 1.3 Cursor (.cursorrules)

**Философия:** Rules-as-code для консистентного поведения

**Структура:**
```
project/
└── .cursorrules       # Plain text rules file
```

**Плюсы:**
- ✅ **Simple** - один файл, plain text
- ✅ **Project-specific** - автоматически применяется
- ✅ **Version control friendly** - легко в git

**Минусы:**
- ❌ **Limited scope** - только текстовые правила
- ❌ **No execution** - не может запускать код

**Best practice:**
```
# Good .cursorrules structure:
1. Project overview (2-3 lines)
2. Tech stack
3. Code style preferences
4. Common patterns/anti-patterns
5. Testing expectations
```

---

### 1.4 Windsurf (Codeium)

**Философия:** AI-first editor с контекстными подсказками

**Особенности:**
- Context awareness через индексацию кодовой базы
- Real-time suggestions
- Multi-file editing

**Плюсы:**
- ✅ Built-in context understanding
- ✅ Fast

**Минусы:**
- ❌ Меньше документации по созданию кастомных расширений

---

### 1.5 CrewAI (Tools)

**Философия:** Python-first, class-based tools

**Структура:**
```python
from crewai.tools import BaseTool
from pydantic import BaseModel, Field

class MyToolInput(BaseModel):
    argument: str = Field(..., description="Description")

class MyCustomTool(BaseTool):
    name: str = "tool_name"
    description: str = "What this tool does"
    args_schema: Type[BaseModel] = MyToolInput

    def _run(self, argument: str) -> str:
        return "result"
```

**Плюсы:**
- ✅ **Type safety** - Pydantic validation
- ✅ **Error handling built-in** - все tools имеют error handling
- ✅ **Caching mechanism** - встроенный кэш результатов
- ✅ **Async support** - поддержка async/await
- ✅ **RAG tools** - специализированные tools для поиска (CSV, PDF, JSON, etc.)

**Минусы:**
- ❌ **Python-only** - нет кроссплатформенности
- ❌ **Verbose** - много boilerplate кода

**Best practice:**
> "Don't be afraid to provide detailed descriptions for your functions if an AI is having trouble calling them. Few-shot examples, recommendations for when to use (and not use) the function, and guidance on where to get required parameters can all be helpful." - CrewAI docs

---

### 1.6 LangChain (Tools/Agents)

**Философия:** Modular, chain-based approach

**Структура:**
```python
from langchain.tools import tool

@tool
def my_tool(question: str) -> str:
    """Clear description for what this tool is useful for"""
    return "result"
```

**Плюсы:**
- ✅ **Decorator-based** - минимальный boilerplate
- ✅ **Huge ecosystem** - тысячи интеграций
- ✅ **Standard interface** - единообразие

**Минусы:**
- ❌ **Complexity** - крутая кривая обучения
- ❌ **Overhead** - много абстракций

**Ключевой инсайт:**
> "LangChain provides a pre-built agent architecture and model integrations to help you get started quickly and seamlessly incorporate LLMs into your agents and applications." - LangChain docs

---

### 1.7 Semantic Kernel (Plugins)

**Философия:** Enterprise-grade, dependency injection-first

**Структура:**
```csharp
[KernelFunction("function_name")]
[Description("What this function does")]
public async Task<string> MyFunction(
    [Description("Parameter description")] string param
) {
    return "result";
}
```

**Плюсы:**
- ✅ **Enterprise features** - DI, security, observability
- ✅ **Multi-language** - C#, Python, Java
- ✅ **Plugin composition** - легко комбинировать
- ✅ **Semantic descriptions** - LLM понимает назначение

**Минусы:**
- ❌ **Microsoft-centric** - завязка на экосистему
- ❌ **Heavy** - много зависимостей

**Критически важно:**
> "Since most LLM have been trained with Python for function calling, it's recommended to use **snake_case** for function names and property names even if you're using the C# or Java SDK." - Microsoft Semantic Kernel docs

**OpenAI recommendation:**
> "We recommend that you use **no more than 20 tools** in a single API call. Developers typically see a reduction in the model's ability to select the correct tool once they have between 10-20 tools defined." - OpenAI Function Calling Guide

---

### 1.8 n8n (Community Nodes)

**Философия:** Visual workflow automation, TypeScript nodes

**Структура:**
```typescript
export class MyNode implements INodeType {
    description: INodeTypeDescription = {
        displayName: 'My Node',
        name: 'myNode',
        inputs: ['main'],
        outputs: ['main'],
        properties: [...]
    };

    async execute(this: IExecuteFunctions): Promise<INodeExecutionData[][]> {
        // node logic
    }
}
```

**Плюсы:**
- ✅ **Visual** - drag-and-drop workflow
- ✅ **Community marketplace** - тысячи готовых nodes
- ✅ **Self-hosted** - полный контроль

**Минусы:**
- ❌ **Not AI-native** - ориентирован на automation, не на LLM
- ❌ **Complex SDK** - много boilerplate

---

### 1.9 OpenAI Custom GPTs (Actions)

**Философия:** No-code, OpenAPI schema-driven

**Структура:**
```yaml
openapi: 3.0.0
info:
  title: My API
  version: 1.0.0
paths:
  /action:
    post:
      operationId: doAction
      description: What this action does
      parameters: [...]
```

**Плюсы:**
- ✅ **No-code** - GUI для создания
- ✅ **OpenAPI standard** - переиспользование спек
- ✅ **Built-in auth** - OAuth, API keys

**Минусы:**
- ❌ **OpenAI-only** - нет портативности
- ❌ **Limited customization** - только через schema
- ❌ **Rate limits** - строгие ограничения

---

### 1.10 AutoGPT (Platform Tools)

**Философия:** Autonomous agents, block-based workflows

**Структура:**
- Agent Builder (low-code interface)
- Workflow Management (block connections)
- Marketplace (pre-built agents)

**Плюсы:**
- ✅ **Autonomous** - агенты работают 24/7
- ✅ **Visual builder** - low-code
- ✅ **Marketplace** - готовые агенты

**Минусы:**
- ❌ **Closed platform** - зависимость от AutoGPT
- ❌ **Learning curve** - сложная архитектура

**Ключевая фича:**
> "AutoGPT Platform allows you to create, deploy, and manage continuous AI agents that automate complex workflows." - AutoGPT docs

---

## 2. Best Practices (синтез)

### 🎯 Топ-15 универсальных правил

#### 1. **Progressive Disclosure Pattern**

**Принцип:** Не грузи всё сразу - давай детали по запросу

```markdown
# ❌ ПЛОХО
## Описание
Этот скилл делает A, B, C, D, E... [5000 слов деталей]

# ✅ ХОРОШО  
## Описание
Создаёт посты для Telegram в стиле {{OWNER_NAME}}.

Детали: references/style-guide.md
Примеры: references/examples/
```

**Почему:** Token efficiency + faster processing

**Источник:** OpenClaw Architecture, Anthropic CLAUDE.md guidelines

---

#### 2. **Snake_Case для Function Calling**

**Принцип:** Используй snake_case для имён функций и параметров

```python
# ✅ ХОРОШО
@tool
def get_user_profile(user_id: str) -> dict:
    """Gets user profile by ID"""
    
# ❌ ПЛОХО
@tool  
def GetUserProfile(userId: str) -> dict:
```

**Почему:** LLM обучены на Python-коде, snake_case = лучшее распознавание

**Источник:** Microsoft Semantic Kernel, OpenAI best practices

---

#### 3. **Limit Tools to 10-20 per Request**

**Принцип:** Не более 10-20 tools одновременно

**Стратегия:**
- **Categorize** - группируй по доменам (crm, billing, support)
- **Defer loading** - используй tool_search для редких функций
- **Progressive loading** - загружай по мере необходимости

**Почему:** Accuracy падает с >20 tools

**Источник:** OpenAI Function Calling Guide

**Цитата:**
> "Developers typically see a reduction in the model's ability to select the correct tool once they have between 10-20 tools defined."

---

#### 4. **Descriptive Names > Abbreviations**

**Принцип:** Ясность важнее краткости

```python
# ✅ ХОРОШО
def get_customer_order_history(customer_id: str)

# ❌ ПЛОХО  
def get_cust_ord_hist(cid: str)
```

**Когда НЕ применять:**
- Общепринятые акронимы (API, URL, HTTP)
- Математические обозначения (x, y, z в координатах)

**Источник:** Semantic Kernel, CrewAI docs

---

#### 5. **Error Handling в Descriptions**

**Принцип:** Опиши edge cases в description

```python
@tool
def divide_numbers(a: float, b: float) -> float:
    """Divides a by b.
    
    Edge cases:
    - Returns error if b is 0
    - Rounds to 2 decimal places
    - Handles negative numbers
    """
```

**Почему:** LLM может предвидеть проблемы и обрабатывать заранее

**Источник:** CrewAI, LangChain patterns

---

#### 6. **Caching для Expensive Operations**

**Принцип:** Кэшируй результаты дорогих операций

```python
from functools import lru_cache

@lru_cache(maxsize=128)
def expensive_api_call(query: str) -> dict:
    # кэшируется по query
    return api.fetch(query)
```

**Или через custom cache function (CrewAI):**
```python
def cache_func(args, result):
    # кэшировать только если результат чётный
    return result % 2 == 0

multiplication_tool.cache_function = cache_func
```

**Источник:** CrewAI tools, OpenClaw plugin patterns

---

#### 7. **Local State для Sensitive Data**

**Принцип:** Не передавай sensitive данные туда-сюда через LLM

```python
# ✅ ХОРОШО
session_store = {}

@tool
def process_document(session_id: str) -> str:
    """Processes document stored in session."""
    doc = session_store[session_id]  # данные локально
    return "processed"

# ❌ ПЛОХО
@tool
def process_document(full_document_text: str) -> str:
    """Processes document."""  # весь текст через LLM
```

**Почему:**
- Privacy & security
- Token efficiency
- Faster execution

**Источник:** Microsoft Semantic Kernel best practices

---

#### 8. **Strict Mode для Production**

**Принцип:** Включай strict mode для JSON Schema validation

```json
{
  "type": "function",
  "name": "get_weather",
  "strict": true,
  "parameters": {
    "type": "object",
    "properties": {
      "location": {"type": "string"},
      "units": {"type": ["string", "null"]}
    },
    "required": ["location", "units"],
    "additionalProperties": false
  }
}
```

**Почему:** Гарантирует что LLM вызовет функцию правильно

**Источник:** OpenAI Structured Outputs

---

#### 9. **Single Responsibility per Function**

**Принцип:** Одна функция = одна задача

```python
# ✅ ХОРОШО
def get_user(user_id: str) -> User
def update_user(user_id: str, data: dict) -> User

# ❌ ПЛОХО
def manage_user(user_id: str, action: str, data: dict = None)
```

**Баланс:** Слишком много мелких функций = overhead. Найди баланс.

**Источник:** Semantic Kernel, software engineering principles

---

#### 10. **Examples в Descriptions (осторожно!)**

**Принцип:** Добавляй примеры для сложных функций

```python
@tool
def query_database(sql: str) -> list:
    """Executes SQL query.
    
    Examples:
    - SELECT * FROM users WHERE age > 18
    - UPDATE orders SET status='shipped' WHERE id=123
    
    Note: Only SELECT, UPDATE, DELETE allowed. No DROP/ALTER.
    """
```

**⚠️ Внимание:** Для reasoning models (GPT-5, o4) примеры могут УХУДШИТЬ качество!

**Источник:** OpenAI Function Calling best practices

---

#### 11. **Namespace Grouping для Масштаба**

**Принцип:** Группируй связанные tools в namespaces

```json
{
  "type": "namespace",
  "name": "crm",
  "description": "CRM tools for customer management",
  "tools": [
    {"type": "function", "name": "get_customer"},
    {"type": "function", "name": "list_orders"}
  ]
}
```

**Почему:** LLM легче выбрать правильную группу, потом функцию

**Источник:** OpenAI Function Calling (2026)

---

#### 12. **Async Support где возможно**

**Принцип:** Используй async для I/O операций

```python
# ✅ ХОРОШО
@tool
async def fetch_data(url: str) -> dict:
    """Asynchronously fetch data."""
    async with aiohttp.ClientSession() as session:
        async with session.get(url) as resp:
            return await resp.json()
```

**Почему:** Non-blocking = faster для множественных вызовов

**Источник:** CrewAI async tools, LangChain patterns

---

#### 13. **Return Type Schema в Description**

**Принцип:** Опиши формат возвращаемых данных

```python
@tool
def get_weather(city: str) -> dict:
    """Gets weather for city.
    
    Returns:
    {
        "temp": float,
        "humidity": int,
        "conditions": str
    }
    """
```

**Почему:** LLM знает что ожидать и может использовать результат корректно

**Источник:** Semantic Kernel recommendations

---

#### 14. **Hot-Reload для Dev Experience**

**Принцип:** Поддерживай live reload для быстрой итерации

**OpenClaw подход:**
- Watch SKILL.md files
- Reload within 1-2 seconds
- No restart needed

**Почему:** Faster development loop = better skills

**Источник:** OpenClaw architecture

---

#### 15. **Security-First для Public Skills**

**Принцип:** Аудит перед публикацией

**Checklist:**
- [ ] Нет hardcoded credentials
- [ ] Нет personal data
- [ ] Нет local paths
- [ ] Input validation
- [ ] Rate limiting для API calls
- [ ] Sandbox для code execution

**Статистика:** 12-20% скиллов на ClawHub содержали malicious код (early 2026)

**Источник:** OpenClaw security analysis

---

## 3. Примеры лучших скиллов

### 3.1 Deep Research Pro (OpenClaw)

**Что делает:** Multi-source research с цитатами

**Почему крут:**
- ✅ **Structured workflow** - чёткие steps
- ✅ **Multi-tool orchestration** - web_search + web_fetch
- ✅ **Citation tracking** - все источники сохраняются
- ✅ **Progressive disclosure** - основной алгоритм + детали в references

**Структура:**
```markdown
---
name: deep-research-pro
version: 1.0.0
description: "Multi-source deep research agent"
---

# Workflow
1. Clarify goal (30s questions)
2. Break into sub-questions
3. Multi-source search (15-30 sources)
4. Deep read key sources
5. Synthesize report with citations
```

**Паттерны:**
- **Clarification upfront** - избегает переделок
- **Iteration budget** - явное управление глубиной
- **Source diversity** - academic > official > blogs > forums

---

### 3.2 Copywriter (OpenClaw)

**Что делает:** Пишет в специфичном стиле ({{OWNER_NAME}} {{OWNER_SURNAME}})

**Почему крут:**
- ✅ **Style guide** - детальный портрет стиля
- ✅ **Anti-patterns** - что НЕ использовать (AI-izmы)
- ✅ **Examples** - конкретные посты как референсы
- ✅ **Related skills** - ссылки на смежные скиллы

**Ключевой паттерн - Anti-AI-izmы:**
```markdown
## ЗАПРЕЩЕНО использовать:
- "стоит отметить"
- "важно понимать"  
- "более того"
- "является"
- "обеспечивает"
```

**Почему работает:** Explicit negatives лучше чем implicit positives

---

### 3.3 LightsPlugin (Semantic Kernel Example)

**Что делает:** Управление умными лампочками

**Код:**
```csharp
[KernelFunction("get_lights")]
[Description("Gets a list of lights and their current state")]
public async Task<List<LightModel>> GetLightsAsync()

[KernelFunction("change_state")]
[Description("Changes the state of the light")]
public async Task<LightModel?> ChangeStateAsync(int id, LightModel model)
```

**Почему крут:**
- ✅ **Clear separation** - get vs change
- ✅ **Type safety** - LightModel с JSON properties
- ✅ **Descriptive names** - self-documenting
- ✅ **Real data model** - не mock, реальная структура

---

### 3.4 Obsidian MCP Server

**GitHub:** cyanheads/obsidian-mcp-server (387 stars)

**Что делает:** Мост между AI агентами и Obsidian vault

**Архитектура:**
```
AI Agent → MCP Protocol → Obsidian Local REST API → Vault
```

**Фичи:**
- Reading/writing notes
- Tag management
- Frontmatter manipulation
- Search across vault

**Почему крут:**
- ✅ **Standard protocol** - MCP (Model Context Protocol)
- ✅ **Clean abstraction** - агент не знает про Obsidian API
- ✅ **Comprehensive** - full CRUD для notes

**Паттерн:** Gateway между AI и existing tool

---

### 3.5 Claude-Mem Plugin

**GitHub:** thedotmack/claude-mem (33K+ stars)

**Что делает:** Автоматическая память для Claude Code sessions

**Workflow:**
1. Captures всё что делает Claude
2. Compresses с AI (agent-sdk)
3. Injects relevant context в future sessions

**Почему крут:**
- ✅ **Zero-effort** - автоматически
- ✅ **Smart compression** - AI-driven summarization
- ✅ **Context injection** - только релевантное

**Паттерн:** Automated context management

---

### 3.6 Uniswap AI Tools

**GitHub:** Uniswap/uniswap-ai (156 stars)

**Что делает:** Skills для работы с Uniswap protocol

**Фичи:**
- Swap tokens
- Check liquidity
- Read pool data
- Transaction history

**Почему крут:**
- ✅ **Domain-specific** - заточен под DeFi
- ✅ **Web3 integration** - работа с blockchain
- ✅ **Safety first** - transaction simulation перед отправкой

**Паттерн:** Domain expert skill

---

### 3.7 Agent Council (Multi-Agent)

**GitHub:** team-attention/agent-council (114 stars)

**Что делает:** Оркестрация нескольких AI агентов

**Workflow:**
```
User Question 
  ↓
Council Coordinator
  ↓
├─ Codex CLI (coding perspective)
├─ Gemini CLI (creative perspective)  
└─ Custom Agent (domain expert)
  ↓
Synthesize Responses
```

**Почему крут:**
- ✅ **Diverse perspectives** - разные LLM = разные подходы
- ✅ **Voting/consensus** - агрегация мнений
- ✅ **Plugin architecture** - легко добавить агентов

**Паттерн:** Multi-agent collaboration

---

## 4. Anti-patterns

### ❌ 1. **Bloated Skill Problem**

**Что:** Один скилл пытается делать всё

**Пример:**
```markdown
# Marketing Mega Skill
- SEO optimization
- Content writing
- Social media posts
- Email campaigns  
- Analytics
- Ads management
... [ещё 15 функций]
```

**Почему плохо:**
- Перегружает context window
- LLM путается когда использовать
- Сложно поддерживать

**Решение:** Разбей на focused skills (seo-skill, copywriter-skill, etc.)

**Источник:** OpenClaw skill patterns

---

### ❌ 2. **Under-Documentation**

**Что:** Минималистичное описание без деталей

**Пример:**
```python
@tool
def process(data: str) -> str:
    """Processes data."""  # ЧТО ИМЕННО?!
```

**Почему плохо:** LLM не знает когда и как использовать

**Решение:** 
```python
@tool
def normalize_phone_number(phone: str) -> str:
    """Converts phone to E.164 format (+1234567890).
    
    Handles: US, UK, EU formats
    Returns: +[country code][number] or error
    Example: "555-1234" → "+15551234"
    """
```

---

### ❌ 3. **Over-Engineering**

**Что:** Слишком много абстракций и параметров

**Пример:**
```python
@tool
def execute_action(
    action_type: str,  # 20+ возможных значений
    entity: str,
    operation: str,
    mode: str,
    options: dict,
    flags: list,
    ...
) -> dict:
```

**Почему плохо:** LLM не может корректно заполнить 10+ параметров

**Решение:** Специализированные функции
```python
@tool
def create_user(name: str, email: str) -> dict

@tool  
def delete_user(user_id: str) -> bool
```

**Правило:** <5 параметров на функцию (идеал: 2-3)

**Источник:** Semantic Kernel best practices

---

### ❌ 4. **No Error Messages**

**Что:** Функция падает без объяснений

**Пример:**
```python
@tool
def get_user(user_id: str) -> dict:
    return db.users[user_id]  # KeyError если нет
```

**Решение:**
```python
@tool
def get_user(user_id: str) -> dict:
    """Gets user by ID.
    
    Returns: User dict or {"error": "User not found"}
    """
    try:
        return db.users[user_id]
    except KeyError:
        return {"error": f"User {user_id} not found"}
```

**Почему важно:** LLM может обработать ошибку и попробовать альтернативу

---

### ❌ 5. **Ignoring Token Costs**

**Что:** Грузишь огромные descriptions и examples в каждый запрос

**Пример:**
```python
@tool
def analyze(text: str) -> dict:
    """Analyzes text... [5000 слов примеров и edge cases]"""
```

**Цена:** Каждый tool definition = input tokens = $$$

**Решение:**
- Core description: краткая (2-3 предложения)
- Детали: в system prompt или отдельном doc
- Progressive disclosure: load detailed docs только when needed

**Источник:** OpenAI token optimization guide

---

### ❌ 6. **Parallel Calls Chaos**

**Что:** Не учитываешь что LLM может вызвать несколько tools одновременно

**Пример:**
```python
# Shared state без thread safety
counter = 0

@tool
def increment() -> int:
    global counter
    counter += 1  # Race condition!
    return counter
```

**Решение:**
- Используй thread-safe structures
- Или отключи parallel calls: `parallel_tool_calls=false`

**Источник:** OpenAI parallel function calling

---

### ❌ 7. **Hard-Coded Assumptions**

**Что:** Предполагаешь что знаешь context пользователя

**Пример:**
```python
@tool
def send_email(body: str) -> str:
    """Sends email."""
    send_to("boss@company.com", body)  # КТО boss?!
```

**Решение:**
```python
@tool
def send_email(to: str, subject: str, body: str) -> str:
    """Sends email to specified recipient."""
```

**Правило:** Make invalid states unrepresentable

---

### ❌ 8. **No Validation**

**Что:** Принимаешь любой input без проверки

**Пример:**
```python
@tool
def divide(a: float, b: float) -> float:
    return a / b  # Division by zero!
```

**Решение:**
```python
@tool  
def divide(a: float, b: float) -> float:
    """Divides a by b. Returns error if b is 0."""
    if b == 0:
        raise ValueError("Cannot divide by zero")
    return a / b
```

---

## 5. Agent Architecture Patterns

### 5.1 Single-Agent Pattern

**Когда:** Простые задачи, один домен

```
User → Agent → Tools → Response
```

**Пример:** ChatGPT с plugins

**Плюсы:**
- Простота
- Быстрая разработка
- Легко дебажить

**Минусы:**
- Ограниченная экспертиза
- Сложно масштабировать

---

### 5.2 Coordinator-Specialist Pattern

**Когда:** Разные домены, нужна экспертиза

```
User → Coordinator Agent
          ↓
    ┌─────┼─────┐
    ↓     ↓     ↓
  Code  Research Design
Specialist Specialist Specialist
```

**Пример:** AutoGPT Platform, CrewAI

**Плюсы:**
- Специализация = quality
- Параллельная работа
- Масштабируемость

**Минусы:**
- Сложная оркестрация
- Overhead на координацию

**Best practice:**
- Coordinator не должен иметь domain knowledge
- Specialists изолированы друг от друга
- Coordinator aggregates результаты

**Источник:** CrewAI architecture, Agent Council pattern

---

### 5.3 Sequential Chain Pattern

**Когда:** Задачи с чёткими этапами

```
User → Agent 1 (Research)
         ↓
       Agent 2 (Analysis)
         ↓
       Agent 3 (Writing)
         ↓
       Final Output
```

**Пример:** LangChain Sequential Chains

**Плюсы:**
- Предсказуемость
- Легко отладить
- Промежуточные результаты

**Минусы:**
- Нет гибкости
- Не работает для non-linear задач

---

### 5.4 Swarm Pattern

**Когда:** Нужен consensus или diverse perspectives

```
        User Question
             ↓
    ┌────────┼────────┐
    ↓        ↓        ↓
  Agent 1  Agent 2  Agent 3
    (GPT-4)  (Claude) (Gemini)
    ↓        ↓        ↓
    └────────┼────────┘
             ↓
       Vote/Aggregate
```

**Пример:** Agent Council, multi-model reasoning

**Плюсы:**
- Robustness (если один агент ошибся)
- Diverse solutions
- Better decisions

**Минусы:**
- Expensive (multiple LLM calls)
- Slower
- Нужен aggregation mechanism

---

### 5.5 Memory-Sharing Patterns

#### A. **Shared Memory** (Centralized)

```
Memory DB ←→ Agent 1
    ↑         Agent 2
    └────────→ Agent 3
```

**Плюсы:** Consistency, easy coordination
**Минусы:** Contention, security risks

#### B. **Isolated Memory** (Decentralized)

```
Agent 1 ←→ Memory 1
Agent 2 ←→ Memory 2  
Agent 3 ←→ Memory 3
```

**Плюсы:** Security, parallel work
**Минусы:** No knowledge sharing

#### C. **Hybrid** (Best of both)

```
Agent 1 ←→ Private Memory 1
    ↓           ↓
Shared Context Store (read-only snapshots)
```

**Рекомендация:** OpenClaw подход
- Core memory (long-term facts) - shared
- Daily notes - isolated per agent
- Session memory - optional per agent

**Источник:** OpenClaw sessionMemory architecture

---

### 5.6 Tool Permission Patterns

#### Level 1: **Unrestricted** (Development)
```json
{
  "tools": {
    "deny": []
  }
}
```

#### Level 2: **Restricted** (Production)
```json
{
  "tools": {
    "deny": ["exec", "gateway", "cron"],
    "allow": ["web_search", "memory_search"]
  }
}
```

#### Level 3: **Approval Required** (Sensitive)
```json
{
  "tools": {
    "approval_required": ["send_email", "delete_file"]
  }
}
```

**Best practice:**
- **Never** дать exec доступ публичным агентам
- **Always** require approval для destructive actions
- **Default deny** для production

**Источник:** OpenClaw security patterns, Semantic Kernel recommendations

---

### 5.7 Agent Lifecycle Management

**States:**
```
Created → Initialized → Active → Paused → Terminated
```

**Triggers:**
- **Created:** конфиг добавлен
- **Initialized:** первый запуск, tools loaded
- **Active:** обрабатывает requests
- **Paused:** временная остановка (maintenance)
- **Terminated:** удалён или crashed

**Monitoring:**
- Health checks (каждые 2 мин)
- Token usage tracking
- Error rate monitoring
- Response time metrics

**Источник:** OpenClaw watchdog patterns

---

## 6. Рекомендации для нашего скилла

### 6.1 Архитектурные улучшения

#### A. **Multi-tier Skill Structure**

Текущая структура:
```
SKILL.md (всё в одном файле)
```

Рекомендуемая:
```
skills/<name>/
├── SKILL.md              # Core (100-300 строк)
├── SKILL-public.md       # Публичная версия
├── references/
│   ├── detailed-guide.md # Детали
│   ├── examples/         # Примеры
│   └── api-reference.md  # Если есть API
├── scripts/
│   └── helper.py         # Вспомогательные скрипты
├── data/                 # Данные скилла (НЕ в memory/)
└── tests/
    └── test_skill.sh     # Тесты
```

**Почему:**
- Progressive disclosure
- Token efficiency
- Easier maintenance
- Security (public version отдельно)

---

#### B. **Skill Metadata Standard**

Добавить в YAML frontmatter:
```yaml
---
name: skill-name
version: 2.0.0
description: "One-line description with triggers"
category: research|content|automation|...
dependencies:
  - web_search
  - memory_search
tools_required:
  - python3
  - curl
min_context_window: 32000
estimated_tokens: 800
related_skills:
  - skill-a: "use case"
  - skill-b: "use case"
security_level: public|internal|sensitive
last_updated: 2026-03-07
---
```

**Почему:**
- Automatic compatibility checks
- Dependency management
- Token budgeting
- Skill discovery

---

#### C. **Skill Testing Framework**

Создать `tests/` для каждого скилла:

```bash
#!/bin/bash
# tests/test_deep-research.sh

echo "Testing Deep Research Pro..."

# Test 1: Basic workflow
echo "1. Testing basic research flow"
result=$(invoke_skill "research topic: AI agents")
assert_contains "$result" "citations"

# Test 2: Multi-source
echo "2. Testing multi-source aggregation"
result=$(invoke_skill "research with 10+ sources")
count_sources "$result"
assert_greater_than "$sources" 10

# Test 3: Edge case
echo "3. Testing unavailable sources handling"
result=$(invoke_skill "research obscure topic xyz123")
assert_no_errors "$result"
```

**CI Integration:**
```yaml
# .github/workflows/test-skills.yml
on: [push]
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - name: Test all skills
        run: |
          for test in skills/*/tests/*.sh; do
            bash "$test" || exit 1
          done
```

---

#### D. **Skill Versioning & Changelog**

Каждый скилл:
```markdown
# CHANGELOG.md

## [2.0.0] - 2026-03-07
### Added
- Multi-source aggregation
- Citation tracking
### Changed  
- Improved prompts for better accuracy
### Fixed
- Edge case with empty results

## [1.0.0] - 2026-02-01
- Initial release
```

**Semantic Versioning:**
- **Major (2.0.0):** Breaking changes в API/interface
- **Minor (1.1.0):** New features, backwards compatible
- **Patch (1.0.1):** Bug fixes

---

### 6.2 Workflow Improvements

#### A. **Skill Creation Wizard**

```bash
$ openclaw skill create
? Skill name: my-awesome-skill
? Category: [research/content/automation/...]: content
? Public or internal? internal
? Dependencies (comma-separated): web_search, memory_search
? Tools required: python3, curl

Creating skill structure...
✓ skills/my-awesome-skill/SKILL.md
✓ skills/my-awesome-skill/references/
✓ skills/my-awesome-skill/data/
✓ skills/my-awesome-skill/tests/

Next steps:
1. Edit SKILL.md - add your logic
2. Add examples to references/examples/
3. Write tests in tests/test_skill.sh
4. Test: openclaw skill test my-awesome-skill
5. Publish: openclaw skill publish my-awesome-skill
```

---

#### B. **Automated Security Audit**

```bash
$ openclaw skill audit my-skill

Running security checks...
✓ No hardcoded credentials
✓ No personal data (names, emails, addresses)
✗ Found local paths: /Users/{{OWNER_USERNAME}}/...
✗ Found internal references: WORKSPACE

Recommendations:
- Replace local paths with variables
- Remove internal project names
- Add to .gitignore: data/*.json

Audit score: 7/10 (Good but needs fixes)
```

---

#### C. **Skill Linter**

```bash
$ openclaw skill lint my-skill

Checking SKILL.md...
✓ YAML frontmatter present
✓ Version follows semver
✗ Description too long (>200 chars)
✗ No examples found in references/
✓ Token estimate: 650 (target: <1000)

Checking scripts...
✓ All scripts have shebangs
✗ helper.py missing docstrings

Lint score: 6/8
```

---

### 6.3 Documentation Improvements

#### A. **Skill Template Library**

Создать templates для типовых скиллов:

```
templates/
├── research-skill/
│   └── SKILL.md (базовая структура для research)
├── content-skill/
│   └── SKILL.md (базовая структура для content)
├── automation-skill/
│   └── SKILL.md (базовая структура для automation)
└── api-integration-skill/
    └── SKILL.md
```

**Usage:**
```bash
$ openclaw skill create --template research-skill
```

---

#### B. **Best Practices Guide**

Создать `skills/skill-and-agent-creator/references/best-practices-guide.md`:

```markdown
# Skill Creation Best Practices

## 1. Planning Phase
- [ ] Define clear triggers
- [ ] List dependencies
- [ ] Estimate token usage
- [ ] Security considerations

## 2. Development Phase
- [ ] Start with template
- [ ] Write core logic first
- [ ] Add examples
- [ ] Test edge cases

## 3. Documentation Phase
- [ ] Update CHANGELOG
- [ ] Add README if complex
- [ ] Create public version if needed

## 4. Publishing Phase
- [ ] Run security audit
- [ ] Run linter
- [ ] Test in production-like environment
- [ ] Version bump
```

---

### 6.4 Integration Improvements

#### A. **Skill Marketplace Integration**

Подготовка для ClawHub:

```yaml
# skills/my-skill/clawhub.yml
name: my-awesome-skill
display_name: My Awesome Skill
author: {{OWNER_USERNAME}}
category: research
tags: [ai, research, deep-dive]
license: MIT
min_openclaw_version: 1.5.0
verified: false
downloads: 0
rating: 0.0
```

---

#### B. **Plugin → Skill Converter**

Для конвертации существующих plugins в skills:

```bash
$ openclaw skill convert-plugin @openclaw/my-plugin

Converting plugin to skill...
✓ Extracted description from plugin.json
✓ Generated SKILL.md from plugin docs
✓ Moved scripts to scripts/
⚠ Manual review needed for:
  - Tool permissions
  - Environment variables

Conversion complete: skills/my-plugin-skill/
```

---

### 6.5 Advanced Features

#### A. **Skill Composition**

Позволить skills использовать другие skills:

```yaml
# SKILL.md frontmatter
uses:
  - deep-research-pro: "for gathering information"
  - copywriter: "for writing final output"
```

**Workflow:**
```markdown
## Algorithm

1. Call `deep-research-pro` to gather facts
2. Extract key findings
3. Call `copywriter` to format as blog post
4. Return final result
```

---

#### B. **Conditional Skill Loading**

```yaml
# SKILL.md
load_if:
  - model: "opus"        # Только для Opus
  - context_size: >32000 # Только если большой контекст
  - tools: ["web_search"] # Только если web_search доступен
```

---

#### C. **Skill Analytics**

Track usage metrics:
```json
{
  "skill": "deep-research-pro",
  "usage": {
    "total_invocations": 1523,
    "avg_tokens": 850,
    "success_rate": 0.94,
    "avg_duration_ms": 4500
  },
  "errors": [
    {"type": "timeout", "count": 12},
    {"type": "rate_limit", "count": 3}
  ]
}
```

**Dashboard:**
```bash
$ openclaw skill stats

Top Skills by Usage:
1. deep-research-pro    1523 calls  94% success
2. copywriter           892 calls   98% success
3. youtube-seo          456 calls   91% success

Most Efficient (tokens/call):
1. subscriber-support   120 tokens
2. copywriter          340 tokens
3. deep-research-pro   850 tokens
```

---

## Источники

### Платформы и документации

1. **OpenClaw**
   - https://www.aitoolskit.io/agents/openclaw-plugins-extensions-guide-2026
   - https://medium.com/@dingzhanjun/deep-dive-into-openclaw-architecture
   - https://hackernoon.com/the-next-trillion-dollar-ai-shift-why-openclaw-changes-everything

2. **Anthropic / Claude**
   - Claude API docs (prompt engineering)
   - CLAUDE.md best practices

3. **Cursor**
   - https://github.com/cursor/cursor
   - .cursorrules documentation

4. **CrewAI**
   - https://docs.crewai.com/concepts/tools
   - CrewAI Tools GitHub

5. **LangChain**
   - https://docs.langchain.com/oss/python/langchain/overview
   - LangChain Tools documentation

6. **Microsoft Semantic Kernel**
   - https://learn.microsoft.com/en-us/semantic-kernel/concepts/plugins/
   - Function Calling best practices

7. **OpenAI**
   - https://developers.openai.com/api/docs/guides/function-calling
   - Structured Outputs guide
   - Tool Search documentation

8. **n8n**
   - https://docs.n8n.io/integrations/creating-nodes/overview/

9. **AutoGPT**
   - https://github.com/Significant-Gravitas/AutoGPT
   - Platform documentation

### GitHub репозитории (исследованные)

10. **thedotmack/claude-mem** - AI memory plugin (33K stars)
11. **elizaOS/eliza** - Autonomous agents (17K stars)
12. **cyanheads/obsidian-mcp-server** - MCP server для Obsidian (387 stars)
13. **team-attention/agent-council** - Multi-agent collaboration (114 stars)
14. **Uniswap/uniswap-ai** - DeFi AI tools (156 stars)
15. **f/prompts.chat** - Largest open-source prompt library (143K stars)
16. **dontriskit/awesome-ai-system-prompts** - System prompts collection
17. **EliFuzz/awesome-system-prompts** - AI coding agents prompts

### Community Resources

18. **Reddit**
    - r/ChatGPT
    - r/LocalLLaMA
    - r/ClaudeAI
    - r/OpenAI

19. **Hugging Face**
    - https://huggingface.co/datasets/fka/prompts.chat

20. **DeepWiki**
    - https://deepwiki.com/f/prompts.chat

### Research Papers & Articles

21. **Forbes** - ChatGPT Success & Prompts (https://www.forbes.com/sites/tjmccue/2023/01/19/chatgpt-success-completely-depends-on-your-prompt/)
22. **Harvard** - AI Prompts Guide (https://www.huit.harvard.edu/news/ai-prompts)
23. **Columbia** - Prompt Library for Academic Use (https://etc.cuit.columbia.edu/news/columbia-prompt-library-effective-academic-ai-use)
24. **Google Scholar** - 40+ academic citations на prompts.chat
25. **GitHub Spotlights** - prompts.chat Staff Pick

### Локальные примеры (workspace)

26. `{{WORKSPACE_PATH}}/skills/deep-research-pro/`
27. `{{WORKSPACE_PATH}}/skills/copywriter/`
28. `{{WORKSPACE_PATH}}/skills/skill-and-agent-creator/`
29. 45 других скиллов в локальной библиотеке

---

## Итоговые выводы

### Ключевые тренды 2025-2026

1. **Natural Language First** - скиллы становятся всё более declarative
2. **Security Focus** - после early 2026 incidents, безопасность = приоритет
3. **Token Efficiency** - progressive disclosure wins
4. **Multi-Agent Collaboration** - swarm/coordinator patterns набирают популярность
5. **Standard Protocols** - MCP, OpenAPI, Function Calling standardization

### Универсальные принципы

- **Clarity > Brevity** - ясность важнее краткости
- **Examples > Theory** - практические примеры лучше абстрактных описаний
- **Progressive Disclosure** - детали по запросу, не всё сразу
- **Security by Default** - безопасность с первого дня
- **Measure Everything** - analytics для continuous improvement

### Будущее (прогноз)

- **AI Skill Generators** - AI будет создавать скиллы для AI
- **Skill Marketplaces** - рост экосистем типа ClawHub
- **Cross-Platform Skills** - унификация между платформами
- **Automated Testing** - CI/CD для скиллов станет стандартом
- **Skill Composition** - комбинирование скиллов как LEGO

---

## 📋 Quick Reference Card

### ✅ DO (Checklist для каждого скилла)

- [ ] **Clear name** - описательное имя, snake_case для функций
- [ ] **Concise description** - 1-2 предложения + triggers
- [ ] **Progressive disclosure** - core <300 строк, детали в references/
- [ ] **Examples included** - 2-3 реалистичных примера
- [ ] **Error handling** - описать edge cases
- [ ] **Type hints** - для параметров (если код)
- [ ] **Token budget** - aim for <1000 tokens
- [ ] **Security audit** - no credentials, no personal data
- [ ] **Tests written** - хотя бы базовый smoke test
- [ ] **Documentation** - CHANGELOG, README если сложный

### ❌ DON'T (Избегай этого)

- ❌ **Bloated skills** - не пытайся делать всё в одном скилле
- ❌ **Vague descriptions** - "processes data" = бесполезно
- ❌ **>20 tools** - точность падает
- ❌ **CamelCase** - используй snake_case для function calling
- ❌ **Hard-coded values** - делай параметризируемым
- ❌ **No validation** - всегда валидируй input
- ❌ **Ignoring tokens** - каждый symbol = cost
- ❌ **Skipping tests** - сломается в production

### 🎯 Golden Ratio (идеальные пропорции)

```
SKILL.md core:        100-300 строк
References:           unlimited (progressive disclosure)
Parameters per func:  2-5 (идеал: 2-3)
Tools per agent:      5-15 (макс 20)
Token budget:         <1000 tokens
Examples:             2-3 конкретных
Update frequency:     patch every 2 weeks, minor every month
```

### 🔧 Tools & Commands

```bash
# Создание
openclaw skill create my-skill --template research

# Проверка
openclaw skill lint my-skill
openclaw skill audit my-skill --security

# Тестирование
openclaw skill test my-skill

# Публикация
openclaw skill publish my-skill --public
```

### 📚 Further Reading

- **OpenAI Function Calling:** https://developers.openai.com/api/docs/guides/function-calling
- **CrewAI Tools:** https://docs.crewai.com/concepts/tools
- **Semantic Kernel Plugins:** https://learn.microsoft.com/en-us/semantic-kernel/concepts/plugins/
- **LangChain Agents:** https://docs.langchain.com/oss/python/langchain/overview
- **Prompts.chat Library:** https://prompts.chat (143K stars)
- **OpenClaw Skills:** https://clawhub.com

---

**Конец отчёта**

*Подготовлено: 07.03.2026*  
*Версия: 1.0.0*  
*Следующее обновление: июнь 2026*

---

## Как использовать этот отчёт

### Для создания нового скилла:
1. Прочитай [Best Practices](#2-best-practices-синтез) (топ-15)
2. Изучи [Примеры](#3-примеры-лучших-скиллов) похожих скиллов
3. Используй [Quick Reference Card](#-quick-reference-card)
4. Запусти через checklist

### Для улучшения существующего:
1. Проверь по [Anti-patterns](#4-anti-patterns)
2. Примени [Рекомендации](#6-рекомендации-для-нашего-скилла)
3. Добавь тесты и документацию

### Для дизайна агента:
1. Выбери [Architecture Pattern](#5-agent-architecture-patterns)
2. Определи tool permissions
3. Настрой memory strategy (shared/isolated/hybrid)
4. Имплементируй lifecycle management
