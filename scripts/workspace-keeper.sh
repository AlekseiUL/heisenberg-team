#!/bin/bash
command -v md5sum &>/dev/null || md5sum() { md5 -q "$@"; }
# workspace-keeper.sh — Администратор рабочего пространства
# Проверяет: структуру скиллов, осиротевшие файлы, дубликаты,
# битые ссылки, мусор, именование файлов
# Запуск: еженедельно по крону (воскресенье 04:00)

set -euo pipefail

WORKSPACE="${WORKSPACE_PATH:-$HOME/workspace}"
KAIZEN_WORKSPACE="$HOME/kaizen-workspace"
cd "$WORKSPACE"

python3 - << 'PYEOF'
import os, re, glob, json, hashlib
from pathlib import Path
from collections import defaultdict

workspace = "${WORKSPACE_PATH:-$HOME/workspace}"
kaizen_workspace = "$HOME/kaizen-workspace"
problems = []
warnings = []
stats = {"skills": 0, "refs": 0, "memory_files": 0, "orphans": 0, "kaizen_issues": 0}

# === 1. SKILLS HEALTH ===
skills_dir = os.path.join(workspace, "skills")
for skill_name in sorted(os.listdir(skills_dir)):
    skill_path = os.path.join(skills_dir, skill_name)
    if not os.path.isdir(skill_path):
        continue
    stats["skills"] += 1
    
    # Check SKILL.md exists
    skill_md = os.path.join(skill_path, "SKILL.md")
    if not os.path.exists(skill_md):
        problems.append(f"\u274c {skill_name}: SKILL.md отсутствует!")
        continue
    
    with open(skill_md) as f:
        content = f.read()
    
    # Check frontmatter
    if not content.startswith("---"):
        warnings.append(f"\u26a0\ufe0f {skill_name}: нет YAML frontmatter")
    elif "description:" not in content[:500]:
        warnings.append(f"\u26a0\ufe0f {skill_name}: нет description в frontmatter")
    
    # Check references/ if exists
    refs_dir = os.path.join(skill_path, "references")
    if os.path.isdir(refs_dir):
        ref_files = os.listdir(refs_dir)
        stats["refs"] += len(ref_files)
        
        # Check each ref is mentioned in SKILL.md
        for ref_file in ref_files:
            if ref_file.startswith('.') or ref_file == '__pycache__':
                continue
            if ref_file not in content:
                warnings.append(f"\u26a0\ufe0f {skill_name}: references/{ref_file} не упомянут в SKILL.md")
    
    # Check for stale memory/ references in SKILL.md
    memory_refs = re.findall(r'memory/[\w\-]+\.md', content)
    for mref in memory_refs:
        if 'YYYY' in mref or 'MM-DD' in mref:
            continue  # skip template placeholders
        mpath = os.path.join(workspace, mref)
        if not os.path.exists(mpath):
            problems.append(f"\u274c {skill_name}: битая ссылка на {mref}")

# === 2. MEMORY/ HEALTH ===
memory_dir = os.path.join(workspace, "memory")
if os.path.isdir(memory_dir):
    for fname in sorted(os.listdir(memory_dir)):
        if not fname.endswith('.md'):
            continue
        stats["memory_files"] += 1
        fpath = os.path.join(memory_dir, fname)
        
        # Check for empty files
        size = os.path.getsize(fpath)
        if size < 10:
            warnings.append(f"\u26a0\ufe0f memory/{fname}: пустой файл ({size} байт)")
        
        # Check for duplicates in skills/
        skill_copies = list(Path(skills_dir).rglob(fname))
        if skill_copies and not re.match(r'2026-\d{2}-\d{2}', fname):
            pass  # Expected duplicates (profiles)

# === 3. ORPHAN FILES ===
# Files in workspace root that shouldn't be there
root_files = [f for f in os.listdir(workspace) 
              if os.path.isfile(os.path.join(workspace, f)) 
              and not f.startswith('.') 
              and f not in ['AGENTS.md', 'SOUL.md', 'TOOLS.md', 'IDENTITY.md', 
                           'USER.md', 'HEARTBEAT.md', 'MEMORY.md', 'BOOTSTRAP.md',
                           '.gitignore', 'README.md']]
for f in root_files:
    if not f.endswith(('.md', '.json', '.log')):
        warnings.append(f"\u26a0\ufe0f \u041a\u043e\u0440\u0435\u043d\u044c: \u043d\u0435\u043e\u0436\u0438\u0434\u0430\u043d\u043d\u044b\u0439 \u0444\u0430\u0439\u043b {f}")

