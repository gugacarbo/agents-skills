import assert from "node:assert/strict";
import test from "node:test";
import { events } from "../src/events.js";

test("uses kebab-case event names", () => {
	assert.deepEqual(events, ["user-signed-up", "project-created"]);
});
