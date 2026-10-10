---
name: create-ticket
description: Create a GitHub issue interactively — infers title, labels, story points and milestone from context, shows a preview for confirmation before creating.
allowed-tools: Bash
---

# Create Ticket

Creá un GitHub issue con formato consistente. Muestra un preview completo para confirmar antes de crear.

**Announce at start:** "Usando create-ticket — armando el preview del issue."

---

## Paso 1: Parsear argumentos

Los args llegan en formato libre. Extraé:

- **repo**: primera palabra si parece un repo conocido (ej: `academika`, `proyecto-finisterre`) — si no se pasa, inferir del `git remote` del directorio actual
- **input**: el resto del texto — puede ser un título limpio o una descripción draft

Si el repo no se puede inferir con confianza, preguntá antes de continuar.

```bash
# Inferir repo del cwd si no se pasó
git remote get-url origin 2>/dev/null | sed 's/.*github.com[:/]\(.*\)\.git/\1/'
```

---

## Paso 2: Obtener contexto del repo en GitHub

```bash
# Milestones abiertos
gh milestone list --repo {owner}/{repo} --state open --json number,title,dueOn

# Labels disponibles
gh label list --repo {owner}/{repo} --json name,description --limit 50

# Project boards del owner
gh project list --owner {owner} --format json --limit 10
```

Guardá: milestone activo (el de número más bajo o el más relevante por nombre), labels disponibles agrupados por tipo (sp:\*, área, tema), project number si existe uno activo.

---

## Paso 3: Analizar el input y proponer campos

### Título

Si el input parece un título limpio, usarlo directo.
Si es una descripción vaga o draft, deducir un título conciso en el mismo idioma/tono que el resto de los issues del repo (revisá los últimos con `gh issue list --repo {owner}/{repo} --limit 5 --json title`).

### Labels a inferir

Analizá el título y el input libre para detectar qué labels aplican.

**Por área:**
| Palabras clave en el input | Label |
|---|---|
| fastapi, python, endpoint, crud, modelo, alembic, sqlalchemy, importador, migration | `backend` |
| next, react, ui, pantalla, vista, componente, página, frontend, shadcn | `frontend` |
| docker, ci, github actions, deploy, nginx, digital ocean, scaffold, setup, monorepo | `infra` |

**Por tema:**
| Palabras clave | Label |
|---|---|
| auth, login, jwt, registro, usuario, rol, permiso, invitación | `auth` |
| modelo, alembic, migración, importador, guaraní, csv, datos, pipeline | `data` |
| endpoint, crud, rest, swagger, postman, openapi, api | `api` |
| scaffold, setup, estructura, configuración, monorepo, boilerplate | `setup` |

### Story points a inferir

Usá la escala Fibonacci: 1, 2, 3, 5, 8. Si el análisis sugiere 13 o más, **no asignar SP — en cambio, informar al usuario** con una nota como:

> ⚠️ Este ticket parece demasiado grande (estimación > 8 SP). ¿Continuamos así o lo dividimos en tickets más chicos?

Esperá respuesta antes de continuar con el preview.

| Señales en el input                                           | SP sugerido |
| ------------------------------------------------------------- | ----------- |
| "skeleton", "básico", "simple", una sola vista o endpoint     | 2–3         |
| feature completo con back + front                             | 5           |
| múltiples subsistemas, deploy, importador con varios formatos | 8           |
| default si no hay señales claras                              | 5           |

### Milestone

Asignar el milestone abierto más relevante. Si hay uno solo, ese. Si hay varios, elegir el que más coincida con el scope del ticket.

### Body del issue

Generá un body con estas secciones fijas:

```markdown
## Contexto

{1-3 oraciones describiendo qué es y por qué existe este ticket. Si el input era vago, ampliar con criterio. Si era específico, parafrasearlo limpio.}

## Criterio de done

- [ ] {criterio concreto 1}
- [ ] {criterio concreto 2}
- [ ] {criterio concreto N}

## Dependencias

{Lista de issues relacionados en formato "- #{N} — título" si los conocés por el contexto de la sesión. Si no hay, escribir "Ninguna."}

## Stack involucrado

{backend / frontend / infra / combinaciones — una línea}
```

El criterio de done debe ser concreto y checkeable, no vago. Ejemplos buenos:

- `[ ] `GET /api/v1/alumnos` retorna lista paginada con 200`
- `[ ] El usuario admin puede invitar a un director desde Backoffice`
- `[ ] Tests de integración pasan con testcontainers`

---

## Paso 4: Mostrar preview

Presentá esto antes de crear. No crear nada todavía.

```markdown
---
## Preview — Issue a crear

**Repo:** {owner}/{repo}
**Título:** {título}
**Milestone:** {título del milestone} (#{número})
**Labels:** `{label1}`, `{label2}`, `sp:{N}`
**Project:** {nombre del board} (si existe)

### Body

## Contexto
{...}

## Criterio de done
- [ ] ...

## Dependencias
{...}

## Stack involucrado
{...}

---

¿Creamos el issue así, o ajustamos algo?
```

Si algún campo fue inferido con baja confianza (no había señales claras), marcalo con `⚠️` para que el usuario lo note.

---

## Paso 5: Esperar confirmación

- Si el usuario confirma → ir al Paso 6.
- Si el usuario pide cambios → aplicarlos, mostrar nuevo preview, esperar confirmación de nuevo.
- Si el usuario cancela → terminar sin crear nada.

---

## Paso 6: Crear el issue

```bash
gh issue create \
  --repo {owner}/{repo} \
  --title "{título}" \
  --body "{body}" \
  --label "{label1}" \
  --label "{label2}" \
  --label "sp:{N}" \
  --milestone "{título del milestone}"
```

Capturá la URL del issue creado.

---

## Paso 7: Agregar al project board

Si había un project board activo:

```bash
gh project item-add {project_number} --owner {owner} --url {issue_url}
```

---

## Paso 8: Confirmar al usuario

```txt
Issue creado: #{número} — {título}
{url}
```

---

## Rules

- **Nunca crear el issue antes de mostrar el preview y recibir confirmación.**
- Si el repo no se puede inferir con confianza, preguntar antes de continuar.
- Los story points van siempre como label (`sp:N`), nunca en el título ni en el body.
- Los criterios de done deben ser checkeable — nada de "implementar X correctamente".
- Si el input está muy vago y no podés inferir campos con confianza razonable, pedí aclaraciones puntuales en lugar de inventar.
