---
name: learnings
description: Manage project learnings — read and write gotchas, patterns, decisions, and discoveries to docs/learnings/
---

# Learnings Skill

This skill manages project learnings — insights, gotchas, patterns, and decisions discovered during development.

## Directory Structure

Learnings are stored in `docs/learnings/` at the project root:

```
docs/learnings/
├── gotchas.md       # Traps, pitfalls, things that bite you
├── patterns.md      # "This is how we do X here"
├── decisions.md     # Architectural/technical decisions and rationale
└── discoveries.md   # TIL moments, how things work in this codebase
```

## Categories

When categorizing a learning, use this guide:

| Category | Use When | Examples |
|----------|----------|----------|
| **Gotchas** | Something unexpected that caused issues or could cause issues | Silent failures, implicit behavior, edge cases, misleading names |
| **Patterns** | A repeated way of doing things in this codebase | "Always use X for Y", naming conventions, preferred libraries |
| **Decisions** | A choice was made with explicit reasoning | "We use X instead of Y because Z", trade-offs, constraints |
| **Discoveries** | You learned how something works | Internal APIs, undocumented behavior, codebase structure |

If a learning fits multiple categories, pick the **primary** one. Don't duplicate.

## Entry Format

Each learning is appended to the top of the relevant file (newest first):

```markdown
## Short descriptive title
**Ticket:** ABC-123
**Date:** 2025-01-25

The actual learning content goes here. Be concise but complete.
Include file paths with line numbers when relevant (e.g., `src/auth/token.ts:42`).

---
```

## Reading Learnings

When starting work (research, planning, implementation):

1. Check if `docs/learnings/` exists
2. If it does, scan all files for learnings relevant to the current task
3. Consider these learnings when making decisions

Relevance signals:
- Same area of the codebase
- Similar problem domain
- Related tickets mentioned
- Keywords matching the current task

## Writing Learnings

At the end of implementation or on-demand:

1. Reflect on the work done in the current session
2. Identify insights that would help future work:
   - What was surprising?
   - What took longer than expected?
   - What would you want to know if you came back to this code?
   - What patterns did you follow or establish?
3. Categorize each learning
4. Create the `docs/learnings/` directory if it doesn't exist
5. Append each learning to the appropriate file using the entry format

## Auto-Extraction Guidelines

When auto-extracting learnings from a session, look for:

- Error messages that required investigation
- Code that needed refactoring to work
- Implicit dependencies or requirements
- Workarounds for framework/library limitations
- Established patterns used or created
- Decisions made with trade-offs
- Non-obvious file relationships
- API quirks or undocumented behavior

**Skip trivial learnings** like:
- Standard library usage
- Common framework patterns
- Things already documented in the codebase
- One-off typos or mistakes

## File Initialization

If a learnings file doesn't exist, create it with this header:

```markdown
# Gotchas

Things that might bite you. Check here before you get bitten.

---
```

(Adjust the title and description for each category)

### Headers for Each File

**gotchas.md:**
```markdown
# Gotchas

Things that might bite you. Check here before you get bitten.

---
```

**patterns.md:**
```markdown
# Patterns

How we do things around here. Follow these for consistency.

---
```

**decisions.md:**
```markdown
# Decisions

Technical decisions and their rationale. Know why before you change.

---
```

**discoveries.md:**
```markdown
# Discoveries

How things work in this codebase. Tribal knowledge, written down.

---
```
