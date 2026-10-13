#!/usr/bin/env node
// ld-prosa — UserPromptSubmit hook: short per-turn nudge. SessionStart
// injects the full ruleset once, but a single injection loses attention as
// a long conversation grows — this keeps the core rule visible every turn.
// Misma línea canónica que el plugin de opencode
// (plugins/ld-prosa/opencode-plugin.js): si cambia una, cambiar la otra.
// No mode/intensity to track (unlike caveman/ponytail-style dials), so this
// just emits the same reminder unconditionally.

process.stdout.write(JSON.stringify({
  hookSpecificOutput: {
    hookEventName: 'UserPromptSubmit',
    additionalContext:
      'ld-prosa: default precise/terse — cut data and ceremony, never the ' +
      'reasoning (rules carry their why); compression removes ideas, never ' +
      'grammar. Rebuild intuition with one concrete example first whenever ' +
      'the reader re-enters context, not only when a term is new. Reasoning ' +
      'in whole sentences, topology in a diagram. Close on the consequence. ' +
      'Flag unverified claims and decision reversals explicitly. Inside a ' +
      'source file none of this applies: comments are Annotation — one ' +
      'line, two if the consequence needs it.'
  }
}));
