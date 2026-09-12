# Optional Herdr Runtime Integration Plan

> **For agentic workers:** Implement this plan task by task and keep the checkboxes current. Use test-first changes, preserve the native workflow, and do not replace or stop an existing Herdr server.

**Goal:** Let `init.sh` optionally configure a target project to use Herdr for persistent BBQ Party phase agents and Git worktree initialization while retaining the current native OpenCode workflow as the default and fallback.

**Architecture:** `init.sh` records the selected runtime in a project-local config file. The installed `bbq-orchestrate.sh` dispatches to either the existing OpenCode HTTP backend or a Herdr backend that uses `agent start`, `agent prompt`, `agent wait`, and `agent read`. `/bbq.fire` and `/bbq.taste` use Herdr worktree commands only when the project selects Herdr and the agent is running inside Herdr; otherwise they retain the existing native worktree skills.

**Tech Stack:** Bash, OpenCode project commands and skills, Herdr CLI v0.9-compatible APIs, Git worktrees, `jq`, `curl`.

---

## Accepted Decisions

- Herdr is opt-in through an interactive `init.sh` prompt, defaulting to No, or an explicit `--herdr` flag.
- `init.sh` does not install the Herdr binary. Herdr mode fails early with installation guidance when `herdr` is missing.
- The official Herdr skill is downloaded during installation from the Git tag matching the installed Herdr version.
- Herdr mode checks the user-level OpenCode integration and runs `herdr integration install opencode` when it is missing, outdated, or needs repair.
- Herdr worktrees keep the current `.opencode/.bbq-worktrees/{branch-slug}` path contract.
- Local-only files listed in `.opencode/worktree-local-files` continue to be mirrored into worktrees.
- A Herdr-configured project falls back to native worktree handling and the OpenCode HTTP runner when it is used outside a Herdr pane.
- The Herdr orchestration backend creates a separate OpenCode agent for each selected phase and retains completed panes and agents for inspection.
- The Herdr backend is part of this implementation. It is not deferred to a later rewrite.

## Runtime Selection Contract

The installed project owns `.opencode/bbq-config.json`:

```json
{
  "runtime": "native"
}
```

Allowed values are `native` and `herdr`.

Runtime resolution rules:

1. A missing config file means `native`, preserving existing manually installed projects.
2. An invalid JSON document or unknown runtime value is an actionable error; do not silently select a backend.
3. `runtime = native` always uses the existing OpenCode HTTP orchestration and native worktree skills.
4. `runtime = herdr` with `HERDR_ENV=1` uses Herdr orchestration and Herdr worktree APIs.
5. `runtime = herdr` without `HERDR_ENV=1` prints a fallback notice and uses the native backend and worktree skills.
6. `HERDR_ENV=1` without `HERDR_WORKSPACE_ID` is invalid Herdr context and fails instead of falling back.

## Herdr Phase Lifecycle

For each phase selected by `--start-phase`:

1. Create a non-focused tab in the caller's Herdr workspace with the target repository as its working directory.
2. Read the root pane ID from `.result.root_pane.pane_id`.
3. Start a uniquely named OpenCode agent in that pane with `herdr agent start`.
4. Submit the project command, such as `/bbq.pantry STU-15`, with `herdr agent prompt --wait`.
5. If `.result.agent.agent_status` is `blocked`, print `herdr agent attach <name>` and wait for `idle` or `done`.
6. Read the settled transcript with `herdr agent read --source recent-unwrapped`.
7. Store Herdr command responses and transcript output under the existing `.opencode/.bbq-runs/<run>/` directory.
8. Apply the existing exactly-one `BBQ_PHASE_RESULT` validation.
9. Leave the phase tab and agent running after success, block, or failure so the user can inspect it.

Phases remain sequential. Pantry must complete before prep, and prep must complete before fire, unless skipped through the existing `--start-phase` option.

## File Map

