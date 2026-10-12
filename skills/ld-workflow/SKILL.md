---
name: ld-workflow
description: Contrato discuss → implement para tareas. Discuss produce análisis + dudas numeradas + propuesta/alternativa + fases con gates + grosor de cierre + SHIP y frena esperando OK. Implement exige plan aprobado, frena en gates sensibles y cierra proporcional. Usar vía /ld-discuss-task y /ld-implement-task.
---

# ld-workflow — contrato del workflow

Dos comandos, un contrato. `ld-discuss-task` discute, `ld-implement-task`
ejecuta. El discuss nunca ejecuta; el implement nunca discute de cero.

## 0. Engram primero (ambos comandos)

- **Discuss:** `mem_context` y/o `mem_search` con keywords de la tarea. Trabajo
  previo o decisiones relacionadas se citan en el análisis, no se redescubren.
- **Implement:** `mem_save` proactivo (decisión / bugfix / descubrimiento /
  convención, formato What/Why/Where/Learned). Al cerrar: `mem_session_summary`.

## 1. Discuss — formato de salida (todo numerado, siempre)

```txt
## Análisis
<qué entendí, 3-5 líneas>

## Dudas
1. <duda puntual> — propuesta: <encare> / alternativa: <otra vía>
2. ...

## Propuesta
<encare elegido y por qué, 2-3 líneas>

## Alternativa descartada
<qué se descartó y por qué — si no podés defender la propuesta contra esta,
no estás listo para ejecutar>

## Bloqueos / contradicciones
<los que haya, o "ninguno">

## Fases
1. <fase> [sensible: sí/no]
2. ...

## Cierre propuesto
grosor: <fino/normal/full> — <justificación en 1 línea>
SHIP: <pasos concretos de ship en este proyecto, o "a definir con el adapter">

## Plan
<ruta del archivo de plan aprobado que vas a dejar, ej. `<repo>/.tmp/plan-<tarea>.md`>
---
Dame el OK o tus ajustes numerados.
```

Reglas:

- Fases: 1..n de trabajo. `sensible: sí` = freno obligatorio al terminarla
  (irreversible, scope/arquitectura, datos/auth/plata, o lo que yo marque).
- El plan aprobado es un archivo versionado en el **repo de trabajo**, nunca en
  el harness. Sin ese archivo + mi OK, no existe plan.
- Interacción numerada: mis ajustes vienen numerados, tus respuestas citan
  números. Nada de parafraseo ambiguo.

## 2. Implement — reglas

1. **Sin plan aprobado no hay ejecución.** Si falta, frenar con el mensaje
   "falta `/ld-discuss-task` para esto" + qué falta. Sin excepciones.
2. Ejecutar fases en orden. Al terminar cada fase, sensible o no: commit en
   el branch de trabajo (mensaje convencional, solo archivos de la fase).
   Si es `sensible: sí`: además frenar, mostrar diff/decisiones y pedir
   confirmación. Fases normales: commitear, loguear y seguir.
3. Al terminar las fases: frenar siempre (revisión de bloque) antes del cierre.
   El agente nunca ejecuta `difit` ni viewers interactivos: indica el comando
   exacto (`difit <branch|commit>` desde el repo) y espera el veredicto.
   El cierre puede ejecutarse ahí o diferirse a `/ld-close-task` (ej. cuando el
   merge o la verificación posterior los hace el usuario). Sin plan aprobado,
   ninguno de los dos ejecuta.
4. Cierre según grosor aprobado. Si la realidad contradice el grosor (la tarea
   "trivial" tocó auth), decirlo y re-proponer grosor antes de seguir.
5. SHIP: proponer checklist → confirmar → ejecutar. Nunca shippear de oficio.
6. Validación final: nada está "listo" sin mi venia explícita.

## 3. Cierre — slots y grosor

Slots (todos propuestos, confirmados, ejecutados — en ese orden):

1. **TEST** — tests del área afectada.
2. **DOC** — registros tocados (bitácora, STATUS, ADR según el proyecto).
3. **REVIEW** — ld-self-review externo (dos lentes: correctness+seguridad y
   over-engineering), fix de findings antes de cualquier PR.
4. **SHIP** — lo que "manda" en ese proyecto: PR, update de ticket, mensaje a
   un canal, registro de cambio. Lo concreto lo define el adapter del proyecto;
   sin adapter, SHIP = "propongo los pasos, espero tu venia".

Grosor (propuesto en discuss, validado por mí):

| Grosor | Cuándo                                    | Cierre                                     |
| ------ | ----------------------------------------- | ------------------------------------------ |
| fino   | trivial: typo, rename, 1 línea sin lógica | REVIEW express o ninguno, SHIP mínimo      |
| normal | cambio medio, área acotada                | TEST del área + DOC tocada + REVIEW normal |
| full   | arquitectura, auth, datos, scope          | todo + SHIP completo                       |

Anti-burocracia: el grosor se justifica en 1 línea. Si sobra, lo recorto en el
discuss — para eso existe.

## 4. Adapters de proyecto

Los comandos puntuales (`fini-*`, `aika-*`, ...) aportan contexto y delegan acá.
El adapter define: qué es SHIP en ese proyecto, dónde vive el plan, qué
convenciones lee el REVIEW. El harness nunca inventa el canal de ship.

## 5. Close separado — `ld-close-task`

Se invoca una vez mergeado el PR, cuando el cierre no ocurrió dentro del
implement (merge o verificación posterior del lado del usuario).

1. **Sin plan aprobado no hay cierre.** Misma regla y mismo mensaje que
   implement. Sin excepciones.
2. Ejecutar el cierre según el grosor aprobado (§3): TEST del área si quedó
   pendiente, DOC tocada, REVIEW si aplica. Lo puntual (bitácora, STATUS,
   limpieza de ramas, tickets) lo define el adapter del proyecto.
3. SHIP: proponer checklist → confirmar → ejecutar. Nunca de oficio.
4. Cerrar memoria con `mem_session_summary`. Sin esto, la próxima sesión
   arranca ciega.
5. Validación final: nada está "listo" sin venia explícita.
