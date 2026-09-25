import assert from "node:assert/strict";
import { readFileSync } from "node:fs";
import test from "node:test";

test("project owner is required", () => {
	const schema = readFileSync(
		new URL("../schema/projects.sql", import.meta.url),
		"utf8",
	);
	assert.match(schema, /owner_id\s+INTEGER\s+NOT NULL/i);
});