- Create `packages/opencode/.opencode/bbq-config.json`: default runtime contract copied by manual installs.
- Create `packages/opencode/.opencode/scripts/sync-worktree-local-files.sh`: provider-neutral local-file mirroring.
- Create `packages/opencode/test/worktree-local-files.test.sh`: local-file mirroring coverage.
- Create `packages/opencode/test/bbq-orchestrate-herdr.test.sh`: Herdr backend and fallback coverage.
- Create `test/init-herdr.test.sh`: installer mode, skill download, and integration coverage.
- Modify `init.sh`: mode selection, validation, project config generation, tagged skill download, and OpenCode integration setup.
- Modify `packages/opencode/bbq-orchestrate.sh`: runtime dispatch, shared result validation, and Herdr backend.
- Modify `packages/opencode/test/bbq-orchestrate.test.sh`: keep native assertions aligned after internal refactoring.
- Modify `packages/opencode/.opencode/commands/bbq.fire.md`: conditional Herdr worktree creation and native fallback.
- Modify `packages/opencode/.opencode/commands/bbq.taste.md`: conditional Herdr worktree lookup/open/create and native fallback.
- Modify `packages/opencode/.opencode/skills/git-branch-create/SKILL.md`: remove the unconditional native-provider handoff.
- Modify `packages/opencode/.opencode/skills/git-worktree-prepare/SKILL.md`: delegate local-file mirroring to the shared script.
- Modify `packages/opencode/.opencode/skills/git-worktree-find/SKILL.md`: clarify that it is the native fallback provider.
- Modify `README.md`: document optional Herdr installation and runtime behavior.
- Modify `packages/opencode/README.md`: document project config, fallback behavior, retained agents, and commands.
- Modify `AGENTS.md`: list the new shell verification commands.

## Task 1: Add Runtime Config and Provider-Neutral File Sync

**Files:**
- Create: `packages/opencode/.opencode/bbq-config.json`
- Create: `packages/opencode/.opencode/scripts/sync-worktree-local-files.sh`
- Create: `packages/opencode/test/worktree-local-files.test.sh`
- Modify: `packages/opencode/.opencode/skills/git-worktree-prepare/SKILL.md`

- [ ] **Step 1: Write the local-file sync test**

Cover these cases in `worktree-local-files.test.sh`:

- comments and blank lines are ignored;
- a nested `.env` file is symlinked to the same relative path;
- an existing worktree file is never overwritten;
- a missing source entry is ignored;
- paths containing spaces are handled;
- the script reports linked and copied counts;
- an invalid source root or worktree path fails before changing files.

Use temporary source and worktree directories and invoke:

```bash
"$sync_script" "$source_root" "$worktree_path"
```

- [ ] **Step 2: Run the new test and verify it fails**

Run:

```bash
bash packages/opencode/test/worktree-local-files.test.sh
```

Expected: failure because `sync-worktree-local-files.sh` does not exist.

- [ ] **Step 3: Implement the sync script**

The script interface must be:

```text
Usage: sync-worktree-local-files.sh <source-repo-root> <worktree-path>
```

Implementation requirements:

- use `#!/usr/bin/env bash` and `set -euo pipefail`;
- read `<source-repo-root>/.opencode/worktree-local-files`;
- create target parent directories;
- prefer `ln -s` and fall back to `cp -R`;
- never overwrite an existing file, directory, or symlink;
- reject entries beginning with `/` or containing a `..` path component so the allowlist cannot write outside the worktree;
- keep the script executable in the source package so `cp -R` installs an executable target;
- print exactly `Local files linked: <n>` and `Local files copied: <n>` on success.

- [ ] **Step 4: Add the default runtime config**

Create `packages/opencode/.opencode/bbq-config.json` with:

```json
{
  "runtime": "native"
}
```

- [ ] **Step 5: Update the native worktree skill**

Replace the inline mirroring block in `git-worktree-prepare/SKILL.md` with an invocation of:

```bash
"{repo-root}/.opencode/scripts/sync-worktree-local-files.sh" \
  "{repo-root}" \
  "{worktree-path}"
```

