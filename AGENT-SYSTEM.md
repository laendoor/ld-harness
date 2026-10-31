# Sistema de agentes — diseño en curso

Documento de trabajo de la rama `feat/agent-system`. **Muere al mergear**: lo que
sobreviva pasa al body del PR y a los archivos que correspondan. No se mantiene.

Fase: definición. Nada de lo de abajo está implementado salvo lo que dice `hecho`.

## Decisiones

**D1 · Rol = modo del mismo agente.** No agentes separados. Sin handoff, sin estado
compartido, sin orquestación. El contexto es uno: cambiar de rol no limpia la ventana.
La memoria NO se segmenta por rol (segmentar resta hoy). Reevaluar la maquinaria más
adelante; si alguna vez se separan, ese es el momento de diseñar particiones.

**D2 · Router sobre Jev** (TypeSafe, `docs.typesafe.ai`). Jev recibe `state` + preguntas
tipadas (`Choice` / `Score` / `Noul`) y devuelve valores con probabilidad y confianza
calibrada. La política de ruteo vive en código nuestro, no en un prompt. Jev no tiene
tools: el `state` se construye a mano. Fallback obligatorio: mismo cuestionario con un
clasificador in-context — sirve de respaldo y de grupo de control para medirlo.

**D3 · Canon de una decisión = el cuerpo del commit.** Qué, por qué, qué se descartó. La
bitácora es práctica local de `proyecto-finisterre` (hay informe y defensa), no se
replica acá. `ld-adr` queda para decisiones que cruzan repos o que hay que defender
académicamente; los adapters (`aika-adr`, `fini-adr`) pueden endurecer esa regla.

**D4 · Cierre = `ld-self-eval`.** Walkthrough corto + evaluación de comprensión antes de
aprobar. Opuesto complementario de `ld-self-review`: esa pregunta _¿está bien el código?_,
esta pregunta _¿entendiste lo que aprobás?_. Cantidad de preguntas proporcional al scope.
Multiple choice + confianza 1..5 por respuesta. Las preguntas las propone un agente fresco
a partir de la superficie de riesgo que declaró el que implementó.

**No bloquea.** Evalúa, ofrece continuar y **registra** el resultado para análisis
posterior. El bloqueo se decide cuando la mecánica esté definida. Puntos de disparo: al
abrir el PR desde el flujo de tarea, y al dar veredicto en `ld-code-review-pr`.

Limitación conocida: sin bloqueo, los datos quedan sesgados hacia las tareas donde uno se
toma el trabajo. Sirven para aprender, no para medir tasa de acierto.

**D5 · El cierre de un inventario es una clasificación, no un reporte.** Cada hallazgo cae
en un balde: **acción ahora** (riesgo activo o reversible y corto: parches, paquetes,
permisos), **issue** (requiere diseño o el dueño es otro repo) o **nota** (corrige el
runbook). El issue va al repo **dueño del componente**, no al de ops. Precedencia: primero
lo que baja el riesgo hoy, después lo que requiere diseño.

**D6 · El adapter es del proyecto, nunca del playbook.** Dos playbooks sobre el mismo
entorno comparten host y credenciales; con un adapter por playbook el dato se duplica y
divergen. Ubicación: `<repo>/ops/adapter.md` si el proyecto es un repo;
`~/.config/opencode/adapters/<tipo>-<nombre>.md` si es cross-proyecto (un host que sirve a
varios repos). El prefijo nombra la clase de entorno (`droplet-`), no el proyecto. El
adapter absorbe desviaciones en vez de forzar convenciones: si el runbook vive en la raíz
del repo, lo declara.

**D7 · La unidad es `skills/`. No hay carpeta `playbooks/`.** En opencode lo único
descubrible es `skill` (por `description`) y `command` (por `/`); un `playbooks/` sería un
directorio de archivos planos que solo el router puede leer. Y en pstack tampoco es una
categoría hermana: es una subcarpeta dentro de `poteto-mode`, porque con 23 playbooks
compitiendo por el mismo trigger la descripción deja de rutear bien.

La razón para quedarse: **la descripción es el router y ya rutea gratis.** B1 mostró que el
84% de las entradas pasa por un procedimiento, y el modelo lo elige por descripción sin
maquinaria. El umbral para separar no es estético: cuando dos playbooks empiecen a competir
por el mismo trigger y el modelo elija mal, o al pasar de ~10. Ahí se discute con evidencia
de misfires.

