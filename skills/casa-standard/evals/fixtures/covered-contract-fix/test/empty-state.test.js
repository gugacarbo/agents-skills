import assert from "node:assert/strict";
import test from "node:test";
import { emptyState } from "../src/empty-state.js";

test("shows the accepted empty-state CTA", () => {
	assert.deepEqual(emptyState(), {
		title: "Nenhum projeto",
		action: "Criar projeto",
	});
});
