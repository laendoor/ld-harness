// ld-prosa — reminder por turno del lado server.
//
// Inyecta el recordatorio en el system de cada request del agent loop
// (hook "context"), NO en el texto del prompt: reescribir el prompt lo
// vuelve input canónico persistido (bloat en historial/compaction) y
// desplaza los offsets de mention de adjuntos. En system es efímero por
// request y se re-aplica solo tras cada compaction.
// El recordatorio largo vive en skills/ld-prosa/SKILL.md (fuente de verdad);
// acá va solo el nudge corto, misma lógica que el UserPromptSubmit de Claude
// (hooks/ld-prosa-reminder.js): si cambia una, cambiar la otra.
//
// El idioma no está hardcodeado: sale de ~/.config/ld-harness/config.env y,
// si existe, de <repo>/.ld-harness.env (el del proyecto pisa al del usuario).

// Nota: sin import de "@opencode/plugin" (ver ld-gate). El schema v2 solo
// pide { id, setup }. Los builtins de node sí resuelven siempre.
// El parser de config es el mismo que usan los hooks de Claude: hooks/config.js.
import { loadConfig } from "./hooks/config.js"

const LANG_NAME = { en: "inglés", es: "español", "es-AR": "español rioplatense" }

function configLine(c) {
	const chat = c.LD_PROSA_CHAT
	const treat = chat.startsWith("es")
		? `, trato ${chat === "es-AR" ? "voseo" : c.LD_PROSA_REGISTER}`
		: ""
	const art = LANG_NAME[c.LD_PROSA_ARTIFACTS] || c.LD_PROSA_ARTIFACTS
	return (
		`ld-harness: respondé en ${LANG_NAME[chat] || chat}${treat}. ` +
		`Artefactos — commits, PRs, tickets, docs — en ${art}. ` +
		`Código, identificadores y comentarios, siempre en inglés.`
	)
}

const RULES =
	"Default precise/terse — cut data and ceremony, never the " +
	"reasoning (rules carry their why); compression removes ideas, never " +
	"grammar. Name who does what: if the reader must rebuild the agent, " +
	"decompress. Rebuild intuition with one concrete example first whenever " +
	"the reader re-enters context, not only when a term is new. Reasoning " +
	"in whole sentences, topology in a diagram. Close on the consequence. " +
	"Flag unverified claims and decision reversals explicitly. Inside a " +
	"source file none of this applies: comments are Annotation — one " +
	"line, two if the consequence needs it."

function reminder() {
	return configLine(loadConfig()) + " " + RULES
}

export default {
	id: "ld-prosa",
	async setup(ctx) {
		await ctx.session.hook("context", (event) => {
			// ponytail: append al último system (patrón engram) — algunos
			// modelos rechazan múltiples bloques system (issue #23).
			const text = reminder()
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
