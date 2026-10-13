# ld-harness

Harness personal de Leandro: el paquete de tools que hace que cualquier agente
(opencode, Claude Code) trabaje a mi gusto sin que yo pierda control ni ownership.

Antes `claude-kit`. Renombrado porque ya no es un kit de piezas sueltas: es el
circuito donde corren.

## Espíritu (las ideas que esto defiende)

1. **Autonomía con gates, no con freno de mano.** El agente avanza solo hasta el
   próximo gate. No pregunta "¿sigo?" cada 2 minutos.
2. **Revisiones pocas y largas.** Yo reviso bloques (diff + decisiones + plan),
   no pasos sueltos. El harness deja rastro revisable para que eso sea posible.
3. **Discutir antes de ejecutar.** Toda tarea arranca con propuesta +
   alternativa descartada + dudas numeradas. Si el agente no puede defender su
   encare contra una alternativa, no está listo para ejecutar.
4. **Todo numerado.** Dudas, opciones, fases, pendientes: numerados. Es la forma
   de interacción que funciona — citar "el punto 3" le gana a parafrasear.
5. **El cierre es proporcional.** Trivial = cierre fino; grande = cierre full.
   Nunca burocracia donde no hace falta.
6. **Nada irreversible sin mi venia.** Push, merge, PR, ship, pulls del propio
   harness: se proponen, se confirman, recién ahí se ejecutan.
7. **El harness avisa, no aplica.** Updates disponibles se notifican; aplicarlos
   es siempre una decisión mía.
8. **Memoria externa, no en mi cabeza.** Engram es parte del harness: el agente
   consulta al abrir y guarda al cerrar. Yo no soy el disco rígido.
9. **Generales acá, puntuales en cada proyecto.** `ld-*` es universal;
   `fini-*`, `aika-*` y demás son adapters finos que aportan contexto y delegan.
10. **Todo lo mío lleva prefijo `ld-`.** Es la marca de ownership: lo que
    empieza con `ld-` vive en este repo y lo mantengo yo. Lo de terceros no se
    vendorea (ver Externos).

## Layout

```txt
ld-harness/
├── commands/               ← entry points /ld-* (visibles en autocompletado)
│   ├── ld-start-task.md / ld-implement-task.md / ld-self-review.md
│   ├── ld-ship-task.md / ld-close-task.md
│   ├── ld-adr.md / ld-create-pr.md / ld-create-ticket.md
│   ├── ld-review-pr.md / ld-review-fix.md
│   └── ld-improve-harness.md / ld-sync.md / ld-whats-next.md
├── skills/                 ← contratos completos (el agente los carga on-demand)
│   ├── ld-adr/ / ld-improve-harness/ / ld-mem/
│   ├── ld-workflow/        ← contrato start → implement → self-review → ship → close
│   │                         + contrato del adapter (slots y defaults)
│   ├── ld-self-review/     ← etapa self-review: triage local, fixups
│   ├── ld-sync/            ← política de sync del propio harness (notify-only)
│   ├── ld-create-pr/       ← body con evidencia; templates de fallback en templates/
│   ├── ld-review-pr/       ← review de un PR ajeno, una sola review en GitHub
│   └── ld-create-ticket/ ld-review-fix/ ld-whats-next/
├── plugins/
│   ├── ld-prosa/           ← estilo de comunicación (always-on)
│   ├── ld-gate/            ← enforcement determinístico: sin push, sin commit en main,
│   │                         sin patrones catastróficos (`bash plugins/ld-gate/test.sh`)
│   └── ld-format/          ← formateo estándar .md (Prettier + MD040); cada
│                             proyecto puede pisarlo con `formatter` propio
├── setup.sh                ← instalación idempotente en PC nueva
└── .claude-plugin/marketplace.json
```

## Concepto clave: command vs skill (opencode y Claude Code los tratan distinto)

- **command** (`commands/*.md`): aparece en el autocompletado cuando escribís
  `/ld...`. Es la puerta de entrada. Cuerpo fino: qué hacer + a qué skill delegar.
- **skill** (`skills/*/SKILL.md`): NO aparece como `/comando` en opencode (el
  modelo la carga vía la tool `skill` cuando la descripción matchea). Acá vive el
  contrato completo.

Regla: **todo lo invocable por mí es command; todo lo invocable por el agente
es skill**. Cada feature tiene ambos: el command adelgaza, el skill engorda.
En Claude Code los skills sí se pueden invocar con `/`, pero el diseño se
mantiene igual para que funcione en ambos motores.

## Flujo diario

1. **Abrir.** `/ld-sync` si dudás del harness; si no, directo a trabajar.
   El agente consulta Engram solo (no arranca de cero).
