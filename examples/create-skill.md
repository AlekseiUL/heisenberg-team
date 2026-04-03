# How to Create a Skill

## What is a Skill?

A skill is a set of instructions that tells an agent how to perform a specific task. Skills are shared across agents.

## 1. Create Skill Directory

```bash
mkdir -p skills/your-skill-name/
```

## 2. Write SKILL.md

This is the only required file. It contains all instructions:

```markdown
# SKILL.md - Your Skill Name

## Description
[What this skill does - used for matching]

## When to Use
- [Trigger 1]
- [Trigger 2]

## Instructions

### Step 1: [Action]
[Detailed instructions]

### Step 2: [Action]
[Detailed instructions]

## Examples

### Example 1: [Use Case]
Input: [what user says]
Output: [what agent does]
```

## 3. Add References (Optional)

For complex skills, add reference files:

```
skills/your-skill-name/
├── SKILL.md              # Main instructions
└── references/
    ├── templates.md      # Templates for output
    └── examples.md       # Detailed examples
```

## 4. Register the Skill

Skills in `skills/` are automatically available to agents that have the skills directory configured. No additional registration needed.

## 5. Test

Ask an agent to perform the task your skill handles. The agent should automatically load and follow SKILL.md.

## Best Practices

- Keep SKILL.md under 500 lines
- Use clear trigger words in the description
- Include at least one concrete example
- Add error handling instructions
- Test with different phrasings of the same request
