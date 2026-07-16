# Phase 1.1: Visual Companion

Browser-based visual brainstorming companion for showing mockups, diagrams, and options during Phase 1.

## When to Use

Decide per-question, not per-session. The test: **would the user understand this better by seeing it than reading it?**

**Use the browser** when the content itself is visual:

- **UI mockups** — wireframes, layouts, navigation structures, component designs
- **Architecture diagrams** — system components, data flow, relationship maps
- **Side-by-side visual comparisons** — comparing two layouts, design directions, or visual systems
- **Design polish** — spacing, hierarchy, look and feel
- **Spatial relationships** — state machines, flowcharts, relationship maps rendered as diagrams

**Use the terminal** when the content is text or tabular:

- **Requirements and scope questions** — "what does X mean?", "which features are in scope?"
- **Conceptual A/B/C choices** — picking between approaches described in words
- **Tradeoff lists** — pros/cons, comparison tables
- **Technical decisions** — API design, data modeling, architectural approach selection
- **Clarifying questions** — anything where the answer is words, not a visual preference

A question about a UI topic is not automatically a visual question. "What kind of wizard do you want?" is conceptual — use the terminal. "Which of these wizard layouts feels right?" is visual — use the browser.

## Offering the Companion

Do NOT offer the companion upfront. Offer it only when the next question would genuinely be easier to understand visually. The offer must be its own message:

> "This next part might be easier if I show you — I can put together mockups, diagrams, and comparisons in a browser tab as we go. To do that, I'll create temporary files under `.code-toolbox/` in the project. It's still new and can be token-intensive. Want me to open it for you?"

Wait for the user's response. If they decline, continue text-only and do not offer it again unless they raise it.

Before starting the companion, explicitly warn that it will create temporary files under `.code-toolbox/` in the project directory.

## Starting a Session

Start the companion only after the user approves it:

```bash
scripts/visual-companion/start-server.sh --project-dir /path/to/project --open
```

> **Requirement:** Requires Node.js to run. If `node` is not available, skip the visual companion and proceed with text-only brainstorming.

This returns JSON like:

```json
{
  "type": "server-started",
  "port": 52341,
  "url": "http://localhost:52341/?key=ab12...",
  "screen_dir": "/path/to/project/.code-toolbox/brainstorm/12345-1706000000/content",
  "state_dir": "/path/to/project/.code-toolbox/brainstorm/12345-1706000000/state"
}
```

Save `screen_dir` and `state_dir`. Always share the complete URL, including `?key=...`.

If the startup JSON is not captured, read `$STATE_DIR/server-info`.

## The Loop

1. Confirm the server is alive before referring to the URL or pushing a screen.
2. Write a new HTML file into `screen_dir`.
3. Tell the user what is on screen and ask them to respond in the terminal.
4. On the next turn, read `state_dir/events` if present and merge that with the user's terminal feedback. If `state_dir/events` exists, read it as JSONL (one JSON object per line). Each event has at least a `type` and `payload` field.
5. Iterate by writing a fresh file each time; never reuse filenames.
6. When returning to a text-only step, push a waiting screen so stale visuals are cleared.

## Writing Content

Write content fragments by default. The server wraps them in a shared frame template automatically. Only write a full HTML document when you need total control.

Minimal example:

```html
<h2>Which layout works better?</h2>
<p class="subtitle">Consider readability and visual hierarchy</p>

<div class="options">
  <div class="option" data-choice="a" onclick="toggleSelect(this)">
    <div class="letter">A</div>
    <div class="content">
      <h3>Single Column</h3>
      <p>Clean, focused reading experience</p>
    </div>
  </div>
  <div class="option" data-choice="b" onclick="toggleSelect(this)">
    <div class="letter">B</div>
    <div class="content">
      <h3>Two Column</h3>
      <p>Sidebar navigation with main content</p>
    </div>
  </div>
</div>
```

Available building blocks come from the shared frame template:

- `.options` and `.option` for A/B/C choices
- `.cards` and `.card` for visual alternatives
- `.mockup` for previews
- `.split` for side-by-side comparisons
- `.pros-cons` for quick tradeoff framing

## Companion Files

The companion assets live here:

- `scripts/visual-companion/start-server.sh`
- `scripts/visual-companion/stop-server.sh`
- `scripts/visual-companion/server.cjs`
- `scripts/visual-companion/helper.js`
- `scripts/visual-companion/frame-template.html`

Use these files as-is unless you need to change companion behavior.

> **Namespace note:** The `.code-toolbox/` directory is shared between the visual companion (`brainstorm/`) and vendored helpers. Ensure files don't collide; brainstorm outputs go under `.code-toolbox/brainstorm/` only.

> **Cleanup:** After completing the brainstorm session, run `stop-server.sh` to clean up the background server process.
