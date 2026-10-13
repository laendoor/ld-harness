---
name: ld-code-review-pr
description: Review someone else's open PR and post the result as one GitHub review — every finding anchored to its line, with a suggestion block where the fix is exact, plus a two-sentence general body (or an LGTM when clean). Picks up the repo's own review rule pack when it has one, falls back to a generic scan when it doesn't. Triages with you and waits for your authorization before anything reaches GitHub. Re-runs skip findings already commented and offer to resolve threads gone stale. For your own branch before a PR exists, use /ld-self-review (or the project's self-review adapter) instead.
argument-hint: <pr-number-or-url> [--full]
allowed-tools: Read, Grep, Glob, Bash(gh pr *), Bash(gh api *), Bash(gh auth *), Bash(git worktree *), Bash(git fetch *), Bash(git diff *), Bash(git log *), Bash(git show *), Bash(git rev-parse *), Bash(git check-ignore *), Bash(git remote *), Bash(grep:*), Bash(awk:*), Bash(jq:*), Bash(ls:*), Bash(cat:*), Bash(test:*), Bash(wc:*), Bash(mkdir:*), Write
---

Review an open PR you did not write, and land the findings where they belong: on the lines.

This is the counterpart to `/ld-self-review`. That one runs on your own branch before
a PR exists, so a finding becomes a commit. This one starts from a PR that already exists, so a finding
becomes a review comment.

**Arguments:**
- `$1` = PR number or URL. Missing → `gh pr list --state open --limit 20` and ask which.
- `--full` = keep ⚪ and `speculative` findings. Default drops both.

## Step 0 — Resolve the PR

```bash
gh pr view <n> --json number,title,author,baseRefName,headRefName,headRefOid,url,state,mergeable,body
```

Unauthenticated `gh` → stop, tell the user to `gh auth login`.

Record `<n>`, `<base>`, `<head>` (full `headRefOid`), `<sha>` (first 8 of it), `<owner>/<repo>` from `url`.
Note `mergeable: CONFLICTING` in the opening line, then proceed against the head branch.

### Title convention — calibrated against the repo, not assumed

Conventional Commits is not universal, and a global skill has no business imposing it on a repo that never
adopted it. So ask the repo:

```bash
gh pr list --state merged --limit 20 --json title --jq '.[].title' \
  | grep -cE '^(feat|fix|docs|style|refactor|perf|test|build|ci|chore|revert)(\([a-z0-9/_.-]+\))?!?: .'
```

Compare against the total. A **majority** of merged titles matching means the repo has the convention in
practice, and this PR's title is held to it; a minority means it does not, and there is nothing to enforce.
Say which way it went and on what count — a check whose calibration is invisible looks like a rule you
invented.

A title that breaks an established convention is a 🟡 finding routed to `Body` (a title has no line to anchor
to), `confidence: certain`, and it goes through triage like anything else. Propose the rewritten title
verbatim so accepting it is a copy-paste. **Never let it gate a merge** — renaming a PR is free and touches
no code, so it does not belong in a `request-changes` verdict.

### Author check — warn, don't refuse

```bash
ME=$(gh api user --jq .login)
```

If `author.login == $ME`, this is your own PR. **Do not refuse** — say so in one line, and force `event: COMMENT`
at Step 7: GitHub rejects `APPROVE`/`REQUEST_CHANGES` from the author, and a 422 at the very last step after a
full review is a waste. Everything else runs unchanged.

## Step 1 — Worktree, no install

```bash
git fetch origin pull/<n>/head
git worktree add ../<repo>-pr-<n> --detach FETCH_HEAD
```

The diff alone is not enough to review someone else's code — half the real findings need the file around the
hunk, or the caller in another module. A detached worktree gives that without disturbing your tree.

**No install, no gates.** CI already ran them on the PR; read the result instead of spending minutes
reproducing it:

```bash
gh pr checks <n>
```

A red check is context for the report, not a finding of yours — cite it in the body and move on.

## Step 2 — Cache the diff

