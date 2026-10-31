---
name: ld-status
description: Mostrar el estado de un proyecto en un pantallazo — dónde estoy, qué sigue y qué está roto — y forzar que cada proyecto tenga un adapter que rinda esos tres bloques. Sólo lectura, nunca transiciona ni edita.
---

# ld-status

Un status contesta tres preguntas y nada más: **dónde estoy**, **qué sigue**,
**qué está roto**. Todo lo demás es una lista de issues con otro nombre.

**Announce at start:** "Usando ld-status — armando el pantallazo del proyecto."

## Slots del adapter

Un adapter (`<proyecto>-status`) llena estos tres; sin adapter corre el default.

| Slot              | Qué define                                                                        |
| ----------------- | --------------------------------------------------------------------------------- |
| `status.fetch`    | de dónde sale el estado: branch actual, PR abierto, tickets del board, CI         |
| `status.order`    | cómo se ordena "qué sigue" y con qué se desempata                                 |
| `status.required` | qué tiene que tener un ticket para ser accionable (el reporte marca lo que falta) |

Default sin adapter: branch actual, último PR de ese branch, y los issues
abiertos ordenados por número.

## Los tres bloques

### 1. Dónde estoy

- Branch actual y si está pusheado / al día con su upstream.
- Ticket activo, si el branch nombra uno.
- PR abierto: número, estado del CI y si falta el merge.
- Una línea por dato. Sin narrativa.

### 2. Qué sigue

- Sólo lo **accionable hoy**: tickets sin bloqueo abierto, con dependencias
  cerradas y Momentum que permita atacar.
- Orden y desempate por `status.order`. Si el adapter no lo define, por número.
- Cada ítem en una línea: `#N · <título corto> · <por qué va primero>`.
- Lo que está esperando a otro ticket **no va acá**: va en el bloque 3.

### 3. Qué está roto

Es el bloque que justifica el comando. Marca, sin ordenar por severidad:

- PRs con CI rojo o con el body desactualizado.
- Tickets accionables a los que les falta lo que exige `status.required`
  (Momentum en el board, primera línea de definición, criterio de done).
- Branches locales sin PR, o con PR mergeado y sin borrar.
- Dependencias declaradas sobre tickets ya cerrados.

Un ítem por línea, con el comando o el link para arreglarlo cuando exista.

## Formato

Un pantallazo, no un informe: los tres bloques, bullets de una línea, números y
links. Si un bloque no tiene nada que decir, se escribe `—` y listo; no se
justifica la ausencia.

## Reglas

- **Sólo lectura.** No crea, no edita, no transiciona: si algo del bloque 3 hay
  que arreglarlo, se hace con `ld-define-ticket` o a mano.
- **No lista lo que no se puede atacar.** Un status con 40 issues abiertos es una
  consulta, no un status.
- Si el adapter no llena un slot, el default aplica; no se inventa el estado.
