---
name: ld-deps-task
description: Consolidar los PRs abiertos de Dependabot (y otros updates de dependencias) en un branch propio — descubre los bumps, propone qué entra y qué se difiere, implementa, verifica localmente y abre un PR que los referencia uno por uno. No mergea; el cierre lo corre el comando del proyecto. Usar vía /ld-deps-task.
---

# ld-deps-task — de N PRs de Dependabot a un branch propio

Dependabot abre un PR por grupo, y esos PRs no se mergean sueltos: uno por uno
reordenan lockfiles y dejan el repo a medio actualizar. Esta tarea los junta.

```txt
descubrir ──▶ [tu OK] ──▶ implementar ──▶ [difit] ──▶ push tuyo ──▶ PR ──▶ [merge tuyo] ──▶ close del proyecto
diff de los              branch, bumps          refs uno          espera          cierra los N
manifests                install, fallout        por uno                          y registra
```

**Nunca mergea.** El merge es tuyo y pasa fuera del harness.

## 1. Descubrir

Tres fuentes. Las alertas mandan sobre los bumps.

**PRs abiertos de Dependabot:**

```bash
gh pr list --state open --author app/dependabot --json number,title,headRefName
```

Por cada uno, primero **qué archivos toca**, después **solo el diff de los
manifests**:

```bash
gh pr diff <n> --name-only
gh pr diff <n> -- package.json pyproject.toml Dockerfile '*.yml' '*.yaml' '*.toml' '*.json'
```

Nada de logs de CI, nada de bodies, nada del contenido de los lockfiles. El
lockfile lo regenera el install; el CI ajeno no dice nada útil de entrada (§6).

Si el único archivo es un lockfile, el bump es **transitivo**: no hay versión que
escribir en ningún manifest. Se resuelve pidiéndole el paquete al resolver
—`npm update <pkg>`, `uv lock --upgrade-package <pkg>`— y el lockfile sale solo.
La versión resultante puede quedar más nueva que la que propone Dependabot: manda
el índice, no el PR, y el body del nuestro lo dice.

**Alertas de seguridad abiertas.** Dependabot no abre PR para todas, y una CVE
no espera a la próxima ronda:

```bash
gh api "repos/<owner>/<repo>/dependabot/alerts?state=open&per_page=100" \
  --jq '.[] | "\(.security_advisory.severity)\t\(.dependency.package.name)\t\(.dependency.manifest_path)\t\(.security_vulnerability.first_patched_version.identifier // "sin fix")"'
```

Cada alerta trae la versión que la arregla. Cruzarla con lo que deja el bump: si
el bump ya alcanza `first_patched_version`, la alerta se cierra con este PR y se
anota así en el plan — es el mejor argumento que va a tener el body. Si no lo
alcanza, el paquete entra aunque no tenga PR de Dependabot: una alerta abierta
pesa más que un bump de versión.

Las alertas son del branch default, así que reflejan `main` y no el branch de
trabajo. Al cerrar hay que volver a consultarlas: las que no se resolvieron
siguen ahí y son lo que queda registrado.

**Otros updates que valga la pena sugerir:** `npm outdated` por cada
`package.json` con lockfile, `uv pip list --outdated` si hay `uv.lock`, y las
imágenes base si el repo las pinnea. **Se sugieren, no se incluyen**: van
listados aparte y entran solo si los pedís.

## 2. Plan

Plan de `ld-workflow` §1 más las secciones propias:

```markdown
## PRs absorbidos

- #127 python 3.13 → 3.15 (Dockerfile)

## Alertas cerradas

- certifi 2026.10.23 ≥ 2026.10.18 (crítica)

## Alertas abiertas

- ninguna

## Diferido

- #139 typescript 5 → 7 — el build falla; va aparte
```

Al proponer, separar en tres baldes:

- **Entra** — bumps de librería y de actions, más todo paquete con alerta abierta.
- **Decisión tuya** — cambios de runtime: imagen base, `engines`,
  `requires-python`, versión de lenguaje en CI. Un major de runtime cambia lo
  que corre en prod y no lo valida ningún test de unidad. Nunca entra solo.