The cache goes in `.claude/reviews/` **only if `.claude/` is actually ignored in this repo** — a global skill
runs in repos that have never heard of it, and a diff dump committed by accident is a real mess:

```bash
git check-ignore -q .claude && CACHE=.claude/reviews || CACHE=${TMPDIR:-/tmp}/ld-code-review-pr
mkdir -p "$CACHE"
DIFF="$CACHE/pr-<n>-<sha>.diff"
gh pr diff <n> > "$DIFF"
```

`<sha>` in the name means a force-push invalidates the cache by itself. Say which path you picked — a cache
under `/tmp` will not survive for tomorrow's re-run, and the dedupe in Step 3 is what covers that anyway.

## Step 3 — Prior review state

A second run on the same PR must not repost what is already there.

```bash
gh api repos/<owner>/<repo>/pulls/<n>/comments --paginate \
  --jq '.[] | select(.user.login == "'"$ME"'") | {id, path, line, original_line, body: .body[0:120]}'
```

```bash
gh api graphql -f query='query($o:String!,$r:String!,$n:Int!){
  repository(owner:$o,name:$r){ pullRequest(number:$n){ reviewThreads(first:100){ nodes{
    id isResolved isOutdated
    comments(first:1){ nodes{ author{login} path line body } } } } } } }' \
  -f o=<owner> -f r=<repo> -F n=<n>
```

Hold both for Step 5 (dedupe) and Step 7 (resolve). Nothing is posted or resolved here.

## Step 4 — Rules: the repo's pack, or the generic fallback

Deterministic rules are repo-specific by nature — an OpenAPI drift check means nothing in a Terraform repo.
An adapter that invokes this skill (`gr-code-review-pr`, …) names its pack directly — use that one and skip
the discovery. Otherwise look for a rule pack, in this order, and use the first that exists:

```bash
grep -l 'review\.scans' ~/.claude/skills/*/SKILL.md .claude/skills/*/SKILL.md 2>/dev/null \
  | xargs grep -l '^# Repo profiles'    # the adapters, not the harness skills that only define the slot
ls .claude/skills/_review-pipeline.md 2>/dev/null
```

A pack is a project's self-review adapter: it fills `review.scans` / `review.lenses` (the slots of
`~/dev/ld-harness/skills/ld-workflow/SKILL.md` §9), usually as a **repo profiles** section keyed on
`basename $(git remote get-url origin) .git` — read the profile matching this PR's repo and use only that
one's scans and judgment lenses. A profile that does not match means no pack: fall through to the generic scan rather than running
another repo's rules, which is how an OpenAPI check ends up firing on Terraform.

**Pack found** → read it and follow its deterministic scan, judgment pass and quote-check against `$DIFF`,
with these deltas:

- **Skip its PR/branch resolution and any `plan.md` reconciliation.** Those steps build their own diff from
  `main...HEAD` and reconcile a plan you wrote; Step 2 above already produced the diff, and someone else's
  plan is not in your working tree.
- Its `DIFF=` assignment is replaced by Step 2's. Every command underneath works unchanged.
- Skip its gate steps (`yarn lint`, `terraform validate`, …) — Step 1 already covered that with `gh pr checks`.
- Skip its posting steps. Steps 5-7 here own the triage and the post.
- Keep its mandatory-mention sections (an auth-surface or security-boundary callout that is deliberately not
  scored) — those exist because "the diff touched it and nobody said anything" is the failure mode.

**No pack** → say so plainly in the report, then run the generic scan below plus the judgment pass. Claiming
repo-specific coverage you did not have is worse than admitting the gap.

### Generic scan (no pack)

Secrets in added lines. The `awk` carries the filename through, because a bare `grep` over a diff matches a
*line* without knowing which file it came from, and that turns every test fixture into a leaked credential:

```bash
awk '/^\+\+\+ b\// { f = substr($2, 3); next } /^\+/ { printf "%s\t", f; print }' "$DIFF" \
  | grep -iE '(password|secret|token|api[_-]?key)[[:space:]]*[=:][[:space:]]*"[^"$]' \
  | grep -viE 'process\.env|CHANGEME|changeme|placeholder|example'
```

