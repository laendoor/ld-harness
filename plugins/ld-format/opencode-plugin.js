// ld-format — formateo estándar de markdown en opencode.
//
// Corre format-md.sh tras edit/write/patch sobre .md (Prettier + MD040).
// Espejo del hook PostToolUse de Claude (hooks/hooks.json): un script,
// dos consumidores.
//
// Nota: sin import de "@opencode/plugin" (ver ld-gate). El schema v2 solo
// pide { id, setup }.

const MARKDOWN_TOOLS = new Set(["edit", "write", "patch", "multiedit"])

export default {
	id: "ld-format",
	async setup(ctx) {
		const script = `${import.meta.dir}/format-md.sh`
		await ctx.tool.hook("execute.after", async (event) => {
			const tool = String(event.tool ?? "").toLowerCase()
			if (!MARKDOWN_TOOLS.has(tool)) return

			// v2 aplana los args en event.input.
			const input = event.input ?? event.args ?? {}
			const filePath = input.filePath ?? input.file_path ?? input.path
			if (typeof filePath !== "string" || !filePath.endsWith(".md")) return

			try {
				Bun.spawnSync(["bash", script, filePath], {
					stdout: "ignore",
					stderr: "ignore",
				})
			} catch {}
		})
	},
}
