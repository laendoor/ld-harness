---
name: self-review
description: Run an external code review on the current PR. Uses two parallel isolated agents (correctness + ponytail over-engineering lens). Presents findings in triage, lets the user validate each one, then posts validated findings as inline PR review comments.
allowed-tools: Bash, Agent
---

# Self Review

Actúa como code reviewer externo sobre el PR activo. El review corre en **dos agentes paralelos** aislados — sin contexto de la conversación actual, solo ven el código y el diff.

## Steps

### 0. Verificar si ya existe un review guardado

```bash
gh pr view --json number,title,url,headRefName,baseRefName
```

Con el número de PR en mano, verificá si existe `.tmp/review-pr-{number}.md`:

```bash
cat .tmp/review-pr-{number}.md 2>/dev/null
```

- Si existe: saltá directamente al **step 4** (triage) usando ese archivo. No relanzar los agentes.
- Si no existe: continuá con el step 1.

### 1. Obtener contexto del PR

```bash
gh pr diff
gh pr view {number} --json headRefOid,files
```

Guardá: número de PR, título, diff completo, HEAD SHA, lista de archivos modificados.

### 2. Leer convenciones del proyecto

Leé el `CLAUDE.md` del proyecto actual para extraer: stack, convenciones de código, criterios de calidad específicos.

### 2b. Obtener historial git de los archivos modificados

Para cada archivo modificado (máximo 5 más relevantes):

```bash
git log --oneline -10 -- {archivo}
```

Este historial va al Agente A para detectar bugs por contexto histórico (ej: revertes, fixes recurrentes, patrones conocidos de la codebase).

### 3. Lanzar dos agentes de review en paralelo — OBLIGATORIO

**IMPORTANTE:** Lanzá ambos agentes **en el mismo mensaje**, como llamadas paralelas al `Agent` tool (`subagent_type: general-purpose`). No hagas el review vos mismo — el aislamiento garantiza independencia. Si no usás el Agent tool, el skill no sirve.

Construí ambos prompts reemplazando todos los placeholders con los valores reales. Cada prompt debe ser completamente autocontenido.

---

**Agente A — Correctness & Security:**

```txt
Sos un code reviewer senior haciendo un review independiente.

**PR #{number}: {title}**

No tenés historial de la conversación. Solo ves el diff y el contexto del proyecto.

**Stack y convenciones del proyecto:**
{contenido relevante del CLAUDE.md — stack, linting, testing, convenciones}

**Historial reciente de archivos modificados:**
{output de git log --oneline -10 por archivo}

**Diff completo:**
{diff}

**Criterios de review (en orden de prioridad):**

1. 🔴 CRÍTICO — bugs, vulnerabilidades de seguridad (OWASP top 10: injection, XSS, broken auth,
   exposed secrets, insecure deserialization), pérdida de datos, race conditions, errores que rompen
   funcionalidad core
2. 🟡 IMPORTANTE — typing incorrecto o ausente, violaciones de convenciones del stack, lógica
   cuestionable, falta de tests para lógica no trivial
3. 🟢 MENOR — style, naming, oportunidades de simplificación, comentarios útiles faltantes

**Instrucciones:**
- Revisá el diff línea por línea
- Para cada finding: indicá ruta exacta del archivo (relativa a la raíz del repo), número de línea
  exacto en el archivo nuevo, categoría, descripción del problema y sugerencia concreta
- Si una categoría no tiene findings, decilo explícitamente ("Sin hallazgos críticos")
- Sé específico — no generalices ni repitas el código sin agregar valor
- Ignorá cambios en lockfiles, archivos generados o configuración trivial salvo que haya algo crítico

**Formato de output:**

## Findings

### 🔴 Críticos
- **src/app/api/route.ts:42** — descripción del problema → sugerencia concreta

### 🟡 Importantes
- **src/app/api/route.ts:15** — descripción → sugerencia

### 🟢 Menores
- **src/app/api/route.ts:7** — descripción → sugerencia

## Veredicto
[una oración: "Approve" o "Request changes" + resumen ejecutivo en 1-2 líneas]
```

