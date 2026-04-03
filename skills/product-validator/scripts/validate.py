#!/usr/bin/env python3
"""
Валидатор продуктов Team Lead.
Проверяет скиллы, материалы для группы и GitHub-проекты
перед передачей на ревью {{AGENT_NICKNAME}}.

Использование:
  python3 validate.py <путь_к_папке> [--type skill|material|github] [--fix]

Без --type автоматически определяет тип по содержимому.
С --fix автоматически исправляет тире на дефис.
"""

import argparse
import os
import re
import sys
import yaml


# ============================================================
# Цвета
# ============================================================
RED = "\033[91m"
GREEN = "\033[92m"
YELLOW = "\033[93m"
BLUE = "\033[94m"
RESET = "\033[0m"
BOLD = "\033[1m"


def ok(msg):
    print(f"  {GREEN}✅{RESET} {msg}")


def warn(msg):
    print(f"  {YELLOW}⚠️{RESET}  {msg}")


def fail(msg):
    print(f"  {RED}❌{RESET} {msg}")


def info(msg):
    print(f"  {BLUE}ℹ️{RESET}  {msg}")


# ============================================================
# Security patterns
# ============================================================
SECURITY_PATTERNS = [
    # Имена и ники
    (r"{{OWNER_NAME}}|{{OWNER_SURNAME}}|{{OWNER_USERNAME}}", "Имя владельца"),
    (r"{{FAMILY_MEMBER_1}}|{{FAMILY_MEMBER_2}}|{{PET_NAME}}", "Имя члена семьи / питомца"),
    (r"{{TELEGRAM_CHANNEL}}|{{OWNER_USERNAME}}", "Ник владельца"),
    # ID
    (r"{{OWNER_TELEGRAM_ID}}|{{SECOND_USER_TELEGRAM_ID}}", "Telegram ID"),
    (r"-100164451720[0-9]|-100386447911[0-9]|-100387762937[0-9]", "Chat ID"),
    # Внутренние имена
    (r"краб(?!ов)|кайдзен|kaizen|спрут", "Внутреннее имя агента"),
    # Локации
    (r"{{CITY}}|{{DISTRICT}}|{{COUNTRY}}|{{HOMETOWN}}|{{BIRTH_CITY}}", "Геолокация"),
    # Деньги
    (r"\$3,?000|\$10,?000|\$40K|\$200/мес", "Финансовые данные"),
    (r"tribute|claude\.max", "Платформа/подписка"),
    # Пути
    (r"{{LOCAL_PATH}}", "Локальный путь"),
    # Порты
    (r"1878[0-9]|1879[0-9]", "Порт gateway"),
    # Телефоны
    (r"\+995|\+7\d{10}", "Телефон"),
    # Другое
    (r"{{INTERNAL_ID_1}}|{{INTERNAL_ID_2}}", "Внутренний идентификатор"),
]

TOKEN_PATTERNS = [
    (r"sk-[a-zA-Z0-9]{20,}", "API ключ (OpenAI/Anthropic)"),
    (r"ghp_[a-zA-Z0-9]{30,}", "GitHub Personal Access Token"),
    (r"gho_[a-zA-Z0-9]{30,}", "GitHub OAuth Token"),
    (r"xai-[a-zA-Z0-9]{20,}", "xAI ключ"),
    (r"AIzaSy[a-zA-Z0-9_-]{30,}", "Google API ключ"),
    (r"\d+:AA[A-Za-z0-9_-]{30,}", "Telegram Bot Token"),
]

# ============================================================
# Стиль
# ============================================================
CANCEL_WORDS = [
    "осуществить", "осуществляется", "осуществлять",
    "является", "являются",
    "данный", "данная", "данное", "данные",
    "в рамках", "в целях",
    "вышеуказанный", "нижеследующий",
    "надлежащим образом",
    "на сегодняшний день",
    "в настоящее время",
]

EM_DASH = "\u2014"  # —
EN_DASH = "\u2013"  # –


