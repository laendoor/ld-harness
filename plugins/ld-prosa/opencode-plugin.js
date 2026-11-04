// ld-prosa — reminder por turno del lado server.
//
// Inyecta el recordatorio en el system de cada request del agent loop
// (hook "context"), NO en el texto del prompt: reescribir el prompt lo
// vuelve input canónico persistido (bloat en historial/compaction) y
// desplaza los offsets de mention de adjuntos. En system es efímero por
// request y se re-aplica solo tras cada compaction.
// El recordatorio largo vive en skills/ld-prosa/SKILL.md (fuente de verdad);
// el nudge corto está en hooks/nudge.js, compartido con el hook de Claude
// (hooks/ld-prosa-reminder.js): una sola copia del texto.
//
// El idioma no está hardcodeado: sale de ~/.config/ld-harness/config.env y,
// si existe, de <repo>/.ld-harness.env (el del proyecto pisa al del usuario).

// Nota: sin import de "@opencode/plugin" (ver ld-gate). El schema v2 solo
// pide { id, setup }. Los builtins de node sí resuelven siempre.
import { reminderText } from "./hooks/nudge.js"

export default {
	id: "ld-prosa",
	async setup(ctx) {
		await ctx.session.hook("context", (event) => {
			// ponytail: append al último system (patrón engram) — algunos
			// modelos rechazan múltiples bloques system (issue #23).
			const text = reminderText()
			const system = event.system ?? []
			if (system.length > 0) {
				const last = system[system.length - 1]
				if (typeof last?.text === "string") {
					last.text += "\n\n" + text
					return
				}
			}
			system.push({ type: "text", text })
		})
	},
}
