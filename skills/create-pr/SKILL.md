---
name: create-pr
description: Create a GitHub pull request with a standard template — infers title, body and linked issue from branch and commits. Shows preview before creating.
allowed-tools: Bash
---

# Create PR

Creá un GitHub pull request con formato consistente. Muestra un preview completo para confirmar antes de crear.

**Announce at start:** "Usando create-pr — armando el preview del PR."

---

## Paso 1: Obtener contexto del branch

```bash
# Repo y owner
git remote get-url origin | sed 's/.*github.com[:/]\(.*\)\.git/\1/'

# Branch actual
git branch --show-current

# Issue number — extraer del nombre del branch (ej: task/monorepo-scaffold-1 → 1)
git branch --show-current | grep -oE '[0-9]+$'

# Commits del branch respecto a main
git log main..HEAD --oneline

# Diff resumido para entender el alcance
git diff main..HEAD --stat
```

Si el branch no termina en número, intentar inferir el issue de otra forma o preguntar.

---

## Paso 2: Obtener datos del issue

```bash
gh issue view {N} --repo {owner}/{repo} --json number,title,body,labels,milestone
```

Extraer del body del issue:

- Sección `## Criterios de done` → usarla como checklist en el PR
- Sección `## Contexto` → referencia para escribir el contexto del PR

---

## Paso 3: Construir el PR

### Título

Derivar del último commit significativo o del conjunto de commits. Seguir formato conventional commits en español:

```txt
{type}({scope}): {descripción}
```

Si hay un solo commit relevante, usarlo directo. Si hay varios, sintetizar en uno que represente el conjunto.

### Body

```markdown
## Contexto

{1-3 oraciones explicando el por qué de este PR — no el qué (eso está en los commits).
Derivar del contexto del issue y de los commits.}

## Qué se hizo

{Descripción conceptual del cambio — lo que no se ve solo leyendo el diff. Puede ser una línea
o un párrafo. El foco es el significado: qué problema resuelve, qué patrón establece, qué
decisión de diseño concreta implementa. No es un listado de archivos modificados.}

## Cómo verificar

{Combinar los criterios de done del issue con los pasos concretos para chequearlo.
Cada ítem es un checkbox con su acción de verificación inline:}

- [ ] criterio del issue — `acción concreta para comprobarlo`
- [ ] criterio del issue — `url, comando o paso observable`

{Deducir las acciones según el tipo de cambio:

- endpoints → curl o Swagger URL
- UI → URL del dev server + qué observar
- infra/CI → comando a correr (make check, make test)
- solo tests → make test o pytest
  Si el scope es complejo y no podés ser preciso, preguntar.}

Closes #{N}
```

### Metadata a aplicar

- **Base branch:** `main`
- **Labels:** heredar del issue
- **Milestone:** heredar del issue
- **Assignee:** el usuario actual (`@me`)

---

## Paso 4: Mostrar preview

```markdown
---
## Preview — PR a crear

**Repo:** {owner}/{repo}
**Branch:** {branch} → main
**Título:** {título}
**Issue:** Closes #{N}
**Labels:** `{label1}`, `{label2}`
**Milestone:** {título del milestone}

### Body

## Contexto
{...}

## Qué se hizo
{...}

## Cómo verificar
- [ ] criterio — acción concreta
- [ ] criterio — acción concreta

Closes #{N}

---

¿Creamos el PR así, o ajustamos algo?
```

---

## Paso 5: Esperar confirmación

- Si el usuario confirma → Paso 6.
- Si pide cambios → aplicar, nuevo preview, esperar confirmación.
- Si cancela → terminar sin crear nada.

---

## Paso 6: Crear el PR

```bash
gh pr create \
  --repo {owner}/{repo} \
  --base main \
  --head {branch} \
  --title "{título}" \
  --body "{body}" \
  --label "{label1}" \
  --label "{label2}" \
  --milestone "{título del milestone}" \
  --assignee "@me"
```

Capturar la URL del PR creado.

---

## Paso 7: Confirmar y recordar el próximo paso

```txt
PR creado: #{número} — {título}
{url}

Próximo paso: cuando el CI esté verde, corré /self-review para una segunda revisión antes de mergear.
```

---

## Rules

- **Nunca crear el PR antes de mostrar el preview y recibir confirmación.**
- El branch base es siempre `main` salvo que el usuario indique otro.
- `Closes #N` va siempre al final del body — es lo que cierra el issue al mergear.
- Si no podés inferir el issue number del branch, preguntar antes de continuar.
- No abrir como draft salvo que el usuario lo pida explícitamente.
- "Cómo verificar" debe ser concreto y ejecutable. Si no podés serlo, decirlo brevemente en lugar de inventar pasos vagos.
