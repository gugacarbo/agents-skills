import assert from "node:assert/strict";
import test from "node:test";
import { health } from "../src/server.js";

test("returns the health contract", () => {
	assert.deepEqual(health(), { status: 200, body: { status: "ok" } });
});