**Nota operativa:** opencode ignora frontmatter desconocido, así que `allowed-tools` en un
skill **no restringe nada**. El límite real es `permission.bash` (el gate) y
`permission.skill`.

## Mapa

```txt
ENTRADA ──→ TRABAJO ──→ CIERRE          ← etapas del ciclo
 router     playbooks    self-eval
            skills

   aprendizaje · memoria · escritura     ← transversales, no etapas
```

## B1 · Inventario (resultado, 2026-10-31)

Corpus: 1183 prompts de usuario en 5 proyectos (jul–oct 2026). De esos, 444 son
cuerpos de comando pegados y 739 son pedidos reales. 79 sesiones. Últimas 8 semanas:
academika 579 prompts en 21 días · proyecto-finisterre 61/9 · inmobiliaria 42/4 ·
crocante-bot 18/1 · espi 17/1.

**Entrada de sesión** (primer prompt, 63 sesiones con contenido):

| cómo arranca                                                   | n   | %   |
| -------------------------------------------------------------- | --- | --- |
| orientación (`status` 21 + `retomar` 6)                        | 27  | 43% |
| entrada/salida de flujo (`start-ticket` 11, `ship`/`close` 15) | 26  | 41% |
| pedido libre                                                   | 10  | 16% |

**Clases con evidencia** (hits por keyword sobre 739 pedidos, no excluyentes):

| clase                             | hits | procedimiento hoy                |
| --------------------------------- | ---- | -------------------------------- |
| tooling / harness                 | 156  | parcial (`ld-improve-harness`)   |
| ops / deploy / server             | 125  | **ninguno**                      |
| refactor / mejora                 | 100  | `ld-implement-task`              |
| status                            | 78   | `ld-status`                      |
| fix                               | 72   | `ld-implement-task`              |
| meta (convenciones, checklists)   | 62   | parcial                          |
| why / investigar                  | 60   | `ld-how`-like, no existe         |
| db (dumps, migraciones)           | 52   | **ninguno**                      |
| escritura (informe, doc, runbook) | 29   | parcial (`fini-latex`, `ld-adr`) |
| infra de la mac (vscode, zsh)     | 18   | **ninguno**                      |

**Lectura**

1. El 84% de los arranques de sesión ya está proceduralizado. El router resuelve el 16%
   — su valor está en la entrada libre y, sobre todo, en re-rutear a mitad de tarea.
2. El catálogo no está corto: está **incompleto en las clases riesgosas**. `ops` y `db`
   suman 177 hits (24%) y no tienen procedimiento. Son las únicas clases irreversibles.
3. `status` + `retomar` son el 43% de los arranques. Puede ser dolor medido o ritual
   instalado; no se distingue desde el log.

**Limitaciones** — unidad = pedido inferido (nuevo ticket, nuevo comando o nueva
formulación de objetivo); los buckets por keyword se solapan, así que no suman 100.
`crocante-bot` y `espi` tienen 1 día de actividad cada uno en 8 semanas: reactivarlos es
una decisión, no un resultado del inventario.

## A2 · Contrato candidato (extraído de `ld-ops`)

No inventado: sale de escribir el primero y ver qué se repite.

**Núcleo — todo playbook lo tiene:**

1. **Pasos numerados**, cada uno con su verificación pegada. Un paso sin forma de saber
   si salió no es un paso, es un deseo.
2. **Criterio de salida explícito y externo.** Verificar con algo distinto al comando que
   hizo el cambio. El exit code no es evidencia.
3. **Prohibido.** Lista corta, concreta y con el porqué. Sin esto el agente improvisa.
4. **Plantilla de reporte** cerrada: qué cambió, verificación real, rollback, qué queda
   pendiente.
5. **Frontmatter con triggers** + command fino como entrypoint que anuncia su uso.

**Opcional según el tipo de trabajo:**

- _Regla de oro_ (leer antes de mutar): obligatoria solo si hay pasos irreversibles.
- _Dónde va lo aprendido_: obligatorio si el trabajo genera gotchas reutilizables.
- _Separación estado/procedimiento_: solo cuando ya existe un doc de estado.

**El adapter aporta parámetros, no pasos.** Qué declara está en `skills/ld-ops/SKILL.md`
(§ _Lo que el adapter tiene que declarar_): acceso, orquestación, verificación, ventana de
arranque, irreversible, ownership y dónde van los documentos. Un playbook genérico no
menciona hosts, puertos ni UIDs.

