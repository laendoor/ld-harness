---
name: ld-workflow
description: Contrato del ciclo de una tarea en cinco etapas — start (plan + decisiones, sin código) → implement (fase = commit, ⏸ frena con difit, frena siempre al final para tu review) → self-review (triage local, fixups) → ship (PR + ticket a review + aviso al canal, con tu OK) → close (post-merge: ticket a done, limpieza, memoria). Define también el contrato del adapter de proyecto (gr-*, aika-*, fini-*). Usar vía /ld-start-task, /ld-implement-task, /ld-self-review, /ld-ship-task, /ld-close-task o el adapter del proyecto.
---

# ld-workflow — contrato del ciclo de una tarea

```txt
start ──▶ implement ──▶ [review tuyo] ──▶ self-review ──▶ ship ──▶ [merge tuyo] ──▶ close
plan +     fase=commit,   difit + bloque    triage local:    PR, ticket     espera fuera     ticket done,
decisiones ⏸ frena,       `review:` →       fix/drop/        a review,      del harness      limpieza,
sin código frena al final fixups            defer/ticket     aviso canal                     memoria
```

Cada etapa es una invocación tuya. Ninguna encadena a la siguiente: lo que separa
las etapas es tu juicio (el OK del plan, tu review, el merge), y una etapa que
encadena sola se saltea justo eso.

Las secciones §1–§3 valen para todas las etapas. §4–§8 son cada etapa; la
self-review vive en su propio skill (`ld-self-review`). §9 es el contrato del
adapter: lo que cada proyecto aporta y los defaults cuando no hay adapter.

## 1. Convenciones

- **Plan.** Un archivo scratch, nunca versionado: el path lo da el adapter;
  default `.tmp/tasks/<id>/plan.md`. Si `.tmp/` no está ignorado en el repo,
  agregarlo a `.git/info/exclude` (no al `.gitignore`: es local, no del equipo).
  `<id>` es la key del ticket o un slug de 2-4 palabras.
- **Una fase es una unidad de commit** con título de una línea. Dos fases que
  tocan el mismo archivo en el mismo commit son una fase: partir más fino fabrica
  decisiones de coordinación entre las mitades. Los unit tests van en el commit de
  la fase que prueban.
- **⏸ marca una fase que toca un path crítico** (los lista el adapter; sin
  adapter: auth, datos/migraciones, plata, borrado, infra). La corrida frena
  después de su commit, porque un rumbo equivocado ahí es el caro de encontrar con
  tres fases construidas encima.
- **Modo, uno por tarea**, con su razón en una línea; lo podés pisar:
  - `fino` — bug o config: una fase, casi sin decisiones, Tests/Docs suelen ser `[-]`.
    Self-review express (solo los scans deterministas).
  - `normal` — el resto. Self-review completa.
  - `full` — arquitectura, auth, datos, cambio de scope. Self-review completa con
    el bucket ⚪ promovido (`--full`).
- **Estados:** `[ ]` pendiente · `[x]` commiteada · `[-]` no aplica, con la razón en
  la línea. Una fase salteada marcada `[x]` manda a la self-review a buscarla en el
  diff y reportar un 🔴 falso.
- **Dos fases de cierre**, siempre últimas: `Tests` (revisar lo que sembraron las
  fases, reforzar lo flojo, sumar el nivel de integración que ninguna fase sola
  podía) y `Docs` (auditar los docs contra lo que cambió). Una que no aplica se
  escribe `[-]` con su razón, nunca se omite, así un refresh no la vuelve a agregar.
- **Trabajo post-merge no es fase:** nada lo dispararía. Va a `## Pendiente de sync`.
- **Severidad**, un solo léxico en todas las etapas: 🔴 must-fix · 🟡 should-fix · ⚪ nit.
- **Numeración:** decisiones, findings y fases se numeran y nunca se renumeran
  dentro de la tarea. Respondés por número; una que se cae "deja de existir", no
  corre a las demás.
- **Commits:** convencionales, una línea, idioma según el historial del repo (o lo
  que diga el adapter). Nunca en `main`/`master`, nunca push: ld-gate los bloquea.

Formato del plan:

```markdown
# <id> — <título corto>
**Goal:** <1-2 líneas>
**Branch:** `<branch>`
**Modo:** <fino|normal|full> — <razón>

## Fases
- [ ] 1 · <fase de trabajo — con sus unit tests>
- [ ] 2 · ⏸ <fase que toca un path crítico>
- [ ] N · Tests (<qué cuenta acá, según el adapter>)
- [ ] N+1 · Docs (auditar docs contra lo que cambió)

## Decisiones
<una línea por decisión resuelta: `N · <qué se decidió> — <razón corta>`>
```

## 2. Decisiones

**La prueba de admisión se corre, no se interpreta.** Una decisión entra solo si
contestarla al revés cambia **qué archivos se tocan, qué ve otro componente, o
cuánto cuesta revertir**. Dos respuestas que dan el mismo diff con otras palabras
adentro (el texto de un comentario, el nombre de una variable) son decisión del
implementador y las agarra la self-review. Cero decisiones es un resultado normal.