- **Difiere** — lo que choca con una decisión abierta del repo: un ticket que
  pide lo contrario, un major que rompe el build. Cada diferido lleva la razón
  en una línea.

Frenar acá. Sin OK sobre el plan no se escribe código.

## 3. Implementar

1. **Branch** desde `origin/<base>` recién fetcheado, con el slot
   `branch.name`; sin adapter, `chore/deps-<YYYY-MM>`. Árbol sucio → frenar,
   nunca cortar arriba de trabajo sin commitear.
2. **Aplicar las versiones en los manifests**, no copiar los lockfiles de los
   PRs. El lockfile se regenera con el install, que es lo único que garantiza
   que el árbol entero resuelve junto.
3. **Instalar**, un comando por ecosistema (`npm install`, `uv lock && uv sync`,
   etc.). Si falla con `ERESOLVE` o un peer conflict, el que choca es más de un
   PR a la vez: agrupar los PRs que comparten el paquete —un provider y su core,
   un meta-paquete y sus piezas— y reintentar. Solo si el árbol sigue sin
   resolver se mira el PR de Dependabot que toca ese paquete.
4. **Fallout.** Una versión nueva activa reglas de lint, cambia un default o
   depreca una API. Se arregla acá, en el mismo commit. Un archivo muerto que
   una regla nueva marca se borra, no se anota.
5. **Verificar** con el slot `check` del adapter; sin adapter, lo que corre el
   repo: lint, build, tests, migraciones. Todo lo que CI corre, corrido local
   primero. Un check que necesita un servicio externo se levanta o se declara
   como hueco en el plan — nunca se da por bueno.

## 4. Ship

1. Commit convencional, en inglés: uno solo, o uno por ecosistema si el diff es
   grande.
2. **Frenar para tu review del diff** (difit si lo pedís).
3. **El push es tuyo.** Mostrar `git push -u origin <branch>` y frenar.
4. **PR** con `ld-create-pr`. El body cierra los PRs absorbidos **con el keyword
   de GitHub, uno por uno**: `Closes #127, closes #128, closes #129`. Nombrarlos
   no alcanza — `Absorb #127` no es un keyword y no linkea ni cierra nada, y un
   rango `#127–#144` linkea 127 y 144 y nada más. El keyword solo actúa si el PR
   apunta al branch default, que es el caso acá.
   Si el branch cierra alertas, decir cuántas y de qué severidad — es lo que más
   le importa a quien revisa. Las etiquetas del ecosistema salen del slot
   `pr.labels`; sin adapter, las que el repo ya use para sus PRs de Dependabot.
5. Hand-off: el link y frenar. El CI lo mira quien mergea. **No mergear.**

## 5. Cierre

Si el body usó los keywords, el merge ya cerró los PRs absorbidos. Lo que queda
para el comando de close del proyecto (`ld-close-task` o su adapter) son los que
no cerraron —porque el keyword faltó, porque el PR apuntaba a otro branch, o
porque Dependabot todavía no recalculó— y el registro de lo que quedó: lee del
plan `## PRs absorbidos` y `## Diferido`. Qué hace con eso —status, bitácora,
branch, memoria— lo define cada proyecto: acá no se asume.

## 6. Rojo en Dependabot

Un PR de Dependabot puede estar en rojo sin que la dependencia tenga nada que
ver: cualquier paso que dependa de un secret falla ahí, porque los runs de
Dependabot no reciben secrets. El upload a Codecov es el caso típico — falla en
las 18 ramas y pasa en la nuestra con el mismo código.

Por eso el rojo ajeno **no se investiga de entrada**. Se traen los cambios y se
prueba todo en nuestro PR, que sí corre con secrets. Solo si **nuestro** PR
falla por algo raro se vuelve al de Dependabot a comparar.

## Prohibido

- Mergear, o encadenar el close sin que el merge haya pasado por vos.
- Incluir un cambio de runtime sin OK explícito.
- Copiar los lockfiles de los PRs de Dependabot.
- Investigar el CI ajeno antes de que falle el nuestro.
