# Duplication audit — durable facts

**Date:** 2026-11-06
**Audited commit:** `df0ef48` (origin/main; this branch was cut from it)
**Status:** snapshot, not a source of truth. This file inventories duplication; it does not choose canonical homes — that is E2 (#4).

## Scope

Included:

- repo: `AGENTS.md`, `README.md`, `docs/`, `skills/`, `commands/`, `plugins/`, `setup.sh`, `config.example.env`, `.github/`, `.claude-plugin/`
- project adapters: `~/dev/academika/.opencode/commands/aika-*.md`, `~/unq/seminario/proyecto-finisterre/.opencode/commands/fini-*.md`, `~/.config/ld-harness/adapters/droplet-*.md`
- global config: `~/.config/opencode/AGENTS.md`

Excluded:

- symlinked installs (`~/.config/opencode/{commands,skills,plugins}`, `~/.claude/{commands,skills}`): same file, not a copy
- command→skill boilerplate and announce lines
- terminology and background prose with no behavioral consequence
- adapter values that intentionally override a harness default: parameters per D6, not duplicates
- facts missing where they would be needed: that is #5
- transient status: branches, open-issue counts
- repetitions inside a single file: one copy per file and surface; an intra-file restatement does not compete for a home
- git history: D3's commit body is the decision canon, not a file copy

## Method

A fact is a durable assertion that changes what an agent does: a decision, rule, path or mechanism, threshold, or a value shared between code and docs. Copies are cited at the audited commit as `path:line`.

A row is `consistent` when the copies agree today and `diverge` when they disagree.

Risk: **high** when the copies disagree in a way that changes behavior, or the rule is gate-enforced or irreversible; **medium** when they are consistent today but edited independently; **low** when the difference is wording with no behavioral consequence.

`path:line` points at the audited commit. Later commits move lines; the finding, not the number, is the durable part.

## Summary

Pending: counts per type and the high-risk list are filled in phase 2.

## 1. Mechanism, path or constant

### 1 · Pre-commit checks name different suites

**Copies.** `AGENTS.md:30-35` · `README.md:64-71` · `.github/workflows/tests.yml:19-26`
**State.** `diverge` — AGENTS runs `ld-gate` + `ld-format`; CI runs `ld-gate` + `ld-format` + `ld-prosa` + shellcheck.
**Risk.** high — the local checklist omits a suite CI enforces.

### 2 · Gate trio: no push, no commit on main, no catastrophic patterns

**Copies.** `README.md:66-67` · `plugins/ld-gate/.claude-plugin/plugin.json:3` · `.claude-plugin/marketplace.json:24` · `skills/ld-workflow/SKILL.md:63` (push and main only)
**State.** `consistent`
**Risk.** high — enforced by `plugins/ld-gate`.

### 3 · How the gate decides (git -C, cd prefix, heredocs, text exemption)

**Copies.** `skills/ld-workflow/SKILL.md:63-71` · `plugins/ld-gate/hooks/block-commit-on-main.sh:10-22` · `plugins/ld-gate/opencode-plugin.js:37-49`
**State.** `consistent`
**Risk.** high — the skill describes the hook's matching; a hook change turns the skill into a wrong instruction.

### 4 · Catastrophic pattern list lives in two engines

**Copies.** `plugins/ld-gate/opencode-plugin.js:21-35` · `plugins/ld-gate/hooks/block-catastrophic.sh:39-68`
**State.** `consistent` — the lists match today; both files say to change the other.
**Risk.** high — one list changed alone opens a hole in the other engine.

### 5 · Who runs the checks

**Copies.** `skills/ld-create-pr/SKILL.md:46` · `skills/ld-self-review/SKILL.md:21-26` · `skills/ld-code-review-pr/SKILL.md:70-77,492` · `skills/ld-deps-task/SKILL.md:119-122` (opposite)
**State.** `diverge` — the review skills say CI owns the gates; deps-task says run everything CI runs locally before opening the PR.
**Risk.** high — same question, two policies; the deps flow is the intentional exception, but nothing says so.

### 6 · Academika checkout path

**Copies.** `~/dev/academika/.opencode/commands/aika-start-task.md:13` · `~/dev/academika/.opencode/commands/aika-implement-task.md:13` · `~/dev/academika/.opencode/commands/aika-self-review.md:13` · `~/dev/academika/.opencode/commands/aika-ship-task.md:13` · `~/dev/academika/.opencode/commands/aika-close-task.md:14` · `~/dev/academika/.opencode/commands/aika-status.md:11` · `~/.config/ld-harness/adapters/droplet-academika.md:3-5`
**State.** `diverge` — the five workflow adapters set `~/unq/seminario/academika/` as the session cwd; the ops adapter says the canon is `~/dev/academika` and to use that one.
**Risk.** high — an agent can commit to the wrong checkout.

### 7 · Config precedence: three levels

**Copies.** `config.example.env:6` · `AGENTS.md:43-44` · `README.md:148` · `docs/agent-system.md:98-100` · `plugins/ld-prosa/hooks/config.js:1-2`
**State.** `consistent` — code default < user config < project config, dotenv.
**Risk.** medium — five surfaces edited independently.

### 8 · Prose keys, defaults and voseo inference

**Copies.** `config.example.env:10-21` · `plugins/ld-prosa/hooks/config.js:8-11` · `plugins/ld-prosa/hooks/nudge.js:10-19` · `README.md:152-159` · `docs/agent-system.md:105-108` · `plugins/ld-prosa/skills/ld-prosa/SKILL.md:70-72`
**State.** `consistent` — `LD_PROSA_CHAT=es-AR`, `LD_PROSA_ARTIFACTS=en`, `LD_PROSA_REGISTER=informal`; `es-AR` implies voseo; code always English.
**Risk.** medium — defaults are written twice (example and code) and the rules four more times.

### 9 · Config directory and its adapters subdirectory

**Copies.** `setup.sh:8,20-21` · `config.example.env:3` · `README.md:136-146` · `docs/agent-system.md:88-100` · `skills/ld-ops/SKILL.md:20-23` · `skills/ld-db/SKILL.md:19-21`
**State.** `consistent` — `~/.config/ld-harness/config.env`, `adapters/` under the same root.
**Risk.** medium.

### 10 · Where a cross-project environment adapter lives

**Copies.** `docs/agent-system.md:64-70` (D6: `adapters/<tipo>-<nombre>.md`) · `docs/agent-system.md:125-127` (D9: `environments/`) · `README.md:144-146` · `skills/ld-ops/SKILL.md:20-23` · `skills/ld-db/SKILL.md:19-21` · `AGENTS.md:42` · `~/.config/ld-harness/adapters/droplet-12-cactus.md:1` · `~/.config/ld-harness/adapters/droplet-academika.md:1`
**State.** `diverge` — D9 names `~/.config/ld-harness/environments/`; D6, README, ops, db and the two live droplet files use `~/.config/ld-harness/adapters/`.
**Risk.** high — a reader following D9 creates the file in a directory nothing reads.

### 11 · Plan path

**Copies.** `skills/ld-workflow/SKILL.md:26,282` · `skills/ld-create-pr/SKILL.md:12` · `~/dev/academika/.opencode/commands/aika-implement-task.md:23` · `~/dev/academika/.opencode/commands/aika-self-review.md:22`
**State.** `consistent` — `.tmp/tasks/<id>/plan.md`.
**Risk.** medium — the two Académika adapters restate the default instead of pointing at §9.

### 12 · Base branch rule

**Copies.** `skills/ld-workflow/SKILL.md:50-53` · `skills/ld-create-pr/SKILL.md:28` · `skills/ld-self-review/SKILL.md:37` · `skills/ld-deps-task/SKILL.md:105`
**State.** `consistent` — the plan's `**Base:**`, `main` otherwise; never the branch's upstream.
**Risk.** medium.

### 13 · Harness path literal

**Copies.** 29 occurrences in 18 files; representative: `setup.sh:7` · `README.md:112-113` · `docs/agent-system.md:102-103` · `commands/ld-start-task.md:9` · `skills/ld-self-review/SKILL.md:14` · `skills/ld-improve-harness/SKILL.md:8`
**State.** `consistent` — `~/dev/ld-harness`; only `setup.sh` parameterizes it (`HARNESS=`).
**Risk.** medium — moving the checkout breaks every literal at once.

### 14 · setup.sh idempotence and symlink destinations

**Copies.** `setup.sh:2,31-54,78-85` · `README.md:129-134` · `docs/agent-system.md:99-103`
**State.** `consistent` — links into `~/.config/opencode/{commands,skills,plugins}` and `~/.claude/{skills,commands}`, rerunnable, purges dangling links.
**Risk.** medium.

### 15 · PR templates duplicated

**Copies.** `.github/pull_request_template.md:1-13` ↔ `skills/ld-create-pr/templates/feature.md:1-15` · `.github/PULL_REQUEST_TEMPLATE/bug.md` ↔ `skills/ld-create-pr/templates/bug.md` · `.github/PULL_REQUEST_TEMPLATE/chore.md` ↔ `skills/ld-create-pr/templates/chore.md` · `skills/ld-create-pr/SKILL.md:52-60`
**State.** `diverge` — the feature pair differs at line 9 (the fallback marker); bug and chore are identical.
**Risk.** medium — the fallback is the copy other repos get; an edit to one does not reach the other.

### 16 · PR body section instructions

**Copies.** `.github/pull_request_template.md:13-45` · `skills/ld-create-pr/SKILL.md:77-91`
**State.** `consistent` — the template's HTML comment is the short form, the skill table the long form.
**Risk.** medium.

### 17 · Prosa injection model

**Copies.** `README.md:161-165` · `plugins/ld-prosa/opencode-plugin.js:2-10` · `plugins/ld-prosa/hooks/ld-prosa-activate.js:2-13` · `plugins/ld-prosa/hooks/ld-prosa-reminder.js:2-7` · `plugins/ld-prosa/hooks/nudge.js:1-4`
**State.** `consistent` — Claude injects core + language references at SessionStart and the nudge per turn; opencode appends the nudge per request.
**Risk.** medium.

### 18 · Rule-pack discovery

**Copies.** `skills/ld-code-review-pr/SKILL.md:113-129` · `README.md:214-217`
**State.** `consistent` — a `# Repo profiles` appendix keyed on `basename $(git remote get-url origin) .git`; first match wins.
**Risk.** medium.

### 19 · Plugin descriptions

**Copies.** `.claude-plugin/marketplace.json:11-14,22-26` · `plugins/ld-prosa/.claude-plugin/plugin.json:3-4` · `plugins/ld-gate/.claude-plugin/plugin.json:2-3`
**State.** `diverge` — the `ld-prosa` description is shorter in the marketplace; `ld-gate` matches.
**Risk.** low — discovery wording, no behavior.

### 20 · Format skip rule

**Copies.** `README.md:68-71` · `plugins/ld-format/format-md.sh:13-15,27-40`
**State.** `consistent` — a repo with its own formatter config is left alone; the list of config files lives in the script.
**Risk.** medium.

### 21 · PR title convention

**Copies.** `.github/pull_request_template.md:2-4` · `skills/ld-create-pr/SKILL.md:106-109`
**State.** `consistent` — `<type>(<scope>): <imperative summary>`, type from the whole change, scope never the ticket key.
**Risk.** low.

## 2. Decision and rationale

### 22 · Merge policy

**Copies.** `AGENTS.md:11` · `~/.config/opencode/AGENTS.md:5-9` · `README.md:22-23` · `skills/ld-workflow/SKILL.md:240` · `skills/ld-deps-task/SKILL.md:17,138` · `skills/ld-create-pr/SKILL.md:144`
**State.** `consistent` — merges are the user's; the global copy adds "a 'mergeamos' is not an invocation", the repo copy does not contradict it.
**Risk.** high — irreversible and repeated in seven surfaces.

### 23 · Push policy

**Copies.** `AGENTS.md:9` · `README.md:22,102` · `skills/ld-workflow/SKILL.md:63,232` · `skills/ld-create-pr/SKILL.md:42` · `skills/ld-review-fix/SKILL.md:72` · `skills/ld-deps-task/SKILL.md:129` · `skills/ld-sync/SKILL.md:26-27` · `skills/ld-improve-harness/SKILL.md:50` · `plugins/ld-gate/hooks/block-git-push.sh:2-4`
**State.** `consistent` — the agent shows the command and stops.
**Risk.** high — gate-enforced and repeated in nine surfaces.

### 24 · Design constraints repeated in AGENTS and docs (D1, D6, D7, D8)

**Copies.** `AGENTS.md:39-46` · `docs/agent-system.md:12-15,64-70,72-82,88-108`
**State.** `consistent` — AGENTS is the always-loaded summary, docs is the full record.
**Risk.** medium — two levels of detail edited independently.

### 25 · D9's adapter future

**Copies.** `docs/agent-system.md:110-136` · `README.md:205-217,221-223`
**State.** `diverge` — D9 says the `aika-*` / `gr-*` / `fini-*` adapters "se borran" and `ld-*` fires directly; README says the local commands "se adelgazan a adapters que delegan".
**Risk.** medium — planning consequence, not runtime. A start decision on #3 (2026-11-06) says the harness does not delete adapters; D9's deletion half is stale against that decision.

### 26 · Commit body format

**Copies.** `docs/agent-system.md:23-26,28-43` · `skills/ld-workflow/SKILL.md:59-63` · `skills/ld-review-fix/SKILL.md:63-67` · `AGENTS.md:27-28`
**State.** `consistent` — what changed, why, what was discarded; subject ≤72.
**Risk.** medium — AGENTS points at §1; the other three restate the format.

### 27 · Engram protocol

**Copies.** `README.md:174-188` · `skills/ld-workflow/SKILL.md:117-122`
**State.** `diverge` — README's start step is `mem_context` and/or `mem_search`; §3 names only `mem_search`.
**Risk.** medium — a session following §3 can skip recent history.

## 3. Rule the agent must always apply

### 28 · Discuss before executing

**Copies.** `README.md:15-17` · `skills/ld-workflow/SKILL.md:95-116` · `skills/ld-define-ticket/SKILL.md:60-70`
**State.** `consistent` — proposal, discarded alternative, numbered doubts; the ticket says what, start decides how.
**Risk.** medium.

### 29 · Closure proportional to the task

**Copies.** `README.md:20-21` · `skills/ld-workflow/SKILL.md:37-42`
**State.** `consistent` — `fino` / `normal` / `full`, with the reason on one line.
**Risk.** medium.

### 30 · `ld-` prefix, no vendoring

**Copies.** `README.md:30-32` · `skills/ld-improve-harness/SKILL.md:31-32`
**State.** `consistent`
**Risk.** low.

## 4. Procedure

### 31 · Five-stage workflow

**Copies.** `README.md:90-108` · `skills/ld-workflow/SKILL.md:8-22`
**State.** `consistent` — start → implement → self-review → ship → close.
**Risk.** medium — README is the daily summary; §4–§8 are the contract.

### 32 · Status three blocks

**Copies.** `skills/ld-status/SKILL.md:8-9,26-59` · `commands/ld-status.md:7-8` · `~/dev/academika/.opencode/commands/aika-status.md:61-94` · `~/unq/seminario/proyecto-finisterre/.opencode/commands/fini-status.md:35-63`
**State.** `consistent` — the block names and the one-line rule repeat; the adapters add local limits (7 vs 5 tickets) and the closing question.
**Risk.** medium.

### 33 · Two-agent review mechanics

**Copies.** `skills/ld-self-review/SKILL.md:98-122` · `skills/ld-code-review-pr/SKILL.md:175-199` · `skills/ld-review-reconcile/SKILL.md:13-39`
**State.** `consistent` — personal (contract, correctness, security) + ponytail (lean, load, tests), then reconcile; reconcile is the declared launcher.
**Risk.** medium — the two reviews restate the brief that reconcile owns.

### 34 · Severity lexicon

**Copies.** `skills/ld-workflow/SKILL.md:55` · `skills/ld-code-review-pr/SKILL.md:198-199` · `plugins/ld-prosa/skills/ld-prosa/references/posturas.md:31-34`
**State.** `consistent` — 🔴 must-fix, 🟡 should-fix, ⚪ nit.
**Risk.** medium.

### 35 · Harness validation checklists

**Copies.** `skills/ld-improve-harness/SKILL.md:34-42` · `skills/ld-sync/SKILL.md:28-33`
**State.** `diverge` — improve runs `setup.sh`, `node --check`, frontmatter and symlinks; sync runs frontmatter, symlinks and a risky-pattern scan.
**Risk.** medium — two "validate the harness" procedures with different items.

### 36 · Fixup and autosquash

**Copies.** `skills/ld-workflow/SKILL.md:211,215` · `skills/ld-self-review/SKILL.md:210,222`
**State.** `consistent` — `git commit --fixup=<sha>` then `GIT_SEQUENCE_EDITOR=: git rebase -i --autosquash`.
**Risk.** medium.

### 37 · ADR default directory

**Copies.** `skills/ld-adr/SKILL.md:14` · `~/unq/seminario/proyecto-finisterre/.opencode/commands/fini-adr.md:9-11` · `~/dev/academika/.opencode/commands/aika-adr.md:9-11`
**State.** `consistent` — `~/unq/seminario/proyecto-finisterre/decisiones/` + `README.md` index.
**Risk.** low — the general skill hardcodes a project path as its default; the adapters repeat it.

## 5. Foundation, evidence, diagram

No finding: B1 and A2 live only in `docs/agent-system.md:148-232`; no second copy.

## Notes

- The start decision on #3 (2026-11-06) says the harness does not delete adapters. That is a decision, not a file copy; it is recorded here because it makes D9's deletion half stale.
- `aika-*` and `fini-*` are outside this repo; their copies are cited with `~` paths and will not appear in a repo diff.