# ============================================================
# Helpers
# ============================================================
def collect_files(path, extensions=None):
    """Собрать все файлы рекурсивно."""
    if extensions is None:
        extensions = {".md", ".py", ".sh", ".json", ".js", ".yaml", ".yml", ".txt"}
    result = []
    for root, dirs, files in os.walk(path):
        dirs[:] = [d for d in dirs if d not in {".git", "node_modules", "__pycache__"}]
        for f in files:
            _, ext = os.path.splitext(f)
            if ext.lower() in extensions:
                result.append(os.path.join(root, f))
    return result


def read_file(path):
    try:
        with open(path, "r", encoding="utf-8") as fh:
            return fh.read()
    except Exception:
        return None


def detect_type(path):
    """Автоопределение типа продукта."""
    files = os.listdir(path)
    if "SKILL.md" in files:
        return "skill"
    if any(f.startswith("AI-OPS-") for f in files):
        return "material"
    if "README.md" in files or ".git" in files:
        return "github"
    return "unknown"


def parse_frontmatter(content):
    """Извлечь YAML frontmatter из MD файла."""
    if not content.startswith("---"):
        return None
    end = content.find("---", 3)
    if end == -1:
        return None
    try:
        return yaml.safe_load(content[3:end])
    except Exception:
        return None


# ============================================================
# Проверки
# ============================================================
class ValidationResult:
    def __init__(self):
        self.errors = 0
        self.warnings = 0
        self.passed = 0

    def error(self, msg):
        fail(msg)
        self.errors += 1

    def warning(self, msg):
        warn(msg)
        self.warnings += 1

    def success(self, msg):
        ok(msg)
        self.passed += 1

    def summary(self):
        total = self.errors + self.warnings + self.passed
        print(f"\n{BOLD}{'=' * 50}{RESET}")
        if self.errors == 0:
            print(f"{GREEN}{BOLD}РЕЗУЛЬТАТ: ПРОЙДЕНО{RESET}")
        else:
            print(f"{RED}{BOLD}РЕЗУЛЬТАТ: НАЙДЕНЫ ПРОБЛЕМЫ{RESET}")
        print(f"  Проверок: {total}")
        print(f"  {GREEN}Пройдено: {self.passed}{RESET}")
        print(f"  {YELLOW}Предупреждений: {self.warnings}{RESET}")
        print(f"  {RED}Ошибок: {self.errors}{RESET}")
        print(f"{BOLD}{'=' * 50}{RESET}")
        return self.errors == 0


def check_security(files, result):
    """Проверка безопасности - личные данные и токены."""
    print(f"\n{BOLD}🛡️  БЕЗОПАСНОСТЬ{RESET}")

    found_any = False
    for fpath in files:
        content = read_file(fpath)
        if not content:
            continue
        fname = os.path.basename(fpath)

        for pattern, label in SECURITY_PATTERNS:
            matches = re.findall(pattern, content, re.IGNORECASE)
            if matches:
                # Исключаем плейсхолдеры и примеры
                real = [m for m in matches if m.lower() not in {
                    "your_", "example", "placeholder", "you@",
                }]
                if real:
                    result.error(f"{fname}: {label} → {real[:3]}")
                    found_any = True

        for pattern, label in TOKEN_PATTERNS:
            if re.search(pattern, content):
                result.error(f"{fname}: {label} найден!")
                found_any = True

    if not found_any:
        result.success("Личных данных и токенов не найдено")


def check_paths(files, result):
    """Проверка абсолютных путей."""
    print(f"\n{BOLD}📁 ПУТИ{RESET}")

    found = False
    for fpath in files:
        content = read_file(fpath)
        if not content:
            continue
        fname = os.path.basename(fpath)

        # Абсолютные пути к домашним директориям
        abs_paths = re.findall(r"/Users/[a-zA-Z]+/|/home/[a-zA-Z]+/|/root/", content)
        # Исключаем шаблонные примеры
        real_paths = [p for p in abs_paths if "example" not in p.lower()]
        if real_paths:
            result.error(f"{fname}: Абсолютные пути → {list(set(real_paths))[:3]}")
            found = True

    if not found:
        result.success("Абсолютных путей не найдено")


