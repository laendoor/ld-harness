// ld-gate — enforcement determinístico del harness.
//
// Regla del harness: instrucciones para gusto (AGENTS.md), permisos para
// seguridad, hooks para calidad. Este plugin es el tercer nivel: lo que está
// acá se cumple aunque el modelo no quiera.
//
// v0: lista mínima de patrones catastróficos en bash. Las deny-lists por
// perfil viven en profiles/ (roadmap) y se cablean acá.

// Nota: sin import de "@opencode/plugin" — Plugin.define es identidad y el
// import estático rompería la carga si el runtime no lo resuelve para
// archivos sueltos. El schema v2 solo pide { id, setup }.
// Misma lista que hooks/block-catastrophic.sh (Claude): si cambia una, cambiar la otra.
//
// Dos grupos. El estructural mata hardware o filesystem y se escanea siempre. El
// de texto son palabras que también aparecen en prosa —el cuerpo de un issue, un
// mensaje de commit que documenta el rollback— así que se saltea cuando el
// comando arranca con gh o git y no trae sustitución ni separadores: ahí el único
// binario que corre es ese, y lo que sigue es dato.
// shortcut: `git -c alias.x='!dropdb y' x` se colaría; eso lo cubre el revisor.
const STRUCTURAL = [
	/\brm\s+-rf?\s+\/$/, // rm -rf /
	/\brm\s+-rf?\s+\/\*/, // rm -rf /*
	/\bmkfs(\.|$|\s)/, // mkfs.*
	/: ?\(\) ?\{ ?: ?\| ?: ?& ?\} ?;/, // fork bomb
	/> ?\/dev\/sd[a-z]\b/, // overwrite de disco
]

const TEXT_ONLY = [
	/\balembic[-\s]+downgrade\b/i, // `downgrade base` dropea todas las tablas
	/\bdropdb\b/i, // binario dropdb
	/\bpg_restore[^\n]*--clean\b/i, // restauración que dropea antes de crear
	/\bdocker\s+volume\s+rm\b/i, // se lleva el volumen de postgres
	/\bdocker[^\n]*\bdown\b[^\n]*(\s-[a-z]*v[a-z]*|--volumes)\b/i, // docker compose down -v
]

const TEXT_WRITER = /^\s*(gh|git)\s/
const SHELL_EXEC = /[$][(]|`|;|&|[|]/
// `cd X &&` antes del comando real: sin esto la exención no se activa nunca,
// porque el shell habitual arranca con cd.
const CD_PREFIX = /^\s*(cd\s+[^&\s]+\s*&&\s*)+/

function isTextOnly(cmd) {
	const probe = cmd.replace(CD_PREFIX, "")
	// Una sola línea: un script multilínea que empiece con git podría llevar un
	// comando destructivo en la segunda línea, y la exención lo taparía.
	if (probe.includes("\n")) return false
	return TEXT_WRITER.test(probe) && !SHELL_EXEC.test(probe)
}

// SQL destructivo sólo importa si el comando habla con la base: así `grep truncate`
// y una commit message que lo nombre pasan, y el heredoc —que trae el cliente y la
// sentencia en líneas distintas— queda cubierto.
const SQL_CLIENT = /\b(psql|dropdb|pg_restore|pg_dumpall|alembic[-\s])\b/i
const DESTRUCTIVE_SQL =
	/\b(truncate|delete\s+from|drop\s+(database|schema|table|extension|column))\b/i

function blockedCommand(input) {
	// ponytail: solo bash en v0; edit/write se gatean por permiso + perfil
	const cmd = input?.command ?? input?.cmd ?? input?.script ?? ""
	if (typeof cmd !== "string" || cmd.trim() === "") return undefined
	for (const re of STRUCTURAL) {
		if (re.test(cmd)) {
			return `[ld-gate] comando bloqueado por patrón catastrófico ${re}: ${cmd.slice(0, 120)}`
		}
	}
	if (isTextOnly(cmd)) return undefined
	for (const re of TEXT_ONLY) {
		if (re.test(cmd)) {
			return `[ld-gate] comando bloqueado por patrón catastrófico ${re}: ${cmd.slice(0, 120)}`
		}
	}
	if (SQL_CLIENT.test(cmd) && DESTRUCTIVE_SQL.test(cmd)) {
		return `[ld-gate] operación SQL destructiva (cliente + sentencia): ${cmd.slice(0, 120)}`
	}
	return undefined
}

export default {
	id: "ld-gate",
	async setup(ctx) {
		await ctx.tool.hook("execute.before", (event) => {
			const reason = blockedCommand(event.input)
			if (reason) throw new Error(reason)
		})
	},
}
