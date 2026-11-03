// ld-prosa — config resolution shared by the two Claude hooks. Same three levels
// as the rest of the harness: code default < user file < project file.

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
			if (!m) continue
			const value = m[2].replace(/^(['"])(.*)\1$/, '$2')
			if (value !== '') out[m[1]] = value
		}
	} catch {}
}

function loadConfig() {
	const out = { ...DEFAULTS }
	merge(path.join(os.homedir(), '.config', 'ld-harness', 'config.env'), out)
	merge(path.join(process.cwd(), '.ld-harness.env'), out)
	return out
}

// The language whose reference a locale or an artifacts setting selects.
function language(value) {
	const v = String(value || '').toLowerCase()
	if (v.startsWith('es')) return 'es'
	if (v.startsWith('en')) return 'en'
	return null
}

module.exports = { loadConfig, language }
