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
│   ├── ld-discuss-task.md
│   ├── ld-implement-task.md
│   └── ld-sync.md
├── skills/                 ← contratos completos (el agente los carga on-demand)
│   ├── ld-mem/             ← handoff pre-/clear
│   ├── ld-workflow/        ← contrato discuss → implement (fases, gates, cierre, SHIP)
│   └── ld-sync/            ← política de sync del propio harness (notify-only)
├── plugins/
│   ├── ld-prosa/           ← estilo de comunicación (always-on)
│   └── ld-gate/            ← enforcement determinístico (deny, no "tratar de")
├── profiles/               ← overlays por objetivo (personal/estudio/trabajo)
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

## Instalación en PC o ambiente nuevo

1. Cloná el repo: `git clone git@github.com:laendoor/ld-harness.git ~/dev/ld-harness`
2. Corré el setup: `bash ~/dev/ld-harness/setup.sh` (con `--profile=trabajo` si
   aplica; ver `profiles/`)
3. En Claude Code: `/plugin marketplace add laendoor/ld-harness` y
   `/plugin install ld-prosa@ld-harness`
4. Verificá: `ls -la ~/.config/opencode/skills/ ~/.claude/skills/` muestra los
   symlinks `ld-*`; en opencode escribí `/ld` y tienen que autocompletar los 3
   comandos
5. Actualizá Engram MCP si el ambiente no lo tiene (ver "Engram" abajo)

`setup.sh` es idempotente: se puede correr de nuevo sin romper nada.

## Engram (memoria del harness)

Engram no es opcional: es el subsistema de memoria del harness.

1. Al abrir trabajo (`ld-discuss-task`): `mem_context` y/o `mem_search` con
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

## Perfiles (personal / estudio / trabajo)

`profiles/` contiene solo overrides (permisos más estrictos, remotes, reglas).
El core `ld-*` es idéntico en todos lados. `setup.sh --profile=<nombre>`
aplica el overlay después de los symlinks. Sin perfil, default personal.

## Adapters de proyecto

Los comandos puntuales (`fini-*`, `aika-*`, ...) NO se absorben: se adelgazan.
Cada uno aporta su contexto puntual y delega al general (`ld-discuss-task` /
`ld-implement-task` / `ld-sync`). La migración es posterior a estabilizar los
generales.

## Pendientes

- [ ] **PC del trabajo (lunes):** clonar `ld-harness` en `~/dev/` (o mover el
      checkout viejo de `claude-kit`) y correr `bash ~/dev/ld-harness/setup.sh`.
      El remote ya se llama `ld-harness`: si el clone es viejo, actualizar remote
      (`git remote set-url origin git@github.com:laendoor/ld-harness.git`).
- [ ] **PC del trabajo (lunes):** en Claude Code, `/plugin marketplace add
laendoor/ld-harness` + `/plugin install ld-prosa@ld-harness` (el marketplace
      `claude-kit` quedó obsoleto; revisar si el plugin viejo sigue instalado y
      removerlo).
- [ ] Verificar que `/ld` autocompleta los 3 comandos en opencode.
- [x] Migrar `create-pr` / `create-ticket` / `self-review` globales al harness.
- [ ] Adelgazar `fini-*` / `aika-*` a adapters que delegan a los generales.
