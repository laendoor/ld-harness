# AGENTS.md

Instrucciones para cualquier agente que trabaje en este repo. El README explica qué es;
esto explica cómo se trabaja acá. Si algo de acá choca con un pedido del usuario, preguntá:
no hay excepciones implícitas.

## Límites duros

- **No `git push`.** El gate lo bloquea y la política es del usuario: él empuja. Dejá el
  comando listo y avisá.
- **No merge**, tampoco `gh pr merge`. Abrir el PR sí; mergear lo hace Leandro.
- Nada irreversible (borrar ramas remotas, reescribir historia, tocar `~/.config/ld-harness`)
  sin pedido explícito.

## Ciclo de trabajo

1. Un issue del milestone [`agent-system`](https://github.com/laendoor/ld-harness/milestone/1)
   en progreso a la vez. Los marcados `needs-definition` se definen antes de empezar.
2. Commits chicos: cada fase de un plan es un commit.
3. Al cerrar, tick del issue con una línea de qué quedó. El detalle está en el commit.

El plan y las decisiones de cada ítem viven en su issue, no en un doc de rama.
El diseño y su evidencia viven en [`docs/agent-system.md`](docs/agent-system.md).

## Commits

El canon de una decisión es el **cuerpo del commit** (D3), no un ADR.

- Subject: `tipo(área): qué`, en inglés, imperativo, ≤72.
- Body: **what** cambió, **why** (el problema real, con números si los hay) y **qué se
  descartó** y por qué. Si no hubo alternativa, decilo.
- El porqué va en el body porque el diff ya dice el qué.

**Gotcha del gate:** los patrones de prosa no se eximen en comandos multilínea. Para un body
largo usá `git commit -F archivo`; nunca `-m` con `;`, `&`, `|`, backticks o `$(`.

## Antes de commitear

```sh
bash plugins/ld-gate/test.sh
bash plugins/ld-format/test.sh
```

## Restricciones de diseño (no re-litigar sin evidencia)

- **Rol = modo del mismo agente** (D1). Sin agentes separados, sin handoff, sin segmentar
  memoria por rol.
- **La unidad es `skills/`** (D7). No hay `playbooks/`; la `description` ya rutea.
- **El adapter es del proyecto, nunca del playbook** (D6).
- **Config en tres niveles** (D8): default del código < `~/.config/ld-harness/config.env` <
  `<repo>/.ld-harness.env`, formato dotenv.
- **Tres superficies de lenguaje, tres dueños**: `LD_PROSA_CHAT`, `LD_PROSA_ARTIFACTS` y
  `LD_PROSA_REGISTER`. El voseo se infiere de `es-AR`; el código va siempre en inglés.

## Deployment

`main` es lo que está vivo: los symlinks globales apuntan a `~/dev/ld-harness`. Un checkout
de rama **no** cambia lo que usan las otras sesiones.

```sh
HARNESS=~/dev/ld-harness               bash setup.sh   # volver a main
HARNESS=~/dev/ld-harness-agent-system  bash setup.sh   # promover esta rama
```

No promuevas una rama que está tocando el gate o los hooks: te bloqueás la sesión que los
está arreglando. Probá con `HOME` falso.

## Gotchas conocidos

- `opencode mcp list` dice "No MCP servers configured" aunque los MCPs estén cargados. No es
  fuente de verdad.
- opencode **ignora** `allowed-tools` en el frontmatter de un skill. El límite real es
  `permission.bash` y `permission.skill`.
- Los `aika-*` / `fini-*` viven en los repos de proyecto, no acá.
