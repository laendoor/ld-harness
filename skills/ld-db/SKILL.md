---
name: ld-db
description: Operar bases de datos — dumps, restores, migraciones de esquema, consultas a producción y correcciones ad-hoc de datos. Read-only por defecto, backup verificado antes de cualquier cambio, y toda escritura con SELECT previo y rowcount esperado. Genérico: motor, acceso y política los aporta el adapter. Usar vía /ld-db o cuando la tarea toca esquema, datos o un dump.
argument-hint: "[qué hay que hacer, o vacío para inventario]"
allowed-tools: Read, Grep, Glob, Bash, Edit
---

# ld-db — operar datos sin perderlos

El modo por defecto es **lectura**. Toda escritura es una excepción que se justifica, se
revierte y se reporta. No hay "un UPDATE rapidito".

| pieza             | qué es                                      | dónde vive           |
| ----------------- | ------------------------------------------- | -------------------- |
| **procedimiento** | pasos, verificación, prohibidos             | este skill           |
| **estado**        | motor, versión, dónde corre, cómo se accede | runbook del proyecto |
| **parámetros**    | lo que este skill necesita para actuar      | adapter del proyecto |

**Dónde está.** `<repo>/ops/adapter.md` si el proyecto es un repo. Si la base es
cross-proyecto —un host que sirve a varios repos— es definición de usuario:
`~/.config/ld-harness/adapters/<tipo>-<nombre>.md` (ej. `droplet-academika.md`).

**Supuesto de herramienta.** Los ejemplos usan postgres/psql y `pg_dump`/`pg_restore`. Si
el motor es otro, lo declara el adapter y los comandos se traducen — lo que no cambia son
los pasos.

## Lo que el adapter tiene que declarar

- **motor y versión** — cliente y servidor, porque un dump se restaura con versión igual o
  mayor.
- **dónde corre y cómo se accede** — contenedor, managed, socket, túnel.
- **credenciales** — de dónde salen. Nunca de la línea de comandos.
- **dónde van los dumps** — destino, formato y retención.
- **herramienta de migraciones** — y si el proyecto trata las migraciones como
  forward-only.
- **ventana de mantenimiento** — cuánto lock se tolera y en qué horario.
- **último restore probado** — la fecha. Si no hay fecha, el backup no está probado.

## Regla de oro

**Ninguna escritura corre sin un SELECT previo que devuelva exactamente las filas que vas
a tocar.** El SELECT primero no es cortesía: es la diferencia entre corregir 3 filas y
corregir la tabla.

Y toda escritura declara, antes de correr, **cuántas filas espera afectar**. Si el número
real no coincide, se revierte.

## Los cinco pasos

### 1. Estado (solo lectura)

- ¿El motor responde? `pg_isready` o equivalente.
- ¿Cuánto pesa? Tamaño de la base y de las tablas más grandes.
- ¿Hay conexiones colgadas o locks abiertos?
- ¿Cuándo fue el último backup y cuándo se restauró por última vez alguno? Si no hay backup
  o no hay fecha, **eso es un hallazgo que se reporta**, no un error del inventario: seguí
  leyendo y dejalo anotado.

**No proponer el cambio hasta tener esta salida.**

### 2. Backup verificado, no backup tomado

```txt
pg_dump -Fc -f <destino>/<base>-AAAA-MM-DD.dump <base>
pg_restore --list <archivo> | head        # abre y lista, sin restaurar
```

Un dump que no se puede abrir no es un backup: es una falsa sensación de seguridad, que es
peor que no tener nada. Verificar el archivo siempre, y restaurarlo a una base descartable
cuando el cambio toca esquema.

### 3. Un cambio, con su transacción

- Escrituras ad-hoc: `BEGIN` → statement → verificar rowcount → `COMMIT` o `ROLLBACK`.
- Migraciones: un paso, no tres juntos.
- Nunca con autocommit, nunca desde el editor sin revisar.

### 4. Verificar los datos, no el exit code

- Rowcount real vs esperado.
- Una query representativa que muestre el estado nuevo.
- El health de la app que la consume.

### 5. Cerrar: clasificar cada hallazgo

Ningún hallazgo se cierra sin balde: "lo vemos después" es una nota sin dueño.

| balde            | cuándo                                                                                                                         | qué se hace                                                                        |
| ---------------- | ------------------------------------------------------------------------------------------------------------------------------ | ---------------------------------------------------------------------------------- |
| **acción ahora** | hay riesgo activo, o es reversible y corto — un dump viejo ocupando disco, una credencial expuesta, una extensión de seguridad | se hace en esta misma corrida, con OK explícito y backup verificado                |
| **issue**        | requiere diseño o toca código — falta un índice, una tabla sin FK, un backup que nunca se restauró, retención mal configurada  | se propone como `<repo> — <título>` y se crea con el flujo de tickets del proyecto |
| **nota**         | corrige el estado declarado                                                                                                    | al runbook                                                                         |

**Regla de ruteo:** el issue va al repo **dueño del esquema o del servicio**, no al repo de
ops. Y un backup sin restore probado es un issue, no una nota: es riesgo, no documentación.

**Regla de precedencia:** primero lo que baja el riesgo hoy, después lo que requiere
diseño. Un dump que se puede borrar es de hoy; la política de retención es un issue.

Lo que cambió de la realidad, al runbook. La operación del día, al run fechado. Nunca a
este skill.

## Migraciones

**Forward-only.** El rollback de una migración no es la migración inversa: es restaurar el
backup y volver a desplegar. Un `down` que nunca se corrió en producción miente.

**Expandir y contraer**, cuando el cambio de esquema convive con la app desplegada:

1. agregar la columna nueva, nullable;
2. desplegar código que escribe en las dos;
3. backfill por lotes;
4. cambiar las lecturas;
5. recién ahí borrar la vieja.

**Un lock largo es una caída.** Antes de correr una migración, contestar: ¿qué bloquea?,
¿cuánto tarda con el volumen real?, ¿qué pasa si tarda el triple? Si no hay respuesta, no
se corre en horario de uso.

## Restore

**Se practica antes de necesitarlo.** Un restore que se improvisa en una caída no es un
plan, es una esperanza. La primera vez, hacerlo sobre una base descartable:

1. crear base vacía;
2. `pg_restore -d <base_nueva> <archivo>`;
3. verificar conteos de las tablas principales y una query de negocio;
4. recién entonces considerarlo probado, y anotar la fecha en el runbook.

## Prohibido

- `DELETE` o `UPDATE` sin `WHERE`.
- `DROP` / `TRUNCATE` sin OK explícito y sin backup verificado.
- Contraseñas en la línea de comandos: quedan en el historial y en `ps`.
- Correr una migración sin backup del paso 2.
- Escribir en producción "para ver si anda".
- Copiar dumps a un repo o a un chat.

## Plantilla de reporte

```txt
qué cambié:       <una línea>
filas afectadas:  <esperadas vs reales, o "no aplica">
verificación:     <query + salida real>
backup:           <archivo + verificado sí/no>
rollback:         <cómo se revierte, o "restore del backup X">
registrado en:    <runbook / run fechado>
```