# === 4. TEMP/JUNK FILES ===
junk_patterns = ['*.tmp', '*.bak', '*.swp', '*~', '.DS_Store', '*.pyc']
junk_count = 0
for pattern in junk_patterns:
    for junk in Path(workspace).rglob(pattern):
        if '.git' not in str(junk):
            junk_count += 1
            if junk_count <= 5:
                warnings.append(f"\U0001f9f9 \u041c\u0443\u0441\u043e\u0440: {junk.relative_to(workspace)}")

# === 5. LARGE FILES ===
skip_large = {'obsidian/.obsidian/plugins', 'node_modules', '.venv'}
for fpath in Path(workspace).rglob("*"):
    if fpath.is_file() and '.git' not in str(fpath):
        rel = str(fpath.relative_to(workspace))
        if any(rel.startswith(s) for s in skip_large):
            continue
        size_mb = fpath.stat().st_size / (1024 * 1024)
        if size_mb > 5:
            warnings.append(f"\U0001f4e6 \u0411\u043e\u043b\u044c\u0448\u043e\u0439 \u0444\u0430\u0439\u043b: {fpath.relative_to(workspace)} ({size_mb:.1f} MB)")

# === 6. DUPLICATE FILES ACROSS SKILLS ===
# Намеренные дубликаты: каждый топик-агент имеет свою независимую копию данных.
# Файлы здесь синхронизируются вручную при обновлении. Это нормально по архитектуре.
INTENTIONAL_DUPLICATES = {
    "marketing-strategy.md",           # creator-marketing (canonical) + business-architect (topic agent)
    "psychology-profile.md",           # psychologist (canonical) + business-architect (topic agent)
}
file_hashes = defaultdict(list)
for skill_name in os.listdir(skills_dir):
    skill_path = os.path.join(skills_dir, skill_name)
    if not os.path.isdir(skill_path):
        continue
    for fpath in Path(skill_path).rglob("*"):
        if fpath.is_file() and fpath.stat().st_size > 100 and fpath.suffix in ('.md', '.json', '.sh', '.py'):
            if fpath.name in INTENTIONAL_DUPLICATES:
                continue  # намеренная копия, не флагим
            h = hashlib.md5(fpath.read_bytes()).hexdigest()
            file_hashes[h].append(str(fpath.relative_to(workspace)))
for h, paths in file_hashes.items():
    if len(paths) > 1:
        warnings.append(f"🔁 Дубликат: {' = '.join(paths)}")

# === 6b. ПУСТЫЕ ПАПКИ ===
skip_empty = {'.git', 'node_modules', '.obsidian', '__pycache__', '.venv'}
for dpath in sorted(Path(workspace).rglob("*")):
    if not dpath.is_dir():
        continue
    rel = str(dpath.relative_to(workspace))
    if any(s in rel for s in skip_empty):
        continue
    # Папка пустая если нет файлов (не считая .DS_Store)
    contents = [f for f in dpath.iterdir() if f.name != '.DS_Store']
    if len(contents) == 0:
        warnings.append(f"📂 Пустая папка: {rel}/")

# === 7. KAIZEN WORKSPACE ===
if os.path.isdir(kaizen_workspace):
    # Check for junk
    for pattern in ['*.tmp', '*.bak', '*.swp', '*~', '.DS_Store', '*.pyc']:
        for junk in Path(kaizen_workspace).rglob(pattern):
            if '.git' not in str(junk):
                stats["kaizen_issues"] += 1
                warnings.append(f"🧹 Кайдзен мусор: {junk.relative_to(kaizen_workspace)}")
    # Check for large files
    for fpath in Path(kaizen_workspace).rglob("*"):
        if fpath.is_file() and '.git' not in str(fpath):
            size_mb = fpath.stat().st_size / (1024 * 1024)
            if size_mb > 5:
                warnings.append(f"📦 Кайдзен большой файл: {fpath.relative_to(kaizen_workspace)} ({size_mb:.1f} MB)")
    # Check key files exist
    for required in ['AGENTS.md', 'goals']:
        rpath = os.path.join(kaizen_workspace, required)
        if not os.path.exists(rpath):
            problems.append(f"❌ Кайдзен: {required} отсутствует!")