2. **Arrancar.** `/ld-start-task <ticket o tarea>` (o el adapter del proyecto,
   ej. `/gr-start-task TL4CODE-123`): branch, plan y decisiones numeradas. Se
   discute hasta que no quede ninguna abierta. No escribe código.
3. **Implementar.** `/ld-implement-task`: fase = commit; después de una fase ⏸
   frena y te pasa el `difit`; al terminar frena siempre para tu review. Tu
   `review:` vuelve como fixups.
4. **Self-review.** `/ld-self-review`: review de tercero con triage local
   (fix · drop · defer · ticket) hasta que los fixes estén commiteados.
5. **Ship.** Pusheás vos; `/ld-ship-task` abre el PR, pasa el ticket a review y
   arma el aviso al canal. Todo lo que sale de la máquina espera tu OK.
6. **Close.** Mergeado el PR, `/ld-close-task`: ticket a done, limpieza de
   branch y plan, resumen en Engram.
7. **Handoff.** `/ld-mem` (o `fini-mem` / `aika-mem`) antes del `/clear`.
8. **Mejorar.** Si algo del harness picó: `/ld-improve-harness <idea>` desde
   donde estés.

## Instalación en PC o ambiente nuevo

1. Cloná el repo: `git clone git@github.com:laendoor/ld-harness.git ~/dev/ld-harness`
2. Corré el setup: `bash ~/dev/ld-harness/setup.sh`
3. En Claude Code, el marketplace apunta al checkout (`directory`), no a GitHub:

   ```bash
   claude plugin marketplace add ~/dev/ld-harness
   claude plugin install ld-prosa@ld-harness
   claude plugin install ld-format@ld-harness
   claude plugin install ld-gate@ld-harness
   ```

   Los skills y commands son symlinks y ven cada cambio al momento; los plugins
   Claude los copia a su cache al instalar, así que un cambio en un hook pide
   `claude plugin update <plugin>@ld-harness`. `ld-prosa` declara `version` en
   su `plugin.json`: subila, o el update no ve el cambio. Los demás versionan por
   SHA del commit, así que el cambio tiene que estar commiteado.
4. Verificá: `ls -la ~/.config/opencode/skills/ ~/.claude/skills/ ~/.claude/commands/`
   muestra los symlinks `ld-*`; en Claude y en opencode `/ld` los autocompleta
5. Actualizá Engram MCP si el ambiente no lo tiene (ver "Engram" abajo)

`setup.sh` es idempotente: se puede correr de nuevo sin romper nada.

## Engram (memoria del harness)

Engram no es opcional: es el subsistema de memoria del harness.

1. Al abrir trabajo (`ld-start-task`): `mem_context` y/o `mem_search` con
   keywords de la tarea — no arrancar de cero lo ya decidido.
2. Durante (`ld-implement-task`): `mem_save` proactivo ante cada decisión,
   bugfix, descubrimiento no-obvio o convención nueva (formato What/Why/Where/
   Learned).
3. Al cerrar: `mem_session_summary` (Goal/Instructions/Discoveries/Accomplished/
   Next Steps/Relevant Files). Sin esto, la próxima sesión arranca ciega.

Si el ambiente no tiene el MCP `engram` configurado, el paso 5 de instalación
lo cubre: agregar el server al `opencode.jsonc` global o al `mcp_servers` de
Claude Code según el motor.

## Externos recomendados (no vendoreados)

El harness los usa pero no los contiene. Se instalan aparte:

- **engram** — memoria persistente entre sesiones (subsistema de memoria del
  harness, ver arriba). Binario local + MCP (`engram mcp --tools=agent`).
- **humanizer** — saca marcas de escritura-AI de textos.
  <https://github.com/blader/humanizer>
  (`git clone ... ~/.claude/skills/humanizer`)
- **ponytail** — plugin de simplicidad radical (stdlib primero, diff mínimo).
  <https://github.com/DietrichGebert/ponytail>
  (en opencode: `"plugin": ["@dietrichgebert/ponytail"]`)
- **find-skills** — descubre skills instalables (registry en <https://skills.sh/>).
- **skill-creator** — crea y evalúa skills nuevos.

## Adapters de proyecto

Los comandos puntuales (`gr-*`, `fini-*`, `aika-*`, ...) no viven en el harness:
son locales de cada máquina o proyecto. Cada uno carga una etapa de
`ld-workflow` y llena sus slots (de dónde sale el ticket, paths críticos, check
rápido, canal de ship…); la tabla de slots y sus defaults está en
`skills/ld-workflow/SKILL.md` §9. Una regla de etapa que no le sirve a un adapter
se cambia en el harness, no se pisa en el adapter.

## Pendientes

- [ ] Verificar que `/ld` autocompleta en opencode.
- [ ] Adelgazar `fini-*` / `aika-*` (PC personal) y `gr-*` (PC del trabajo) a
      adapters que delegan a los generales.
