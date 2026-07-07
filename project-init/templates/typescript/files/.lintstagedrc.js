/**
 * @filename: lint-staged.config.js
 * @type {import('lint-staged').Configuration}
 */
export default {
	"*.{js,ts,mjs,cjs,json,jsonc,yml,yaml,toml,html,css}": "pnpm format",
	"*.{md,mdx}": "pnpm format:md",
};
