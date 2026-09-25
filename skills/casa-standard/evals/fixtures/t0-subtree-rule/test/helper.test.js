import assert from "node:assert/strict";
import test from "node:test";
import { helper } from "../packages/core/helper.js";

test("exports helper by name", () => {
	assert.equal(helper(), "ok");
});
