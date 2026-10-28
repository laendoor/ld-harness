---
name: ld-review-reconcile
description: Mecánica compartida de las reviews con dos agentes — uno personal (contrato, reglas del repo, correctness, seguridad) y uno con ponytail-review (calidad general, código conectado, lean, carga, tests) — su conciliación en una sola lista con origen, el formato del reporte y el log de calibración. La cargan ld-self-review y ld-code-review-pr; no se invoca sola.
---

# ld-review-reconcile

Existe para confiar en una review leyendo menos. Dos lectores que no comparten
contexto ni checklist: lo que marcan los dos es casi seguro real; lo que marca uno
solo es donde vale mirar; y el log de calibración dice, con el tiempo, cuánto vale
cada uno. Un tercero no suma: no agrega independencia y multiplica la conciliación.

## 1. Lanzar los dos agentes

En un solo mensaje, para que corran en paralelo (Claude Code: `Agent`, tipo
general-purpose; opencode: `task`). Ninguno recibe la conversación.

**Personal.** El brief lo arma la skill que llama (plan o rule pack, ticket,
lentes). Siempre suma:

- leer `AGENTS.md` / `CLAUDE.md` y `.claude/rules/*.md` del repo antes de juzgar;
- su alcance: el contrato (plan y decisiones, o el ticket; reglas del repo; lentes
  del adapter), correctness — incluidos los callers de un contrato que el diff
  cambia — y seguridad en los bordes reales. Lean, carga, velocidad y tests
  faltantes no: son de ponytail;
- cada 🔴 y 🟡 necesita un caso concreto: esta entrada o situación da este
  resultado incorrecto. Sin caso no hay finding;
- devolver cada finding con `file:line`, claim, severidad, `confidence`, categoría
  (`contract`, `rule`, `bug`, `security`, `doc`) y, para 🔴 y 🟡, qué pasa, caso,
  fix con su costo concreto y qué se acepta si se deja.

**Ponytail.** Brief fijo, sin plan, ticket ni lentes — su valor es no saber qué se
quiso hacer:

> Cargá el skill `ponytail-review` y revisá `<el branch: git diff origin/<base>...HEAD en <path> | el PR #<n> en el worktree <path>>`. Devolvé su reporte completo, sin resumir.

Si `ponytail-review` no está instalado, el agente lo dice y vuelve sin reporte: la
review sigue con el personal solo y el encabezado lo dice. Nunca se emula su
checklist a mano: eso es un segundo agente personal con otro nombre.

## 2. Conciliar

Corre en la sesión que llamó. Es mecánico: agrupa y etiqueta; no descarta ni
re-puntúa.

1. **Normalizar ponytail.** `Must fix` → 🔴, `Should fix` → 🟡, `Nice to have` →
   ⚪. Categoría de su checklist: `bug`, `risk`, `scale`, `test`, `speed`, `lean`.
   Sus partes van a las nuestras: _What this is_ + _Problem_ → Qué pasa, el caso
   concreto que exige → Caso, _Fix_ → Fix, _If we skip it_ → Si se deja. Al
   castellano.
2. **Agrupar.** Mismo archivo, líneas a cinco o menos de distancia y el mismo
   problema → un finding `ambos`. Severidad: la mayor; si difieren, una línea en la
   entrada (`personal 🟡 · ponytail 🔴`). Texto: el más concreto de los dos, y el
   Caso de quien lo tenga. Mismo lugar con problemas distintos → dos findings.
3. **Quote-check sobre la lista unida** — un solo lector contra el mismo texto, por
   eso corre acá y no en cada agente. El `file:line` existe en HEAD (en el worktree,
   si es un PR); si no, descartar (`cite-not-found`). Las 5–10 líneas alrededor
   contienen lo que el claim nombra; si no, descartar (`claim-not-supported`). Una
   cita fuera del diff vale — ponytail lee callers — y se marca `fuera del diff`.
4. **Intención.** El `What this change does:` de ponytail contra el Goal del plan, o
   contra el resumen y los criterios del ticket. Coincide → una línea con su frase.
   Difiere, o hay duda → el bloque Intención con las dos frases textuales y la
   diferencia. La duda se muestra, no se resuelve acá: esta sesión es la que menos
   puede juzgarla.
5. Si esta sesión cree que un finding es falso por contexto que los agentes no
   tenían, lo dice debajo en una línea (`Contexto: …`). Nunca lo saca.

Orden: por severidad, y dentro de cada una `ambos` primero.

## 3. Formato del reporte