**Validado con dos instancias** (`ld-ops`, `ld-db`): 5 de 7 secciones coinciden por nombre.
El segundo caso reveló que _Diagnóstico_ y _Convención de documentos_ no son específicas de
ops: son transversales y hoy viven en un solo archivo.

**Desmentido con la tercera** (`ld-research`): la intersección real de los tres son tres
secciones —_Los cinco pasos_, _Prohibido_, _Plantilla_— y ninguna repite texto, solo la
forma. Lo que se creía duplicación transversal era coincidencia de nombres con contenido
distinto. **No se extrae nada a `references/`**: el esqueleto es el contrato, no un archivo
compartido. Se revisa si un cuarto playbook necesita el triage de hallazgos.

**`ld-research` no tiene adapter y no lo necesita.** Es la prueba de que el contrato no
depende de la capa de parámetros: investigar no sabe de entornos.

**Prohibido en el contrato:** secciones de "contexto" o "filosofía". Si una línea no
cambia lo que el agente hace, no entra.

## Backlog

| id  | qué                                | produce                                    | estado       | depende de       |
| --- | ---------------------------------- | ------------------------------------------ | ------------ | ---------------- |
| A1  | Contrato de rol                    | definición de qué compone un modo          | cerrado (D1) | —                |
| A2  | Contrato de procedimiento          | formato de playbook + uno de muestra       | pendiente    | A1               |
| B1  | Inventario de tareas reales        | clase → frecuencia → ¿duele?               | hecho 31/10  | —                |
| B2  | Catálogo de playbooks              | 5-7 playbooks con criterio de salida       | pendiente    | B1, A2           |
| A3  | Spec del router                    | batería de preguntas + política + fallback | pendiente    | B2               |
| C1  | Jev vs clasificador in-context     | comparación medida                         | pendiente    | A3               |
| C2  | Prototipo medido                   | acierto sobre 30 tareas reales             | pendiente    | C1               |
| B3  | Matriz de cobertura de skills      | paso → skill existente / crear / borrar    | pendiente    | B2               |
| E1  | Auditoría de duplicación de hechos | dónde se dice lo mismo N veces             | pendiente    | —                |
| E2  | Fuente canónica por tipo de hecho  | regla + punteros de una línea              | pendiente    | E1, D3           |
| E4  | Formato de commit con el porqué    | sección en la plantilla de commit          | pendiente    | D3               |
| E3  | Mapa de lectura por repo           | archivo + check de paths                   | pendiente    | E2               |
| C3  | Spec de `ld-self-eval`             | preguntas, scoring, registro del veredicto | pendiente    | —                |
| C4  | Implementación de `ld-self-eval`   | skill + command                            | pendiente    | C3, B2           |
| D1  | Diff `ld-prosa` vs `unslop`        | tabla de reglas con veredicto              | pendiente    | —                |
| D2  | Nueva `ld-prosa`                   | archivo + 5 pares antes/después            | pendiente    | D1               |
| P1  | Playbook `ld-ops`                  | skill + command, genérico con adapter      | hecho 31/10  | —                |
| P2  | Playbook `ld-db`                   | skill + command, genérico con adapter      | hecho 31/10  | P1               |
| P3  | Playbook `ld-research`             | skill + command, sin adapter               | hecho 31/10  | P2               |
| P4  | Adapters `droplet-*`               | 12-cactus y academika, nivel usuario       | hecho 31/10  | P1, P2           |
| P5  | `ld-gate`: texto vs ejecución      | patrones de prosa no bloquean gh/git       | hecho 31/10  | —                |
| F   | Implementación por slices          | ramas chicas, una por cambio               | pendiente    | todo lo anterior |

## No objetivos

- Roles docente / estudiante / asistente separados. Primero el patrón con ingeniero.
- Portar pstack. Se copian ideas, no 60 skills.
- Paneles multi-modelo (arena / swarm / interrogate). `ld-self-review` cubre el ángulo.
- Bitácora dentro del harness.
- La app de comprensión post-tarea: proyecto aparte, ver `proyecto-finisterre` (memoria).

## Preguntas abiertas

1. ¿B1 tiene muestra suficiente en engram, o hay que capturar dos semanas antes?
2. ¿La confianza 1..5 se usa como probabilidad o solo como "sé / creo / adivino"?
3. ¿El disparo del PR es `ld-ship-task` o `ld-start-task`?