```markdown
### 🔴 1 · <qué se decide>
<el problema, 1-3 oraciones>
**Propuesta:** <la recomendación y su razón>
**Alternativas:** <cuáles y por qué pierden, una oración>
```

- 🔴 bloquea la tarea o es caro de revertir una vez construido · 🟡 el resto.
  Sin nivel nit: la prueba ya excluye lo no bloqueante.
- Una propuesta sigue siendo propuesta y lleva su razón. Si depende de un dato que
  solo vos tenés, recomendar igual y decir el supuesto.
- Anclas: path sí, línea no (las líneas se pudren entre la discusión y el commit).

## 3. Memoria (Engram)

- **start:** `mem_search` con keywords de la tarea; lo previo se cita, no se redescubre.
- **implement / self-review:** `mem_save` ante decisión, bugfix, descubrimiento no
  obvio o convención nueva.
- **close:** `mem_session_summary`. Sin esto la próxima sesión arranca ciega.

## 4. Start — `/ld-start-task <ticket | tarea en una línea>`

Alinear todo lo que necesita tu juicio, para que implement corra de punta a punta
sin frenar. **No escribe código.**

1. **Resolver la tarea.** Con ticket: traerlo por el slot `ticket.fetch` del
   adapter (título, tipo, descripción, criterios de aceptación). Sin ticket: la
   tarea viene en el prompt; si falta, pedirla en una línea.
2. **Branch.** `git status --porcelain` sucio → frenar, nunca cambiar de branch
   arriba de trabajo sin commitear. Si el branch actual ya es el de la tarea,
   seguir. Si no, cortarlo de `main` actualizado con el nombre del slot
   `branch.name` e imprimirlo en su propia línea. Cualquier falla → frenar, nunca forzar.
3. **Leer el contexto:** el código que van a tocar las fases más lo que agregue el
   adapter. Un doc que contradice el código se marca, no se resuelve: cualquiera
   de los dos puede ser el viejo.
4. **Escribir o refrescar el plan** (§1). Sembrar 1-3 fases de trabajo; ante la
   duda, menos. Si el ticket ya trae un desglose, reusarlo tal cual. Pasos manuales
   del operador (un secreto, una credencial) son su propia fase. Plan existente:
   refrescar en el lugar, respetando tus fases, orden y redacción.
5. **Responder en el chat** (no en el plan): `## Plan` (fases + modo), `## Qué hay
   que hacer` (un párrafo: el problema y el encare, lo que necesita alguien que
   vuelve de un corte; riesgos a tener presentes van acá) y `## Decisiones
   pendientes` en el formato de §2, ordenadas por severidad.
6. **Cerrar el loop.** Cada respuesta tuya → una línea en `## Decisiones`. Repetir
   lo que siga abierto. Sin nada abierto: `sin decisiones pendientes — corré
   /ld-implement-task` (o el comando del adapter).

**Gate duro.** Lo único que dispara código es que invoques la etapa implement. No
"dale", "ok", "seguí", ni que todas las decisiones estén contestadas.

## 5. Implement — `/ld-implement-task`

Invocarla **es** la autorización para todo el plan acordado: no pregunta entre fases.

**Precondiciones — se chequean, nunca se arreglan:**

1. El plan existe y tiene línea `**Modo:**`. Falta → `falta /ld-start-task para esto`.
2. Ninguna decisión pendiente: nombrar las abiertas por número y frenar.
3. `git branch --show-current` coincide con el `**Branch:**` del plan y no es `main`.
4. `git status --porcelain` limpio, así cada commit contiene solo su fase.

**La corrida.** Para cada fase `[ ]` en orden (las de trabajo, después Tests y Docs):

1. Implementar lo que dicen la fase y las decisiones; ese scope, nada más.
2. Correr el **check rápido** del adapter (segundos, no CI; nunca re-correr los
   gates de CI). Sin adapter: los tests de lo tocado.
3. Commitear solo los archivos de la fase y marcarla `[x]` en el plan.
4. **Fase ⏸ → frenar después del commit.** Mostrar qué cambió (`file:line`), el
   output del check, el commit, y el comando exacto para revisarlo:
   `difit <sha>` (un commit) o `difit HEAD <sha-base>` (varios). El agente nunca
   corre `difit`: es un viewer interactivo tuyo. Cualquier OK retoma la corrida.

**Frenar a mitad de corrida solo por:**

- **Una decisión que apareció tarde** y pasa la prueba de admisión (§2): se
  presenta en ese formato, la respuesta va a `## Decisiones`, se retoma. Si no
  pasa la prueba, la decide el implementador, sigue, y la menciona al final.
- **Un check que falla** por algo que la discusión no previó y cuyo arreglo
  agrandaría la fase. Reportar; no agrandar.
- **Trabajo de otra fase u otra tarea.** Decirlo y preguntar; nunca absorberlo.

**Al terminar el plan: frenar siempre.** Es tu revisión de bloque, no un trámite.
El turno cierra con:

- la lista fase → commit (`sha subject`),
- los resultados de los checks, fallas incluidas,
- las decisiones del implementador, una línea cada una,
- el comando para revisar todo: `difit HEAD $(git merge-base main HEAD)`.

**El loop de review.** Respondés con un bloque `review:` de bullets.

- Cada fix es un fixup de la fase a la que pertenece: `git commit --fixup=<sha>`.
  Una fase = un commit es la unidad contra la que la self-review reconcilia el plan.
- Resolver, no acusar recibo. Un bullet que pide un cambio aparece en el resumen;
  uno que pregunta, se contesta. Cambios y respuestas van en bloques separados.
- Cuando aprobás: `GIT_SEQUENCE_EDITOR=: git rebase -i --autosquash $(git merge-base main HEAD)`,
  mostrar `git log --oneline main..HEAD` y sugerir `/ld-self-review`.

## 6. Self-review — `/ld-self-review`

Ver el skill `ld-self-review`. Triage local con cuatro verbos (fix · drop · defer
· ticket); los fix son fixups de su fase. Termina cuando los fixes están
commiteados y autosquasheados con tu OK. Después: push (tuyo) → ship.

## 7. Ship — `/ld-ship-task`

Lo que manda la tarea a review. Todo lo que sale de la máquina (PR, ticket, canal)
se arma, se muestra y espera tu OK antes de salir.

1. **Branch listo o frenar.** Árbol limpio, sin fixups pendientes de squash
   (`git log --oneline main..HEAD | grep -c 'fixup!'` = 0), y el branch pusheado y
   al día con su upstream (`git status -sb` sin `ahead`). Falta el push → mostrar
   `git push -u origin <branch>` y frenar: el push es tuyo.
2. **PR.** Con el skill `ld-create-pr`, pasándole la referencia al ticket del
   slot `ticket.ref` (`Closes #N`, una key de Jira, nada). PR ya abierto: ofrecer
   actualizar el body si ya no coincide con el branch.
3. **Ticket a review** por el slot `ticket.review` (comentar el link del PR y
   transicionar). Sin adapter: nada.
4. **Aviso al canal** por el slot `ship.notify`: armar el mensaje, mostrar texto y
   destino, y mandarlo solo con tu OK explícito sobre ambos. Sin adapter: no hay canal.
5. Devolver los links (PR, ticket, mensaje). El merge es tuyo; close va después.

## 8. Close — `/ld-close-task`

Post-merge. Se infiere la tarea por contexto: `$ARGUMENTS`, el branch actual, el
plan más reciente en el path del adapter, o la última sesión de Engram. Si nada
cierra, recién ahí pedirla en una línea.

1. **Verificar el merge:** `gh pr view <branch> --json state,mergedAt` → `MERGED`.
   Si no está mergeado, frenar: no hay nada que cerrar.
2. **Ticket a done** por el slot `ticket.done`. Sin adapter: nada.
3. **Limpieza**, propuesta como checklist y ejecutada con tu OK: volver a `main`
   y `git pull --ff-only`, borrar el branch local (`git branch -d`, nunca `-D`:
   si no está mergeado, que falle), borrar el directorio de la tarea
   (`.tmp/tasks/<id>/`) y lo que agregue el slot `close.cleanup`.
4. `## Pendiente de sync` del plan: mostrarlo antes de borrar el plan, para que no
   se pierda con él.
5. `mem_session_summary`.

## 9. Contrato del adapter

Un adapter es un command/skill del proyecto (`gr-start-task`, `aika-implement`,
…) que carga este contrato y llena los slots. No reescribe etapas: si una regla de
acá no le sirve, se cambia acá con `/ld-improve-harness`.

Forma mínima de un adapter:

```markdown
Leé `~/dev/ld-harness/skills/ld-workflow/SKILL.md` y seguí la etapa <start|implement|ship|close>
con estos slots. Lo que no esté definido acá usa el default del contrato.
<tabla de slots>
```

| Slot | Qué define | Default sin adapter |
| --- | --- | --- |
| `ticket.fetch` | De dónde sale la tarea y cómo leerla | GitHub issue (`gh issue view`) o el prompt |
| `ticket.ref` | Cómo el PR referencia al ticket | `Closes #N` si hay issue; si no, nada |
| `ticket.review` / `ticket.done` | Transiciones del ticket | Ninguna |
| `branch.name` | Nombre y estrategia del branch | `<feat\|fix\|task>/<id>-<slug>` desde `main` |
| `plan.path` | Dónde vive el plan | `.tmp/tasks/<id>/plan.md` |
| `context` | Qué leer además del código | `CLAUDE.md` / `AGENTS.md` del repo |
| `critical` | Paths que llevan ⏸ | auth, datos/migraciones, plata, borrado, infra |
| `check` | Check rápido por área | Los tests de lo tocado |
| `closing` | Qué cuenta en Tests y Docs | Tests del área; docs que mencionan lo tocado |
| `review.scans` / `review.lenses` | Scans y lentes extra de la self-review | Ninguno |
| `ship.notify` | Canal y formato del aviso | Ninguno |
| `close.cleanup` | Limpieza extra post-merge | Ninguna |