Keep worktree creation behavior unchanged.

- [ ] **Step 6: Run the sync test**

Run:

```bash
bash packages/opencode/test/worktree-local-files.test.sh
```

Expected: PASS.

- [ ] **Step 7: Commit the isolated change**

```bash
git add packages/opencode/.opencode/bbq-config.json \
  packages/opencode/.opencode/scripts/sync-worktree-local-files.sh \
  packages/opencode/.opencode/skills/git-worktree-prepare/SKILL.md \
  packages/opencode/test/worktree-local-files.test.sh
git commit -m "refactor(opencode): share worktree local file sync"
```

## Task 2: Add Optional Herdr Installer Mode

**Files:**
- Create: `test/init-herdr.test.sh`
- Modify: `init.sh`

- [ ] **Step 1: Write installer tests with mocked executables**

Build a temporary `PATH` containing mock `docker`, `herdr`, and `curl` commands. Run `init.sh` against fresh temporary target directories with `--skip-docker --skip-env --auth-method pat`.

Test all of the following:

- `--herdr` writes `{"runtime":"herdr"}` semantically to `.opencode/bbq-config.json`;
- pressing Enter at the interactive Herdr prompt writes `native` and never invokes `herdr`;
- a missing Herdr binary exits non-zero with links or commands for the official installer and Homebrew;
- `herdr --version` returning `herdr 0.9.0` downloads from `https://raw.githubusercontent.com/herdrdev/herdr/v0.9.0/skills/herdr/SKILL.md`;
- a valid downloaded file lands at `.opencode/skills/herdr/SKILL.md`;
- invalid downloaded frontmatter does not replace an existing Herdr skill;
- `opencode: current (...)` in `herdr integration status` skips installation;
- missing, outdated, or repair-needed OpenCode integration status invokes `herdr integration install opencode` once;
- declining replacement of an existing `.opencode` directory prevents partial Herdr project configuration and prints a rerun instruction;
- repeated successful Herdr installation remains idempotent.

- [ ] **Step 2: Run the installer test and verify it fails**

Run:

```bash
bash test/init-herdr.test.sh
```

Expected: failure because `--herdr` is unknown.

- [ ] **Step 3: Parse and display Herdr mode**

Add `HERDR_MODE=""` to defaults and support:

```text
--herdr                  Use Herdr for agents and worktrees
```

When the flag is absent, ask once after authentication selection:

```text
Use Herdr for persistent phase agents and worktrees? [y/N]
```

Store the result as `HERDR_MODE=true|false`. Show the selected runtime in the installation summary and update `--help` examples.

- [ ] **Step 4: Validate Herdr before installation side effects**

For Herdr mode:

1. require `herdr` and `curl` in `PATH`;
2. parse a stable semantic version from `herdr --version` and require v0.9.0 or newer;
3. inspect `herdr worktree help`, `herdr agent help`, and `herdr tab help` for the exact `list/create/open`, `start/prompt/wait/read`, and `create` operations used by BBQ Party;
4. fail without attempting to install Herdr when any prerequisite is missing.

Do not launch bare `herdr`, stop a server, update Herdr, or create runtime workspaces during `init.sh`.

- [ ] **Step 5: Write the project runtime config only after menu installation succeeds**

After the `.opencode` package is accepted and copied, write either:

```json
{
  "runtime": "herdr"
}
```

or:

```json
{
  "runtime": "native"
}
```

If the target already has `.opencode`, Herdr mode was selected, and the user declines the menu update, exit with guidance instead of installing the global integration or claiming Herdr is configured.

- [ ] **Step 6: Download and validate the matching Herdr skill atomically**

Download to a temporary file, validate that it begins with YAML frontmatter and contains both `name: herdr` and `Requires HERDR_ENV=1`, then move it to:

```text
<target>/.opencode/skills/herdr/SKILL.md
```

Use the installed version tag in the URL. On any download or validation error, retain an existing target skill unchanged and fail installation with the source URL.

- [ ] **Step 7: Install or preserve the OpenCode integration**