---

**Agente B — Over-engineering (Ponytail lens):**

```txt
Sos un code reviewer senior especializado en detectar sobre-ingeniería y código innecesario.

**PR #{number}: {title}**

**Diff completo:**
{diff}

Tu único objetivo: encontrar qué se puede eliminar o simplificar. Ignorá bugs de correctness
y seguridad — eso lo revisa otro agente.

Para cada finding, una línea con formato exacto:
`{ruta/archivo.ts}:L{line}: {tag}: {qué}. {reemplazo}.`

Tags:
- `delete:` código muerto o flexibilidad especulativa. Reemplazo: nada.
- `stdlib:` cosa reimplementada que ya existe en stdlib. Nombrá la función.
- `native:` dependencia o código para algo que la plataforma ya hace nativa. Nombrá el feature.
- `yagni:` abstracción con una sola implementación, config que nadie setea, layer con un solo caller.
- `shrink:` misma lógica, menos líneas. Mostrá la forma más corta.

Si no hay nada para cortar: respondé solo "Lean already. Ship." y terminá.

Al final: `net: -{N} lines possible.`
```

---

### 3b. Guardar ambos reviews en disco

Inmediatamente después de recibir ambos outputs:

```bash
mkdir -p .tmp
cat > .tmp/review-pr-{number}.md << 'EOF'
# Review — Correctness & Security

{output completo del Agente A}

---

# Review — Over-engineering (Ponytail)

{output completo del Agente B}
EOF
```

Esto permite recuperar el review si la sesión se compacta antes de terminar el triage.

### 4. Presentar findings al usuario en triage

Mostrá los findings consolidados de ambos agentes:

1. Correctness: críticos → importantes → menores
2. Ponytail: findings de over-engineering (o "Lean already. Ship." si no hay nada)

Para los findings no-obvios, preguntá al usuario si los considera válidos antes de postear.

### 5. Postear findings validados como inline comments

Primero obtené el HEAD SHA y el owner/repo:

```bash
HEAD_SHA=$(gh pr view {number} --json headRefOid --jq '.headRefOid')
OWNER_REPO=$(gh repo view --json nameWithOwner --jq '.nameWithOwner')
```

Para cada finding validado que tenga archivo y línea específicos, postealo como **inline comment**:

```bash
gh api "repos/${OWNER_REPO}/pulls/{number}/comments" \
  --method POST \
  -f body="**[{emoji} {categoría}]** {descripción}

> {sugerencia}" \
  -f commit_id="${HEAD_SHA}" \
  -f path="{ruta/relativa/archivo.ts}" \
  -F line={numero_linea} \
  -f side="RIGHT"
```

> **Nota:** GitHub solo acepta inline comments en líneas que aparecen en el diff. Si la línea no está
> en el diff, posteá el finding como comment de cuerpo:
>
> ```bash
> gh pr review {number} --comment --body "**[{categoría}]** {descripción} → {sugerencia}"
> ```

Si hay críticos, además de los inline comments agregá un `--request-changes`:

```bash
gh pr review {number} --request-changes --body "$(cat .tmp/review-pr-{number}.md)"
```

No borres `.tmp/review-pr-{number}.md` — queda como registro y es liviano.

### 6. Reportar resumen final

```txt
Review completado:
  🔴 Críticos posteados: N
  🟡 Importantes posteados: N
  🟢 Menores posteados: N
  🔧 Ponytail (over-engineering): N

PR: {url}

Para aplicar los fixes: /review-fix
```

## Rules

- **Siempre usar el Agent tool** — nunca hacer el review en el contexto actual. Sin Agent tool, no hay
  context fork y el review pierde independencia.
- **Lanzar Agente A y Agente B en el mismo mensaje** — paralelo real, no secuencial.
- El prompt de cada agente debe ser autocontenido: diff + contexto + criterios. Sin referencias a la sesión.
- Nunca postear findings que el usuario descartó.
- Si el diff está vacío o el PR no existe, abortá con mensaje claro.
