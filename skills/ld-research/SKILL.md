---
name: ld-research
description: Responder una pregunta con evidencia — cómo funciona algo del repo, por qué se construyó así, o qué dice el mundo sobre un tema. Elige fuente (código, historia git o web), cita cada afirmación y declara lo que no pudo confirmar. Se detiene cuando dos consultas nuevas no agregan evidencia. Usar vía /ld-research o cuando la tarea es entender antes de actuar.
argument-hint: "[la pregunta]"
allowed-tools: Read, Grep, Glob, Bash
---

# ld-research — contestar con evidencia, no con impresiones

Una sola regla manda: **toda afirmación va con su fuente o va marcada como inferencia.** Lo
demás es una opinión con formato de informe.

Este playbook **no tiene adapter**. Si alguna vez necesita uno, es señal de que el contrato
está mal: investigar no depende del entorno.

## Los cinco pasos

### 1. Reformular la pregunta en una línea

Escrita como algo que se puede contestar con evidencia, y con la decisión que depende de la
respuesta.

- "¿Cómo funciona el import de CSV?" no es una pregunta: es un tema.
- "¿Qué pasa con una fila cuyo curso no existe: se descarta o se crea?" sí lo es.

Si no se puede reformular, la pregunta todavía no está lista. Devolver la reformulación y
frenar.

### 2. Elegir la fuente

| la pregunta es sobre                            | fuente        | herramienta                        |
| ----------------------------------------------- | ------------- | ---------------------------------- |
| el comportamiento actual del código             | repo          | `Read`, `Grep`, `Glob`             |
| por qué algo se construyó así                   | historia      | `git log`, `git blame`             |
| el mundo, un estándar, una librería de terceros | web           | `tavily_search` + `tavily_extract` |
| una decisión pasada del equipo                  | commits y PRs | cuerpo del commit primero          |

Si la respuesta está en el repo, la web no aporta. Si la pregunta es sobre el mundo, el
repo no aporta. Mezclar sin motivo es lo que vuelve caro investigar.

### 3. Recoger, leyendo la fuente y no el resumen

- **Repo:** leer el archivo, no el nombre del archivo. Para comportamiento, ir al punto
  donde se decide, no a donde se usa.
- **Por qué:** `git log -S'<símbolo>'` encuentra el commit que lo introdujo; `git blame`
  da la línea. El cuerpo del commit explica el porqué, el diff no.
- **Web:** buscar, y **extraer la página del resultado más prometedor antes de citarla**.
  Un snippet es un resumen hecho por un buscador, no la fuente.

### 4. Responder con la certeza marcada

Tres etiquetas, y cada afirmación lleva una:

- **confirmado** — lo vi en la fuente y la cita lo demuestra.
- **inferido** — se deduce de lo que vi, pero la fuente no lo dice. Se explica de qué se
  deduce.
- **no confirmado** — no lo pude cerrar. Se dice qué haría falta para cerrarlo.

Un informe sin la tercera etiqueta está mintiendo: nadie contesta todo.

### 5. Parar

Se deja de buscar cuando **dos consultas nuevas no agregan evidencia**, o cuando la
pregunta del paso 1 ya tiene respuesta con cita. No se busca "por completitud": el
resultado es una respuesta, no un corpus.

## Prohibido

- Contestar de memoria una pregunta sobre este repo. La memoria es una hipótesis de dónde
  mirar, nunca la respuesta.
- Citar una URL sin haber extraído la página.
- Presentar una inferencia como hecho, o esconder la incertidumbre para que el informe se
  vea terminado.
- Investigar sin una pregunta contestable.
- Seguir buscando después del paso 5 para "estar seguro".

## Plantilla de reporte

```txt
pregunta:      <una línea, la del paso 1>
respuesta:     <2-3 líneas, directa>
evidencia:     <path:línea o URL por afirmación>
inferido:      <lo que se deduce y de qué, o "nada">
no confirmado: <lo que quedó abierto y qué haría falta, o "nada">
```
