---
name: ld-define-ticket
description: Definir un ticket — nuevo o existente — hasta que no queden decisiones abiertas, y crearlo o actualizarlo en el tracker. Investiga en solo lectura, pregunta numerado, y sólo escribe con tu OK tras un preview. El body explica el qué y el resultado esperado, nunca el cómo (eso es start). Tiene un modo `--quick` para capturar una idea sin definirla.
---

# Skill: ld-define-ticket

Un ticket se define el día que alguien puede atacarlo sin preguntar nada. Este
skill lleva un issue —vacío, escueto o creado hace un mes— a ese estado, o lo
crea ya definido.

**Announce at start:** "Usando ld-define-ticket — definiendo el ticket."

## Modos y argumentos

| Entrada    | Modo                  | Qué hace                                                                                                                    |
| ---------- | --------------------- | --------------------------------------------------------------------------------------------------------------------------- |
| vacío      | **definir** (default) | investiga, pregunta hasta que no queden dudas, crea el issue                                                                |
| `#N` o URL | **definir existente** | lo mismo, pero al final `gh issue edit` en vez de crear                                                                     |
| `--quick`  | **captura**           | sin investigación ni preguntas: primera línea + contexto de tres oraciones, y el issue nace con Momentum "Falta Definición" |

`--quick` existe porque una idea sin ticket se pierde. Pero **el default es
definir**: el estado "Falta Definición" tiene que ser una elección, nunca un
accidente. Si el adapter define un campo de Momentum, `--quick` lo deja en
"Falta Definición" y el modo normal en "Listos"; sin adapter, no hay campo.

## 1. Antes de escribir nada

- Leé `AGENTS.md` / `CLAUDE.md` del repo y el template de issues si existe
  (`.github/ISSUE_TEMPLATE/`): sus secciones ganan sobre las de este skill.
- `mem_search` con las keywords del ticket: lo previo se cita, no se redescubre.
- Idioma del body: el del repo.

## 2. La primera línea — obligatoria

El body abre con una cita de una sola oración, antes de cualquier heading:

```markdown
> Que `make docker-dev` levante api + web + postgres desde un clone limpio
```

- **Imperativo + resultado verificable.** Qué tiene que pasar para que el ticket
  esté hecho, no de qué se trata.
- **No repite el título**: el título nombra el área y sirve para escanear una
  lista; esta línea da la idea completa.
- **Corta: lo esperable es una oración, dos son aceptables** cuando la tarea
  tiene una condición o un alcance que no entra en una sola. Si se estira a tres
  o a un párrafo, preguntá si conviene partir el ticket — es una pregunta, no una
  regla: hay tickets legítimamente grandes que no se parten.
- Es después la línea que abre el PR: se escribe una vez, no dos versiones de la
  misma historia.

## 3. El título

Corto y de escaneo: se lee en una lista, al lado de otros diez. No necesita ser
declarativo ni explicar la tarea — de eso se encarga la primera línea. Seguí la
convención del repo (`infra: …`, `feat(web): …`); sin convención, `<área>:
<resumen corto>`.

## 4. Qué, no cómo

El body dice **qué** se quiere y **qué resultado se espera**. No dice cómo
implementarlo: eso es una decisión de `start`, que la toma leyendo el código y
queda numerada en el plan.

La prueba: si una línea del body deja al implementador con dos caminos válidos y
el ticket elige uno, esa línea es un _cómo_ y va afuera. Lo que el ticket sí
puede fijar es el borde: "no entra X", "tiene que funcionar con Y", "hoy devuelve
Z y esperamos W".

## 5. Flujo (modo definir)

1. **Leer.** Con `#N`: `gh issue view … --json number,title,labels,body,milestone`
   (el comando concreto lo da el adapter). Sin ticket, el input del prompt.
2. **Investigar (solo lectura).** Código, datos, docs y convenciones que toquen
   la definición — lo justo para saber si la pregunta se puede contestar sola.
3. **Responder en el chat:** qué creo que hay que hacer, y preguntas/dudas
   numeradas. Cada respuesta cierra o reformula un número; se itera hasta que no
   queden abiertos. No se escribe nada en el tracker en este paso.
4. **Preview completo** (ver abajo) y esperar OK.
5. **Con OK:** crear (`gh issue create`) o actualizar (`gh issue edit`), labels,
   milestone, alta en el board y campos del adapter. Sin OK, nada.

## 6. Preview

Siempre el mismo, y siempre completo:

```markdown
## Preview — Ticket a definir

**Acción:** crear | actualizar #N
**Título:** <título>
**Milestone:** <título> (#N) — o "ninguno"
**Labels:** `x`, `y`
**Board:** <campo> = <valor> (si el adapter lo define)

### Primera línea

> <la oración>

### Body

<el body completo, con sus secciones>
```

Marcá con ⚠️ todo lo inferido con baja confianza. Si el body se reemplaza en un
issue existente, decilo explícito: se pierde el anterior.

## 7. Body

Si el repo tiene template de issues, usalo y llená sus secciones (el template
manda sobre este skill). Si no, este es el mínimo:

```markdown
> <primera línea>

## Contexto

<2-4 oraciones: qué es hoy, por qué el ticket existe>

## Alcance

- Entra: <lo que el ticket cubre, en resultados, no en pasos>
- No entra: <lo que queda afuera y por qué>

## Criterio de done

- [ ] <resultado verificable 1>
- [ ] <resultado verificable 2>

## Dependencias

<"- #N — qué aporta" o "Ninguna">

## Stack involucrado

<backend / frontend / infra / data — una línea>
```

Criterio de done es lo que se chequea al final, no una lista de tareas: "`GET /x`
devuelve 200 con el filtro `q`", no "implementar el endpoint".

## 8. Inferencias

- **Labels:** por área y tema, mirando qué labels existen en el repo; no inventar.
- **Milestone:** el abierto que mejor coincida; si hay dudas, preguntar.
- **Estimación:** sólo si el repo tiene una escala (labels `sp:*`, un campo del
  board). Si parece > 8, avisar y proponer partir el ticket.

## Reglas

- **Nunca se escribe en el tracker sin preview y OK**, en ningún modo.
- **Nada de código ni branches**: eso es `start`.
- El body no explica el cómo (§4).
- Si la primera línea se estira más allá de dos oraciones, preguntá si conviene
  partir el ticket; no lo impongas.
