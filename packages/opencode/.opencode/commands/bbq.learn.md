# Write it down, Chef!

Extract learnings from the current conversation and add them to the project's knowledge base.

## Arguments

None required — uses the current conversation as context.

## Instructions

### 1. Load the Learnings Skill

Load and follow the `learnings` skill for structure and categorization.

### 2. Review the Conversation

Look back at this entire conversation and identify learnings:

- What was surprising or unexpected?
- What took longer than expected to figure out?
- What workarounds were needed?
- What patterns were followed or established?
- What decisions were made and why?
- What would you want to know if you came back to this code?

### 3. Categorize Each Learning

For each learning, determine the category:

| Category | File | Use When |
|----------|------|----------|
| Gotchas | `gotchas.md` | Traps, pitfalls, unexpected behavior |
| Patterns | `patterns.md` | How things are done in this codebase |
| Decisions | `decisions.md` | Choices made with explicit reasoning |
| Discoveries | `discoveries.md` | How things work, TIL moments |

### 4. Skip Trivial Learnings

Don't document:
- Standard library/framework usage
- Things already in project docs
- One-off typos or simple mistakes
- Generic programming knowledge

### 5. Write the Learnings

For each learning:

1. Create `docs/learnings/` directory if it doesn't exist
2. Create the category file with header if it doesn't exist
3. Prepend the learning entry (newest at top)

Entry format:
```markdown
## Short descriptive title
**Ticket:** <ticket-id if known, or "N/A">
**Date:** <today's date>

The learning content. Be concise but complete.
Include file paths with line numbers when relevant.

---
```

### 6. Summarize

Tell the chef what was documented:

```
Documented X learnings:
- gotchas.md: "Title of gotcha"
- patterns.md: "Title of pattern"
...
```

If no learnings were worth documenting, say so — that's fine too.
