---
name: start-ticket
description: Use when starting work on a GitHub issue or ticket — creates the branch, enters plan mode, and structures the implementation plan with Greek phases and mandatory confirm+commit steps per phase
---

# Start Ticket

## Overview

Standard workflow for beginning work on any GitHub issue. Four steps: fetch issue → create branch → enter plan mode → write structured plan.

**Announce at start:** "Usando start-ticket — creando branch y armando el plan."

---

## Step 1: Fetch the issue

```bash
gh issue view {N} --json number,title,labels,body,milestone
```

Read the title, description, and labels to inform the branch type and plan scope.

---

## Step 2: Create Branch

Branch naming convention:

```txt
{type}/short-description-{issue-number}
```

| Issue label / nature            | Branch type |
| ------------------------------- | ----------- |
| feature / feat                  | `feature/`  |
| fix / bug                       | `fix/`      |
| chore / infra / task / refactor | `task/`     |

Examples:

- Issue #2 (scaffold, chore) → `task/monorepo-scaffold-2`
- Issue #6 (auth feature) → `feature/auth-middleware-6`
- Issue #15 (fix auth bug) → `fix/auth-jwt-15`

```bash
git checkout main
git pull
git checkout -b {type}/short-description-{N}
```

---

## Step 3: Enter Plan Mode

Use `EnterPlanMode` immediately after creating the branch. Do not write any code before the plan is confirmed.

---

## Step 4: Write the Plan

### Plan header

```markdown
# Issue #{N}: {Title}

**Branch:** `{type}/short-description-{N}`
**Goal:** [one sentence]
**Scope:** [key files / components affected]

---
```

### Phase structure

Use Greek letters for phases: **Alpha, Beta, Gamma, Delta, Epsilon, Zeta, Eta, Theta, Iota, Kappa...**

Each phase must end with these two steps — no exceptions:

```txt
N-1. Pedir confirmación al usuario de los cambios de la fase
N.   Commit: {type}({scope}): {descripción en español}
```

**Example:**

```markdown
## Fase Alpha: Scaffold de directorios

1. Crear estructura de carpetas base
2. Crear archivos de configuración iniciales
3. Verificar que lint pasa sin errores
4. Pedir confirmación al usuario de los cambios de la fase
5. Commit: `chore(api): scaffold inicial`

## Fase Beta: Docker dev

1. Crear `docker-compose.dev.yml` con servicios api + db
2. Crear `.env.example` con variables necesarias
3. Verificar que `docker compose config` valida sin errores
4. Pedir confirmación al usuario de los cambios de la fase
5. Commit: `chore(infra): docker-compose dev`
```

### Phase size guidelines

- **Small phases (3–6 steps):** for risky, complex, or high-impact work
- **Larger phases (up to 10 steps):** for mechanical, low-risk work
- Each phase must be independently committable

### Commit format (conventional commits, Spanish descriptions)

```txt
{type}({scope}): {descripción}

# Types: feat, fix, chore, refactor, test, docs
```

---

## Rules

- Always branch from `main`
- Never touch code before the plan is written and confirmed
- Confirm + commit are the last two steps of **every** phase — no exceptions

---

## Closing the ticket (after all phases complete)

Once all phases are committed, close the loop with this sequence. Present it as a block so Lean can run each step when ready:

```txt
# 1 — Push the branch
git push -u origin {branch-name}

# 2 — Create the PR  (run after push)
/create-pr

# 3 — Self-review  (run after PR is open)
/self-review
```

Announce it as:

> "Todas las fases commiteadas. Para cerrar el ticket: `git push`, luego `/create-pr`, luego `/self-review`."
