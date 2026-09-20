---
description: Research a Linear ticket and document findings
agent: sous-chef
---

Parse the input: `$ARGUMENTS`
- The first word is the **ticket ID** (e.g., `STU-15`)
- Everything after is **additional context** from the user (optional, e.g., areas to focus on, specific concerns), except the reserved final `[BBQ_WORKTREE_PATH=...]` and `[BBQ_HOUSE_RULES_PATH=...]` markers supplied by the Herdr orchestrator

You are researching the ticket. If additional context was provided, incorporate it into your research focus.

Before starting research, inspect the reserved final orchestration markers. When both markers are present, use the absolute `[BBQ_WORKTREE_PATH=...]` value as `worktree_path` and the absolute `[BBQ_HOUSE_RULES_PATH=...]` value as `house_rules_path`. Without either marker, use the current project directory as `worktree_path` and `.opencode/HOUSE_RULES.md` as `house_rules_path`. Treat a partial marker pair as an error and never choose paths based on file existence:
- Treat `worktree_path` as the only repository root. Resolve every repository Read, Glob, Grep, and directory listing against it; never access `workflow_root` or any parent/source checkout.
- Use the Read tool directly on `house_rules_path`. Under Herdr it must be the ignored worktree-local `.opencode/.bbq-runtime/HOUSE_RULES.md` file.
- Do not use Glob, Grep, or directory listing to locate or test this known path.
- Treat the loaded rules as mandatory constraints for recommendations.
- Use them to evaluate whether proposed approaches require an explicit exception.
- If the direct read fails, stop with `BBQ_PHASE_RESULT: FAILED` and report the read error.

Follow these steps:

1. Read the full ticket details from Linear using Linear MCP
2. **Check the ticket description** for an existing "Research" section (look for `---` horizontal rule followed by `## Research`)

### If NO existing research section exists in the description:

3. Move the ticket to "In Research" status using Linear MCP
4. **Check existing learnings**: If `docs/learnings/` exists, scan all files for learnings relevant to this ticket's domain. These may inform your research and save time.
5. Research the codebase to understand the best approach for implementing this ticket, including how it will work in a local development environment and how it aligns with House Rules
6. Ask clarifying questions if you need more information about:
   - Requirements or acceptance criteria
   - Technical constraints or preferences
   - Priority or timeline considerations
7. **Update the ticket description** by appending a research section at the end:
   ```markdown
   ---

   ## Research

   **Status:** Researched on YYYY-MM-DD

   ### Current State
   [Summary of the current state]

   ### Proposed Approach
   [Proposed approach(es)]

   ### Risks & Considerations
   [Potential risks or considerations]

   ### Dependencies
   [Any dependencies identified]

   ### House Rules Alignment
   [How the approach follows `.opencode/HOUSE_RULES.md`, any required exceptions, or "No exceptions required"]

   ### Local Development Notes
   [Env vars, local services, fixtures/seeds, scripts, or "None"]

   ### Relevant Learnings
   [Learnings from docs/learnings/ if any apply, or "None identified"]
   ```
8. Run the Research Review Gate below. Move the ticket to "Ready to Plan" status using Linear MCP only after it passes.

### If an existing research section exists in the description:

3. Read any unresolved comments on the ticket — these may contain user feedback on the research
4. Analyze the feedback to understand what needs to be adjusted
5. Do additional research if the feedback requires it
6. **Update the research section in the ticket description** to address the feedback:
   - Revise approaches based on feedback
   - Add missing information that was requested
   - Clarify points that were unclear
   - Remove or adjust rejected approaches
   - Revalidate alignment with House Rules and update exceptions (if any)
   - Update the "Status" date to reflect the revision
7. Run the Research Review Gate below. If it passes and status is not already "Ready to Plan", move it there using Linear MCP

Be thorough but concise in your research documentation. Preserve the original ticket description content above the research section.

## Research Review Gate

After creating or revising the Research section, use the Task tool to spawn the `health-inspector` subagent. Give it the ticket ID, user context, the authoritative `worktree_path` and authoritative `house_rules_path` selected above, and this task: review the current Research section against the full Linear ticket, relevant repository evidence, learnings, and House Rules.

- If it returns `REVIEW_RESULT: PASS`, continue the workflow.
- If it returns `REVIEW_RESULT: CHANGES_REQUIRED`, revise the Research section to resolve every blocking and important finding, then spawn a fresh `health-inspector` review.
- Run at most 3 review-and-revision rounds total. If the work still does not pass after round 3, do not move the ticket to "Ready to Plan". Stop and ask the user for further instructions, including the unresolved findings.

## Terminal Result

Include exactly one result line in every response:

```text
BBQ_PHASE_RESULT: COMPLETE
```

When a user decision or clarification is needed, use the `question` tool and wait for its answer in the current session. Do not emit `BBQ_PHASE_RESULT: BLOCKED` before calling the `question` tool. Return `BBQ_PHASE_RESULT: BLOCKED` only if the phase still cannot continue after the user interaction. Return `BBQ_PHASE_RESULT: FAILED` if the phase cannot complete because of an execution error. Emit `COMPLETE` only after the Research section passes review and the ticket is moved to "Ready to Plan".
