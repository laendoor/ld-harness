---
name: ld-self-review
description: Revisar tu propio branch como lo haría un tercero, antes de que exista el PR y mientras un finding todavía es un fixup — reconcilia las fases del plan contra el diff, corre un scan determinista de hard-fails, y dos agentes frescos, sin la conversación de la implementación — uno personal (criterios, decisiones, reglas del repo, correctness, seguridad) y uno con ponytail-review (calidad general, lean, carga, tests) — cuyos findings se concilian en una lista con origen (ambos · personal · ponytail). Quote-check para descartar findings alucinados, chequeo de intención contra el plan, log de calibración por origen, mapa de riesgo de qué commits leer línea por línea, y triage tuyo con cuatro verbos — fix (fixup) · drop · defer (deja un `ponytail:`) · ticket. No postea en GitHub ni corre gates de CI. Etapa self-review de ld-workflow; los adapters suman scans y lentes. Para un PR ajeno ya abierto, usar una review de PR, no esto.
argument-hint: "[--full]"
allowed-tools: Read, Grep, Glob, Edit, Skill, Bash, Agent
---

# ld-self-review

Revisás tu propio branch contra el plan que lo guió, antes del PR. No es una
review de PR: acá un finding todavía es un fixup que se pliega en el commit de su
fase; en el PR ya sería un comentario de otro y un commit "fix review".

Contrato general: `~/dev/ld-harness/skills/ld-workflow/SKILL.md` (§1 convenciones,
§9 slots). El adapter aporta `review.scans`, `review.lenses`, `ticket.fetch` y
`plan.path`; sin adapter corren solo los pasos de acá.

**`--full`** promueve el bucket ⚪ / `speculative` a entradas completas. El modo
`full` del plan lo activa solo; el modo `fino` corre solo los pasos 1–3 (express).

## 0. Sin gates, y por qué

No corras typecheck, build, lint ni suites: CI los corre en cada branch. El
reporte igual dice que no se corrieron y que los tiene CI; una omisión callada se
lee como un paso salteado. La única excepción es un gate que el adapter declare
(cuesta un segundo y su falla tira todo un stage de CI).

## 1. Resolver el objetivo y cachear el diff

```bash
git status --porcelain     # tiene que estar vacío
git branch --show-current
git rev-parse --short HEAD
git rev-list --count origin/<base>..HEAD
```

`<base>` es la línea `**Base:**` del plan, `main` si falta (contrato §1).

Árbol sucio → frenar: la review describe un estado al que se puede apuntar, y
trabajo sin commitear no lo es.

Cachear el diff una vez, junto al plan, con el sha en el nombre para que un
rebase lo invalide solo: `git diff origin/<base>...HEAD > <dir del plan>/.review-<sha>.diff`.
**Tres puntos**, no dos: con dos entra todo lo que llegó a la base desde que nació
el branch y se reporta trabajo ajeno como propio.

## 2. Plan contra diff

Leer el plan del working tree (es scratch, nunca está en el diff). Por fase:

- `[x]` sin cambio correspondiente en el diff → 🔴 `likely`. Decir la búsqueda
  que se corrió: un grep que falló por adivinar mal el path no es un finding, y
  decir la búsqueda es la única forma de distinguirlos. Antes de un 🔴, buscar por
  basename: los paths del plan son prosa.
- `[ ]` cuyo trabajo está en el diff → 🟡: el scope se adelantó y la próxima
  corrida lo va a rehacer.
- `[-]` → nunca finding, salvo que su trabajo esté en el diff igual (🟡, citando la
  razón por la que se salteó).
- Exentas: fases cuyo entregable no es código (verificación manual, decisiones).

Reportar como tabla corta aunque todo coincida: un resultado limpio tiene que
verse como resultado, no como paso salteado.

## 3. Scan determinista de hard-fails

Salen de comandos, no de juicio: si no corriste el comando, no chequeaste la
regla. Son `certain` y no pasan por el quote-check. `DIFF=<el diff cacheado>`.

**3.a Secretos en líneas agregadas.** Un grep pelado no sabe de qué archivo vino
cada línea y convierte cada fixture en una credencial filtrada; el `awk` arrastra
el nombre del archivo:

```bash
awk '/^\+\+\+ b\// { f = substr($2, 3) } /^\+/ && !/^\+\+\+/ { print f "\t" $0 }' "$DIFF" \
  | grep -iE '(password|secret|token|api[_-]?key)[[:space:]]*[=:][[:space:]]*"[^"$]' \
  | grep -viE 'process\.env|os\.getenv|CHANGEME|changeme|placeholder|example|00000000'
```

Código de producción → 🔴. Tests, fixtures y templates `.example` → ⚪ en una sola
línea colapsada. Nunca se descartan: una credencial real en un test llega al
mismo repo.

**3.b Higiene.**

```bash
grep -E '^\+\+\+ b/.*(\.(old|bak|orig)$|-(old|bak)\.[A-Za-z]+$)' "$DIFF"   # archivos de respaldo
grep -nE '^\+(<<<<<<<|>>>>>>>|=======$)' "$DIFF"                          # marcadores de conflicto
```

Cualquier match → 🔴.

**3.x Scans del adapter** (`review.scans`), en su orden. Los que marque como
**mención obligatoria** no llevan severidad: dan una línea en el encabezado del
reporte. "El diff tocó el borde de confianza o el deploy y nadie lo dijo" es la
falla que existen para evitar; una severidad falsa sobre un refactor inocuo se
descarta en el triage y se lleva la señal real con ella.

## El corte: los pasos 4 y 5 los corren dos agentes frescos

Los pasos 1–3 son mecánicos y corren acá. El 4 (decisiones y criterios) y el 5
(juicio) los corren dos subagentes sin esta conversación, según
`~/dev/ld-harness/skills/ld-review-reconcile/SKILL.md`: uno **personal** y uno con
**ponytail-review**. El 6 es la conciliación de esa skill; el 7 y el 8 vuelven acá.
El modo `fino` no los lanza: corre solo 1–3.

Por qué fuera de esta sesión: suele ser la que implementó. Sabe por qué escribió
cada línea, así que lee el diff confirmando su propio razonamiento — un cliente HTTP
nuevo al lado de uno que ya existía pasa como decisión, no como finding. Por qué
dos: lo que marcan los dos es casi seguro real, lo que marca uno solo es donde vale
mirar, y el log de calibración dice cuánto vale cada uno.

El brief del personal, además de lo que fija la skill de conciliación:

- los paths de los diffs cacheados y la `<base>`;
- el path del plan: fases y `## Decisiones`, donde vive el porqué acordado;
- cómo leer el ticket (slot `ticket.fetch`), o "sin ticket";
- las `review.lenses` del adapter, textuales, y `--full` si corre;
- correr los pasos 4 y 5 de este archivo.

Nunca va en ningún brief: el resumen de la implementación, decisiones que no están
en el plan, ni qué mirar. Eso es el ancla que el corte saca. Si una decisión que
importa no está en el plan, el finding que dispare es correcto: falta en el plan.

## 4. Decisiones y criterios de aceptación

Primero `## Decisiones` del plan: código que contradice una decisión registrada →
🔴, citando la línea: es el acuerdo bajo el que se autorizó la corrida. Después
el ticket (slot `ticket.fetch`), en las dos direcciones:

- Un criterio que el branch no cumple → 🟡 `likely`, citándolo.
- **Un criterio o decisión de diseño que el branch contradice → 🔴.** Es la
  dirección que un review de PR no agarra, porque para entonces el ticket se lee
  como la autoridad.
- Scope que el ticket no describe → 🟡: el ticket necesita actualizarse, no el código.

Ticket sin criterios, o tarea sin ticket: decirlo en una línea y seguir.

## 5. Pasada de juicio (agente personal)

Revisar el diff como alguien que no lo escribió, en lo que solo este agente puede
ver: correctness y seguridad en los bordes reales del repo (el adapter los nombra
en `review.lenses`; una lista genérica da findings genéricos), incluidos los
callers de un contrato que el diff cambia, y el contrato del repo — sus
`.claude/rules` y convenciones, como reusar el cliente HTTP que ya existe. La forma
— duplicación, diseño, sobre-ingeniería — junto con la carga y los tests faltantes,
es del agente ponytail.

Tres reglas:

- **Cada 🔴 y 🟡 necesita un caso concreto:** esta entrada o situación da este
  resultado incorrecto. Sin caso no hay finding.
- **Doc contra código, sin elegir ganador de antemano.** Cuando el diff toca ambos
  o cambia conducta que un doc tocado describe: reportar la divergencia citando
  los dos lados y decir cuál _parece_ más viejo y por qué. No reconciliar acá, no
  auditar docs que el diff no tocó.
