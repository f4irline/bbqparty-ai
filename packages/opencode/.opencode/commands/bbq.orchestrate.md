---
description: Run the complete research, planning, and implementation workflow for one Linear ticket
agent: pitmaster
---

Parse the input: `$ARGUMENTS`
- The first word is the **ticket ID** (for example, `STU-15`).
- Everything after is **additional context** that must be passed unchanged to every phase.

OpenCode expands `$1` before this command is given to you. Run `.opencode/scripts/bbq-orchestrate.sh "$1" "<additional context>"` from the repository root. Pass the expanded ticket ID as the first argument and the parsed remainder as the optional second argument; do not pass `$ARGUMENTS` as one argument.

The script starts fresh OpenCode sessions for the existing commands in this order:

```text
bbq.pantry -> bbq.prep -> bbq.fire
```

Do not duplicate any phase work. Report the script's final status and log directory. If it stops, report the stopped phase and the phase log path.
