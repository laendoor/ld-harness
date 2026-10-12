// ld-prosa — reminder por turno del lado server.
//
// Equivalente v2 del viejo `tui.prompt.append`: antepone el recordatorio a
// cada prompt admitido, sin importar si viene de la TUI, un comando o la API.
// El recordatorio largo vive en skills/ld-prosa/SKILL.md (fuente de verdad
// para Claude Code vía hooks/); acá va solo el nudge corto por turno, igual
// que el UserPromptSubmit de Claude.

// Nota: sin import de "@opencode/plugin" (ver ld-gate). El schema v2 solo
// pide { id, setup }.

const REMINDER =
	"ld-prosa active: default to precise/terse, but switch to building " +
	"intuition with one concrete example before compressing into a table " +
	"or acronym when a term is new or the question is why/for-what, not " +
	"how. Flag unverified claims and decision reversals explicitly."

export default {
	id: "ld-prosa",
	async setup(ctx) {
		await ctx.session.hook("prompt", (event) => {
			// ponytail: prepend, no merge semántico
			if (typeof event.prompt.text === "string" && event.prompt.text.length > 0) {
				event.prompt.text = `${REMINDER}\n\n${event.prompt.text}`
			}
		})
	},
}
