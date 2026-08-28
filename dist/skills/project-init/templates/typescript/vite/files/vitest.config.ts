import { defineConfig } from "vitest/config";

export default defineConfig({
	test: {
		// "node" cobre lógica/backend; mude para "jsdom" ou "happy-dom" em apps
		// de UI que manipulam DOM nos testes.
		environment: "node",
		// threads evita workers concorrentes deletando .vitest-coverage/.tmp
		// no meio da execução.
		pool: "threads",
		maxWorkers: 1,
		fileParallelism: false,
		passWithNoTests: true,
		onConsoleLog() {
			return false;
		},
		coverage: {
			provider: "v8",
			reportsDirectory: "./.vitest-coverage",
			reporter: ["text", "json-summary", "html-spa"],
			include: ["src/**/*.{ts,tsx}"],
			exclude: [
				"**/*.d.ts",
				"**/*.test.{ts,tsx}",
				"**/*.spec.{ts,tsx}",
				"**/test/**",
			],
			thresholds: {
				lines: 90,
				statements: 90,
				functions: 90,
				branches: 90,
			},
		},
	},
});
