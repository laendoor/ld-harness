// ld-prosa — reminder por turno del lado server.
//
// Inyecta el recordatorio en el system de cada request del agent loop
// (hook "context"), NO en el texto del prompt: reescribir el prompt lo
// vuelve input canónico persistido (bloat en historial/compaction) y
// desplaza los offsets de mention de adjuntos. En system es efímero por
// request y se re-aplica solo tras cada compaction.
// El recordatorio largo vive en skills/ld-prosa/SKILL.md (fuente de verdad);
// acá va solo el nudge corto, misma línea canónica que el UserPromptSubmit
// de Claude (hooks/ld-prosa-reminder.js).

// Nota: sin import de "@opencode/plugin" (ver ld-gate). El schema v2 solo
// pide { id, setup }.

const REMINDER =
	"ld-prosa: default precise/terse — cut data and ceremony, never the " +
	"reasoning (rules carry their why); compression removes ideas, never " +
	"grammar. Rebuild intuition with one concrete example first whenever " +
	"the reader re-enters context, not only when a term is new. Reasoning " +
	"in whole sentences, topology in a diagram. Close on the consequence. " +
	"Flag unverified claims and decision reversals explicitly. Inside " +
	"source files none of this applies (Annotation)."

export default {
	id: "ld-prosa",
	async setup(ctx) {
		await ctx.session.hook("context", (event) => {
			// ponytail: append al último system (patrón engram) — algunos
			// modelos rechazan múltiples bloques system (issue #23).
			const system = event.system ?? []
			if (system.length > 0) {
				const last = system[system.length - 1]
				if (typeof last?.text === "string") {
					last.text += "\n\n" + REMINDER
					return
				}
			}
			system.push({ type: "text", text: REMINDER })
		})
	},
}