Tres reglas para que no abrume: el encabezado dice en siete líneas si hace falta
seguir leyendo; solo 🔴 y 🟡 llevan explicación completa; cada finding dice quién
lo encontró, porque eso es lo que con el tiempo deja confiar sin releer.

**Encabezado** — solo las filas que dispararon; `Fases` y `Gates` las pone la skill
que llama:

```txt
Intención    ✓ coincide: "<frase de ponytail>"   |   ⚠ difiere del plan — ver abajo
Criterios    3/4 cumplidos · falta AC2 → #2
Fases        6/6 coinciden con el diff
Gates        no corridos — CI los gatea en cada build
Menciones    toca el borde de auth (apps/api/src/auth/session.ts)
Revisores    12 candidatos → 7 findings: 2 ambos · 3 solo personal · 2 solo ponytail · quote-check descartó 2
Historial    30 días: ambos 18/20 · personal 9/17 · ponytail 7/15
```

Sin ponytail: `Revisores    solo personal — ponytail-review no disponible`. Sin log
todavía: no va `Historial`.

**Intención**, solo cuando difiere:

> **Intención.** El plan dice: _"<Goal textual>"_. ponytail, sin leer el plan,
> describe el cambio así: _"<su frase textual>"_. La diferencia: <una oración>. → #N

Después, el bloque que agregue la skill que llama (el mapa de riesgo en
self-review, la tabla de destinos en code-review-pr), y los findings.

**🔴 y 🟡, entrada completa:**

````markdown
### N. 🔴 <el claim en una línea> · <ambos | personal | ponytail (categoría)>

`file:line` <· fuera del diff>

```ts
<el hunk más chico que lo prueba>
```

**Qué pasa.** <qué es este código y el problema, en castellano llano, 2-4 oraciones>
**Caso.** <esta entrada o situación → este resultado incorrecto>
**Fix.** <qué hacer y su costo concreto — nunca "chico" o "fácil"> · **Si se deja:** <qué se acepta exactamente>
````

**⚪ y `speculative`, bucket compacto, y el cierre:**

```txt
⚪ y speculative (4) — pedime el detalle por número:
  4. scan-runner.ts:12 — MAX_ATTEMPTS exportado y no usado afuera · ponytail (lean)
  5. scan-runner.test.ts:70 — espera 3 s reales; usar fake timers · ambos

Lean (ponytail): −22 líneas posibles → #4, #7
No chequeado: carga con más de una réplica (no hay config de réplicas) · ponytail
```

## 4. Log de calibración

Es lo que convierte "confío en este reviewer" en un número. Una línea por finding
presentado (⚪ incluidos), escrita **después** de ejecutar el triage: el veredicto
es el dato. Columnas separadas por tab; `claim` en inglés, una línea, sin tabs.

- `origin`: `both` · `personal` · `ponytail`
- `verdict`: el verbo del triage — `fix` · `drop` · `defer` · `ticket` en
  self-review; `post` · `drop` en code-review-pr.

```bash
L="${XDG_STATE_HOME:-$HOME/.local/state}/ld-harness/review-calibration.tsv"
mkdir -p "$(dirname "$L")"
[ -f "$L" ] || printf 'date\trepo\tskill\tref\tn\torigin\tsev\tcategory\tverdict\tclaim\n' > "$L"
printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n' \
  "$(date +%F)" "<repo>" "<self-review|code-review>" "<KEY o PR#n>" "<n>" "<origin>" "<sev>" "<category>" "<verdict>" "<claim>" >> "$L"
```

**Historial** — aceptado es todo lo que no terminó en `drop`: un `defer` o un
`ticket` es un finding real que hoy no se arregla.

```bash
awk -F'\t' -v since="$(date -v-30d +%F 2>/dev/null || date -d '30 days ago' +%F)" '
  NR > 1 && $1 >= since { n[$6]++; if ($9 != "drop") a[$6]++ }
  END {
    split("both personal ponytail", k, " "); split("ambos personal ponytail", l, " ")
    for (i = 1; i <= 3; i++) if (n[k[i]]) s = s sprintf(" %s %d/%d ·", l[i], a[k[i]], n[k[i]])
    sub(/ ·$/, "", s); if (s != "") print "30 días:" s
  }' "$L"
```

## Qué no hace

- **No lanza un tercer agente** ni reparte el diff entre varios.
- **No descarta ni re-puntúa** lo que vuelve: agrupa, etiqueta, chequea citas.
- **No emula ponytail** cuando no está: lo dice y sigue con el personal.