Production code → 🔴. Test code (`\.(test|spec)\.[a-z]+$`, or a path segment of `tests?/`) → ⚪, collapsed into
one line, not one finding each. **Downgraded, never dropped** — a real credential in a test file reaches the
same public repo.

Backup files, and new dependencies:

```bash
grep -E '^\+\+\+ b/.*(\.(old|bak)$|-(old|bak)\.[A-Za-z]+$)' "$DIFF"
awk '/^\+\+\+ b\/.*(package\.json|requirements\.txt|go\.mod|Cargo\.toml|pyproject\.toml)$/ { f=1; next }
     /^\+\+\+ / { f=0 } f && /^\+[^+]/ && /["a-z]/ { print }' "$DIFF"
```

Backup file → 🔴. A new dependency is not automatically a finding — read what it replaces. One that does what
a few lines of stdlib do → 🟡, and name the stdlib call.

Then read the repo's `CLAUDE.md` / `AGENTS.md` / `CONTRIBUTING.md` if present, and treat their rules as the
style and design checklist for the judgment pass.

### Judgment pass (always, pack or not)

- **Correctness** — null handling, async misuse, unbounded in-process state, a changed contract breaking a
  caller that did not change. CI catches a compile break, not a logic break.
- **Security at the real boundaries** — anything reading request input, auth and session handling, crypto,
  archive extraction, subprocess and SQL construction, and anything reachable before an auth check.
- **Design** — reuse before reinvention: an HTTP client, a retry loop, a date parser the repo already has.
- **Over-engineering** — the diff's best outcome is getting shorter. An interface with one implementation, a
  factory for one product, config nobody sets. Name what to cut and what replaces it. Do **not** flag a single
  test or self-check as bloat; that is the minimum, not excess.

**Don't flag what a tool already catches.** Formatting, import order, line width, unused locals: the repo's
linter gates those and a finding about them is noise.

Severity is 🔴 must-fix · 🟡 should-fix · ⚪ nit. Every finding carries
`confidence: certain | likely | speculative`.

### Quote-check

For every judged finding (never the ones a shell command produced — those cite by construction):

1. Look up the cited `file:line` in `$DIFF`. Absent → drop, reason `cite-not-in-diff`.
2. Read 5–10 diff lines around it. If they do not contain the construct the claim names → drop, reason
   `claim-not-supported`.
3. Add nothing, re-score nothing. This is a citation check, not a second review.

Print the result on one line. A pass that drops nothing still prints it — silence reads as "not run":

```text
Quote-check: dropped 2 of 9 candidates (1 cite-not-in-diff, 1 claim-not-supported).
```

Read files from the worktree at `../<repo>-pr-<n>`, not from your own checkout — yours is on a different
commit, and a claim verified against the wrong source is worse than no claim.

## Step 5 — Triage, and wait

Drop what the dedupe covers: a Step 3 comment of yours on the same `path` + `line` making the same claim.
Report the count on its own line rather than silently — a finding that vanished without explanation reads as a
finding that was never found:

```text
Dedupe: 3 findings ya comentados en runs anteriores (omitidos del post, listados abajo).
```

`speculative` findings are dropped without `--full`, always — that is a confidence call and no budget changes
it.

⚪ nits are governed by **how crowded the review already is**, not by a flag. A nit is worth the author's
attention when it arrives next to two findings; the same nit is noise when it arrives next to eight.

- **🔴 + 🟡 ≤ 3** → the ⚪ go into the table as ordinary rows and get triaged like everything else.
- **More than 3** → they stay out of the table, and are listed *below* it collapsed, one line each:
  `⚪ apps/mcp/src/http.ts:51 — API key compared with === (not constant-time)`.

Either way they are **listed, never silently dropped**, and either way the user can promote one by number at
triage (`subir 8,9`). The collapsed list is the filter — a flat count cannot tell a timing-unsafe secret
comparison from a misplaced JSDoc, and a human skimming eight one-liners can. `--full` still overrides and
puts everything in the table.

Three is a threshold, not a law: it is the point where the inline comments stop reading as a short list and
start reading as a wall. Move it if real runs say otherwise.

