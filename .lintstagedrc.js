/**
 * '*.ts': {
 *  title: 'Log staged TS files to console',
 *  task: async (files) => {
 *   console.log('Staged TS files:', files);
 *  },
 * },
 * @filename: lint-staged.config.js
 * @type {import('lint-staged').Configuration}
 */
export default {
	"*.{json,jsonc,js,ts,jsx,tsx}": (files) =>
		`pnpm exec biome check --write --no-errors-on-unmatched ${files.map((file) => JSON.stringify(file)).join(" ")}`,
	"*.{md,mdx}": (files) =>
		`pnpm prettier --write ${files.map((file) => JSON.stringify(file)).join(" ")} --log-level=warn --cache`,
	"*.sh": (files) =>
		`pnpm exec prettier --write ${files.map((file) => JSON.stringify(file)).join(" ")} --plugin=prettier-plugin-sh --log-level=warn --cache`,
	"*.{js,ts,jsx,tsx}": [
		// Run TypeScript compiler on staged files without emitting output
		"tsc-files --noEmit",
		// Run test-staged to execute tests related to staged files
		"test-staged",
	],
};
