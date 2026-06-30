### Task N: [Component Name]

**Files:**

- Create: `exact/path/to/file.py`
- Modify: `exact/path/to/existing.py:123-145`
- Test: `tests/exact/path/to/test.py`

**Interfaces:**

- Consumes: [what this task uses from earlier tasks — exact signatures]
- Produces: [what later tasks rely on — exact function names, parameter
  and return types. A task's implementer sees only their own task; this
  block is how they learn the names and types neighboring tasks use.]

- [ ] **Step 1: Write the failing test**

```python
def test_specific_behavior():
    result = function(input)
    assert result == expected
```

- [ ] **Step 2: Run test to verify it fails**

Run: `pytest tests/path/test.py::test_name -v`
Expected: FAIL with "function not defined"

- [ ] **Step 3: Write minimal implementation**

```python
def function(input):
    return expected
```

- [ ] **Step 4: Run test to verify it passes**

Run: `pytest tests/path/test.py::test_name -v`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add tests/path/test.py src/path/file.py
git commit -m "feat: add specific feature"
```

---

**Notes on the Interfaces block:**

The Interfaces block is critical for parallel dispatch. Implementers see only their own task brief, so they learn about neighboring tasks' APIs through Consumes and Produces declarations. Without exact signatures, parallel tasks will produce incompatible interfaces.

- **Consumes:** List every function, type, or module this task imports from an earlier task, with exact signatures.
- **Produces:** List every function, type, or export this task makes available to later tasks, with exact signatures.

Every step must contain the actual content an implementer needs. Never write placeholders like "TBD", "TODO", "implement later", "Add appropriate error handling" (without the code), "Write tests for the above" (without test code), or "Similar to Task N" (repeat the code — the implementer may read tasks out of order).
