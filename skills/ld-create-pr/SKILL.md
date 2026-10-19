---
name: ld-create-pr
description: Open a pull request with a body a reviewer can act on — the problem in real numbers, the approach and what it beat, the accepted cost, where the risk is, and how to verify. Picks the repo's own template from .github/ (falls back to its own), selects the variant from the ticket type, and builds the substance from the branch's plan, commits and diff rather than from a paraphrase of the diff. Drafts everything and waits for approval before anything reaches GitHub. Use whenever the user wants a PR opened or a PR body written — "armá el PR", "abrí el pull request", "necesito el body del PR" — and when a PR already exists whose body no longer matches the branch. Touches GitHub only; the ticket side is the ship stage of ld-workflow.
argument-hint: "[free-text framing, or nothing]"
allowed-tools: Read, Write, Bash
---

Write a PR body that a reviewer can act on without reading the diff first, and that answers their objections before they raise them.

**Arguments** are optional free text — a framing, an emphasis, a caveat the user wants surfaced. With none, everything comes from the branch.

**Adapter slots** (`~/dev/ld-harness/skills/ld-workflow/SKILL.md` §9): `ticket.fetch` (how to read the ticket and its type), `ticket.ref` (how the PR references it) and `plan.path`. Without an adapter: a GitHub issue number from the branch, `Closes #N`, and `.tmp/tasks/<id>/plan.md`.

## The rule that shapes everything else

**The body is built from evidence on disk, never from a paraphrase of the diff.** A body written by reading the diff and describing it back is a changelog: it says what changed, which the reviewer can already see, and omits why, which is the only thing they cannot. The sections below exist to force the why, and each one is allowed to be **absent** rather than filled with prose that has no evidence behind it.

Concretely: a "The problem" section with no numbers in it is worse than no section, because it promises evidence and delivers adjectives. Cut it and say so in the draft.

## Steps

### 1. Resolve the ticket and the base

The ticket id comes from the branch name, through the adapter's `ticket.ref` shape (`feat/PROJ-98_normalize-score` → `PROJ-98`; without an adapter, a trailing issue number: `feat/auth-middleware-6` → `#6`). Failing that, from the commit subjects. Failing that, ask once. **Never guess a number out of a key**: `task/PROJ-139_x` is not issue `#139`.

**No ticket is a valid answer.** Some work has none. Replace the ticket line with `No ticket` and carry on — never block on it, and never invent one.

Base branch: the plan's `**Base:**` line when the task has a plan, `main` otherwise — never the branch's upstream, which `git push -u` points at the branch's own remote copy. Confirm when the branch looks cut from something else, since a stacked PR against `main` shows a diff nobody asked for.

### 2. Run the mechanical gates

These are cheap, they are the ones a human forgets, and a PR that fails them wastes a reviewer's pass:

```bash
git status --porcelain                                  # empty, or the diff is not what you are describing
git log --oneline @{u}..HEAD 2>/dev/null                # empty, or the branch is not pushed
git log --oneline HEAD..origin/<base>                   # empty, or the branch is behind
git diff --shortstat origin/<base>...HEAD               # the Net: line
git log --oneline origin/<base>..HEAD                   # the commits, for the type and the substance
```

Not pushed → show `git push -u origin <branch>` and stop: the push is the user's (ld-gate blocks it). `Net:` is quoted from `--shortstat`, never estimated.

**Report the size when the diff exceeds ~400 changed lines.** Review effectiveness drops sharply past that (the SmartBear finding), so the reviewer is going to miss things and it is worth the user knowing before they open it rather than after. Say it once, in the draft, as a fact — not as a demand to split the PR.

**Checks:** do not run the repo's gates; CI runs them on the PR. Name the gate command if the repo has an obvious one (`package.json` script, `Makefile` target) and say CI owns it.

### 3. Pick the template

Read the repo's own templates — they are the contract, because they are what another developer sees:

```txt
.github/pull_request_template.md          default: feature and task work
.github/PULL_REQUEST_TEMPLATE/bug.md      a bug fix
.github/PULL_REQUEST_TEMPLATE/chore.md    docs, deps, renames, moves
```

**The ticket's type picks the variant** — read through `ticket.fetch` (a Jira issue type, a GitHub `bug` label). Bug → `bug.md`. Story, feature, task → the default. No ticket, or a diff that is only docs and config → `chore.md`. This is why nobody has to choose: the classification already happened when the ticket was written.

When the repo has no templates, fall back to this skill's `templates/` (`feature.md`, `bug.md`, `chore.md`), and **offer to write them into the repo's `.github/`** — that is how the next repo inherits the convention instead of copying it by hand. Offer once; a decline is final.

### 4. Gather the substance

In descending order of value, because the first two carry reasoning and the last two only carry facts:

1. **The plan** (`plan.path`) if the task has one — the phases and the decisions taken, which is where "why this approach" actually lives.
2. **The ticket** — the problem as stated before the work started, and the scope the PR may have grown past.
3. **The commit subjects** — the shape of the work, and the type for the title.
4. **The diff** — last, and only to check the claims. Reading it first is what produces a changelog.

**Name the source of each section in the draft** (`from the plan, decision 4`, `from the diff — unverified`). The user is reviewing whether the body is *true*, and they can only do that if they can see which sentences are grounded and which are your reading.