# === 8. CRON SCRIPTS INTEGRITY ===
# Check that scripts referenced in cron jobs actually exist
cron_scripts = [
    "scripts/workspace-keeper.sh",
    "scripts/cron-watchdog.sh",
    "scripts/daily-obsidian-note.sh",
    "scripts/daily_health_check_gemini.sh",
    "scripts/progress-log.sh",
    "scripts/read-document.py",
]
for script in cron_scripts:
    spath = os.path.join(workspace, script)
    if not os.path.exists(spath):
        problems.append(f"❌ Крон-скрипт отсутствует: {script}")
    elif not os.access(spath, os.X_OK) and script.endswith('.sh'):
        warnings.append(f"⚠️ Скрипт не исполняемый: {script}")

# === 8b. SQLITE MEMORY SIZE ===
sqlite_path = os.path.expanduser("~/.openclaw/memory/main.sqlite")
if os.path.exists(sqlite_path):
    sqlite_mb = os.path.getsize(sqlite_path) / (1024 * 1024)
    if sqlite_mb > 1000:
        problems.append(f"❌ SQLite: {sqlite_mb:.0f} MB (>1 GB, стоит архивировать старые сессии)")
    elif sqlite_mb > 500:
        warnings.append(f"⚠️ SQLite: {sqlite_mb:.0f} MB (растёт, скоро >1 GB)")

# === 9. SESSIONS SIZE ===
for agent_name, agent_dir in [("main", os.path.expanduser("~/.openclaw/agents/main/sessions")),
                               ("kaizen", os.path.expanduser("~/.openclaw/agents/kaizen/sessions"))]:
    if os.path.isdir(agent_dir):
        total_size = sum(f.stat().st_size for f in Path(agent_dir).rglob("*.jsonl"))
        size_mb = total_size / (1024 * 1024)
        if size_mb > 50:
            problems.append(f"❌ Sessions {agent_name}: {size_mb:.0f} MB (>50 MB, нужна чистка!)")
        elif size_mb > 30:
            warnings.append(f"⚠️ Sessions {agent_name}: {size_mb:.0f} MB (растёт)")

# === 10. OLD/CONFLICTING REFERENCES ===
# Check location-helper for old monolithic files vs new split
gh_refs = os.path.join(skills_dir, "location-helper", "references")
if os.path.isdir(gh_refs):
    old_files = ["location-guide.md", "location-documents.md"]
    for old in old_files:
        if os.path.exists(os.path.join(gh_refs, old)):
            size_kb = os.path.getsize(os.path.join(gh_refs, old)) / 1024
            if size_kb > 50:
                warnings.append(f"⚠️ location-helper: старый монолит {old} ({size_kb:.0f} KB) - заменён тематическими файлами?")

# === OUTPUT ===
if problems:
    print(f"\U0001f6a8 Workspace Keeper\n")
    print(f"\u0421\u043a\u0438\u043b\u043b\u043e\u0432: {stats['skills']} | References: {stats['refs']} | Memory: {stats['memory_files']}\n")
    print("\u274c \u041f\u0440\u043e\u0431\u043b\u0435\u043c\u044b:")
    for p in problems:
        print(f"  {p}")
    if warnings:
        print(f"\n\u26a0\ufe0f \u041f\u0440\u0435\u0434\u0443\u043f\u0440\u0435\u0436\u0434\u0435\u043d\u0438\u044f ({len(warnings)}):")
        for w in warnings[:10]:
            print(f"  {w}")
        if len(warnings) > 10:
            print(f"  ... \u0438 \u0435\u0449\u0451 {len(warnings)-10}")
elif warnings:
    print(f"\U0001f6a8 Workspace Keeper\n")
    print(f"\u0421\u043a\u0438\u043b\u043b\u043e\u0432: {stats['skills']} | References: {stats['refs']} | Memory: {stats['memory_files']}\n")
    print(f"\u26a0\ufe0f \u041f\u0440\u0435\u0434\u0443\u043f\u0440\u0435\u0436\u0434\u0435\u043d\u0438\u044f ({len(warnings)}):")
    for w in warnings[:10]:
        print(f"  {w}")
    if len(warnings) > 10:
        print(f"  ... \u0438 \u0435\u0449\u0451 {len(warnings)-10}")
else:
    print(f"ALL_OK:{stats['skills']}:{stats['refs']}:{stats['memory_files']}:kaizen_ok")

PYEOF