Then the table:

```text
| # | Sev | Conf    | Location                        | Claim                                   | Destino |
|---|-----|---------|---------------------------------|-----------------------------------------|---------|
| 1 | 🔴  | certain | apps/mcp/src/http.ts:121        | Malformed Host header kills the process | Suggest |
| 2 | 🟡  | likely  | apps/mcp/src/lib/api-client.ts  | No timeout, so the budget is not a cap  | Line    |
| 3 | 🟡  | likely  | .gitignore                      | Route changed, spec never updated       | Body    |
```

Spell the destination out — `Line`, `Suggest`, `Body`, never initials. Print the legend under the table every
time, because the column is meaningless to a reader who has not memorised it:

```text
Line = comment inline en la línea · Suggest = inline con bloque ```suggestion (botón "Commit suggestion")
Body = al body del review, sin ancla de línea
```

Deciding the destination **before** triage is the point — a finding you would phrase differently as a
one-click suggestion than as a paragraph should be triaged knowing which it is.

Then:

> Triage: ¿alguno a **dropear**, **bajar**, o mover entre Line/Suggest/Body? Respondé con números + acción (ej. `drop 3; bajar 2 a nit; 4 a Suggest`), o `keep all`.

**Wait for the answer.** A report that skips triage is a list of candidates presented as conclusions.

## Step 6 — Compose

### 6a — Route each kept finding

**Inline is the default.** A finding goes to the body only when it has nowhere to anchor: it is about the PR
as a whole, about a file absent from the diff, or about something *missing* — a route changed with no spec
hunk has no line to point at, because the absence is the finding.

**Recompute every anchor here. Never carry a line number forward.** A finding's `file:line` was written when
the finding was found — possibly from a file read twenty tool calls ago, from a prior run, or from an earlier
pass in this same session. Walk `$DIFF` now and derive the number from it:

```bash
awk '/^\+\+\+ b\//{f=substr($2,3);next} /^@@/{match($0,/\+[0-9]+/);n=substr($0,RSTART+1,RLENGTH-1)+0;next}
     /^-/{next} {print f":"n"\t"$0; n++}' "$DIFF" | grep -F '<the construct the claim names>'
```

If the line the diff reports differs from the one the finding carried, **the diff wins** — the finding was
stale, not the file. This is not hypothetical: a real run carried `analyze.ts:48` for a rethrow that lives at
`:50`, which would have hung the comment off an unrelated line.

**Anti-422 guard.** GitHub rejects the *entire* review — every comment, not just the bad one — if any inline
comment names a line absent from the diff. After recomputing, confirm each anchor appears in `$DIFF`. An
anchor that does not hold gets **demoted to the body, never dropped**.

The anchor is the line in the new file (`side: RIGHT`) unless the finding is about a removed line
(`side: LEFT`). For a range, add `start_line` and `start_side`.

### 6b — Inline comments → `$CACHE/pr-<n>-<sha>.comments.json`

```jsonc
[
  {
    "path": "apps/mcp/src/http.ts",
    "line": 121,
    "side": "RIGHT",
    "body": "🔴 Malformed `Host` header crashes the process (unauthenticated DoS).\n\n```suggestion\n\tlet url: URL;\n\ttry {\n\t\turl = new URL(req.url ?? \"/\", `http://${req.headers.host ?? \"localhost\"}`);\n\t} catch {\n\t\tsendRpcError(res, 400, \"Invalid request URL\");\n\t\treturn;\n\t}\n```\n\n**Why:** Node accepts spaces in header values, so `Host: exa mple` throws `ERR_INVALID_URL` synchronously → `uncaughtException` → exit. This runs before the API-key gate, so no credential is needed."
  }
]
```

Per comment, ≤12 lines, and it must carry **both halves — what is wrong, and how to fix it.** A comment that
only names the defect makes the author do the diagnosis twice. Shape:

1. Severity emoji + the claim in one line. Non-blocking findings say so here, on the first line.
2. The mechanism — what has to be true for it to fire, and whether it is live today or latent.
3. **Fix:** the concrete change. **The fix is never omitted — only its form changes.** A ` ```suggestion `
   block when it qualifies (below); when it does not, the same code in a plain fenced block (` ```ts `,
   ` ```yaml `), plus which file it goes in when that is not the anchored one. Failing to qualify for the
   one-click button is not a reason to drop to prose-only.
   A finding with no proposable fix still earns its inline comment if the line is worth flagging — say what
   is wrong and what you would want instead, even when you cannot write it out.
