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
const CATASTROPHIC = [
	/\brm\s+-rf?\s+\/$/, // rm -rf /
	/\brm\s+-rf?\s+\/\*/, // rm -rf /*
	/\bmkfs(\.|$|\s)/, // mkfs.*
	/: ?\(\) ?\{ ?: ?\| ?: ?& ?\} ?;/, // fork bomb
	/> ?\/dev\/sd[a-z]\b/, // overwrite de disco
]

function blockedCommand(input) {
	// ponytail: solo bash en v0; edit/write se gatean por permiso + perfil
	const cmd = input?.command ?? input?.cmd ?? input?.script ?? ""
	if (typeof cmd !== "string" || cmd.trim() === "") return undefined
	for (const re of CATASTROPHIC) {
		if (re.test(cmd)) {
			return `[ld-gate] comando bloqueado por patrón catastrófico ${re}: ${cmd.slice(0, 120)}`
		}
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
