#!/usr/bin/env node
// ld-prosa — UserPromptSubmit hook: short per-turn nudge. SessionStart
// injects the full ruleset once, but a single injection loses attention as
// a long conversation grows — this keeps the core rule visible every turn.
// Misma lógica que el plugin de opencode (plugins/ld-prosa/opencode-plugin.js):
// si cambia una, cambiar la otra.
//
// El idioma no está hardcodeado: sale de ~/.config/ld-harness/config.env y,
// si existe, de <repo>/.ld-harness.env (el del proyecto pisa al del usuario).

const fs = require('fs')
const os = require('os')
const path = require('path')

const DEFAULTS = {
	LD_PROSA_CHAT: 'es-AR',
	LD_PROSA_ARTIFACTS: 'en',
	LD_PROSA_REGISTER: 'informal',
}

function merge(file, out) {
	try {
		for (const line of fs.readFileSync(file, 'utf8').split('\n')) {
			const m = line.match(/^\s*([A-Z0-9_]+)\s*=\s*(.*?)\s*$/)
			if (m && m[2] !== '') out[m[1]] = m[2]
		}
	} catch {}
}

function loadConfig() {
	const out = { ...DEFAULTS }
	merge(path.join(os.homedir(), '.config', 'ld-harness', 'config.env'), out)
	merge(path.join(process.cwd(), '.ld-harness.env'), out)
	return out
}

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
	'grammar. Rebuild intuition with one concrete example first whenever ' +
	'the reader re-enters context, not only when a term is new. Reasoning ' +
	'in whole sentences, topology in a diagram. Close on the consequence. ' +
	'Flag unverified claims and decision reversals explicitly. Inside a ' +
	'source file none of this applies: comments are Annotation — one ' +
	'line, two if the consequence needs it.'

process.stdout.write(
	JSON.stringify({
		hookSpecificOutput: {
			hookEventName: 'UserPromptSubmit',
			additionalContext: configLine(loadConfig()) + ' ' + RULES,
		},
	}),
)