4. What the verification was, if any. A claim nobody checked gets said as such.

Nothing qualifies → write `[]`.

**Suggestion blocks — when, and the trap.** A ` ```suggestion ` block replaces *exactly* the anchored lines and
gives the author a "Commit suggestion" button. Use it when the replacement is literal and complete: a changed
argument, a swapped comparison, a tightened regex. Do **not** use it for a fix that spans lines the comment
does not anchor, or that the author has to adapt — a half-right suggestion is a wrong commit one click away,
which is worse than prose.

The block must carry the **full replacement lines including leading whitespace**. Read the anchored lines out
of the diff and copy their indentation exactly: a tab-indented repo given a space-indented suggestion commits
a formatting break that CI then fails on, in the author's name.

**Check it, don't just intend it.** For every suggestion, print the anchored line as it exists in the worktree
next to what you are proposing, before the authorization prompt:

```bash
sed -n "<line>p" ../<repo>-pr-<n>/<path> \
  | awk '{ match($0,/^[ \t]*/); w=substr($0,1,RLENGTH); t=gsub(/\t/,"",w);
           printf "tabs=%d spaces=%d | %s\n", t, length(w), $0 }'
```

```text
tabs=3 spaces=0 | 			annotations: { readOnlyHint: true, openWorldHint: true },
```

Match those counts in the replacement's first line, or fix the replacement. A rule with no command behind it
is an intention — this one is two lines of shell and turns the indentation trap into something checkable.

Everything else — the mechanism, the alternatives, what leaving it costs — goes in prose in the same comment.
A review comment gets one recommendation, not a menu.

### 6c — Body → `$CACHE/pr-<n>-<sha>.body.md`

Short on purpose. The detail is on the lines now.

**Never describe the change back to its author.** "Aligns every workspace `engines.node` with the root floor
and extends the preinstall guard" is a summary of what they already wrote — it reads as filler at best and as
condescension at worst. A review body answers one question: is this OK, or what needs aligning. Everything
else is the author's own PR description quoted back at them.

**Never restate CI.** The checks are rendered on the PR, above your review. "CI is green" adds nothing; a red
check is worth a sentence only when it changes what you are asking for.

What *does* belong is what the author cannot see from their own diff: **your verification.** "Ran the guard on
Node 24.18.0 (exits 0) and confirmed the drift check passes against all 16 workspaces" is evidence they did
not have. That distinction — description out, verification in — is the whole rule.

```text
<verdict + what you actually ran or checked, in one or two sentences>

<one line pointing at the inline notes, only if there are any and their nature needs framing
 (e.g. "one non-blocking note inline, on the error output rather than the logic")>

## No line anchor
<only findings that could not be anchored, one short entry each>

