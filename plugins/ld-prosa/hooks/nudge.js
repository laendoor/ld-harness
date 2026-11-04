// The per-turn reminder, shared by the Claude UserPromptSubmit hook and the
// opencode plugin. One text, so editing the rule cannot leave one engine behind.
// The plugin is ESM and imports this CommonJS module the same way it imports
// config.js.

const { loadConfig } = require('./config')

const LANG_NAME = { en: 'inglés', es: 'español', 'es-AR': 'español rioplatense' }

function configLine(c) {
	const chat = c.LD_PROSA_CHAT
	const treat = chat.startsWith('es')
		? `, trato ${chat === 'es-AR' ? 'voseo' : c.LD_PROSA_REGISTER}`
		: ''
	const art = LANG_NAME[c.LD_PROSA_ARTIFACTS] || c.LD_PROSA_ARTIFACTS
	return (
		`ld-harness: respondé en ${LANG_NAME[chat] || chat}${treat}. ` +
		`Artefactos — commits, PRs, tickets, docs — en ${art}. ` +
		`Código, identificadores y comentarios, siempre en inglés.`
	)
}

const RULES =
	'Default precise/terse — cut data and ceremony, never the ' +
	'reasoning (rules carry their why); compression removes ideas, never ' +
	'grammar. Name who does what: if the reader must rebuild the agent, ' +
	'decompress. Rebuild intuition with one concrete example first whenever ' +
	'the reader re-enters context, not only when a term is new. Reasoning ' +
	'in whole sentences, topology in a diagram. Close on the consequence. ' +
	'Flag unverified claims and decision reversals explicitly. Inside a ' +
	'source file none of this applies: comments are Annotation — one ' +
	'line, two if the consequence needs it.'

function reminderText() {
	return configLine(loadConfig()) + ' ' + RULES
}

module.exports = { reminderText }
