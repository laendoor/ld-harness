#!/usr/bin/env node
// ld-prosa — UserPromptSubmit hook: short per-turn nudge. SessionStart
// injects the full ruleset once, but a single injection loses attention as
// a long conversation grows — this keeps the core rule visible every turn.
// El texto vive en hooks/nudge.js, compartido con el plugin de opencode.
//
// El idioma no está hardcodeado: sale de ~/.config/ld-harness/config.env y,
// si existe, de <repo>/.ld-harness.env (el del proyecto pisa al del usuario).

const { reminderText } = require('./nudge')

process.stdout.write(
	JSON.stringify({
		hookSpecificOutput: {
			hookEventName: 'UserPromptSubmit',
			additionalContext: reminderText(),
		},
	}),
)
