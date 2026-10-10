---
name: ld-review-fix
description: Read review comments on the current PR and propose fixes for each. Run after receiving code review feedback — reads inline comments, proposes concrete fixes, applies approved ones, and pushes.
allowed-tools: Bash, Read, Glob, Edit
---

# Review Fix

Lee los comentarios de review del PR activo y propone fixes concretos para cada uno.

## Steps

### 1. Obtener PR y comentarios

```bash
gh pr view --json number,title,headRefName
gh pr view --json reviews
gh api repos/{owner}/{repo}/pulls/{number}/comments
```

Para obtener `{owner}/{repo}`, usá:

```bash
gh repo view --json nameWithOwner --jq '.nameWithOwner'
```

### 2. Clasificar los comentarios

Agrupá por archivo y tipo:

- **Blocking** — el reviewer pidió cambio explícito (`request-changes`)
- **Discussion** — sugerencia o pregunta, no blocking
- **Resolved** — ya marcado como resuelto → ignorar

Procesá primero los blocking, luego los discussion.

### 3. Para cada comentario

Leé el archivo afectado en el contexto del comentario. Proponé un fix concreto.

Presentalo así:

```txt
**Comentario en api/models/alumno.py:38**
Reviewer: "Este campo debería ser Optional[str] — puede venir null de Guaraní"

Fix propuesto:
  - nombre: str
  + nombre: Optional[str] = None

¿Aplicar? [s = aplicar / n = saltar / v = ver más contexto]
```

### 4. Aplicar fixes aprobados

Para cada fix que el usuario aprueba, aplicarlo directamente con Edit sobre el archivo afectado.

### 5. Commit final

Cuando todos los fixes estén aplicados, stagear los archivos modificados y sugerir el commit:

```txt
fix(review): address PR #{number} comments
```

### 6. Push

```bash
git push
```

El PR se actualiza automáticamente — los comentarios que tenían fix aplicado quedan resueltos.

### 7. Reportar

```txt
Fixes aplicados: N/{total}
Saltados: N
Push: ok — PR #{number} actualizado
```

## Rules

- Nunca aplicar un fix sin aprobación explícita del usuario
- Si un comentario no tiene fix obvio, decirlo y preguntar cómo proceder
- Si el PR no tiene comentarios pendientes, decirlo y no hacer nada