### 5. Fill the sections

Each heading in the template maps to an instruction. The template's own HTML comment is the short form for a human; this is the long form:

| Heading | What has to be true of it |
|---|---|
| **Opening line** | One or two sentences, standalone: a reader who never opens the diff still knows what changed and why. Ticket link on this line. |
| **The problem** | The problem that motivated the work, in evidence — real numbers from a real run, real output, a `path:line`. Any claim of an improvement carries the numbers that back it (the kernel rule). **No evidence, no section.** |
| **What changed, and why this approach** | The approach, plus the alternative that was rejected and the reason it lost. A reviewer who disagrees should find their objection already answered. |
| **Accepted cost** | Where the approach falls short, or what got worse. Omit only when nothing got worse — and check twice before believing that. |
| **What reviewers should know** | Where the risk is, and anything in the diff that reads as a mistake without context: deleted tests, a behaviour change for existing callers, scope that grew past the ticket. **State the growth explicitly** — scope a reviewer discovers is scope they distrust. |
| **How to verify** | Commands runnable verbatim with their expected results. "Run the tests" is not verification; a command with the numbers it should print is. |
| **Out of scope, on purpose** | What was deliberately not done, so review does not reopen it. |
| **What was broken** *(bug)* | The reproduction verbatim, then expected vs actual with the real output. |
| **Root cause** *(bug)* | The mechanism at `path:line`. Unconfirmed causes are labelled unconfirmed — a guess presented as a diagnosis sends the review the wrong way. |
| **The fix** *(bug)* | What changed, and why at this layer rather than another one where it would also have worked. That choice is the part of a bug fix reviewers most often disagree with. |
| **Why it will not come back** *(bug)* | The regression test and what it asserts. A fix whose test does not fail without it is a fix nobody can defend later. |

**A heading this table does not know gets filled from its own name and its HTML comment.** The repo's template wins over this skill: someone adding a section there must not have to edit a global skill for it to be filled.

**Writing rules:**

- **English, always** — the PR is team-facing (ld-prosa's hard boundary).
- **Imperative mood, and never "this PR does X"** — "normalize the score over evaluated domains", not "this PR normalizes the score". Straight from the kernel's `SubmittingPatches`.
- **No people.** No names, no reviewer requests, no "coordinate with X" — unless the user explicitly asks for a reviewer.
- **Never reference anything the reviewer cannot open.** No plan file, no scratch files, no chat. Reasoning that lives only in the plan gets rewritten into the body; a pointer to something private reads as if there is more to read and there is not.
- **Cite code as `path/to/file.ts:42`** with the smallest snippet that proves the claim.
- **No checkbox checklist.** It gets ticked without reading and an unticked box blocks nothing. Step 2 is what those boxes were pretending to be.
- **`ticket.ref` decides the link.** A GitHub issue gets `Closes #N` as the body's last line, so merging closes it. A key from another tracker goes on the opening line as a link and as the title suffix.

### 6. Compose the title

```txt
<type>(<scope>): <imperative summary> (<TICKET-KEY>)
```

`type` describes **the change as a whole**, not the sum of its commits — a branch with `feat`, `fix`, `test` and `docs` commits that delivers a feature is `feat`. `scope` is the area of the codebase (`web`, `api`, `core`), following Conventional Commits, where a scope "MUST consist of a noun describing a section of the codebase" — **never the ticket key**, since changelog tooling groups by scope and grouping by ticket is not grouping. The key goes in the suffix, where it stays visible in the PR list and readable by tracker integrations. Drop the suffix for a GitHub issue (`Closes #N` already links it) and when there is no ticket.

State the type and scope you chose in the draft, since it is a judgment call on a multi-commit branch.

### 7. Show it, then open it

Print the full draft — title, template chosen and why, the gate results, `Net:`, the body, and any section deliberately omitted with the reason. Wait for approval.

The `gh` call may also be gated by a permission prompt, but that prompt only asks whether to run a command; it cannot show whether the body is *right*. This step is what makes the approval mean something.

```bash
gh pr create --base <base> --title "<title>" --body-file <file>
```

Open, not draft, unless the user asks. Write the body through a file in the scratchpad rather than an inline `--body`, so backticks and `$` survive the shell.

### 8. Existing PR

If a PR is already open for the branch (`gh pr view --json number,title,body`), do not open a second one. Diff the current body against what step 5 produces and **only offer the update when it would actually change something** — new commits the body does not mention, a claim the diff no longer supports, a section now fillable. A body that would come out the same is left alone rather than rewritten to look busy.

### 9. Hand back the link

The URL and one line, nothing more:

```txt
PROJ-98 · feat(core) · +736 / −358 across 32 files
https://github.com/<org>/<repo>/pull/33
```

## What this skill does not do

- **Nothing in the ticket.** No comment, no transition. Touching one system keeps it safe to invoke on its own; the ticket side is the ship stage (`/ld-ship-task` or the project's adapter).
- **No reviewers, no assignees, no labels** unless the user asks for them by name.
- **No merging, and no chasing CI.** The PR is opened and handed back.
- **No commits, no push.** A dirty tree or an unpushed branch stops step 2 and gets reported.
