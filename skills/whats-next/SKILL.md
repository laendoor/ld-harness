---
name: whats-next
description: Use when the user wants to see what GitHub issues are available to pick up. Shows issues assigned to @me and unassigned. Triggered by /whats-next or "qué hay para hacer".
---

# What's Next

Muestra los issues disponibles para elegir qué trabajar.

## Steps

### 1. Fetch issues — dos queries en paralelo

```bash
gh issue list --assignee @me --state open --json number,title,labels,milestone --limit 30
gh issue list --assignee "" --state open --json number,title,labels,milestone --limit 30
```

### 2. Merge y deduplicar

Combiná ambas listas eliminando duplicados (mismo número). Marcá los asignados a `@me` con 👤.

### 3. Ordenar

Prioridad de ordenamiento:

1. Milestone (ascendente — el milestone más temprano es más urgente)
2. Número de issue (ascendente)

### 4. Filtrar

Excluir issues con label `blocked` o `wontfix`.

### 5. Presentar

```txt
Issues disponibles:

  #38  [fase-1, backend]  Scaffold FastAPI base        (Fase 1)  👤
  #40  [fase-1, backend]  Modelos de datos base         (Fase 1)
  #42  [fase-1, data]     Importador Guaraní CSV→DB     (Fase 1)

Sugerencia: #38 — prerequisito del resto de Fase 1.

Para arrancar: /start-ticket 38
```

### 6. Terminar con

```txt
Para arrancar: /start-ticket <número>
```

## Rules

- Si no hay issues, decirlo y sugerir crearlos
- Si hay más de 10, mostrar los primeros 10 y avisar cuántos quedan
