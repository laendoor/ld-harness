---
name: ld-ops
description: Operar un entorno desplegado — deploy, releases, parches, backups, dumps, migraciones y diagnóstico de contenedores. Read-only primero, rollback nombrado antes del cambio, verificación desde afuera y lo aprendido al runbook del proyecto. Genérico: los datos del entorno los aporta el adapter. Usar vía /ld-ops o cuando la tarea toca un server, un deploy, un backup o datos de producción.
argument-hint: "[qué hay que hacer, o vacío para inventario]"
allowed-tools: Read, Grep, Glob, Bash, Edit
---

# ld-ops — operar un entorno desplegado

Este skill no sabe de qué habla. No conoce hosts, puertos, UIDs ni rutas: **todo lo que
es de un entorno puntual lo aporta el adapter del proyecto.** Si te falta un dato, no lo
inventes ni lo busques a ciegas — pedilo.

| pieza             | qué es                                                      | dónde vive           |
| ----------------- | ----------------------------------------------------------- | -------------------- |
| **procedimiento** | pasos, verificación, prohibidos                             | este skill           |
| **estado**        | qué hay desplegado, con qué identidad, qué no re-researchar | runbook del proyecto |
| **parámetros**    | lo que este skill necesita para actuar                      | adapter del proyecto |

**Dónde está.** `<repo>/ops/adapter.md` si el proyecto es un repo. Si es cross-proyecto
—un host que sirve a varios repos— es definición de usuario:
`~/.config/ld-harness/adapters/<tipo>-<nombre>.md` (ej. `droplet-12-cactus.md`). El prefijo
dice qué clase de entorno es, no qué proyecto lo usa.

**Supuesto de herramienta.** Los ejemplos usan docker/compose y curl porque es lo que hay
en todos los proyectos hoy. Si un entorno usa otro orquestador, lo declara el adapter y
los comandos se traducen — lo que no cambia son los cinco pasos. Si algún día la mayoría
cambia de orquestador, se cambia acá una vez, no en cada adapter.

## Lo que el adapter tiene que declarar

Si alguno falta, se pide antes de empezar. Sin esto el procedimiento es una receta a
ciegas.

- **host y acceso** — alias SSH o equivalente, usuario, método de auth.
- **orquestación** — dónde viven los compose / manifiestos y los scripts de deploy.
- **verificación** — endpoints externos que tienen que responder, y cuál es la señal de
  "está sano" (status code, body, healthcheck).
- **ventana de arranque** — cuánto tarda el servicio en estar sano después de un reinicio.
  Es propiedad del proyecto, no del skill.
- **irreversible declarado** — qué operaciones destruyen datos o no se pueden deshacer.
- **ownership intocable** — UIDs o dueños de volúmenes y bind mounts que no se cambian.
- **dónde van los documentos** — runbook de estado y bitácora de operaciones.

## Convención de documentos (el adapter puede cambiarla)

Si el proyecto no dice otra cosa:

```txt
ops/RUNBOOK.md                  estado del entorno — vivo, se corrige
ops/runs/AAAA-MM-DD-<tema>.md   una operación puntual — fechado, no se edita después
```

El runbook describe **qué hay**; el run de `ops/runs/` describe **qué se hizo ese día**.
El segundo no se actualiza: es historia. El primero se corrige cada vez que la realidad
lo contradice.

## Regla de oro

**Ningún paso que muta corre antes de un paso que solo lee.** El inventario primero no es
ceremonia: es lo que evita tocar el contenedor equivocado, el volumen equivocado o el
dominio equivocado.

Antes de cualquier cambio irreversible, el rollback se **nombra en una línea**. Si no
podés escribir esa línea, no estás listo para el paso.

## Los cinco pasos

### 1. Inventario (solo lectura)

Correr y pegar la salida antes de decidir:

```bash
<acceso> 'docker ps --format "{{.Names}} | {{.Status}}"; \
          docker system df; df -h /; uptime'
```

El healthcheck va aparte, porque su ausencia no se ve en la salida anterior:

```bash
<acceso> 'docker ps --format "{{.Names}}" | xargs -I{} \
  docker inspect --format "{{.Name}} {{if .State.Health}}{{.State.Health.Status}}{{else}}sin-healthcheck{{end}}" {}'
```

`sin-healthcheck` es un dato, no un error: significa que la única señal de salud es la
externa.

**Regla del disco.** Si el uso supera el 70%, `docker system df` no alcanza: lo que ocupa
puede estar fuera del orquestador — bind mounts, uploads, dumps, logs. Listar antes de
proponer cualquier limpieza:

```bash
<acceso> 'du -xh -d1 / 2>/dev/null | sort -h | tail -8'
```

