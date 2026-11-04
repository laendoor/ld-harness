#!/usr/bin/env node
// ld-prosa — SessionStart hook: inject the ruleset so it's live from turn one,
// instead of waiting to be invoked as an on-demand skill.
// The skill files are the source of truth — this reads the core and the
// configured references at runtime, so edits propagate without touching this.
//
// core and references are two commands because Claude Code caps a hook's stdout
// at 10,000 characters and replaces anything longer with a 2 KB preview; on the
// default config the two together cross it. posturas.md stays out on purpose:
// the core names it, and it is read when a posture trigger fires.
//
// Usage: ld-prosa-activate.js [core|references] — anything but "references"
// prints core, so no invocation can cross the cap.

const fs = require('fs');
const path = require('path');
const { loadConfig, language } = require('./config');

const root = path.join(__dirname, '..', 'skills', 'ld-prosa');
const part = process.argv[2] === 'references' ? 'references' : 'core';

function read(file) {
  try {
    const raw = fs.readFileSync(path.join(root, file), 'utf8');
    return raw.replace(/^---[\s\S]*?---\s*/, '').trim(); // strip YAML frontmatter
  } catch (e) {
    return null;
  }
}

const core = read('SKILL.md');

const chunks = [];
if (part === 'core' && core) {
  chunks.push('LD-PROSA ACTIVE — skill files in ' + root + '\n\n' + core);
}

if (part === 'references') {
  const config = loadConfig();
  const langs = [
    ...new Set([language(config.LD_PROSA_CHAT), language(config.LD_PROSA_ARTIFACTS)]),
  ].filter(Boolean);
  for (const lang of langs) {
    const body = read(path.join('references', lang + '.md'));
    if (body) chunks.push(body);
  }
}

if (chunks.length) process.stdout.write(chunks.join('\n\n---\n\n'));
