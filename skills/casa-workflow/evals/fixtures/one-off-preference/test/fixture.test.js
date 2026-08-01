import assert from "node:assert/strict";
import test from "node:test";
import { fixtureName } from "../src/fixture.js";

test("uses the requested fixture name", () => {
	assert.equal(fixtureName, "temporary-user");
});