- **No marcar lo que una herramienta ya agarra:** formato, orden de imports,
  ancho de línea, tipos, locals sin usar.

Cada finding lleva una `confidence` interna, no impresa: `certain` (el hunk lo
prueba mecánicamente), `likely` (lo sostiene con juicio), `speculative` (sin cita
inequívoca). Solo decide la ubicación: `speculative` va al bucket compacto.

## 6. Conciliación y quote-check

`ld-review-reconcile` §2, en esta sesión: normaliza el reporte de ponytail, agrupa
lo que los dos marcaron (`ambos`), corre el quote-check sobre la lista unida —
la cita tiene que existir en HEAD; fuera del diff vale — y compara la intención
contra el `**Goal:**` del plan. Los findings del paso 3 no pasan por el
quote-check: citan por construcción.

## 7. Reporte y triage

Un solo listado en el chat. Nada de archivos, comentarios en el PR ni commits.
Título: `## Self-review · <id> · <branch> · <N> commits sobre <base>`. Encabezado,
bloque Intención, entradas de findings y bucket: formato de `ld-review-reconcile`
§3. Esta skill aporta las filas `Fases` (paso 2, `6/6 coinciden` o la tabla si no)
y `Gates`, y el mapa de riesgo entre la intención y los findings.

**Mapa de riesgo — dónde leer**, una línea por commit de fase, en tres niveles.
Existe porque revisás una vez por tarea: es lo que hace que esa revisión gaste su
profundidad donde un error cuesta.

```txt
Dónde leer:
  línea por línea  a1b2c3d 2 · ⏸ migración — schema + datos
  con atención     d4e5f6a 3 · orquestador — lógica nueva, sin path crítico
  pasada rápida    0718293 4 · Tests · 1a2b3c4 5 · Docs
```

Línea por línea: fases ⏸, commits con mención obligatoria y los que cita un 🔴.
Con atención: lógica nueva fuera de eso. Pasada rápida: tests, docs, renames.

Después los findings, numerados, en el orden y el formato de `ld-review-reconcile`
§3. Cerrar con:

> Triage por número: `fix` · `drop` · `defer` (dejo un `ponytail:`) · `ticket`. Ej: `fix 1,3; defer 2; drop 4`.

**Esperar la respuesta.** Algunos findings no se pueden zanjar desde el diff, y
presentarlos como conclusiones en vez de candidatos es como una review empieza a
ser ignorada.

## 8. Ejecutar el triage

El único paso que escribe, y solo sobre lo que marcaste.

- **`fix`** → `git commit --fixup=<sha del commit de la fase>`.
- **`drop`** → nada.
- **`defer`** → un comentario `ponytail:` en el lugar del finding que nombra el
  techo y el camino de upgrade (`// ponytail: map en memoria, cache por cuenta si
supera una réplica`). Un defer sin techo nombrable es un `drop`: decirlo.
- **`ticket`** → no crearlo: pasarlo como semilla al skill de tickets del adapter
  (o `ld-create-ticket`), que arma el draft y pregunta.

Después, una línea por finding presentado en el log de calibración
(`ld-review-reconcile` §4, `skill` = `self-review`, `ref` = la key o el slug).

Cerrar con lo que se arregló (fixup → fase) y lo que queda con su razón. Cuando
aprobás: `GIT_SEQUENCE_EDITOR=: git rebase -i --autosquash $(git merge-base origin/<base> HEAD)`
y `git log --oneline origin/<base>..HEAD`. Siguiente: push (tuyo) → `/ld-ship-task`.

## Qué no hace

- **Nada en GitHub ni en el ticket.** No hay PR todavía.
- **No arregla antes del triage.**
- **No caza duplicados por todo el repo ni audita docs que el diff no tocó.** Que
  el diff reinvente un helper existente sí se marca: lo ve ponytail, o el personal
  si una regla del repo lo nombra.
- **Dos agentes con lentes distintas, nunca más.** Un tercero no agrega
  independencia y multiplica la conciliación. El quote-check corre una vez, en la
  conciliación, porque solo vale cuando un mismo lector verifica cada cita contra
  el mismo texto. Un diff demasiado grande se parte por área, no por lente.
- **No resume la tarea.** Qué cambió y por qué va al body del PR, en ship.
- **No pushea.** Los únicos commits son fixups de lo que marcaste `fix`.