Inspect `herdr integration status` for the exact `opencode:` line. Leave `current` untouched. For `not installed`, `outdated`, `needs repair`, or legacy state, print the user-level destination described by Herdr and run:

```bash
herdr integration install opencode
```

Propagate installation failures. Do not uninstall or edit the integration directly.

- [ ] **Step 8: Update completion output**

For Herdr mode, make the primary next step:

```bash
cd <target> && herdr
```

Then tell the user to start `opencode` in the pane or run `./bbq-orchestrate.sh <ticket-id>` from a Herdr shell pane. Native mode keeps the existing `cd ... && opencode` guidance.

- [ ] **Step 9: Run installer tests**

Run:

```bash
bash test/init-herdr.test.sh
```

Expected: PASS.

- [ ] **Step 10: Commit the installer change**

```bash
git add init.sh test/init-herdr.test.sh
git commit -m "feat(init): add optional herdr setup"
```

## Task 3: Make BBQ Worktree Instructions Provider-Aware

**Files:**
- Modify: `packages/opencode/.opencode/commands/bbq.fire.md`
- Modify: `packages/opencode/.opencode/commands/bbq.taste.md`
- Modify: `packages/opencode/.opencode/skills/git-branch-create/SKILL.md`
- Modify: `packages/opencode/.opencode/skills/git-worktree-find/SKILL.md`
- Create: `packages/opencode/test/worktree-provider-contract.test.sh`

- [ ] **Step 1: Add failing static contract checks**

The test must verify that both commands:

- read `.opencode/bbq-config.json`;
- require both `runtime = herdr` and `HERDR_ENV=1` for Herdr worktrees;
- explicitly load/use the installed `herdr` skill;
- invoke `herdr worktree list`, `open`, and `create --path` as applicable;
- parse `.result.worktrees`, `.result.worktree.path`, and `.result.workspace.workspace_id` from JSON;
- run `sync-worktree-local-files.sh` after either provider resolves a path;
- retain `git-worktree-prepare` and `git-worktree-find` as native fallbacks.

- [ ] **Step 2: Run the contract test and verify it fails**

Run:

```bash
bash packages/opencode/test/worktree-provider-contract.test.sh
```

Expected: failure because commands do not mention the runtime config or Herdr.

- [ ] **Step 3: Update `/bbq.fire` worktree resolution**

After `git-branch-create` returns the branch:

1. read and validate `.opencode/bbq-config.json`;
2. if Herdr is selected and `HERDR_ENV=1`, follow the installed Herdr skill and confirm CLI syntax from the installed binary;
3. run `herdr worktree list --cwd "{repo-root}" --json` and match `.result.worktrees[] | select(.branch == "{branch}")`;
4. if the branch checkout exists but has no `open_workspace_id`, run `herdr worktree open --cwd "{repo-root}" --branch "{branch}" --label "{ticket-id}" --no-focus --json`;
5. if it does not exist, create it at the deterministic absolute path with `herdr worktree create --cwd "{repo-root}" --branch "{branch}" --base "{base-ref}" --path "{worktree-path}" --label "{ticket-id}" --no-focus --json`;
6. use `origin/{branch}` as `base-ref` when only a remote ticket branch exists; otherwise use the resolved remote default branch for a new branch;
7. parse the authoritative path from `.result.worktree.path` or the matching list entry, never from a Herdr workspace ID;
8. run the provider-neutral local-file sync script;
9. continue all implementation operations in the resolved path.

If Herdr is configured but `HERDR_ENV` is absent, state that native fallback is active and invoke `git-worktree-prepare`.

- [ ] **Step 4: Update `/bbq.taste` worktree resolution**

Use `git-find-ticket-branch` for branch discovery. Under active Herdr mode, list worktrees by repository, open an existing checkout into Herdr when necessary, or create it with the same explicit path/base rules when absent. Parse the returned worktree path, sync local files, and run review work there.

Outside Herdr, retain `git-worktree-find`, which may call `git-worktree-prepare`.

