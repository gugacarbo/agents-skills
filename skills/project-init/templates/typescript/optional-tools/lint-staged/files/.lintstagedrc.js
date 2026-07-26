/** @type {import('lint-staged').Configuration} */
export default {
	"*.{json,jsonc,js,ts,jsx,tsx}": (files) =>
		`{{pmExec}} biome check --write --no-errors-on-unmatched ${files.map((file) => JSON.stringify(file)).join(" ")}`,
	"*.{md,mdx}": (files) =>
		`{{pmExec}} prettier --write --log-level=warn --no-error-on-unmatched-pattern ${files.map((file) => JSON.stringify(file)).join(" ")}`,
	"*.{js,ts,jsx,tsx}": ["tsc-files --noEmit"],
};