## <mandatory-mention section, if the repo's pack has one and it fired>
```

A counts line (`N inline · M below`) is worth printing from about four findings up. Below that the review
already shows them, and the line is noise.

Answer anything the PR description explicitly put up for review. An author who wrote "note for review: X" gets
a paragraph on X, whether or not it became a finding.

Nothing survived triage → the body is the whole review:

```text
LGTM — <what you ran or read, and what held up>.
```

Say what was actually checked, and say it if no rule pack was found. "LGTM" with nothing behind it is
indistinguishable from not having looked.

A body-routed finding can still show its code, via a permalink with the **full** sha — GitHub renders the
snippet inline, and only the full sha works (`$(git rev-parse HEAD)` in the URL does not, the comment is
rendered as literal Markdown):

```text
https://github.com/<owner>/<repo>/blob/<head>/apps/mcp/src/http.ts#L118-L124
```

## Step 7 — Authorize, then submit

Print the body and one line per inline comment (`path:line` + its first line). Then ask — and this is the only
place anything reaches GitHub:

> Postear el review?
> - `comment` — deja los findings sin bloquear el merge
> - `request-changes` — bloquea (recomendado si hay 🔴)
> - `approve` — aprueba con los comments adjuntos
> - `print only` — no toca GitHub
>
> Threads a resolver: <N> (ver abajo) — `resolve` para incluirlos, o se dejan.

Recommend by severity — any 🔴 → `request-changes`; 🟡 only → `comment`; nothing kept → `approve`. It is a
recommendation, not the decision. **On your own PR, `comment` is the only option** (Step 0), and the prompt
says why rather than offering three of which two will 422.

**Wait.** No default, no timeout, no "proceeding since it looks clean".

On approval:

```bash
B="$CACHE/pr-<n>-<sha>"
jq -n --arg ci "<head>" --arg ev "<EVENT>" \
   --rawfile body "$B.body.md" --slurpfile comments "$B.comments.json" \
   '{commit_id:$ci, event:$ev, body:$body, comments:$comments[0]}' > "$B.review.json"
gh api repos/<owner>/<repo>/pulls/<n>/reviews --input "$B.review.json"
```

One `POST`, one review, one notification to the author.

A 422 despite the Step 6a guard means an anchor moved between the diff cache and now — most likely the author
pushed mid-review. Re-fetch the diff, re-verify the anchors, retry once. Say that is what happened; never
retry silently.

Verify, then hand back the cleanup command in the same breath — Step 8 states the policy, but the moment the
user actually wants it is right after the review lands, not as a step they have to remember:

```bash
gh pr view <n> --json reviews --jq '.reviews[-1] | {author: .author.login, state}'
```

> Review posteado. Worktree en `../<repo>-pr-<n>`:
> ```bash
> git worktree remove ../<repo>-pr-<n>
> ```

Print it on `print only` too. The worktree exists either way.

### Resolving stale threads

Only if the user said `resolve`. A candidate is a Step 3 thread that is `isOutdated`, not already
`isResolved`, and whose first comment is yours.

⚠️ **`isOutdated` means the line moved, not that the problem is fixed.** A refactor above the hunk marks a
thread outdated with the bug sitting there untouched. So candidates are listed with their claim at Step 7 for
you to see, and each is checked against the worktree before resolving — if the construct the comment named is
still there, it is not stale and it stays open.

```bash
gh api graphql -f query='mutation($id:ID!){ resolveReviewThread(input:{threadId:$id}){ thread{ isResolved } } }' -f id=<threadId>
```

## Step 8 — Cleanup (recommend, don't run)

> Worktree en `../<repo>-pr-<n>`. Cuando termines:
> ```bash
> git worktree remove ../<repo>-pr-<n>
> ```

Removing it is the user's call — they may want to keep reading the code after the review lands.

## What this skill does NOT do

- **No gates.** CI owns them on the PR. `gh pr checks` reads the verdict; the review does not reproduce it.
- **No install.** The worktree is for reading code, not building it.
- **No posting without authorization.** Step 7 is a hard stop, every run, including the LGTM case.
- **No commits, no pushes, no fixes.** The findings go to the author.
- **No repo-specific rules of its own.** Those live in the repo's pack, so a rule is fixed in one place and
  every skill that reads the pack picks it up.

## Notes

- Bash state does not persist between calls: every command in the worktree needs its own
  `cd ../<repo>-pr-<n> && …`, or `git -C ../<repo>-pr-<n> …`. Same for `$DIFF` / `$CACHE` — re-derive them.
- Dedupe compares `path` + `line` + the claim's substance, not the comment text — the same finding rephrased
  is still the same finding. When a line has shifted, `original_line` from Step 3 is what matches.
- The worktree name is `<repo>-pr-<n>`, so it never collides with a self-review worktree of the same PR.
- Packs live in the project adapters, never here. Step 4 discovers them by the `review.scans` slot, so a
  new repo or a new adapter needs no edit in this skill.
