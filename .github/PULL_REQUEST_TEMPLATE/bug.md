<!--
Title:  fix(scope): imperative summary (TICKET-KEY)
        scope = the area of the codebase, e.g. web, api, core — never the ticket key

A bug fix is read differently from a feature: the reviewer has to believe the diagnosis before
they can judge the fix. So the reproduction and the cause come before the change.

Drop any section that has nothing real to say. Write in the imperative.
-->

<!-- One or two sentences: the wrong behaviour, in the terms someone would notice it. -->
[TICKET-KEY](<ticket url>)

Net: **+X / −Y** across N files

## What was broken

<!-- The reproduction a reviewer can run verbatim, then expected vs actual with the real output. -->

## Root cause

<!-- The mechanism, anchored at path:line with the smallest snippet that proves it.
     Not confirmed? Say "unconfirmed" and give the leading theory — a guess labelled as a guess
     is useful, a guess presented as a diagnosis sends the review the wrong way. -->

## The fix

<!-- What changed, and why here rather than at another layer where it would also have worked. -->

## Why it will not come back

<!-- The regression test, at path:line, and what it asserts. A fix with no test that fails
     without it is a fix nobody can defend in six months. -->

## What reviewers should know

<!-- Blast radius: who else calls this, what else the same cause could be breaking,
     and anything in the diff that reads as unrelated. -->

## How to verify

<!-- The reproduction above, now passing, plus the command for the new test. -->