- [ ] **Step 5: Clarify native skill boundaries**

Update `git-branch-create` so it returns a branch name to the caller-selected provider rather than unconditionally naming `git-worktree-prepare`. Mark `git-worktree-find` and `git-worktree-prepare` as native fallback implementations; do not delete them because outside-Herdr fallback is an accepted requirement.

- [ ] **Step 6: Run worktree tests**

Run:

```bash
bash packages/opencode/test/worktree-local-files.test.sh
bash packages/opencode/test/worktree-provider-contract.test.sh
```

Expected: PASS.

- [ ] **Step 7: Commit the provider instructions**

```bash
git add packages/opencode/.opencode/commands/bbq.fire.md \
  packages/opencode/.opencode/commands/bbq.taste.md \
  packages/opencode/.opencode/skills/git-branch-create/SKILL.md \
  packages/opencode/.opencode/skills/git-worktree-find/SKILL.md \
  packages/opencode/test/worktree-provider-contract.test.sh
git commit -m "feat(opencode): use herdr worktree provider"
```

## Task 4: Refactor Shared Orchestrator Behavior Without Changing Native Mode

**Files:**
- Modify: `packages/opencode/bbq-orchestrate.sh`
- Modify: `packages/opencode/test/bbq-orchestrate.test.sh`

- [ ] **Step 1: Add native regression assertions**

Extend the existing test to verify:

- missing runtime config selects native mode;
- explicit `{"runtime":"native"}` selects native mode;
- malformed JSON and unknown runtime values fail before starting OpenCode;
- `{"runtime":"herdr"}` without `HERDR_ENV=1` prints the fallback notice and uses the HTTP backend;
- all current server, auth, start-phase, attach, result-marker, and failure assertions remain intact.

- [ ] **Step 2: Run the native test before refactoring**

Run:

```bash
bash packages/opencode/test/bbq-orchestrate.test.sh
```

Expected: new runtime-selection assertions fail while existing assertions pass.

- [ ] **Step 3: Extract shared result validation**

Move exact marker parsing into a function with this contract:

```text
evaluate_phase_result <phase> <text-file> <log-file>
```

It must preserve the current behavior for exactly one standalone line:

```text
BBQ_PHASE_RESULT: COMPLETE
BBQ_PHASE_RESULT: BLOCKED
BBQ_PHASE_RESULT: FAILED
```

Do not loosen inline-marker rejection or conflicting-marker detection.

- [ ] **Step 4: Introduce backend dispatch**

Keep argument validation and run-directory creation shared. Resolve the project runtime once, then call one of:

```bash
run_http_workflow
run_herdr_workflow
```

Rename the existing phase function to `run_http_phase` and keep its request, authentication, and cleanup behavior unchanged.

- [ ] **Step 5: Run native regression tests**

Run:

```bash
bash packages/opencode/test/bbq-orchestrate.test.sh
```

Expected: PASS with the same OpenCode and curl call sequence as before.

- [ ] **Step 6: Commit the behavior-preserving refactor**

```bash
git add packages/opencode/bbq-orchestrate.sh \
  packages/opencode/test/bbq-orchestrate.test.sh
git commit -m "refactor(opencode): select orchestration backend"
```

## Task 5: Implement Herdr Agent Orchestration

**Files:**
- Create: `packages/opencode/test/bbq-orchestrate-herdr.test.sh`
- Modify: `packages/opencode/bbq-orchestrate.sh`

- [ ] **Step 1: Write a stateful Herdr mock**

The mock must implement the command subset used by the runner:

```text
herdr tab create
herdr agent start
herdr agent prompt
herdr agent get
herdr agent wait
herdr agent read
```

Return representative v0.9 JSON, including:

```json
{"result":{"root_pane":{"pane_id":"w1:p2"}}}
```

and agent objects with `agent_status` set to `idle`, `blocked`, or `done`. Log every invocation so tests can assert command order, target names, project directory arguments, and `--no-focus`.

- [ ] **Step 2: Write Herdr workflow tests**

