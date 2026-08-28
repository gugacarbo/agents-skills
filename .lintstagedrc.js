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
	"*.{json,jsonc,js,ts,jsx,tsx}": (files) => {
		const biomeFiles = files.filter(
			(file) => !file.endsWith("/docs/index.json"),
		);
		return biomeFiles.length
			? `bunx biome check --write --no-errors-on-unmatched ${biomeFiles.map((file) => JSON.stringify(file)).join(" ")}`
			: [];
	},
	"*.{md,mdx}": (files) =>
		`bunx prettier --write ${files.map((file) => JSON.stringify(file)).join(" ")} --log-level=warn --cache`,
	"*.sh": (files) =>
		`bunx prettier --write ${files.map((file) => JSON.stringify(file)).join(" ")} --plugin=prettier-plugin-sh --log-level=warn --cache`,
	"*.{js,ts,jsx,tsx}": (files) => {
		const matched = files.filter(
			(file) =>
				file.endsWith(".ts") ||
				file.endsWith(".tsx") ||
				file === ".lintstagedrc.js",
		);
		return matched.length
			? `tsc-files --noEmit ${matched.map((file) => JSON.stringify(file)).join(" ")}`
			: [];
	},
};