def check_style(files, result, fix=False):
    """Проверка стиля текста."""
    print(f"\n{BOLD}✍️  СТИЛЬ{RESET}")

    md_files = [f for f in files if f.endswith(".md")]
    dash_count = 0
    cancel_count = 0
    fixes_applied = 0

    for fpath in md_files:
        content = read_file(fpath)
        if not content:
            continue
        fname = os.path.basename(fpath)

        # Длинное тире
        em_count = content.count(EM_DASH)
        en_count = content.count(EN_DASH)
        if em_count + en_count > 0:
            dash_count += em_count + en_count
            result.error(
                f"{fname}: Длинное/среднее тире ({em_count + en_count} шт.) "
                f"- заменить на дефис (-)"
            )
            if fix:
                new_content = content.replace(EM_DASH, "-").replace(EN_DASH, "-")
                with open(fpath, "w", encoding="utf-8") as fh:
                    fh.write(new_content)
                fixes_applied += em_count + en_count
                info(f"  → Исправлено {em_count + en_count} тире в {fname}")

        # Канцелярит (исключаем строки-примеры "чего НЕ писать")
        for word in CANCEL_WORDS:
            matches = 0
            for line in content.split("\n"):
                if re.search(r"\b" + word + r"\b", line, re.IGNORECASE):
                    # Пропускаем строки которые явно перечисляют запрещённые слова
                    if any(x in line.lower() for x in [
                        "нет слов", "не писать", "не использ", "запрещён",
                        "канцелярит", "не \"", "не «",
                    ]):
                        continue
                    matches += 1
            if matches > 0:
                cancel_count += matches
                result.warning(f"{fname}: Канцелярит «{word}» ({matches} раз)")

    if dash_count == 0:
        result.success("Длинных тире нет - везде дефис")
    if cancel_count == 0:
        result.success("Канцелярита не обнаружено")
    if fix and fixes_applied > 0:
        info(f"Всего исправлено тире: {fixes_applied}")


def check_skill_specific(path, result):
    """Проверки специфичные для скиллов."""
    print(f"\n{BOLD}🔧 СКИЛЛ{RESET}")

    skill_path = os.path.join(path, "SKILL.md")
    if not os.path.exists(skill_path):
        result.error("SKILL.md не найден")
        return

    content = read_file(skill_path)

    # Frontmatter
    fm = parse_frontmatter(content)
    if fm is None:
        result.error("YAML frontmatter отсутствует или невалиден")
        return

    if "name" not in fm:
        result.error("Frontmatter: поле 'name' отсутствует")
    else:
        result.success(f"Frontmatter name: {fm['name']}")

    if "description" not in fm:
        result.error("Frontmatter: поле 'description' отсутствует")
    else:
        desc = fm["description"]
        if len(desc) < 30:
            result.warning(f"Description слишком короткий ({len(desc)} символов)")
        else:
            result.success(f"Description: {len(desc)} символов")

        # Проверка триггеров в description
        if "trigger" not in desc.lower() and "use when" not in desc.lower():
            result.warning("Description: нет явных триггеров (Triggers: ...)")

    # Размер
    lines = content.split("\n")
    if len(lines) > 500:
        result.warning(f"SKILL.md слишком большой ({len(lines)} строк > 500)")
    else:
        result.success(f"Размер SKILL.md: {len(lines)} строк")

    # References существуют
    ref_dir = os.path.join(path, "references")
    if os.path.isdir(ref_dir):
        ref_files = os.listdir(ref_dir)
        # Проверяем что упомянутые references реально существуют
        for ref_mention in re.findall(r"references/([a-zA-Z0-9_-]+\.md)", content):
            if ref_mention not in ref_files:
                result.error(f"Упомянут references/{ref_mention}, но файл не найден")
            else:
                result.success(f"references/{ref_mention} существует")

    # Примеры
    if "пример" not in content.lower() and "example" not in content.lower():
        result.warning("Нет примеров использования")

    # Запрещённые поля
    if fm and "version" in fm:
        result.error("Frontmatter: поле 'version' НЕ поддерживается OpenClaw")