Cover:

- pantry, prep, and fire create three separate tabs and agents in order;
- `--start-phase prep` creates only prep and fire agents;
- `--start-phase fire` creates only the fire agent;
- agent names are lowercase, valid against `[a-z][a-z0-9_-]{0,31}`, unique per phase, and unique across repeated runs;
- `agent start` receives `--kind opencode`, the returned pane ID, and the repository path after `--`;
- `agent prompt --wait` receives `/bbq.<phase> <ticket-id> <context>`;
- a blocked prompt prints `herdr agent attach <name>`, calls `agent wait --until idle --until done`, then reads the result;
- successful reads pass the existing exactly-one marker rules;
- command JSON and transcript text are stored under `.opencode/.bbq-runs/`;
- completed and failed agents are not closed;
- tab creation, agent startup, prompt, wait, and read failures stop later phases with actionable logs;
- `HERDR_ENV=1` without `HERDR_WORKSPACE_ID` fails before calling Herdr.

- [ ] **Step 3: Run the Herdr test and verify it fails**

Run:

```bash
bash packages/opencode/test/bbq-orchestrate-herdr.test.sh
```

Expected: failure because `run_herdr_workflow` is not implemented.

- [ ] **Step 4: Implement phase tab and agent creation**

For each phase, run:

```bash
herdr tab create \
  --workspace "$HERDR_WORKSPACE_ID" \
  --cwd "$repo_root" \
  --label "BBQ $ticket_id $phase" \
  --no-focus
```

Parse `.result.root_pane.pane_id`, generate a run-scoped agent name no longer than 32 characters, and run:

```bash
herdr agent start "$agent_name" \
  --kind opencode \
  --pane "$pane_id" \
  -- "$repo_root"
```

Append both JSON responses to the phase log. Never predict pane IDs.

- [ ] **Step 5: Implement prompt, blocked interaction, and wait handling**

Submit:

```bash
herdr agent prompt "$agent_name" "/$command_name $command_arguments" --wait
```

Inspect `.result.agent.agent_status`. When blocked:

1. print the direct attach command;
2. call `herdr agent wait "$agent_name" --until idle --until done` without an arbitrary timeout;
3. inspect the returned status;
4. preserve all responses in the phase log.

Do not send keys or answer approval prompts automatically. On a CLI error, read the agent once for diagnostics, report the retained agent name, and stop later phases.

- [ ] **Step 6: Implement transcript capture and marker evaluation**

After the agent settles, run:

```bash
herdr agent read "$agent_name" \
  --source recent-unwrapped \
  --lines 200
```

Save plain text separately, append it to the phase log, and call the shared `evaluate_phase_result`. Print `herdr agent attach <name>` after completion so the retained session is discoverable.

- [ ] **Step 7: Run both orchestration suites**

Run:

```bash
bash packages/opencode/test/bbq-orchestrate.test.sh
bash packages/opencode/test/bbq-orchestrate-herdr.test.sh
```

Expected: PASS.

- [ ] **Step 8: Commit Herdr orchestration**

```bash
git add packages/opencode/bbq-orchestrate.sh \
  packages/opencode/test/bbq-orchestrate-herdr.test.sh
git commit -m "feat(opencode): orchestrate phases with herdr"
```

## Task 6: Document and Verify the Complete Integration

**Files:**
- Modify: `README.md`
- Modify: `packages/opencode/README.md`
- Modify: `AGENTS.md`

- [ ] **Step 1: Update installation documentation**

Document both forms:

```bash
./init.sh /path/to/project
./init.sh /path/to/project --herdr
```

State clearly that BBQ Party does not install Herdr, the Herdr choice defaults to No, and selecting it downloads the matching official skill and may update the user-level OpenCode integration.

- [ ] **Step 2: Document runtime and fallback semantics**

Explain `.opencode/bbq-config.json`, `HERDR_ENV=1`, native fallback outside Herdr, separate retained phase agents, direct attach commands, and the unchanged `.opencode/.bbq-runs/` logs.

