import type { Plugin } from "@opencode-ai/plugin"

const runtime = "__RUNTIME_ROOT__/.task-completion-notifier/scripts/hook-dispatch.py"
const stateDir = "__RUNTIME_ROOT__/.task-completion-notifier/state"
const notifier = "__RUNTIME_ROOT__/.task-completion-notifier/scripts/notify.sh"

export const TaskCompletionNotifier: Plugin = async ({ $ }) => ({
  event: async ({ event }) => {
    if (event.type !== "session.idle") return

    await $`python3 ${runtime} --agent opencode --event session.idle --state-dir ${stateDir} --notifier ${notifier}`
  },
})