def check_material_specific(path, result):
    """Проверки специфичные для материалов группы."""
    print(f"\n{BOLD}📄 МАТЕРИАЛ ДЛЯ ГРУППЫ{RESET}")

    files = os.listdir(path)
    ops_files = [f for f in files if f.startswith("AI-OPS-")]

    # Dual format
    md_files = [f for f in ops_files if f.endswith(".md") and "AGENT" not in f]
    pdf_files = [f for f in ops_files if f.endswith(".pdf")]
    agent_files = [f for f in ops_files if "AGENT" in f and f.endswith(".md")]

    if md_files:
        result.success(f"MD файлы: {len(md_files)}")
    else:
        result.error("Нет MD файлов AI-OPS-*")

    if pdf_files:
        result.success(f"PDF файлы: {len(pdf_files)}")
    else:
        result.warning("Нет PDF файлов")

    if agent_files:
        result.success(f"AGENT.md файлы: {len(agent_files)}")
    else:
        result.warning("Нет AGENT.md файлов (dual format неполный)")

    # Проверяем структуру MD
    for md in md_files:
        content = read_file(os.path.join(path, md))
        if not content:
            continue

        checks = {
            "Что это": r"##\s*(Что это|Введение)",
            "Зачем нужно": r"##\s*Зачем",
            "Что потребуется": r"##\s*Что потребуется",
            "Как настроить": r"##\s*Как настроить",
            "Проверка": r"##\s*Проверка",
            "Частые ошибки": r"##\s*(Частые ошибки|Troubleshoot)",
            "Итого": r"##\s*Итого",
        }

        for section, pattern in checks.items():
            if re.search(pattern, content, re.IGNORECASE):
                result.success(f"{md}: раздел «{section}» есть")
            else:
                result.warning(f"{md}: раздел «{section}» не найден")


def check_github_specific(path, result):
    """Проверки специфичные для GitHub проектов."""
    print(f"\n{BOLD}🐙 GITHUB ПРОЕКТ{RESET}")

    files = os.listdir(path)

    for required in ["README.md"]:
        if required in files:
            result.success(f"{required} есть")
        else:
            result.error(f"{required} отсутствует")

    for recommended in ["LICENSE", "INSTALL.md", ".gitignore"]:
        if recommended in files:
            result.success(f"{recommended} есть")
        else:
            result.warning(f"{recommended} отсутствует")


# ============================================================
# Main
# ============================================================
def main():
    parser = argparse.ArgumentParser(
        description="Валидатор продуктов Team Lead"
    )
    parser.add_argument("path", help="Путь к папке продукта")
    parser.add_argument(
        "--type", choices=["skill", "material", "github"],
        help="Тип продукта (auto если не указан)"
    )
    parser.add_argument(
        "--fix", action="store_true",
        help="Автоисправление (тире → дефис)"
    )
    args = parser.parse_args()

    path = os.path.abspath(args.path)
    if not os.path.isdir(path):
        print(f"{RED}Ошибка: {path} не найден{RESET}")
        sys.exit(1)

    product_type = args.type or detect_type(path)

    print(f"\n{BOLD}{'=' * 50}{RESET}")
    print(f"{BOLD}🔍 ВАЛИДАЦИЯ ПРОДУКТА{RESET}")
    print(f"  Путь: {path}")
    print(f"  Тип: {product_type}")
    print(f"  Fix: {'да' if args.fix else 'нет'}")
    print(f"{BOLD}{'=' * 50}{RESET}")

    files = collect_files(path)
    result = ValidationResult()

    if not files:
        result.error("Нет файлов для проверки")
        result.summary()
        sys.exit(1)

    info(f"Файлов для проверки: {len(files)}")

    # Общие проверки
    check_security(files, result)
    check_paths(files, result)
    check_style(files, result, fix=args.fix)

    # Специфичные проверки
    if product_type == "skill":
        check_skill_specific(path, result)
    elif product_type == "material":
        check_material_specific(path, result)
    elif product_type == "github":
        check_github_specific(path, result)

    passed = result.summary()
    sys.exit(0 if passed else 1)


if __name__ == "__main__":
    main()