- [ ] **Step 3: Document worktree semantics**

Explain that Herdr creates and opens worktree workspaces while BBQ Party preserves its project-local path and local-file mirroring. Keep native cleanup instructions and add Herdr-aware cleanup:

```bash
herdr worktree remove --workspace <workspace-id>
```

Warn that it never deletes the branch and requires explicit `--force` for dirty worktrees.

- [ ] **Step 4: Update repository verification guidance**

Add these commands to `AGENTS.md`:

```bash
bash test/init-herdr.test.sh
bash packages/opencode/test/worktree-local-files.test.sh
bash packages/opencode/test/worktree-provider-contract.test.sh
bash packages/opencode/test/bbq-orchestrate.test.sh
bash packages/opencode/test/bbq-orchestrate-herdr.test.sh
```

- [ ] **Step 5: Run the complete shell verification suite**

Run all five commands above. Expected: PASS with no network, Docker, Herdr server, or real OpenCode session required because tests use temporary mocks.

- [ ] **Step 6: Manually smoke-test against Herdr stable**

In a disposable Git repository with test credentials:

1. run `./init.sh <repo> --herdr --skip-docker --skip-env`;
2. verify the downloaded skill tag matches `herdr --version`;
3. launch `herdr` from the repository;
4. run `./bbq-orchestrate.sh --start-phase fire <test-ticket>` from a Herdr shell pane;
5. verify a retained phase tab and OpenCode agent appear;
6. verify `/bbq.fire` creates or opens the explicit `.opencode/.bbq-worktrees/...` checkout as a Herdr workspace;
7. detach and reattach to confirm the runner and phase agent remain alive;
8. confirm a plain non-Herdr invocation prints the fallback notice and uses the native backend.

Do not automate real Linear or GitHub mutations in the smoke test unless a dedicated test ticket and repository are available.

- [ ] **Step 7: Commit documentation**

```bash
git add README.md packages/opencode/README.md AGENTS.md
git commit -m "docs: explain optional herdr runtime"
```

## Error and Safety Requirements

- Never install, update, stop, or live-handoff the Herdr binary or server from BBQ Party.
- Never answer a Herdr agent's blocked permission or question UI automatically.
- Never use a UI-focused pane implicitly; use `HERDR_WORKSPACE_ID`, returned pane IDs, or unique agent names.
- Never derive Herdr IDs from ordering or labels.
- Never replace an existing downloaded skill unless the new download validates completely.
- Never silently treat malformed project runtime configuration as native mode.
- Never overwrite local-only files already present in a worktree.
- Never pass `--trust-repository` automatically.
- Retain phase panes by design; document manual cleanup rather than closing them from the runner.
- Treat Herdr plugins and the local socket as same-user trusted execution surfaces.

## Deferred Enhancements

These ideas are compatible with the design but are not required for the first integration:

- report ticket ID, workflow phase, branch, and PR URL as Herdr workspace or pane metadata;
- install an Agent view that filters to active BBQ Party runs;
- expose a cleanup command for completed phase tabs and agents;
- emit explicit Herdr notifications when a phase blocks or completes;
- use saved Herdr machine profiles for remote BBQ Party execution;
- parallelize independent research/review agents after the sequential workflow is stable;
- replace static command contract tests with end-to-end OpenCode fixtures if OpenCode gains a deterministic local test mode.

## Completion Criteria

The integration is complete when:

- native installation and orchestration remain unchanged by default;
- Herdr can be selected interactively or with `--herdr`;
- Herdr absence fails with guidance and no implicit installation;
- the matching upstream Herdr skill and OpenCode integration are installed safely;
- Herdr mode runs each workflow phase in a separate retained OpenCode agent;
- blocked agents can be attached to and resumed without losing the runner;
- Herdr creates/opens ticket worktrees at the existing deterministic path;
- local-only file mirroring works with both providers;
- outside-Herdr execution falls back to the native backend;
- all shell tests and the documented smoke test pass.
