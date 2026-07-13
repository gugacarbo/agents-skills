import type { Plugin } from "@opencode-ai/plugin"

const dispatcher = __DISPATCH_JSON__
const repoRoot = __REPO_ROOT_JSON__
const notifier = __NOTIFIER_JSON__

export const TaskCompletionNotifier: Plugin = async ({ $ }) => ({
  event: async ({ event }) => {
    if (event.type !== "session.idle") return

    await $`python3 ${dispatcher} --agent opencode --event session.idle --repo-root ${repoRoot} --notifier ${notifier} --session-id ${event.properties.sessionID}`
  },
})
