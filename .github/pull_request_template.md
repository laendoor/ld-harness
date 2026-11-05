<!--
Title:  feat(scope): imperative summary (TICKET-KEY)
        type  = feat | fix | refactor | perf | test | docs | chore   — the change as a whole, not the sum of its commits
        scope = the area of the codebase, e.g. web, api, core  — never the ticket key

This is the template for feature and task work. For a bug fix use ?template=bug.md,
for docs/deps/renames use ?template=chore.md.

This is ld-create-pr's fallback copy, used when the repo has no .github templates of its own.

Drop any section that has nothing real to say. An empty section is worse than no section.
Write in the imperative — "normalize the score", not "this PR normalizes the score".
-->

<!-- One or two sentences: what this changes and why it needed changing. Keep the ticket link on this line. -->
[TICKET-KEY](<ticket url>)

Net: **+X / −Y** across N files

## The problem

<!-- The problem that motivated the change, in evidence: real numbers, real output, a path:line.
     Nothing concrete to show? Cut this section rather than describing the problem in adjectives. -->

## What changed, and why this approach

<!-- The approach taken, and the alternative that was rejected with the reason it lost.
     A reader who disagrees with the approach should find their objection already answered here. -->

## Accepted cost

<!-- What gets worse, or where this approach falls short. Omit only when nothing does —
     a cost found in review instead of here turns into an argument. -->

## What reviewers should know

<!-- Where the risk is, and anything in the diff that reads as a mistake without context:
     deleted tests, a widened scope, behaviour that changed for existing callers. -->

## How to verify

<!-- Commands a reviewer can run, with the expected result. Not "run the tests". -->

## Out of scope, on purpose

<!-- Decided-not-to-do, so it does not get reopened in review. -->