Sin eso, "no hay nada que limpiar" es una conclusión falsa: el orquestador te muestra el
1% del problema.

Según el caso, sumar: `compose config`, validación de la config del proxy, paquetes
actualizables.

**No proponer el cambio hasta tener esta salida.** Si falta un dato, se pide.

**Si el acceso remoto está bloqueado por la política del harness, no lo esquives:** pedile
la salida al humano, seguí con lo que te pegue y decí explícitamente qué quedó sin leer. Un
playbook que no puede leer el entorno empieza pidiendo lectura, no flaqueando.

### 2. Snapshot o backup, en ese orden

Irreversible es: un dump que reemplaza, una migración, un borrado, un prune de volúmenes,
un `down -v`, una actualización de paquetes del sistema, una renovación de certificados,
un borrado de ramas.

- Datos → dump antes, con fecha en el nombre.
- Sistema → snapshot del host antes.
- Código → tag o rama antes.

### 3. Un cambio por paso, y su verificación pegada

Nunca dos cambios seguidos sin verificar entre medio: si algo rompe, no sabés cuál fue.

Mostrar el comando completo antes de correrlo. Nada de banderas destructivas sin ver el
objetivo.

### 4. Verificar desde afuera, no desde adentro

Que el contenedor exista no dice que la app responda.

```bash
curl -s -o /dev/null -w '%{http_code}\n' <url>
curl -sf <url-sana> && echo ok
```

Tres reglas:

- **Respetar la ventana de arranque del adapter.** Un 5xx dentro de esa ventana no es
  falla: reintentar antes de diagnosticar.
- **El healthcheck del contenedor y la respuesta externa pueden discrepar**, en las dos
  direcciones. Se miran las dos. Si no hay healthcheck declarado, la respuesta externa es
  la única señal real: no asumas sano porque el proceso vive.
- **Nunca verificar con el mismo comando que hizo el cambio.** El exit code no es
  evidencia.

### 5. Cerrar: clasificar cada hallazgo

El inventario no termina con una lista, termina con cada hallazgo asignado a un balde.
Ningún hallazgo se cierra sin balde: "lo vemos después" es una nota sin dueño.

| balde            | cuándo                                                                                                                                  | qué se hace                                                                        |
| ---------------- | --------------------------------------------------------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------- |
| **acción ahora** | hay riesgo activo, o es reversible y corto — parche de seguridad, actualización de paquetes, permisos, un contenedor sin restart policy | se hace en esta misma corrida, con OK explícito antes de cada comando              |
| **issue**        | requiere diseño, toca código, o el dueño es otro repo — falta de healthcheck, falta de logs, un servicio sin backup                     | se propone como `<repo> — <título>` y se crea con el flujo de tickets del proyecto |
| **nota**         | corrige el estado declarado                                                                                                             | al runbook                                                                         |

**Regla de ruteo:** el issue va al repo **dueño del componente**, no al repo de ops. Un
contenedor de `espi` sin healthcheck es un issue de `espi`, aunque lo hayas encontrado
desde el droplet.

**Regla de precedencia:** si un hallazgo admite las dos, primero la acción que baja el
riesgo y después el issue con lo que quede. Parchear es urgente; diseñar el parche no.

Al runbook de estado, lo que cambió de la realidad. Al run fechado, lo que se hizo hoy.
**Nunca a este skill**: el skill no crece con casos.

## Diagnóstico cuando ya está roto

1. ¿Responde desde afuera? → si sí, es degradación, no caída.
2. ¿El contenedor está arriba? → si no, logs recientes.
3. ¿La dependencia de datos responde? → si no, puede ser el orden de arranque.
4. ¿Disco? → un disco lleno se ve igual que una app colgada.
5. ¿Se tocó algo en los últimos 30 minutos? → ahí está la respuesta la mayoría de las
   veces.

**Si dos intentos fallan, parar.** Dos fixes que fallan comparten una premisa. Escribirla
en una línea y probarla directamente, en vez de un tercer fix.

## Prohibido

- Correr algo destructivo sin mostrarlo antes y tener OK explícito.
- Cambiar el ownership de volúmenes o bind mounts sin saber qué UID espera el proceso.
  El adapter lo declara; si no lo declara, se averigua antes de tocarlo.
- Publicar un puerto en la interfaz pública cuando tiene que ser local: el orquestador
  puede saltear el firewall del host.
- Tocar el entorno "para probar" sin snapshot.
- Commitear credenciales, `.env` o dumps.

## Plantilla de reporte

```txt
qué cambié:     <una línea>
verificación:   <comando + salida real, no "anda">
rollback:       <cómo se revierte, o "no aplica porque X">
registrado en:  <runbook / run fechado>
pendiente:      <lo que quedó abierto, o "nada">
```
