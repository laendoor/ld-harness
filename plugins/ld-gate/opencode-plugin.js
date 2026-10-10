// ld-gate — enforcement determinístico del harness.
//
// Regla del harness: instrucciones para gusto (AGENTS.md), permisos para
// seguridad, hooks para calidad. Este plugin es el tercer nivel: lo que está
// acá se cumple aunque el modelo no quiera.
//
// v0: lista mínima de patrones catastróficos en bash. Las deny-lists por
// perfil viven en profiles/ (roadmap) y se cablean acá.

const CATASTROPHIC = [
	/\brm\s+-rf?\s+\/$/, // rm -rf /
	/\brm\s+-rf?\s+\/\*/, // rm -rf /*
	/\bmkfs(\.|$|\s)/, // mkfs.*
	/: ?\(\) ?\{ ?: ?\| ?: ?& ?\} ?;/, // fork bomb
	/> ?\/dev\/sd[a-z]\b/, // overwrite de disco
];

export const LdGatePlugin = async () => {
	return {
		"tool.execute.before": async (_input, output) => {
			// ponytail: solo bash en v0; edit/write se gatean por permiso + perfil
			const cmd =
				output?.args?.command ?? output?.args?.cmd ?? output?.args?.script ?? "";
			if (typeof cmd !== "string" || cmd.trim() === "") return;
			for (const re of CATASTROPHIC) {
				if (re.test(cmd)) {
					throw new Error(
						`[ld-gate] comando bloqueado por patrón catastrófico ${re}: ${cmd.slice(0, 120)}`,
					);
				}
			}
		},
	};
};
